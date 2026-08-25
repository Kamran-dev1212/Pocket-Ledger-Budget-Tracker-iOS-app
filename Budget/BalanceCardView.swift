import SwiftUI

struct BalanceCardView: View {

    let balance: Double

    @AppStorage(
        "selectedCurrency"
    )
    private var currency: String = "PKR"

    @State private var isVisible = false

    // MARK: - Current Date

    private var currentDate: String {

        Date()
            .formatted(
                .dateTime
                    .day()
                    .month(.wide)
                    .year()
            )

    }

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 5
        ) {

            Text("Your Balance")
                .font(
                    .headline
                )
                .foregroundStyle(
                    AppColors.textOnPrimary
                        .opacity(0.85)
                )

            Text(
                                CurrencyManager.string(
                                    for: balance,
                                    currencyCode: currency
                                )
                            )
            .font(
                            .system(
                                size: 32,
                                weight: .bold
                            )
                        )
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
            .foregroundStyle(
                AppColors.textOnPrimary
            )

            // MARK: - Date

            Text(currentDate)
                .font(
                    .system(
                        size: 11,
                        weight: .regular
                    )
                )
                .foregroundStyle(
                    AppColors.textOnPrimary
                        .opacity(0.60)
                )

        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )

            .padding(.horizontal, AppColors.heroCardPadding)
                    .padding(.vertical, 20)
        .background(

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

        )
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
        .opacity(
            isVisible ? 1 : 0
        )
        .offset(
            y: isVisible ? 0 : 8
        )
        .onAppear {

            withAnimation(
                .easeOut(
                    duration: 0.35
                )
            ) {

                isVisible = true

            }

        }

    }

}

#Preview {

    ZStack {

        AppColors.background
            .ignoresSafeArea()

        VStack {

            BalanceCardView(
                balance: 125450
            )

        }
        .padding()

    }

}
