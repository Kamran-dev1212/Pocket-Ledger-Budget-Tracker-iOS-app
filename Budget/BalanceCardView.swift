import SwiftUI

struct BalanceCardView: View {

    enum PresentationStyle {
        case card
        case header
    }

    let balance: Double

    var presentationStyle: PresentationStyle = .card

    @AppStorage("selectedCurrency")
    private var currency: String = "USD"

    @State private var isVisible = false

    // MARK: - Current Date

    private var currentDate: String {
        Date().formatted(
            .dateTime
                .day()
                .month(.wide)
                .year()
        )
    }

    // MARK: - Balance Content

    private var balanceContent: some View {

        VStack(
            alignment: presentationStyle == .header
                ? .center
                : .leading,
            spacing: presentationStyle == .header ? 6 : 5
        ) {

            Text("This Month's Balance")
                .font(
                    presentationStyle == .header
                        ? .system(size: 15, weight: .medium)
                        : .headline
                )
                .foregroundStyle(
                    AppColors.textOnPrimary.opacity(0.85)
                )

            Text(
                CurrencyManager.string(
                    for: balance,
                    currencyCode: currency
                )
            )
            .font(
                .system(
                    size: presentationStyle == .header ? 38 : 32,
                    weight: .bold,
                    design: .rounded
                )
            )
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.55)
            .foregroundStyle(AppColors.textOnPrimary)

            Text(currentDate)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(
                    AppColors.textOnPrimary.opacity(0.65)
                )

        }
        .frame(
            maxWidth: .infinity,
            alignment: presentationStyle == .header
                ? .center
                : .leading
        )
    }

    // MARK: - Body

    var body: some View {

        Group {

            if presentationStyle == .header {

                balanceContent
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)

            } else {

                balanceContent
                    .padding(
                        .horizontal,
                        AppColors.heroCardPadding
                    )
                    .padding(.vertical, 20)
                    .background {

                        ZStack {

                            LinearGradient(
                                colors: [
                                    AppColors.primary,
                                    AppColors.accent,
                                    AppColors.secondary
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )

                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.16),
                                    Color.white.opacity(0)
                                ],
                                startPoint: .top,
                                endPoint: .center
                            )

                        }

                    }
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius:
                                AppColors.heroCardCornerRadius
                        )
                    )
                    .shadow(
                        color: AppColors.primary.opacity(0.16),
                        radius: AppColors.heroShadowRadius,
                        x: 0,
                        y: AppColors.heroShadowY
                    )

            }

        }
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 8)
        .onAppear {

            withAnimation(
                .easeOut(duration: 0.35)
            ) {
                isVisible = true
            }

        }
        .accessibilityElement(children: .combine)
    }

}

// MARK: - Preview

#Preview("Dashboard Header Style") {

    ZStack {

        AppColors.dashboardGradient
            .ignoresSafeArea()

        BalanceCardView(
            balance: 125450,
            presentationStyle: .header
        )

    }

}

#Preview("Existing Card Style") {

    ZStack {

        AppColors.background
            .ignoresSafeArea()

        BalanceCardView(
            balance: 125450
        )
        .padding()

    }

}
