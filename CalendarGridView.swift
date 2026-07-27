import SwiftUI

struct CalendarGridView: View {

    let displayedMonth: Date
    @Binding var selectedDate: Date

    private let calendar = Calendar.current
    private let weekdaySymbols = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    private let columns = Array(
        repeating: GridItem(.flexible()),
        count: 7
    )

    // MARK: - Days to display (including leading blanks for month offset)

    private var daysInMonth: [Date?] {

        guard
            let monthInterval = calendar.dateInterval(of: .month, for: displayedMonth),
            let firstWeekday = calendar.dateComponents([.weekday], from: monthInterval.start).weekday
        else {
            return []
        }

        let leadingBlanks = firstWeekday - 1

        var days: [Date?] = Array(repeating: nil, count: leadingBlanks)

        var currentDate = monthInterval.start

        while currentDate < monthInterval.end {

            days.append(currentDate)

            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
                break
            }

            currentDate = nextDate

        }

        return days

    }

    var body: some View {

        VStack(spacing: 12) {

            // MARK: Weekday Labels

            HStack {

                ForEach(weekdaySymbols, id: \.self) { symbol in

                    Text(symbol)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppColors.textSecondary)
                        .frame(maxWidth: .infinity)

                }

            }

            // MARK: Day Grid

            LazyVGrid(columns: columns, spacing: 10) {

                ForEach(Array(daysInMonth.enumerated()), id: \.offset) { _, date in

                    if let date {

                        dayCell(for: date)

                    } else {

                        Color.clear
                            .frame(height: 40)

                    }

                }

            }

        }

    }

    // MARK: - Day Cell

    @ViewBuilder
    private func dayCell(for date: Date) -> some View {

        let isToday = calendar.isDateInToday(date)
        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)

        Button {

            selectedDate = date

        } label: {

            Text("\(calendar.component(.day, from: date))")
                .font(.subheadline)
                .fontWeight(isSelected ? .bold : .regular)
                .foregroundStyle(
                    isSelected
                        ? AppColors.textOnPrimary
                        : AppColors.textPrimary
                )
                .frame(width: 40, height: 40)
                .background(

                    Circle()
                        .fill(isSelected ? AppColors.primary : Color.clear)

                )
                .overlay(

                    Circle()
                        .stroke(
                            isToday && !isSelected ? AppColors.primary : Color.clear,
                            lineWidth: 1.5
                        )

                )

        }

    }

}

#Preview {

    ZStack {

        AppColors.background
            .ignoresSafeArea()

        CalendarGridView(
            displayedMonth: Date(),
            selectedDate: .constant(Date())
        )
        .padding()

    }

}
