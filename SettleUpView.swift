
import SwiftUI

struct SettleUpView: View {

    let group: SharedGroup

    @Environment(\.dismiss) private var dismiss

    @State private var expenses: [SharedExpense] = []
    @State private var participants: [GroupParticipant] = []
    @State private var balances: [Balance] = []
    @State private var payments: [SettlementPayment] = []

    @State private var isLoading = false
    @State private var hasLoaded = false
    @State private var isSettling = false
    @State private var paymentToSettle: SettlementPayment?

    @State private var errorMessage = ""
    @State private var showError = false

    @AppStorage("selectedCurrency")
    private var currency: String = "USD"

    // MARK: - Derived Data

    private struct PayerGroup: Identifiable {
        let id: String
        let name: String
        let total: Double
        let expenses: [SharedExpense]
    }

    private var realExpenses: [SharedExpense] {
        expenses.filter { !$0.isSettlement }
    }

    private var settlements: [SharedExpense] {
        expenses
            .filter { $0.isSettlement }
            .sorted { $0.date > $1.date }
    }

    private var total: Double {
        realExpenses.reduce(0) { $0 + $1.amount }
    }

    private var perPersonShare: Double {
        guard !participants.isEmpty else { return 0 }

        return CurrencyManager.rounded(
            total / Double(participants.count)
        )
    }

    private var payerGroups: [PayerGroup] {

        let resolver = ParticipantResolver(
            participants: participants
        )

        var expensesByPayer: [String: [SharedExpense]] = [:]
        var order: [String] = []

        for expense in realExpenses.sorted(
            by: { $0.date < $1.date }
        ) {

            let payerID = resolver.id(
                for: expense.paidByUserRecordID
            )

            if expensesByPayer[payerID] == nil {
                order.append(payerID)
            }

            expensesByPayer[payerID, default: []]
                .append(expense)
        }

        return order.map { payerID in

            let items = expensesByPayer[payerID] ?? []

            return PayerGroup(
                id: payerID,
                name: resolver.name(
                    for: payerID,
                    storedName: items.first?.paidByDisplayName
                ),
                total: items.reduce(0) {
                    $0 + $1.amount
                },
                expenses: items
            )
        }
    }

    private var outstandingTotal: Double {
        CurrencyManager.rounded(
            payments.reduce(0) { $0 + $1.amount }
        )
    }

    private func formatted(_ amount: Double) -> String {
        CurrencyManager.string(
            for: amount,
            currencyCode: currency
        )
    }

    // MARK: - Body

