import SwiftUI
import CloudKit

struct GroupDetailView: View {

    let group: SharedGroup

    // One sheet driver rather than three .sheet modifiers stacked on the
    // same view, which SwiftUI handles unreliably.
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

    @State private var expenses: [SharedExpense] = []
    @State private var participants: [GroupParticipant] = []
    @State private var balances: [Balance] = []
    @State private var payments: [SettlementPayment] = []

    /// Expenses saved on this device that the server's query index hasn't
    /// caught up with yet. Kept on screen until the server returns them.
    @State private var recentlySaved: [SharedExpense] = []

    @State private var isLoading = false
    @State private var activeSheet: ActiveSheet?
    @State private var expenseToDelete: SharedExpense?
    @State private var errorMessage = ""
    @State private var showError = false

    @AppStorage("selectedCurrency") private var currency: String = "PKR"

    private var total: Double {

        expenses.reduce(0) { $0 + $1.amount }

    }

    var body: some View {

        ZStack {

            AppColors.background
                .ignoresSafeArea()

            if isLoading {

                ProgressView()

            } else if expenses.isEmpty {

                VStack(spacing: 16) {

                    Image(systemName: "receipt")
                        .font(.system(size: 48))
                        .foregroundStyle(AppColors.primary)

                    Text("No Expenses Yet")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(AppColors.textPrimary)

                    Text("Add the first expense for this group.")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.textSecondary)

                }

            } else {

                List {

                    // MARK: Totals

                    Section {

                        HStack {

                            Text("Total")
                                .font(.headline)

                            Spacer()

                            Text(
                                CurrencyManager.string(
                                    for: total,
                                    currencyCode: currency
                                )
                            )
                            .font(.headline)
                            .fontWeight(.bold)

                        }

                        HStack {

                            Text("Members")
                                .font(.subheadline)
                                .foregroundStyle(AppColors.textSecondary)

                            Spacer()

                            Text("\(participants.count)")
                                .font(.subheadline)
                                .foregroundStyle(AppColors.textSecondary)

                        }

                    }

                    // MARK: Settlement

                    Section("Who Owes Whom") {

                        if payments.isEmpty {

                            Text("Everyone is settled up.")
                                .font(.subheadline)
                                .foregroundStyle(AppColors.textSecondary)

                        } else {

                            ForEach(payments.indices, id: \.self) { index in

                                let payment = payments[index]

                                HStack {

                                    Text(settlementLine(for: payment))
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(AppColors.textPrimary)

                                    Spacer()

                                    Text(
                                        CurrencyManager.string(
                                            for: payment.amount,
                                            currencyCode: currency
                                        )
                                    )
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundStyle(AppColors.primary)

                                }
                                .padding(.vertical, 2)

                            }

                        }

                        NavigationLink {

                            SettleUpView(group: group)

                        } label: {

                            Label(
                                "Full Breakdown",
                                systemImage: "arrow.left.arrow.right.circle.fill"
                            )
                            .foregroundStyle(AppColors.primary)

                        }

                    }

                    // MARK: Expenses

                    Section("Expenses") {

                        ForEach(expenses) { expense in

                            VStack(alignment: .leading, spacing: 4) {

                                HStack {

                                    Text(expense.title)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(AppColors.textPrimary)

                                    Spacer()

                                    Text(
                                        CurrencyManager.string(
                                            for: expense.amount,
                                            currencyCode: currency
                                        )
                                    )
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundStyle(AppColors.textPrimary)

                                }

                                Text("Paid by \(payerName(for: expense)) · split \(expense.splitAmongUserRecordIDs.count) ways")
                                    .font(.caption)
                                    .foregroundStyle(AppColors.textSecondary)

                            }
                            .padding(.vertical, 4)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {

                                Button(role: .destructive) {

                                    expenseToDelete = expense

                                } label: {

                                    Label("Delete", systemImage: "trash")

                                }

                                Button {

                                    activeSheet = .editExpense(expense)

                                } label: {

                                    Label("Edit", systemImage: "pencil")

                                }
                                .tint(AppColors.primary)

                            }

                        }

                    }

                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .refreshable {

                    await load(showSpinner: false)

                }

            }

        }
        .navigationTitle(group.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {

            ToolbarItem(placement: .topBarTrailing) {

                Menu {

                    Button {

                        activeSheet = .addExpense

                    } label: {

                        Label("Add Expense", systemImage: "plus")

                    }

                    // Only the group's creator can change who is in it.
                    if group.isOwnedByCurrentUser {

                        Button {

                            activeSheet = .addMembers

                        } label: {

                            Label("Add Members", systemImage: "person.badge.plus")

                        }

                    }

                } label: {

                    Image(systemName: "plus")

                }
                .accessibilityLabel("Group Options")

            }

        }
        .sheet(item: $activeSheet) { sheet in

            switch sheet {

            case .addExpense:

                AddSharedExpenseView(group: group) { saved in

                    apply(saved)

                }

            case .editExpense(let expense):

                AddSharedExpenseView(group: group, expense: expense) { saved in

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
                set: { if !$0 { expenseToDelete = nil } }
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

            Text("This removes the expense for everyone in the group and recalculates the balances.")

        }
        .task {
            await load()
        }
        .alert("Error", isPresented: $showError) {

            Button("OK", role: .cancel) { }

        } message: {

            Text(errorMessage)

        }

    }

    // MARK: - Helpers

    private func settlementLine(for payment: SettlementPayment) -> String {

        let verb = payment.fromName == "You" ? "owe" : "owes"

        return "\(payment.fromName) \(verb) \(payment.toName)"

    }

    private func payerName(for expense: SharedExpense) -> String {

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
        payments = SettlementCalculator.settlementPlan(from: calculated)

    }

    // MARK: - Actions

    /// Puts the saved expense on screen straight away. CloudKit's query
    /// index lags a second or two behind a write, so reloading alone often
    /// comes back without the expense that was just saved — which reads to
    /// the user as the save having failed.
    private func apply(_ saved: SharedExpense) {

        if let index = expenses.firstIndex(where: { $0.id == saved.id }) {
            expenses[index] = saved
        } else {
            expenses.append(saved)
        }

        expenses.sort { $0.date > $1.date }

        if let index = recentlySaved.firstIndex(where: { $0.id == saved.id }) {
            recentlySaved[index] = saved
        } else {
            recentlySaved.append(saved)
        }

        recalculate()

        Task {
            await load(showSpinner: false)
        }

    }

    private func delete(_ expense: SharedExpense) async {

        do {

            try await GroupSharingManager.shared.deleteExpense(
                expense,
                in: group
            )

            // Otherwise a just-deleted expense could reappear from the
            // pending list on the next load.
            recentlySaved.removeAll { $0.id == expense.id }

            expenseToDelete = nil

            await load(showSpinner: false)

        } catch {

            expenseToDelete = nil
            errorMessage = error.localizedDescription
            showError = true

        }

    }

    private func load(showSpinner: Bool = true) async {

        if showSpinner {
            isLoading = true
        }

        do {

            async let fetchedExpenses =
                GroupSharingManager.shared.fetchExpenses(for: group)

            async let fetchedParticipants =
                GroupSharingManager.shared.fetchParticipants(for: group)

            let (loadedExpenses, loadedParticipants) =
                try await (fetchedExpenses, fetchedParticipants)

            // Drop anything the server has now caught up on, and keep the
            // rest visible so a fresh save never vanishes.
            recentlySaved = recentlySaved.filter { local in

                !loadedExpenses.contains { $0.id == local.id }

            }

            var merged = loadedExpenses
            merged.append(contentsOf: recentlySaved)
            merged.sort { $0.date > $1.date }

            let calculatedBalances = SettlementCalculator.balances(
                for: merged,
                participants: loadedParticipants
            )

            expenses = merged
            participants = loadedParticipants
            balances = calculatedBalances
            payments = SettlementCalculator.settlementPlan(
                from: calculatedBalances
            )

        } catch {

            errorMessage = error.localizedDescription
            showError = true

        }

        if showSpinner {
            isLoading = false
        }

    }

}
