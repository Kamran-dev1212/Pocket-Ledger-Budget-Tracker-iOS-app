import SwiftUI

struct TransactionTypePicker: View {

    @Binding var selection: String
    @Namespace private var animation

    private let options: [(label: String, value: String, color: Color)] = [
        ("Expense", "Expense", AppColors.expense),
        ("Income", "Income", AppColors.success)
    ]

    var body: some View {

        HStack(spacing: 4) {

            ForEach(options, id: \.value) { option in

                let isSelected = selection == option.value

                Button {

                    withAnimation(.easeInOut(duration: 0.25)) {
                        selection = option.value
                    }

                } label: {

                    Text(option.label)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(
                            isSelected ? AppColors.textOnPrimary : AppColors.textSecondary
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background {

                            if isSelected {

                                Capsule()
                                    .fill(option.color)
                                    .matchedGeometryEffect(id: "pill", in: animation)

                            }

                        }

                }
                .buttonStyle(.plain)

            }

        }
        .padding(4)
        .background(AppColors.card)
        .overlay(
            Capsule()
                .stroke(AppColors.border, lineWidth: 1)
        )
        .clipShape(Capsule())

    }

}

#Preview {

    ZStack {

        AppColors.background
            .ignoresSafeArea()

        TransactionTypePicker(selection: .constant("Expense"))
            .padding()

    }

}
