import SwiftUI

struct CustomTabBar: View {

    @Binding var selectedTab: Int
    @Binding var showAddTransaction: Bool

    var body: some View {

        HStack {

            tabButton(
                icon: "house.fill",
                title: "Home",
                index: 0
            )

            Spacer()

            tabButton(
                icon: "wallet.pass.fill",
                title: "Budget",
                index: 1

            )

            Spacer()

            // Floating Add Button
            Button {

                showAddTransaction = true

            } label: {

                ZStack {

                    Circle()
                        .fill(AppColors.primary)
                        .frame(width: 68, height: 68)
                        .shadow(color: AppColors.shadow, radius: 8, y: 5)

                    Image(systemName: "plus")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(AppColors.textOnPrimary)

                }

            }
            .offset(y: -10)

            Spacer()

            tabButton(
                icon: "doc.text.fill",
                title: "Reports",
                index: 2
            )

            Spacer()

            tabButton(
                icon: "person.fill",
                title: "Profile",
                index: 3
            )

        }
        .padding(.horizontal, 25)
        .padding(.top, 15)
        .padding(.bottom, 25)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 30))
        .shadow(color: AppColors.shadow, radius: 10, y: 5)
        .padding(.horizontal, 20)
        .padding(.bottom, 10)

    }

    @ViewBuilder
    func tabButton(icon: String, title: String, index: Int) -> some View {

        Button {

            selectedTab = index

        } label: {

            VStack(spacing: 5) {

                Image(systemName: icon)
                    .font(.title3)

                Text(title)
                    .font(.caption2)
                    .fontWeight(.medium)

            }
            .foregroundStyle(selectedTab == index ? AppColors.primary : AppColors.textSecondary)
            .padding(.vertical, 8)
            .frame(width: 60)
            .background(
                selectedTab == index
                ? AppColors.primary.opacity(0.12)
                : Color.clear
            )
            .clipShape(Capsule())

        }

    }

}

#Preview {

    CustomTabBar(
        selectedTab: .constant(0),
        showAddTransaction: .constant(false)
    )

}