    var body: some View {

        ZStack {

            AppColors.dashboardGradient
                .ignoresSafeArea()

            VStack(spacing: 0) {

                purpleHeader

                contentArea

            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {

            ToolbarItem(placement: .topBarLeading) {

                Button {
                    dismiss()
                } label: {

                    HStack(spacing: 5) {

                        Image(systemName: "chevron.left")
                            .font(
                                .system(
                                    size: 18,
                                    weight: .semibold
                                )
                            )

                        Text("Back")
                            .font(.system(size: 17))

                    }
                    .foregroundStyle(.white)

                }
                .buttonStyle(.plain)

            }

            ToolbarItem(placement: .principal) {

                Text("Full Breakdown")
                    .font(
                        .system(
                            size: 17,
                            weight: .semibold
                        )
                    )
                    .foregroundStyle(.white)

            }

        }
        .confirmationDialog(
            paymentToSettle.map {
                "Record that \($0.fromName) paid \($0.toName)?"
            } ?? "",
            isPresented: Binding(
                get: {
                    paymentToSettle != nil
                },
                set: {
                    if !$0 {
                        paymentToSettle = nil
                    }
                }
            ),
            titleVisibility: .visible
        ) {

            Button("Mark as Paid") {

                if let payment = paymentToSettle {

                    Task {
                        await settle(payment)
                    }

                }

            }

            Button("Cancel", role: .cancel) {
                paymentToSettle = nil
            }

        } message: {

            if let paymentToSettle {

                Text(
                    "This records a payment of \(formatted(paymentToSettle.amount)) and clears the balance between them. Everyone in the group will see it."
                )

            }

        }
        .task {
            await load()
        }
        .alert(
            "Error",
            isPresented: $showError
        ) {

            Button("OK", role: .cancel) {}

        } message: {

            Text(errorMessage)

        }

    }

    // MARK: - Purple Header

    private var purpleHeader: some View {

        VStack(alignment: .leading, spacing: 12) {

            Text(group.name)
                .font(
                    .system(
                        size: 27,
                        weight: .bold
                    )
                )
                .foregroundStyle(.white)
                .lineLimit(2)

            HStack(spacing: 8) {

                Image(systemName: "person.2.fill")

                Text(
                    "\(participants.count) \(participants.count == 1 ? "Member" : "Members")"
                )

            }
            .font(
                .system(
                    size: 14,
                    weight: .medium
                )
            )
            .foregroundStyle(
                .white.opacity(0.85)
            )

            Text("Review balances and settle shared expenses.")
                .font(.system(size: 13))
                .foregroundStyle(
                    .white.opacity(0.75)
                )

        }
        .padding(.horizontal, 22)
        .padding(.top, 14)
        .padding(.bottom, 28)
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )

    }

    // MARK: - Main Content

    private var contentArea: some View {

        ScrollView {

            VStack(alignment: .leading, spacing: 24) {

                if isLoading && !hasLoaded {

                    ProgressView()
                        .tint(
                            AppColors.dashboardPurple
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.top, 70)

                } else if expenses.isEmpty {

                    emptyState

                } else {

                    summarySection

                    settlementSection

                    balancesSection

                    expenseBreakdownSection

                    if !settlements.isEmpty {
                        paymentsMadeSection
                    }

                }

            }
            .padding(.horizontal, 18)
            .padding(.top, 24)
            .padding(.bottom, 40)

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

    // MARK: - Summary

    private var summarySection: some View {

        VStack(alignment: .leading, spacing: 16) {

            sectionTitle("Expense Summary")

            VStack(alignment: .leading, spacing: 18) {

                VStack(alignment: .leading, spacing: 8) {

                    Text("TOTAL GROUP EXPENSES")
                        .font(
                            .system(
                                size: 12,
                                weight: .semibold
                            )
                        )
                        .foregroundStyle(
                            AppColors.textSecondary
                        )

                    Text(formatted(total))
                        .font(
                            .system(
                                size: 30,
                                weight: .bold
                            )
                        )
                        .foregroundStyle(
                            AppColors.textPrimary
                        )
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                }

                Divider()

                summaryRow(
                    title: "Each Person's Share",
                    value: formatted(perPersonShare)
                )

                Divider()

                HStack {

                    Text("Group Members")
                        .font(.system(size: 14))
                        .foregroundStyle(
                            AppColors.textSecondary
                        )

                    Spacer()

                    Text("\(participants.count)")
                        .font(
                            .system(
                                size: 15,
                                weight: .semibold
                            )
                        )
                        .foregroundStyle(
                            AppColors.textPrimary
                        )

                }

                Divider()

                summaryRow(
                    title: "Outstanding Payments",
                    value: formatted(outstandingTotal)
                )

            }
            .padding(20)
            .background(AppColors.card)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 20
                )
            )

        }

    }

    private func summaryRow(
        title: String,
        value: String
    ) -> some View {

        HStack(spacing: 12) {

            Text(title)
                .font(.system(size: 14))
                .foregroundStyle(
                    AppColors.textSecondary
                )

            Spacer()

            Text(value)
                .font(
                    .system(
                        size: 15,
                        weight: .semibold
                    )
                )
                .foregroundStyle(
                    AppColors.textPrimary
                )
                .lineLimit(1)
                .minimumScaleFactor(0.7)

        }

    }

    // MARK: - Who Owes Whom

    private var settlementSection: some View {

        VStack(alignment: .leading, spacing: 12) {

            sectionTitle("Who Owes Whom")

            VStack(spacing: 0) {

                if payments.isEmpty {

                    VStack(spacing: 12) {

                        Image(
                            systemName: "checkmark.circle.fill"
                        )
                        .font(.system(size: 34))
                        .foregroundStyle(
                            AppColors.success
                        )

                        Text("Everyone Is Settled Up")
                            .font(
                                .system(
                                    size: 16,
                                    weight: .semibold
                                )
                            )
                            .foregroundStyle(
                                AppColors.textPrimary
                            )

                        Text("There are no outstanding payments.")
                            .font(.system(size: 13))
                            .foregroundStyle(
                                AppColors.textSecondary
                            )

                    }
                    .frame(maxWidth: .infinity)
                    .padding(24)

                } else {

                    ForEach(
                        payments.indices,
                        id: \.self
                    ) { index in

                        let payment = payments[index]

                        Button {

                            guard !isSettling else {
                                return
                            }

                            paymentToSettle = payment

                        } label: {

                            HStack(spacing: 12) {

                                Image(
                                    systemName: "arrow.left.arrow.right.circle.fill"
                                )
                                .font(.system(size: 25))
                                .foregroundStyle(
                                    AppColors.dashboardPurple
                                )

                                VStack(
                                    alignment: .leading,
                                    spacing: 6
                                ) {

                                    Text(
                                        settlementLine(
                                            for: payment
                                        )
                                    )
                                    .font(
                                        .system(
                                            size: 14,
                                            weight: .semibold
                                        )
                                    )
                                    .foregroundStyle(
                                        AppColors.textPrimary
                                    )
                                    .multilineTextAlignment(.leading)

                                    Text("Tap to mark as paid")
                                        .font(
                                            .system(size: 12)
                                        )
                                        .foregroundStyle(
                                            AppColors.textSecondary
                                        )

                                }

                                Spacer(minLength: 8)

                                Text(
                                    formatted(payment.amount)
                                )
                                .font(
                                    .system(
                                        size: 15,
                                        weight: .bold
                                    )
                                )
                                .foregroundStyle(
                                    AppColors.dashboardPurple
                                )
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)

                            }
                            .padding(16)
                            .contentShape(Rectangle())

                        }
                        .buttonStyle(.plain)
                        .disabled(isSettling)

                        if index < payments.count - 1 {

                            Divider()
                                .padding(.horizontal, 16)

                        }

                    }

                }

            }
            .background(AppColors.card)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 18
                )
            )

        }

    }

    // MARK: - Balances

    private var balancesSection: some View {

        VStack(alignment: .leading, spacing: 12) {

            sectionTitle("Member Balances")

            VStack(spacing: 0) {

                ForEach(
                    Array(balances.enumerated()),
                    id: \.element.participantID
                ) { index, balance in

                    HStack(spacing: 12) {

                        Image(
                            systemName: "person.crop.circle.fill"
                        )
                        .font(.system(size: 28))
                        .foregroundStyle(
                            AppColors.dashboardPurple
                        )

                        VStack(
                            alignment: .leading,
                            spacing: 5
                        ) {

                            Text(balance.displayName)
                                .font(
                                    .system(
                                        size: 15,
                                        weight: .semibold
                                    )
                                )
                                .foregroundStyle(
                                    AppColors.textPrimary
                                )

                            Text(
                                balanceStatus(
                                    for: balance
                                )
                            )
                            .font(.system(size: 12))
                            .foregroundStyle(
                                AppColors.textSecondary
                            )

                        }

                        Spacer(minLength: 8)

                        Text(
                            formatted(
                                abs(balance.netAmount)
                            )
                        )
                        .font(
                            .system(
                                size: 15,
                                weight: .bold
                            )
                        )
                        .foregroundStyle(
                            balanceColor(
                                for: balance
                            )
                        )
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    }
                    .padding(16)

                    if index < balances.count - 1 {

                        Divider()
                            .padding(.leading, 56)

                    }

                }

            }
            .background(AppColors.card)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 18
                )
            )

        }

    }

    // MARK: - Expense Breakdown

    private var expenseBreakdownSection: some View {

        VStack(alignment: .leading, spacing: 12) {

            sectionTitle("Expenses by Member")

            if payerGroups.isEmpty {

                Text("No expenses recorded.")
                    .font(.subheadline)
                    .foregroundStyle(
                        AppColors.textSecondary
                    )
                    .frame(maxWidth: .infinity)
                    .padding(20)
                    .background(AppColors.card)
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 18
                        )
                    )

            } else {

                ForEach(payerGroups) { payerGroup in

                    VStack(spacing: 0) {

                        HStack(spacing: 12) {

                            Image(
                                systemName: "person.circle.fill"
                            )
                            .font(.system(size: 24))
                            .foregroundStyle(
                                AppColors.dashboardPurple
                            )

                            VStack(
                                alignment: .leading,
                                spacing: 4
                            ) {

                                Text(
                                    "\(payerGroup.name) paid"
                                )
                                .font(
                                    .system(
                                        size: 15,
                                        weight: .semibold
                                    )
                                )
                                .foregroundStyle(
                                    AppColors.textPrimary
                                )

                                Text(
                                    "\(payerGroup.expenses.count) \(payerGroup.expenses.count == 1 ? "expense" : "expenses")"
                                )
                                .font(.system(size: 12))
                                .foregroundStyle(
                                    AppColors.textSecondary
                                )

                            }

                            Spacer()

                            Text(
                                formatted(
                                    payerGroup.total
                                )
                            )
                            .font(
                                .system(
                                    size: 15,
                                    weight: .bold
                                )
                            )
                            .foregroundStyle(
                                AppColors.dashboardPurple
                            )
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)

                        }
                        .padding(16)

                        Divider()
                            .padding(.horizontal, 16)

                        ForEach(
                            Array(
                                payerGroup.expenses.enumerated()
                            ),
                            id: \.element.id
                        ) { index, expense in

                            HStack(spacing: 12) {

                                Image(
                                    systemName: "receipt.fill"
                                )
                                .font(.system(size: 16))
                                .foregroundStyle(
                                    AppColors.dashboardPurple
                                )
                                .frame(
                                    width: 36,
                                    height: 36
                                )
                                .background(
                                    AppColors.dashboardPurple
                                        .opacity(0.10)
                                )
                                .clipShape(
                                    RoundedRectangle(
                                        cornerRadius: 10
                                    )
                                )

                                VStack(
                                    alignment: .leading,
                                    spacing: 5
                                ) {

                                    Text(expense.title)
                                        .font(
                                            .system(
                                                size: 14,
                                                weight: .medium
                                            )
                                        )
                                        .foregroundStyle(
                                            AppColors.textPrimary
                                        )

                                    Text(
                                        expense.date,
                                        style: .date
                                    )
                                    .font(.system(size: 12))
                                    .foregroundStyle(
                                        AppColors.textSecondary
                                    )

                                }

                                Spacer(minLength: 8)

                                Text(
                                    formatted(
                                        expense.amount
                                    )
                                )
                                .font(
                                    .system(
                                        size: 14,
                                        weight: .semibold
                                    )
                                )
                                .foregroundStyle(
                                    AppColors.textPrimary
                                )
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)

                            }
                            .padding(14)

                            if index < payerGroup.expenses.count - 1 {

                                Divider()
                                    .padding(.leading, 62)

                            }

                        }

                    }
                    .background(AppColors.card)
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 18
                        )
                    )

                }

            }

        }

    }

    // MARK: - Payments Made

    private var paymentsMadeSection: some View {

        VStack(alignment: .leading, spacing: 12) {

            sectionTitle("Payments Made")

            VStack(spacing: 0) {

                ForEach(
                    Array(settlements.enumerated()),
                    id: \.element.id
                ) { index, settlement in

                    HStack(spacing: 12) {

                        Image(
                            systemName: "checkmark.circle.fill"
                        )
                        .font(.system(size: 23))
                        .foregroundStyle(
                            AppColors.success
                        )

                        VStack(
                            alignment: .leading,
                            spacing: 5
                        ) {

                            Text(
                                settlementDescription(
                                    for: settlement
                                )
                            )
                            .font(
                                .system(
                                    size: 14,
                                    weight: .semibold
                                )
                            )
                            .foregroundStyle(
                                AppColors.textPrimary
                            )

                            Text(
                                settlement.date,
                                style: .date
                            )
                            .font(.system(size: 12))
                            .foregroundStyle(
                                AppColors.textSecondary
                            )

                        }

                        Spacer(minLength: 8)

                        Text(
                            formatted(
                                settlement.amount
                            )
                        )
                        .font(
                            .system(
                                size: 14,
                                weight: .bold
                            )
                        )
                        .foregroundStyle(
                            AppColors.success
                        )
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    }
                    .padding(16)

                    if index < settlements.count - 1 {

                        Divider()
                            .padding(.horizontal, 16)

                    }

                }

            }
            .background(AppColors.card)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 18
                )
            )

        }

    }

    // MARK: - Empty State

    private var emptyState: some View {

        VStack(spacing: 14) {

            Image(systemName: "arrow.left.arrow.right.circle")
                .font(.system(size: 45))
                .foregroundStyle(
                    AppColors.dashboardPurple
                )

            Text("Nothing to Settle Yet")
                .font(
                    .system(
                        size: 18,
                        weight: .bold
                    )
                )
                .foregroundStyle(
                    AppColors.textPrimary
                )

            Text(
                "Add shared expenses to see member balances and settlement details."
            )
            .font(.system(size: 14))
            .foregroundStyle(
                AppColors.textSecondary
            )
            .multilineTextAlignment(.center)

        }
        .frame(maxWidth: .infinity)
        .padding(28)
        .background(AppColors.card)
        .clipShape(
            RoundedRectangle(
                cornerRadius: 20
            )
        )

    }

    // MARK: - Helpers

    private func sectionTitle(
        _ text: String
    ) -> some View {

        Text(text)
            .font(
                .system(
                    size: 18,
                    weight: .bold
                )
            )
            .foregroundStyle(
                AppColors.textPrimary
            )

    }

    private func balanceStatus(
        for balance: Balance
    ) -> String {

        if balance.netAmount > 0.005 {

            return balance.isCurrentUser
                ? "You are owed"
                : "Is owed"

        } else if balance.netAmount < -0.005 {

            return balance.isCurrentUser
                ? "You owe"
                : "Owes"

        } else {

            return "Settled up"

        }

    }

    private func balanceColor(
        for balance: Balance
    ) -> Color {

        if balance.netAmount > 0.005 {
            return AppColors.success
        }

        if balance.netAmount < -0.005 {
            return AppColors.expense
        }

        return AppColors.textSecondary

    }

    private func settlementLine(
        for payment: SettlementPayment
    ) -> String {

        let verb = payment.fromName == "You"
            ? "owe"
            : "owes"

        return "\(payment.fromName) \(verb) \(payment.toName)"

    }

    private func settlementDescription(
        for settlement: SharedExpense
    ) -> String {

        let resolver = ParticipantResolver(
            participants: participants
        )

        let payer = resolver.name(
            for: settlement.paidByUserRecordID,
            storedName: settlement.paidByDisplayName
        )

        let payee = settlement.settlementPayeeID
            .map {
                resolver.name(for: $0)
            }
            ?? "the group"

        return "\(payer) paid \(payee)"

    }

    // MARK: - Record Settlement

    private func settle(
        _ payment: SettlementPayment
    ) async {

        guard !isSettling else {
            return
        }

        isSettling = true
        paymentToSettle = nil

        do {

            _ = try await GroupSharingManager.shared
                .recordSettlement(
                    payment,
                    in: group
                )

            await load(showSpinner: false)

        } catch {

            errorMessage = CloudKitMessage.message(
                for: error
            )
            showError = true

        }

        isSettling = false

    }

    // MARK: - Load Data

    private func load(
        showSpinner: Bool = true
    ) async {

        if showSpinner {
            isLoading = true
        }

        do {

            async let fetchedExpenses =
                GroupSharingManager.shared
                    .fetchExpenses(for: group)

            async let fetchedParticipants =
                GroupSharingManager.shared
                    .fetchParticipants(for: group)

            let (
                loadedExpenses,
                loadedParticipants
            ) = try await (
                fetchedExpenses,
                fetchedParticipants
            )

            let calculatedBalances =
                SettlementCalculator.balances(
                    for: loadedExpenses,
                    participants: loadedParticipants
                )

            expenses = loadedExpenses
            participants = loadedParticipants
            balances = calculatedBalances

            payments =
                SettlementCalculator.settlementPlan(
                    from: calculatedBalances
                )

            hasLoaded = true

        } catch {

            errorMessage = CloudKitMessage.message(
                for: error
            )
            showError = true

        }

        if showSpinner {
            isLoading = false
        }

    }

}
