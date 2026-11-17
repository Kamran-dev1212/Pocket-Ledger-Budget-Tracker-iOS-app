import SwiftUI

struct TransactionTypePicker: View {

    @Binding var selection: String
    @Namespace private var animation

    private let options = ["Expense", "Income"]

    var body: some View {

        HStack(spacing: 4) {

            ForEach(options, id: \.self) { option in

                let isSelected = selection == option

                Button {

                    withAnimation(.easeInOut(duration: 0.25)) {
                        selection = option
                    }

                } label: {

                    Text(option)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(
                            isSelected
                                ? Color.white
                                : AppColors.textSecondary
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background {

                            if isSelected {

                                Capsule()
                                    .fill(AppColors.dashboardPurple)
                                    .matchedGeometryEffect(
                                        id: "pill",
                                        in: animation
                                    )

                            }

                        }

                }
                .buttonStyle(.plain)

            }

        }
        .padding(5)
        .background(AppColors.card)
        .overlay {

            Capsule()
                .stroke(
                    AppColors.border,
                    lineWidth: 1
                )

        }
        .clipShape(Capsule())

    }

}

#Preview {

    ZStack {

        AppColors.background
            .ignoresSafeArea()

        TransactionTypePicker(
            selection: .constant("Expense")
        )
        .padding()

    }

}
