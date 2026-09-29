import Foundation
import StoreKit

/// Product identifiers for the Premium subscription group. These must match
/// exactly what's configured in App Store Connect (and in Products_1.storekit
/// for local testing) — the trial itself is configured as an Introductory
/// Offer on the monthly product in App Store Connect, not tracked here.
enum SubscriptionProductID: String, CaseIterable {

    case monthly = "com.kamranzaidi.pocketledger.premium.monthly"
    case yearly = "com.kamranzaidi.pocketledger.premium.yearly"

}

/// Tracks Premium entitlement state and handles purchases, restores, and
/// renewal updates via StoreKit 2. Mirrors the singleton + @Published
/// pattern used by SaveReporter and GroupSharingManager elsewhere in the app.
@MainActor
final class SubscriptionManager: ObservableObject {

    static let shared = SubscriptionManager()

    // MARK: - Published State

    /// Whether the user currently has an active Premium entitlement
    /// (paid or in a free trial — StoreKit treats both as "entitled").
    @Published private(set) var isSubscribed = false

    /// The products fetched from the App Store, in display order
    /// (monthly first, then yearly).
    @Published private(set) var products: [Product] = []

    /// True while a purchase or restore is in flight, so the paywall
    /// can show a spinner and disable its buttons.
    @Published private(set) var isWorking = false

    /// Set when a purchase/restore fails, for the paywall to display.
    @Published var errorMessage: String?

    /// True while products are being fetched from the App Store.
    @Published private(set) var isLoadingProducts = false

    /// Set when the last product fetch failed or came back empty, so the
    /// paywall can offer a retry instead of spinning forever.
    @Published private(set) var productsFailedToLoad = false

    private var transactionListenerTask: Task<Void, Never>?

    private init() {

        // Start listening for transaction updates (renewals, cancellations,
        // refunds, family sharing changes) as soon as the app launches.
        transactionListenerTask = listenForTransactionUpdates()

        Task {
            await loadProducts()
            await refreshEntitlementStatus()
        }

    }

    deinit {
        transactionListenerTask?.cancel()
    }

    // MARK: - Existing Users

    /// UserDefaults key set once at launch for people who installed 1.0,
    /// where categories, currency, PDF export and reminders were free.
    static let legacyUserKey = "legacyFreeFeatures"

    /// True for users who had the app before Premium existed.
    var isLegacyUser: Bool {
        UserDefaults.standard.bool(forKey: Self.legacyUserKey)
    }

    /// Unlocks the features that were free in 1.0: subscribers, plus
    /// everyone who installed before Premium. Unlimited groups stays
    /// subscription-only via `isSubscribed`, since groups are new.
    var hasPremiumFeatures: Bool {
        isSubscribed || isLegacyUser
    }

    // MARK: - Loading Products

    func loadProducts() async {

        guard !isLoadingProducts else { return }

        isLoadingProducts = true
        productsFailedToLoad = false

        defer { isLoadingProducts = false }

        do {

            let storeProducts = try await Product.products(
                for: SubscriptionProductID.allCases.map(\.rawValue)
            )

            // Keep a stable, predictable order for the paywall UI
            // regardless of what order the App Store returns them in.
            let order = SubscriptionProductID.allCases.map(\.rawValue)

            products = storeProducts.sorted { lhs, rhs in

                (order.firstIndex(of: lhs.id) ?? .max) < (order.firstIndex(of: rhs.id) ?? .max)

            }

            productsFailedToLoad = products.isEmpty

        } catch {

            productsFailedToLoad = true

        }

    }

    var monthlyProduct: Product? {
        products.first { $0.id == SubscriptionProductID.monthly.rawValue }
    }

    var yearlyProduct: Product? {
        products.first { $0.id == SubscriptionProductID.yearly.rawValue }
    }

    // MARK: - Purchasing

    func purchase(_ product: Product) async {

        isWorking = true
        errorMessage = nil

        defer { isWorking = false }

        do {

            let result = try await product.purchase()

            switch result {

            case .success(let verification):

                let transaction = try checkVerified(verification)
                await refreshEntitlementStatus()
                await transaction.finish()

            case .userCancelled:
                // Not an error — the user backed out of the sheet.
                break

            case .pending:
                // Awaiting approval (e.g. Ask to Buy for a family member).
                errorMessage = "Your purchase is pending approval."

            @unknown default:
                break

            }

        } catch {

            errorMessage = "Something went wrong with the purchase. Please try again."

        }

    }

    func restorePurchases() async {

        isWorking = true
        errorMessage = nil

        defer { isWorking = false }

        do {

            try await AppStore.sync()
            await refreshEntitlementStatus()

            if !isSubscribed {
                errorMessage = "No active subscription was found for this Apple ID."
            }

        } catch {

            errorMessage = "Couldn't restore purchases. Please try again."

        }

    }

    // MARK: - Entitlement State

    /// Re-derives `isSubscribed` from StoreKit's own record of current
    /// entitlements. This is the source of truth — never a locally stored
    /// flag — so reinstalls, new devices, and Family Sharing all resolve
    /// correctly without any server of our own.
    func refreshEntitlementStatus() async {

        var activeSubscription = false

        for await result in StoreKit.Transaction.currentEntitlements {

            guard let transaction = try? checkVerified(result) else { continue }

            if SubscriptionProductID.allCases.contains(where: { $0.rawValue == transaction.productID }) {

                activeSubscription = true

            }

        }

        isSubscribed = activeSubscription

    }

    private func listenForTransactionUpdates() -> Task<Void, Never> {

        Task.detached { [weak self] in

            for await result in StoreKit.Transaction.updates {

                guard let transaction = try? await self?.checkVerified(result) else { continue }

                await self?.refreshEntitlementStatus()
                await transaction.finish()

            }

        }

    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {

        switch result {

        case .unverified:
            throw StoreError.failedVerification

        case .verified(let safe):
            return safe

        }

    }

    private enum StoreError: Error {
        case failedVerification
    }

}
