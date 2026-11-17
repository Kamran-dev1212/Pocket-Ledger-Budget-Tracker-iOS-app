
import SwiftUI
import CloudKit

struct GroupDetailView: View {

    let group: SharedGroup
    @Environment(\.dismiss) private var dismiss
    // MARK: - Sheets

    private enum ActiveSheet: Identifiable {
        case addExpense
        case editExpense(SharedExpense)
        case addMembers

        var id: String {
            switch self {
            case .addExpense:
                return "add-expense"
            case .editExpense(let expense):
                return "edit-\(expense.id.recordName)"
            case .addMembers:
                return "add-members"
            }
        }
    }

    // MARK: - State

    @State private var expenses: [SharedExpense] = []
    @State private var participants: [GroupParticipant] = []
    @State private var balances: [Balance] = []
    @State private var payments: [SettlementPayment] = []

    // Keeps recently saved records visible while CloudKit catches up.
    @State private var recentlySaved: [SharedExpense] = []

    @State private var isLoading = false
    @State private var hasLoaded = false

    @State private var activeSheet: ActiveSheet?
    @State private var expenseToDelete: SharedExpense?

    @State private var errorMessage = ""
    @State private var showError = false

    @AppStorage("selectedCurrency")
    private var currency: String = "USD"

    // MARK: - Financial Data

    private var realExpenses: [SharedExpense] {
        expenses.filter { !$0.isSettlement }
    }

    private var settlements: [SharedExpense] {
        expenses.filter { $0.isSettlement }
    }

    private var total: Double {
        realExpenses.reduce(0) { $0 + $1.amount }
    }

    private var currentUserIDs: Set<String> {
        Set(
            participants
                .filter { $0.isCurrentUser }
                .map { $0.id }
        )
    }

    private var currentUserNetBalance: Double {
        CurrencyManager.rounded(
            balances
                .filter { $0.isCurrentUser }
                .reduce(0) { $0 + $1.netAmount }
        )
    }

    private var amountOwedToYou: Double {
        CurrencyManager.rounded(
            payments
                .filter {
                    currentUserIDs.contains($0.toID)
                }
                .reduce(0) { $0 + $1.amount }
        )
    }

    private var amountYouOwe: Double {
        CurrencyManager.rounded(
            payments
                .filter {
                    currentUserIDs.contains($0.fromID)
                }
                .reduce(0) { $0 + $1.amount }
        )
    }

    private func formatted(_ amount: Double) -> String {
        CurrencyManager.string(
            for: amount,
            currencyCode: currency
        )
    }

    // MARK: - Main View

