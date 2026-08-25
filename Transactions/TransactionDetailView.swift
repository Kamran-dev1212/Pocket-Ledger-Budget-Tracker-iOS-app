import SwiftUI
import SwiftData

struct TransactionDetailView: View {

    @Environment(\.dismiss) private var dismiss

    let transaction: Transaction

    @AppStorage("selectedCurrency") private var currency: String = "PKR"

    @State private var showEdit = false

    private var isIncome: Bool {
        transaction.type == "Income"
    }

    private var accentColor: Color {
        isIncome ? AppColors.success : AppColors.expense
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, d MMMM yyyy"
        return formatter
    }()

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()

    var body: some View {

        NavigationStack {

            ZStack {

                AppColors.background
                    .ignoresSafeArea()

                ScrollView {

                    VStack(spacing: 28) {

                        // MARK: Icon, Title, Amount, Type

                        VStack(spacing: 16) {

                            ZStack {

                                Circle()
                                    .fill(accentColor.opacity(0.12))
                                    .frame(width: 88, height: 88)

                                Image(
                                    systemName: TransactionIcon.icon(
                                        for: transaction.category,
                                        type: transaction.type
                                    )
                                )
                                .font(.system(size: 36, weight: .semibold))
                                .foregroundStyle(accentColor)

                            }

                            Text(transaction.title)
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundStyle(AppColors.textPrimary)
                                .multilineTextAlignment(.center)

                            Text(
                                CurrencyManager.string(
                                    for: transaction.amount,
                                    currencyCode: currency,
                                    forcedSign: isIncome ? "+" : "-"
                                )
                            )
                            .font(.system(size: 34, weight: .bold))
                            .monospacedDigit()
                            .foregroundStyle(accentColor)

                            Text(transaction.type)
                                .font(.footnote)
                                .fontWeight(.semibold)
                                .foregroundStyle(accentColor)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(accentColor.opacity(0.12))
                                .clipShape(Capsule())

                        }
                        .padding(.top, 12)

                        // MARK: Category / Date / Time

                        VStack(spacing: 0) {

                            detailRow(
                                label: "Category",
                                value: transaction.category
                            )

                            Divider()
                                .overlay(AppColors.divider)

                            detailRow(
                                label: "Date",
                                value: Self.dateFormatter.string(from: transaction.date)
                            )

                            Divider()
                                .overlay(AppColors.divider)

                            detailRow(
                                label: "Time",
                                value: Self.timeFormatter.string(from: transaction.date)
                            )

                        }
                        .padding(.horizontal, AppColors.cardPadding)
                        .background(AppColors.card)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppColors.cardCornerRadius)
                                .stroke(AppColors.border, lineWidth: 1)
                        )
                        .clipShape(
                            RoundedRectangle(cornerRadius: AppColors.cardCornerRadius)
                        )

                        // MARK: Edit

                        Button {

                            showEdit = true

                        } label: {

                            Label("Edit Transaction", systemImage: "pencil")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)

                        }
                        .buttonStyle(.borderedProminent)
                        .tint(AppColors.primary)

                        Spacer(minLength: 20)

                    }
                    .padding(.horizontal, AppColors.pageHorizontalPadding)

                }

            }
            .navigationTitle("Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {

                ToolbarItem(placement: .topBarLeading) {

                    Button("Done") {

                        dismiss()

                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(AppColors.primary)

                }

            }
            .sheet(isPresented: $showEdit) {

                AddTransactionView(transaction: transaction)

            }

        }

    }

    // MARK: - Detail Row

    @ViewBuilder
    private func detailRow(label: String, value: String) -> some View {

        HStack {

            Text(label)
                .font(.subheadline)
                .foregroundStyle(AppColors.textSecondary)

            Spacer()

            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(AppColors.textPrimary)
                .multilineTextAlignment(.trailing)

        }
        .padding(.vertical, 16)

    }

}
