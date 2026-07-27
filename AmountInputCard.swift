import SwiftUI

struct AmountInputCard: View {

    @Binding var amount: String
    var accentColor: Color = AppColors.primary
    var isFocused: FocusState<Bool>.Binding

    @AppStorage("selectedCurrency") private var currency: String = "PKR"

    var body: some View {

        VStack(spacing: 10) {

            Text("Amount")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(AppColors.textSecondary)

            HStack(spacing: 6) {

                Text(CurrencyManager.symbol(for: currency))
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(AppColors.textSecondary)

                TextField("0", text: $amount)
                    .keyboardType(.decimalPad)
                    .focused(isFocused)
                    .font(.system(size: 44, weight: .bold))
                    .foregroundStyle(AppColors.textPrimary)
                    .multilineTextAlignment(.leading)
                    .fixedSize()
                    .accessibilityLabel("Amount")

            }

        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppColors.heroCardPadding)
        .padding(.horizontal, AppColors.cardPadding)
        .background(AppColors.card)
        .overlay(
            RoundedRectangle(cornerRadius: AppColors.heroCardCornerRadius)
                .stroke(accentColor.opacity(0.15), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: AppColors.heroCardCornerRadius))
        .shadow(
            color: AppColors.shadow,
            radius: AppColors.cardShadowRadius,
            x: 0,
            y: AppColors.cardShadowY
        )
        .contentShape(Rectangle())
        .onTapGesture {
            isFocused.wrappedValue = true
        }
        .animation(.easeInOut(duration: 0.2), value: amount)
        .toolbar {

            ToolbarItemGroup(placement: .keyboard) {

                Spacer()

                Button("Done") {
                    isFocused.wrappedValue = false
                }
                .fontWeight(.semibold)

            }

        }

    }

}

// MARK: - Preview wrapper (avoids @Previewable for compatibility with older Xcode)

private struct AmountInputCardPreviewWrapper: View {

    @State private var amount = "2500"
    @FocusState private var isFocused: Bool

    var body: some View {

        ZStack {

            AppColors.background
                .ignoresSafeArea()

            AmountInputCard(amount: $amount, isFocused: $isFocused)
                .padding()

        }

    }

}

#Preview {
    AmountInputCardPreviewWrapper()
}
