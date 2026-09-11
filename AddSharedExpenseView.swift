import SwiftUI

struct AddSharedExpenseView: View {

    let group: SharedGroup

    /// nil = adding a new expense, non-nil = editing that one.
    var expense: SharedExpense?

    var onSaved: () -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var amount = ""
    @State private var participants: [GroupParticipant] = []
    @State private var selectedPayer: GroupParticipant?
    @State private var isLoadingParticipants = true
    @State private var isSaving = false
    @State private var errorMessage = ""
    @State private var showError = false

    private var isEditing: Bool {
        expense != nil
    }

    private var isFormValid: Bool {

        CurrencyManager.isValidAmount(amount)
            && !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && selectedPayer != nil

    }

    var body: some View {

        NavigationStack {

            Form {

                Section("Details") {

                    TextField("What was it for?", text: $title)

                    TextField("Amount", text: $amount)
                        .keyboardType(.decimalPad)

                }

                Section("Paid By") {

                    if isLoadingParticipants {

                        ProgressView()

                    } else if participants.isEmpty {

                        Text("Couldn't load group members.")
                            .foregroundStyle(AppColors.textSecondary)

                    } else {

                        Picker("Paid By", selection: $selectedPayer) {

                            ForEach(participants) { participant in

                                Text(participant.displayName)
                                    .tag(Optional(participant))

                            }

                        }
                        .pickerStyle(.inline)
                        .labelsHidden()

                    }

                }

                if !participants.isEmpty {

                    Section {

                        Text("Split equally among all \(participants.count) group members.")
                            .font(.caption)
                            .foregroundStyle(AppColors.textSecondary)

                    }

                }

            }
            .navigationTitle(isEditing ? "Edit Expense" : "Add Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {

                ToolbarItem(placement: .topBarLeading) {

                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(AppColors.textSecondary)

                }

                ToolbarItem(placement: .topBarTrailing) {

                    Button {

                        Task {
                            await save()
                        }

                    } label: {

                        if isSaving {

                            ProgressView()

                        } else {

                            Text(isEditing ? "Update" : "Save")
                                .fontWeight(.semibold)

                        }

                    }
                    .disabled(!isFormValid || isSaving)

                }

            }
            .task {
                await loadParticipants()
            }
            .alert(
                isEditing ? "Could Not Update Expense" : "Could Not Add Expense",
                isPresented: $showError
            ) {

                Button("OK", role: .cancel) { }

            } message: {

                Text(errorMessage)

            }

        }

    }

    // MARK: - Load

    private func loadParticipants() async {

        isLoadingParticipants = true

        do {

            let loaded = try await GroupSharingManager.shared.fetchParticipants(for: group)

            participants = loaded

            if let expense {

                title = expense.title
                amount = CurrencyManager.editableText(for: expense.amount)

                // The stored payer id may be an old alias, so resolve it
                // before matching against the current member list.
                let payerID = ParticipantResolver(participants: loaded)
                    .id(for: expense.paidByUserRecordID)

                selectedPayer = loaded.first { $0.id == payerID }
                    ?? loaded.first(where: \.isCurrentUser)
                    ?? loaded.first

            } else {

                selectedPayer = loaded.first(where: \.isCurrentUser)
                    ?? loaded.first

            }

        } catch {

            errorMessage = error.localizedDescription
            showError = true

        }

        isLoadingParticipants = false

    }

    // MARK: - Save

    private func save() async {

        guard
            let payer = selectedPayer,
            let amountValue = CurrencyManager.amount(from: amount)
        else {
            return
        }

        isSaving = true

        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)

        do {

            if let expense {

                try await GroupSharingManager.shared.updateExpense(
                    expense,
                    title: trimmedTitle,
                    amount: amountValue,
                    paidBy: payer,
                    splitAmong: participants,
                    in: group
                )

            } else {

                _ = try await GroupSharingManager.shared.addExpense(
                    title: trimmedTitle,
                    amount: amountValue,
                    paidBy: payer,
                    splitAmong: participants,
                    in: group
                )

            }

            onSaved()
            dismiss()

        } catch {

            errorMessage = error.localizedDescription
            showError = true

        }

        isSaving = false

    }

}
