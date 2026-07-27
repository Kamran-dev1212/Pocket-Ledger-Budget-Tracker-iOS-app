import SwiftUI

struct HomeView: View {

    @State private var selectedTab = 0
    @State private var showAddTransaction = false

    var body: some View {

        NavigationStack {

            VStack(spacing: 0) {

                Group {

                    switch selectedTab {

                    case 0:
                        DashboardView()

                    case 1:
                        BudgetView()

                    case 2:
                        ReportsView()

                    case 3:
                        ProfileView()

                    default:
                        DashboardView()

                    }

                }

                CustomTabBar(
                    selectedTab: $selectedTab,
                    showAddTransaction: $showAddTransaction
                )

            }

        }
        .sheet(isPresented: $showAddTransaction) {

            AddTransactionView()

        }

    }

}

#Preview {
    HomeView()
}
