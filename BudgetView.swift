import SwiftUI
import SwiftData

struct BudgetView: View {

    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Budget.category)
    private var budgets: [Budget]

    @Query(sort: \Transaction.date, order: .reverse)
    private var transactions: [Transaction]

    @State private var showAddBudget = false
    @State private var selectedBudget: Budget?

    var body: some View {

        NavigationStack {

            ZStack {

                AppColors.background
                    .ignoresSafeArea()

                if budgets.isEmpty {

                    VStack(spacing: 24) {
                        
                        ZStack {
                            
                            Circle()
                                .fill(AppColors.primary.opacity(0.12))
                                .frame(width: 120, height: 120)
                            
                            Image(systemName: "wallet.pass.fill")
                                .font(.system(size: 54, weight: .semibold))
                                .foregroundStyle(AppColors.primary)
                            
                        }
                        
                        Text("Create Your First Budget")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(AppColors.textPrimary)
                        
                        Text("Set monthly spending limits for each category and keep your finances under control.")
                            .font(.subheadline)
                            .foregroundStyle(AppColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 320)
                            .lineSpacing(3)
                        
                        Button {
                            
                            showAddBudget = true
                            
                        } label: {
                            
                            Label("Add Budget", systemImage: "plus")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                            
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(AppColors.primary)
                        .padding(.horizontal, 40)
                    }

                } else {

                    ScrollView {

                        LazyVStack(spacing: 18) {

                            ForEach(budgets) { budget in

                                let calendar = Calendar.current

                                let spent = transactions
                                    .filter {
                                        $0.type == "Expense" &&
                                        $0.category == budget.category &&
                                        calendar.component(.month, from: $0.date) == budget.month &&
                                        calendar.component(.year, from: $0.date) == budget.year
                                    }
                                    .reduce(0) { $0 + $1.amount }

                                BudgetCardView(
                                    budget: budget,
                                    spent: spent,
                                    onEdit: {

                                        selectedBudget = budget

                                    },
                                    onDelete: {

                                        modelContext.delete(budget)

                                    }
                                )

                            }

                        }
                        .padding()

                    }

                }

            }
            .navigationTitle("Monthly Budget")
            .toolbar {

                ToolbarItem(placement: .topBarTrailing) {

                    Button {

                        showAddBudget = true

                    } label: {

                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(AppColors.primary)

                    }

                }

            }
            .sheet(isPresented: $showAddBudget) {

                AddBudgetView()

            }
            .sheet(item: $selectedBudget) { budget in

                AddBudgetView(budgetToEdit: budget)

            }

        }

    }

}

#Preview {

    BudgetView()

}
