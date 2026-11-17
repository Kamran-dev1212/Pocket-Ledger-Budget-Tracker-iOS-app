
import SwiftUI

struct AddSharedExpenseView: View {

    let group: SharedGroup

    /// nil = new expense, non-nil = editing.
    var expense: SharedExpense?

    var onSaved: (SharedExpense) -> Void

    @Environment(\.dismiss) private var dismiss

    @AppStorage("selectedCurrency")
    private var currency: String = "USD"

    // MARK: - State

    @State private var title = ""
    @State private var amount = ""

    @State private var participants: [GroupParticipant] = []
    @State private var selectedPayer: GroupParticipant?

    @State private var isLoadingParticipants = true
    @State private var isSaving = false
    @State private var hasLoadedParticipants = false

    @State private var errorMessage = ""
    @State private var showError = false

    @FocusState private var focusedField: FormField?

    private enum FormField: Hashable {
        case amount
        case title
    }

    // MARK: - Computed Properties

    private var isEditing: Bool {
        expense != nil
    }

    private var isFormValid: Bool {
        CurrencyManager.isValidAmount(amount)
            && !title.trimmingCharacters(
                in: .whitespacesAndNewlines
            ).isEmpty
            && selectedPayer != nil
            && !participants.isEmpty
            && !isLoadingParticipants
    }

    private var amountValue: Double {
        CurrencyManager.amount(from: amount) ?? 0
    }

    private var amountPerPerson: Double {
        guard !participants.isEmpty else { return 0 }

        return CurrencyManager.rounded(
            amountValue / Double(participants.count)
        )
    }

    private func formatted(_ value: Double) -> String {
        CurrencyManager.string(
            for: value,
            currencyCode: currency
        )
    }

    // MARK: - Body

    var body: some View {

        NavigationStack {

            ZStack {

                AppColors.dashboardGradient
                    .ignoresSafeArea()

                VStack(spacing: 0) {

                    customHeader

                    contentArea

                }

            }
            .toolbar(.hidden, for: .navigationBar)
            .task {
                if !hasLoadedParticipants {
                    await loadParticipants()
                }
            }
            .alert(
                isEditing
                    ? "Could Not Update Expense"
                    : "Could Not Add Expense",
                isPresented: $showError
            ) {

                Button("OK", role: .cancel) {}

            } message: {

                Text(errorMessage)

            }

        }

    }

    // MARK: - Purple Header

    private var customHeader: some View {

        VStack(alignment: .leading, spacing: 24) {

            HStack {

                Button {
                    focusedField = nil
                    dismiss()
                } label: {

                    Text("Cancel")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white)

                }
                .disabled(isSaving)

                Spacer()

                Text(isEditing ? "Edit Expense" : "Add Expense")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)

                Spacer()

                Button {
                    focusedField = nil

                    Task {
                        await save()
                    }
                } label: {

                    Group {

                        if isSaving {

                            ProgressView()
                                .tint(.white)

                        } else {

                            Text(isEditing ? "Update" : "Save")
                                .font(
                                    .system(
                                        size: 16,
                                        weight: .semibold
                                    )
                                )

                        }

                    }
                    .foregroundStyle(
                        isFormValid && !isSaving
                            ? Color.white
                            : Color.white.opacity(0.5)
                    )

                }
                .disabled(!isFormValid || isSaving)

            }

            VStack(alignment: .leading, spacing: 10) {

                Text(group.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.85))
                    .lineLimit(1)

                HStack(alignment: .firstTextBaseline, spacing: 8) {

                    Text(
                        CurrencyManager.string(
                            for: 0,
                            currencyCode: currency
                        )
                        .components(separatedBy: "0")
                        .first ?? ""
                    )
                    .font(.system(size: 25, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.85))

                    TextField("0.00", text: $amount)
                        .keyboardType(.decimalPad)
                        .font(
                            .system(
                                size: 42,
                                weight: .bold,
                                design: .rounded
                            )
                        )
                        .foregroundStyle(.white)
                        .tint(.white)
                        .focused(
                            $focusedField,
                            equals: .amount
                        )
                        .accessibilityLabel("Expense amount")

                }

