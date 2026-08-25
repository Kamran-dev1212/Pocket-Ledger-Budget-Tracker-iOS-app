import SwiftUI

struct CalendarView: View {

    @Environment(\.dismiss) private var dismiss

    @Binding var selectedDate: Date
    @State private var displayedMonth: Date

    init(selectedDate: Binding<Date>) {

        self._selectedDate = selectedDate
        self._displayedMonth = State(initialValue: selectedDate.wrappedValue)

    }

    var body: some View {

        NavigationStack {

            ZStack {

                AppColors.background
                    .ignoresSafeArea()

                VStack(spacing: 24) {

                    CalendarHeaderView(displayedMonth: $displayedMonth)

                    CalendarGridView(
                        displayedMonth: displayedMonth,
                        selectedDate: $selectedDate
                    )

                    Spacer()

                }
                .padding()
                .background(AppColors.card)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(
                    color: AppColors.shadow,
                    radius: 6,
                    x: 0,
                    y: 3
                )
                .padding()

            }
            .navigationTitle("Select Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {

                ToolbarItem(placement: .topBarTrailing) {

                    Button("Done") {

                        dismiss()

                    }
                    .fontWeight(.semibold)

                }

            }

        }

    }

}

#Preview {

    CalendarView(selectedDate: .constant(Date()))

}
