import SwiftUI

struct AddSharedExpenseView: View {

    let group: SharedGroup
    var onAdded: () -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var amount = ""
    @State private var participants: [GroupParticipant] = []
    @State private var selectedPayer: GroupParticipant?
    @State private var isLoadingParticipants = true
    @State private var isSaving = false
    @State private var errorMessage = ""
    @State private var showError = false

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
            .navigationTitle("Add Expense")
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

                            Text("Save")
                                .fontWeight(.semibold)

                        }

                    }
                    .disabled(!isFormValid || isSaving)

                }

            }
            .task {
                await loadParticipants()
            }
            .alert("Could Not Add Expense", isPresented: $showError) {

                Button("OK", role: .cancel) { }

            } message: {

                Text(errorMessage)

            }

        }

    }

    private func loadParticipants() async {

        isLoadingParticipants = true

        do {

            participants = try await GroupSharingManager.shared.fetchParticipants(for: group)
            selectedPayer = participants.first

        } catch {

            errorMessage = error.localizedDescription
            showError = true

        }

        isLoadingParticipants = false

    }

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

            try await GroupSharingManager.shared.addExpense(
                title: trimmedTitle,
                amount: amountValue,
                paidBy: payer,
                splitAmong: participants,
                in: group
            )

            onAdded()
            dismiss()

        } catch {

            errorMessage = error.localizedDescription
            showError = true

        }

        isSaving = false

    }

}
