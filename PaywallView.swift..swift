import SwiftUI
import StoreKit

/// Shown whenever a free user hits a Premium-only limit (a second owned
/// group, full transaction history, PDF export, etc). Presented as a sheet
/// from wherever the gate is triggered.
struct PaywallView: View {

    @Environment(\.dismiss) private var dismiss
    @StateObject private var subscriptionManager = SubscriptionManager.shared

    @State private var selectedProductID = SubscriptionProductID.yearly.rawValue

    /// Optional context-specific message for why the paywall appeared
    /// (e.g. "Create unlimited groups with Premium"). Falls back to a
    /// generic message if not provided.
    var reason: String?

    var body: some View {

        NavigationStack {

            ZStack {

                AppColors.background
                    .ignoresSafeArea()

                ScrollView {

                    VStack(spacing: AppColors.sectionSpacing) {

                        header

                        featureList

                        planPicker

                        subscribeButton

                        footer

                    }
                    .padding(.horizontal, AppColors.pageHorizontalPadding)
                    .padding(.top, 24)
                    .padding(.bottom, 32)

                }

            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {

                ToolbarItem(placement: .topBarLeading) {

                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(AppColors.textSecondary)
                    }

                }

            }
            .alert(
                "Error",
                isPresented: Binding(
                    get: { subscriptionManager.errorMessage != nil },
                    set: { if !$0 { subscriptionManager.errorMessage = nil } }
                )
            ) {

                Button("OK", role: .cancel) { }

            } message: {

                Text(subscriptionManager.errorMessage ?? "")

            }
            .onChange(of: subscriptionManager.isSubscribed) { _, isSubscribed in

                if isSubscribed {
                    dismiss()
                }

            }

        }

    }

    // MARK: - Sections

    private var header: some View {

        VStack(spacing: 12) {

            Image(systemName: "crown.fill")
                .font(.system(size: 44))
                .foregroundStyle(AppColors.warning)

            Text("Pocket Ledger Premium")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(AppColors.textPrimary)

            Text(reason ?? "Unlock the full power of Pocket Ledger.")
                .font(.subheadline)
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)

        }

    }

    private var featureList: some View {

        VStack(alignment: .leading, spacing: 14) {

            featureRow(icon: "person.3.fill", text: "Unlimited shared groups")
            featureRow(icon: "doc.text.fill", text: "Full transaction history & PDF export")
            featureRow(icon: "bell.badge.fill", text: "Custom reminders")
            featureRow(icon: "star.fill", text: "Priority support")

        }
        .padding(AppColors.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: AppColors.cardCornerRadius))
        .shadow(color: AppColors.shadow, radius: AppColors.cardShadowRadius, y: AppColors.cardShadowY)

    }

    private func featureRow(icon: String, text: String) -> some View {

        HStack(spacing: 12) {

            Image(systemName: icon)
                .foregroundStyle(AppColors.primary)
                .frame(width: 24)

            Text(text)
                .font(.subheadline)
                .foregroundStyle(AppColors.textPrimary)

        }

    }

    private var planPicker: some View {

        VStack(spacing: 12) {

            if let monthly = subscriptionManager.monthlyProduct {

                planOption(
                    product: monthly,
                    badge: "7-day free trial",
                    subtitle: "then \(monthly.displayPrice)/month"
                )

            }

            if let yearly = subscriptionManager.yearlyProduct {

                planOption(
                    product: yearly,
                    badge: "Best value",
                    subtitle: "\(yearly.displayPrice)/year"
                )

            }

            if subscriptionManager.products.isEmpty {

                ProgressView()
                    .padding()

            }

        }

    }

    private func planOption(product: Product, badge: String, subtitle: String) -> some View {

        let isSelected = selectedProductID == product.id

        return Button {

            selectedProductID = product.id

        } label: {

            HStack {

                VStack(alignment: .leading, spacing: 4) {

                    Text(product.displayName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppColors.textPrimary)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(AppColors.textSecondary)

                }

                Spacer()

                Text(badge)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(AppColors.primary.opacity(0.12))
                    .foregroundStyle(AppColors.primary)
                    .clipShape(Capsule())

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? AppColors.primary : AppColors.textSecondary)

            }
            .padding(AppColors.cardPadding)
            .background(AppColors.card)
            .clipShape(RoundedRectangle(cornerRadius: AppColors.cardCornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: AppColors.cardCornerRadius)
                    .stroke(isSelected ? AppColors.primary : .clear, lineWidth: 2)
            )

        }
        .buttonStyle(.plain)

    }

    private var subscribeButton: some View {

        Button {

            guard let product = subscriptionManager.products.first(where: { $0.id == selectedProductID }) else {
                return
            }

            Task {
                await subscriptionManager.purchase(product)
            }

        } label: {

            if subscriptionManager.isWorking {

                ProgressView()
                    .tint(AppColors.textOnPrimary)
                    .frame(maxWidth: .infinity)
                    .padding()

            } else {

                Text("Start 7-Day Free Trial")
                    .font(.headline)
                    .foregroundStyle(AppColors.textOnPrimary)
                    .frame(maxWidth: .infinity)
                    .padding()

            }

        }
        .background(AppColors.primary)
        .clipShape(RoundedRectangle(cornerRadius: AppColors.cardCornerRadius))
        .disabled(subscriptionManager.isWorking || subscriptionManager.products.isEmpty)

    }

    private var footer: some View {

        VStack(spacing: 8) {

            Button("Restore Purchases") {

                Task {
                    await subscriptionManager.restorePurchases()
                }

            }
            .font(.footnote)
            .foregroundStyle(AppColors.primary)

            Text("After your 7-day free trial, your subscription renews automatically at the price shown above until cancelled. Manage or cancel anytime in Settings > Apple ID > Subscriptions.")
                .font(.caption2)
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)

        }
        .padding(.top, 8)

    }

}

#Preview {
    PaywallView(reason: "Create unlimited groups with Premium.")
}
