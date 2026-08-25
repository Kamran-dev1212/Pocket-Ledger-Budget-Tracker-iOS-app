import SwiftUI

struct CalendarHeaderView: View {

    @Binding var displayedMonth: Date

    private var monthYearText: String {

        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"

        return formatter.string(from: displayedMonth)

    }

    var body: some View {

        HStack {

            Button {

                changeMonth(by: -1)

            } label: {

                Image(systemName: "chevron.left")
                    .font(.headline)
                    .foregroundStyle(AppColors.primary)
                    .frame(width: 36, height: 36)
                    .background(AppColors.primary.opacity(0.1))
                    .clipShape(Circle())

            }

            Spacer()

            Text(monthYearText)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(AppColors.textPrimary)

            Spacer()

            Button {

                changeMonth(by: 1)

            } label: {

                Image(systemName: "chevron.right")
                    .font(.headline)
                    .foregroundStyle(AppColors.primary)
                    .frame(width: 36, height: 36)
                    .background(AppColors.primary.opacity(0.1))
                    .clipShape(Circle())

            }

        }
        .padding(.horizontal, 4)

    }

    private func changeMonth(by value: Int) {

        if let newMonth = Calendar.current.date(byAdding: .month, value: value, to: displayedMonth) {

            displayedMonth = newMonth

        }

    }

}

#Preview {

    ZStack {

        AppColors.background
            .ignoresSafeArea()

        CalendarHeaderView(displayedMonth: .constant(Date()))
            .padding()

    }

}