                Text("Enter shared expense amount")
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.75))

            }

        }
        .padding(.horizontal, 22)
        .padding(.top, 14)
        .padding(.bottom, 30)

    }

    // MARK: - Content Area

    private var contentArea: some View {

        ScrollView {

            VStack(alignment: .leading, spacing: 24) {

                expenseDetailsSection

                paidBySection

                splitSection

                saveButton

            }
            .padding(.horizontal, 18)
            .padding(.top, 26)
            .padding(.bottom, 40)

        }
        .scrollDismissesKeyboard(.interactively)
        .background(
            UnevenRoundedRectangle(
                topLeadingRadius: 28,
                topTrailingRadius: 28
            )
            .fill(AppColors.dashboardSurface)
            .ignoresSafeArea(edges: .bottom)
        )

    }

    // MARK: - Expense Details

    private var expenseDetailsSection: some View {

        VStack(alignment: .leading, spacing: 12) {

            sectionTitle("Expense Details")

            VStack(alignment: .leading, spacing: 8) {

                Text("Expense Title")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppColors.textSecondary)

                TextField(
                    "e.g. Dinner, Groceries, Fuel",
                    text: $title
                )
                .font(.system(size: 16))
                .foregroundStyle(AppColors.textPrimary)
                .tint(AppColors.dashboardPurple)
                .focused(
                    $focusedField,
                    equals: .title
                )
                .submitLabel(.done)

            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColors.card)
            .clipShape(
                RoundedRectangle(cornerRadius: 16)
            )

        }

    }

    // MARK: - Paid By

    private var paidBySection: some View {

        VStack(alignment: .leading, spacing: 12) {

            sectionTitle("Paid By")

            VStack(spacing: 0) {

                if isLoadingParticipants {

                    HStack(spacing: 12) {

                        ProgressView()

                        Text("Loading group members...")
                            .font(.subheadline)
                            .foregroundStyle(AppColors.textSecondary)

                        Spacer()

                    }
                    .padding(18)

                } else if participants.isEmpty {

                    HStack(spacing: 12) {

                        Image(systemName: "exclamationmark.circle")
                            .foregroundStyle(.orange)

                        Text("Couldn't load group members.")
                            .font(.subheadline)
                            .foregroundStyle(AppColors.textSecondary)

                        Spacer()

                    }
                    .padding(18)

                } else {

                    Menu {

                        ForEach(participants) { participant in

                            Button {

                                selectedPayer = participant

                            } label: {

                                if selectedPayer?.id == participant.id {

                                    Label(
                                        participant.displayName,
                                        systemImage: "checkmark"
                                    )

                                } else {

                                    Text(participant.displayName)

                                }

                            }

                        }

                    } label: {

                        HStack(spacing: 12) {

                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 25))
                                .foregroundStyle(
                                    AppColors.dashboardPurple
                                )

                            VStack(
                                alignment: .leading,
                                spacing: 4
                            ) {

                                Text("Who paid?")
                                    .font(.system(size: 12))
                                    .foregroundStyle(
                                        AppColors.textSecondary
                                    )

                                Text(
                                    selectedPayer?.displayName
                                        ?? "Select Member"
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

                            }

                            Spacer()

                            Image(systemName: "chevron.up.chevron.down")
                                .font(.system(size: 13))
                                .foregroundStyle(
                                    AppColors.textSecondary
                                )

                        }
                        .padding(16)
                        .contentShape(Rectangle())

                    }

                }

            }
            .background(AppColors.card)
            .clipShape(
                RoundedRectangle(cornerRadius: 16)
            )

        }

    }

    // MARK: - Split Equally

    private var splitSection: some View {

        VStack(alignment: .leading, spacing: 12) {

            HStack {

                sectionTitle("Split Between")

                Spacer()

                Text("Equal Split")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(
                        AppColors.dashboardPurple
                    )

            }

            VStack(spacing: 0) {

                if isLoadingParticipants {

                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(24)

                } else if participants.isEmpty {

                    Text("No group members available.")
                        .font(.subheadline)
                        .foregroundStyle(
                            AppColors.textSecondary
                        )
                        .frame(maxWidth: .infinity)
                        .padding(20)

                } else {

                    ForEach(
                        Array(participants.enumerated()),
                        id: \.element.id
                    ) { index, participant in

                        HStack(spacing: 12) {

                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(
                                    AppColors.success
                                )

                            Text(participant.displayName)
                                .font(
                                    .system(
                                        size: 14,
                                        weight: .medium
                                    )
                                )
                                .foregroundStyle(
                                    AppColors.textPrimary
                                )

                            Spacer()

                            Text(formatted(amountPerPerson))
                                .font(
                                    .system(
                                        size: 14,
                                        weight: .semibold
                                    )
                                )
                                .foregroundStyle(
                                    AppColors.textPrimary
                                )

                        }
                        .padding(16)

                        if index < participants.count - 1 {

                            Divider()
                                .padding(.horizontal, 16)

                        }

                    }

                    Divider()
                        .padding(.horizontal, 16)

                    HStack {

                        Text(
                            "Split equally among \(participants.count) members"
                        )
                        .font(.system(size: 12))
                        .foregroundStyle(
                            AppColors.textSecondary
                        )

                        Spacer()

                        Text(formatted(amountValue))
                            .font(
                                .system(
                                    size: 13,
                                    weight: .bold
                                )
                            )
                            .foregroundStyle(
                                AppColors.dashboardPurple
                            )

                    }
                    .padding(16)

                }

            }
            .background(AppColors.card)
            .clipShape(
                RoundedRectangle(cornerRadius: 16)
            )

        }

    }

    // MARK: - Save Button

    private var saveButton: some View {

        Button {

            focusedField = nil

            Task {
                await save()
            }

        } label: {

            HStack(spacing: 10) {

                if isSaving {

                    ProgressView()
                        .tint(.white)

                } else {

                    Image(systemName: "checkmark.circle.fill")

                    Text(
                        isEditing
                            ? "Update Expense"
                            : "Save Expense"
                    )

                }

            }
            .font(
                .system(
                    size: 16,
                    weight: .semibold
                )
            )
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                isFormValid && !isSaving
                    ? AppColors.dashboardPurple
                    : AppColors.dashboardPurple.opacity(0.45)
            )
            .clipShape(
                RoundedRectangle(cornerRadius: 16)
            )

        }
        .disabled(!isFormValid || isSaving)

    }

    // MARK: - Reusable Section Title

    private func sectionTitle(_ text: String) -> some View {

        Text(text)
            .font(
                .system(
                    size: 17,
                    weight: .bold
                )
            )
            .foregroundStyle(AppColors.textPrimary)

    }

    // MARK: - Load Participants

    private func loadParticipants() async {

        isLoadingParticipants = true

        do {

            let loaded = try await GroupSharingManager.shared
                .fetchParticipants(for: group)

            participants = loaded

            if let expense {

                title = expense.title

                amount = CurrencyManager.editableText(
                    for: expense.amount
                )

                // Resolve old payer aliases before matching.
                let payerID = ParticipantResolver(
                    participants: loaded
                )
                .id(for: expense.paidByUserRecordID)

                selectedPayer = loaded.first {
                    $0.id == payerID
                }
                ?? loaded.first(where: \.isCurrentUser)
                ?? loaded.first

            } else {

                selectedPayer = loaded.first(
                    where: \.isCurrentUser
                )
                ?? loaded.first

            }

            hasLoadedParticipants = true

        } catch {

            errorMessage = error.localizedDescription
            showError = true

        }

        isLoadingParticipants = false

    }

    // MARK: - Save Expense

    private func save() async {

        guard
            !isSaving,
            isFormValid,
            let payer = selectedPayer,
            let amountValue = CurrencyManager.amount(
                from: amount
            )
        else {
            return
        }

        isSaving = true

        let trimmedTitle = title.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        do {

            let saved: SharedExpense

            if let expense {

                saved = try await GroupSharingManager.shared
                    .updateExpense(
                        expense,
                        title: trimmedTitle,
                        amount: amountValue,
                        paidBy: payer,
                        splitAmong: participants,
                        in: group
                    )

            } else {

                saved = try await GroupSharingManager.shared
                    .addExpense(
                        title: trimmedTitle,
                        amount: amountValue,
                        paidBy: payer,
                        splitAmong: participants,
                        in: group
                    )

            }

            onSaved(saved)
            dismiss()

        } catch {

            errorMessage = error.localizedDescription
            showError = true

        }

        isSaving = false

    }

}