    var body: some View {

        ZStack {

            AppColors.dashboardGradient
                .ignoresSafeArea()

            VStack(spacing: 0) {

                groupHeader

                contentArea

            }

        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbarColorScheme(.dark, for: .navigationBar)
        
        
        .toolbar {

            // Custom White Back Button
            ToolbarItem(placement: .topBarLeading) {

                Button {
                    dismiss()
                } label: {

                    HStack(spacing: 5) {

                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))

                        Text("Back")
                            .font(.system(size: 17))

                    }
                    .foregroundStyle(.white)

                }
                .buttonStyle(.plain)

            }

            // Centered Screen Title
            ToolbarItem(placement: .principal) {

                Text("Group Details")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)

            }

        }

        .sheet(item: $activeSheet) { sheet in

            switch sheet {

            case .addExpense:

                AddSharedExpenseView(group: group) { saved in
                    apply(saved)
                }

            case .editExpense(let expense):

                AddSharedExpenseView(
                    group: group,
                    expense: expense
                ) { saved in
                    apply(saved)
                }

            case .addMembers:

                InviteMembersView(group: group) {
                    Task {
                        await load(showSpinner: false)
                    }
                }

            }

        }
        .confirmationDialog(
            "Delete \"\(expenseToDelete?.title ?? "")\"?",
            isPresented: Binding(
                get: { expenseToDelete != nil },
                set: {
                    if !$0 {
                        expenseToDelete = nil
                    }
                }
            ),
            titleVisibility: .visible
        ) {

            Button("Delete", role: .destructive) {
                if let expense = expenseToDelete {
                    Task {
                        await delete(expense)
                    }
                }
            }

            Button("Cancel", role: .cancel) {
                expenseToDelete = nil
            }

        } message: {

            Text(
                "This removes the record for everyone in the group and recalculates the balances."
            )

        }
        .task {
            await load()
        }
        .alert("Error", isPresented: $showError) {

            Button("OK", role: .cancel) {}

        } message: {

            Text(errorMessage)

        }

    }

    // MARK: - Purple Header

    private var groupHeader: some View {

        VStack(alignment: .leading, spacing: 12) {

            HStack(alignment: .top, spacing: 12) {

                VStack(alignment: .leading, spacing: 8) {

                    Text(group.name)
                        .font(.system(size: 27, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(2)

                    Label(
                        "\(participants.count) \(participants.count == 1 ? "Member" : "Members")",
                        systemImage: "person.2.fill"
                    )
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.85))

                }

                Spacer(minLength: 8)

                Menu {

                    Button {
                        activeSheet = .addExpense
                    } label: {
                        Label(
                            "Add Expense",
                            systemImage: "plus.circle"
                        )
                    }

                    if group.isOwnedByCurrentUser {

                        Button {
                            activeSheet = .addMembers
                        } label: {
                            Label(
                                "Add Members",
                                systemImage: "person.badge.plus"
                            )
                        }

                    }

                } label: {

                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 25))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)

                }
                .accessibilityLabel("Group Options")

            }

        }
        .padding(.horizontal, 22)
        .padding(.top, 14)
        .padding(.bottom, 28)
        .frame(maxWidth: .infinity, alignment: .leading)

    }

    // MARK: - Content Area

    private var contentArea: some View {

        ScrollView {

            VStack(spacing: 22) {

                if isLoading && !hasLoaded {

                    VStack(spacing: 16) {
                        ProgressView()
                            .tint(AppColors.dashboardPurple)

                        Text("Loading group details...")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 70)

                } else {

                    financialSummaryCard

                    quickActions

                    settlementSection

                    expensesSection

                    if !settlements.isEmpty {
                        paymentsSection
                    }

                }

            }
            .padding(.horizontal, 18)
            .padding(.top, 22)
            .padding(.bottom, 36)

        }
        .refreshable {
            await load(showSpinner: false)
        }
        .background(
            UnevenRoundedRectangle(
                topLeadingRadius: 28,
                topTrailingRadius: 28
            )
            .fill(AppColors.dashboardSurface)
            .ignoresSafeArea(edges: .bottom)
        )

    }

    // MARK: - Financial Summary

    private var financialSummaryCard: some View {

        VStack(alignment: .leading, spacing: 18) {

            VStack(alignment: .leading, spacing: 7) {

                Text("TOTAL GROUP EXPENSES")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppColors.textSecondary)

                Text(formatted(total))
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)

            }

            Divider()

            HStack(alignment: .top, spacing: 14) {

                balanceColumn(
                    title: "You are owed",
                    amount: amountOwedToYou,
                    color: AppColors.success
                )

                balanceColumn(
                    title: "You owe",
                    amount: amountYouOwe,
                    color: .orange
                )

            }

        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.card)
        .clipShape(
            RoundedRectangle(cornerRadius: 22)
        )

    }

    private func balanceColumn(
        title: String,
        amount: Double,
        color: Color
    ) -> some View {

        VStack(alignment: .leading, spacing: 7) {

            Text(title)
                .font(.system(size: 13))
                .foregroundStyle(AppColors.textSecondary)

            Text(formatted(amount))
                .font(.system(size: 19, weight: .bold))
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.65)

        }
        .frame(maxWidth: .infinity, alignment: .leading)

    }

    // MARK: - Quick Actions

    private var quickActions: some View {

        HStack(spacing: 12) {

            Button {
                activeSheet = .addExpense
            } label: {

                Label(
                    "Add Expense",
                    systemImage: "plus.circle.fill"
                )
                .font(.system(size: 14, weight: .semibold))
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .foregroundStyle(.white)
                .background(AppColors.dashboardPurple)
                .clipShape(
                    RoundedRectangle(cornerRadius: 15)
                )

            }

            NavigationLink {

                SettleUpView(group: group)

            } label: {

                Label(
                    "Settle Up",
                    systemImage: "arrow.left.arrow.right"
                )
                .font(.system(size: 14, weight: .semibold))
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .foregroundStyle(AppColors.dashboardPurple)
                .background(AppColors.card)
                .clipShape(
                    RoundedRectangle(cornerRadius: 15)
                )

            }

        }
        .buttonStyle(.plain)

    }

    // MARK: - Who Owes Whom

    private var settlementSection: some View {

        VStack(alignment: .leading, spacing: 12) {

            Text("Who Owes Whom")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(AppColors.textPrimary)

            VStack(spacing: 0) {

                if payments.isEmpty {

                    HStack(spacing: 12) {

                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(AppColors.success)

                        Text("Everyone is settled up.")
                            .font(.subheadline)
                            .foregroundStyle(AppColors.textSecondary)

                        Spacer()

                    }
                    .padding(16)

                } else {

                    ForEach(payments.indices, id: \.self) { index in

                        let payment = payments[index]

                        HStack(spacing: 12) {

                            Text(settlementLine(for: payment))
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(AppColors.textPrimary)

                            Spacer(minLength: 8)

                            Text(formatted(payment.amount))
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(AppColors.dashboardPurple)

                        }
                        .padding(16)

                        if index < payments.count - 1 {
                            Divider()
                                .padding(.horizontal, 16)
                        }

                    }

                }

                Divider()
                    .padding(.horizontal, 16)

                NavigationLink {

                    SettleUpView(group: group)

                } label: {

                    HStack(spacing: 10) {

                        Image(
                            systemName: "arrow.left.arrow.right.circle.fill"
                        )
                        .font(.system(size: 20))

                        Text("Full Breakdown")
                            .font(.system(size: 14, weight: .semibold))

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(AppColors.textSecondary)

                    }
                    .foregroundStyle(AppColors.dashboardPurple)
                    .padding(16)

                }

            }
            .background(AppColors.card)
            .clipShape(
                RoundedRectangle(cornerRadius: 18)
            )

        }

    }

    // MARK: - Expenses

    private var expensesSection: some View {

        VStack(alignment: .leading, spacing: 12) {

            HStack {

                Text("Expenses")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(AppColors.textPrimary)

                Spacer()

                Text("\(realExpenses.count)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppColors.textSecondary)

            }

            VStack(spacing: 0) {

                if realExpenses.isEmpty {

                    VStack(spacing: 12) {

                        Image(systemName: "receipt")
                            .font(.system(size: 34))
                            .foregroundStyle(AppColors.dashboardPurple)

                        Text("No Expenses Yet")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(AppColors.textPrimary)

                        Text("Add the first expense for this group.")
                            .font(.system(size: 13))
                            .foregroundStyle(AppColors.textSecondary)
                            .multilineTextAlignment(.center)

                        Button("Add Expense") {
                            activeSheet = .addExpense
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppColors.dashboardPurple)

                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 30)
                    .padding(.horizontal, 16)

                } else {

                    ForEach(realExpenses.indices, id: \.self) { index in

                        let expense = realExpenses[index]

                        expenseRow(expense)
                            .contextMenu {

                                Button {
                                    activeSheet = .editExpense(expense)
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }

                                Button(role: .destructive) {
                                    expenseToDelete = expense
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }

                            }

                        if index < realExpenses.count - 1 {
                            Divider()
                                .padding(.leading, 54)
                        }

                    }

                }

            }
            .background(AppColors.card)
            .clipShape(
                RoundedRectangle(cornerRadius: 18)
            )

        }

    }

    private func expenseRow(
        _ expense: SharedExpense
    ) -> some View {

        HStack(alignment: .center, spacing: 12) {

            Image(systemName: "receipt.fill")
                .font(.system(size: 17))
                .foregroundStyle(AppColors.dashboardPurple)
                .frame(width: 40, height: 40)
                .background(
                    AppColors.dashboardPurple.opacity(0.10)
                )
                .clipShape(
                    RoundedRectangle(cornerRadius: 12)
                )

            VStack(alignment: .leading, spacing: 5) {

                Text(expense.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppColors.textPrimary)

                Text(
                    "Paid by \(payerName(for: expense)) · Split \(expense.splitAmongUserRecordIDs.count) ways"
                )
                .font(.system(size: 12))
                .foregroundStyle(AppColors.textSecondary)
                .lineLimit(2)

                Text(expense.date, style: .date)
                    .font(.system(size: 11))
                    .foregroundStyle(AppColors.textSecondary)

            }

            Spacer(minLength: 6)

            Text(formatted(expense.amount))
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(AppColors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

        }
        .padding(14)

    }

    // MARK: - Payments Made

    private var paymentsSection: some View {

        VStack(alignment: .leading, spacing: 12) {

            Text("Payments Made")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(AppColors.textPrimary)

            VStack(spacing: 0) {

                ForEach(settlements.indices, id: \.self) { index in

                    let settlement = settlements[index]

                    HStack(spacing: 12) {

                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(AppColors.success)

                        VStack(alignment: .leading, spacing: 4) {

                            Text(
                                "\(payerName(for: settlement)) paid up"
                            )
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(AppColors.textPrimary)

                            Text(settlement.date, style: .date)
                                .font(.system(size: 12))
                                .foregroundStyle(AppColors.textSecondary)

                        }

                        Spacer()

                        Text(formatted(settlement.amount))
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(AppColors.success)

                    }
                    .padding(16)
                    .contextMenu {

                        Button(role: .destructive) {
                            expenseToDelete = settlement
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }

                    }

                    if index < settlements.count - 1 {
                        Divider()
                            .padding(.horizontal, 16)
                    }

                }

            }
            .background(AppColors.card)
            .clipShape(
                RoundedRectangle(cornerRadius: 18)
            )

        }

    }

    // MARK: - Helpers

    private func settlementLine(
        for payment: SettlementPayment
    ) -> String {

        let verb = payment.fromName == "You"
            ? "owe"
            : "owes"

        return "\(payment.fromName) \(verb) \(payment.toName)"

    }

    private func payerName(
        for expense: SharedExpense
    ) -> String {

        ParticipantResolver(participants: participants)
            .name(
                for: expense.paidByUserRecordID,
                storedName: expense.paidByDisplayName
            )

    }

    private func recalculate() {

        let calculated = SettlementCalculator.balances(
            for: expenses,
            participants: participants
        )

        balances = calculated

        payments = SettlementCalculator.settlementPlan(
            from: calculated
        )

    }

    // MARK: - Apply Saved Expense

    private func apply(_ saved: SharedExpense) {

        if let index = expenses.firstIndex(
            where: { $0.id == saved.id }
        ) {
            expenses[index] = saved
        } else {
            expenses.append(saved)
        }

        expenses.sort { $0.date > $1.date }

        if let index = recentlySaved.firstIndex(
            where: { $0.id == saved.id }
        ) {
            recentlySaved[index] = saved
        } else {
            recentlySaved.append(saved)
        }

        recalculate()

        Task {
            await load(showSpinner: false)
        }

    }

    // MARK: - Delete Expense

    private func delete(
        _ expense: SharedExpense
    ) async {

        do {

            try await GroupSharingManager.shared.deleteExpense(
                expense,
                in: group
            )

            recentlySaved.removeAll {
                $0.id == expense.id
            }

            expenseToDelete = nil

            await load(showSpinner: false)

        } catch {

            expenseToDelete = nil

            errorMessage = error.localizedDescription
            showError = true

        }

    }

    // MARK: - CloudKit Loading

    private func load(
        showSpinner: Bool = true
    ) async {

        if showSpinner {
            isLoading = true
        }

        do {

            async let fetchedExpenses =
                GroupSharingManager.shared.fetchExpenses(
                    for: group
                )

            async let fetchedParticipants =
                GroupSharingManager.shared.fetchParticipants(
                    for: group
                )

            let (loadedExpenses, loadedParticipants) =
                try await (
                    fetchedExpenses,
                    fetchedParticipants
                )

            // Keep recently saved records until CloudKit
            // query results contain them.

            recentlySaved = recentlySaved.filter { local in
                !loadedExpenses.contains {
                    $0.id == local.id
                }
            }

            var merged = loadedExpenses

            merged.append(contentsOf: recentlySaved)

            merged.sort {
                $0.date > $1.date
            }

            let calculatedBalances =
                SettlementCalculator.balances(
                    for: merged,
                    participants: loadedParticipants
                )

            expenses = merged
            participants = loadedParticipants

            balances = calculatedBalances

            payments = SettlementCalculator.settlementPlan(
                from: calculatedBalances
            )

            hasLoaded = true

        } catch {

            errorMessage = error.localizedDescription
            showError = true

        }

        if showSpinner {
            isLoading = false
        }

    }

}
