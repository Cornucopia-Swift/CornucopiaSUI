//
//  NonConsumablePurchaseManager.swift
//  CornucopiaStoreKit
//

import Combine
import Foundation
import StoreKit

/// An `ObservableObject` that manages the complete lifecycle of a single
/// non-consumable in-app purchase.
///
/// The manager loads the product, runs purchases and restores, tracks the
/// current entitlement, and observes transaction updates that arrive while
/// the app runs — e.g. a purchase completed on another device, an approved
/// *Ask to Buy* request, a refund, or a revocation. It starts working right
/// from `init`: current entitlements are refreshed and the product is loaded
/// in the background, so the UI can bind to ``status`` immediately and only
/// needs to call ``purchase()`` or ``restorePurchases()`` in response to
/// user actions.
///
/// - Important: Create one instance per product identifier and keep it alive
///   for the lifetime of the scene (e.g. as an `@StateObject` or via the
///   environment). Transaction updates are only observed while the manager
///   exists; short-lived instances miss updates that arrive in between.
@MainActor
public final class NonConsumablePurchaseManager: ObservableObject {

    /// Whether the user currently owns the managed product.
    @frozen public enum Status: Equatable, Sendable {
        /// The entitlement has not been determined yet — the initial state
        /// until the first entitlement refresh completes.
        case unknown
        /// The user does not own the product: it was never purchased, or the
        /// entitlement was refunded, revoked, or upgraded away.
        case locked
        /// The user owns the product.
        case unlocked
    }

    /// The outcome of a ``purchase()`` attempt.
    @frozen public enum PurchaseOutcome: Equatable, Sendable {
        /// The purchase succeeded and the entitlement is now active.
        case purchased
        /// The purchase needs approval (e.g. *Ask to Buy*) and is still pending;
        /// the unlock typically arrives later through the transaction observer.
        case pending
        /// The user dismissed the purchase sheet without buying.
        case userCancelled
        /// The product could not be loaded from the store.
        case unavailable
        /// The purchase failed — see ``lastErrorMessage`` for the reason.
        case failed
    }

    /// The identifier of the managed product, as configured in App Store Connect.
    public let productIdentifier: String

    /// The current entitlement state; drives feature gating in the UI.
    @Published public private(set) var status: Status = .unknown

    /// The loaded store products; at most the single product matching
    /// ``productIdentifier``.
    @Published public private(set) var products: [Product] = []

    /// Whether a purchase or restore is currently talking to the store.
    @Published public private(set) var isProcessingPurchase = false

    /// The most recent user-presentable error, or `nil` if the last operation
    /// succeeded. Product-loading failures, purchase errors, and transaction
    /// verification failures end up here.
    @Published public private(set) var lastErrorMessage: String?

    /// The loaded store product for ``productIdentifier``, if available.
    public var product: Product? {
        products.first { $0.id == productIdentifier }
    }

    /// Whether the user currently owns the product (`status == .unlocked`).
    public var isUnlocked: Bool {
        status == .unlocked
    }

    private let productUnavailableMessage: String
    private var updatesTask: Task<Void, Never>?
    private var bootstrapTask: Task<Void, Never>?

    /// Creates a manager for the given product and starts observing the store.
    ///
    /// Initialization kicks off two background tasks — refreshing the current
    /// entitlements and loading the product — and installs a listener for
    /// transaction updates. All of them are cancelled when the manager is
    /// deallocated.
    ///
    /// - Parameters:
    ///   - productIdentifier: The identifier of the non-consumable product to manage.
    ///   - productUnavailableMessage: User-presentable message published through
    ///     ``lastErrorMessage`` when the product cannot be found in the store.
    public init(productIdentifier: String, productUnavailableMessage: String) {
        self.productIdentifier = productIdentifier
        self.productUnavailableMessage = productUnavailableMessage

        updatesTask = Task { [weak self] in
            await self?.observeTransactions()
        }
        bootstrapTask = Task { [weak self] in
            guard let self else { return }
            await self.refreshEntitlements()
            await self.loadProductsIfNeeded()
        }
    }

    deinit {
        updatesTask?.cancel()
        bootstrapTask?.cancel()
    }

    /// Loads the product from the store unless products are already loaded.
    public func loadProductsIfNeeded() async {
        guard products.isEmpty else { return }
        await loadProducts()
    }

    /// (Re-)loads the managed product from the store.
    ///
    /// Only products matching ``productIdentifier`` of type `.nonConsumable` are
    /// kept. When the store returns no such product, ``lastErrorMessage`` is set
    /// to the manager's unavailable message; fetch errors surface their localized
    /// description instead.
    public func loadProducts() async {
        do {
            let fetched = try await Product.products(for: [productIdentifier])
            products = fetched
                .filter { $0.id == productIdentifier && $0.type == .nonConsumable }
                .sorted { $0.displayName < $1.displayName }
            lastErrorMessage = products.isEmpty ? productUnavailableMessage : nil
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    /// Purchases the managed product, loading it on demand when necessary.
    ///
    /// Only transactions that pass StoreKit's signature verification unlock the
    /// product; successful transactions are finished automatically. A `.pending`
    /// outcome means *Ask to Buy* approval is still outstanding — the unlock
    /// then arrives later through the transaction observer. The call fails fast
    /// while another purchase or restore is already in flight.
    @discardableResult
    public func purchase() async -> PurchaseOutcome {
        guard !isProcessingPurchase else { return .failed }

        if product == nil {
            await loadProducts()
        }
        guard let product else {
            lastErrorMessage = productUnavailableMessage
            return .unavailable
        }

        isProcessingPurchase = true
        lastErrorMessage = nil
        defer { isProcessingPurchase = false }

        do {
            switch try await product.purchase() {
            case .success(let verification):
                guard let transaction = verifiedTransaction(from: verification) else {
                    return .failed
                }
                await handle(transaction)
                return .purchased
            case .pending:
                return .pending
            case .userCancelled:
                return .userCancelled
            @unknown default:
                return .failed
            }
        } catch {
            lastErrorMessage = error.localizedDescription
            return .failed
        }
    }

    /// Restores previous purchases through the user's App Store account.
    ///
    /// Calls `AppStore.sync()`, which may prompt for the Apple ID, and then
    /// refreshes the entitlements. Shares the ``isProcessingPurchase`` flag
    /// with ``purchase()``, so it does nothing while an operation is in flight.
    public func restorePurchases() async {
        guard !isProcessingPurchase else { return }

        isProcessingPurchase = true
        lastErrorMessage = nil
        defer { isProcessingPurchase = false }

        do {
            try await AppStore.sync()
            await refreshEntitlements()
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    /// Refreshes the entitlement state from `Transaction.currentEntitlements`.
    ///
    /// The product counts as unlocked only when a verified transaction for
    /// ``productIdentifier`` exists that is neither revoked nor upgraded away.
    /// Failing verifications surface their error through ``lastErrorMessage``.
    public func refreshEntitlements() async {
        var isEntitled = false
        var verificationError: Error?

        for await result in Transaction.currentEntitlements {
            switch result {
            case .verified(let transaction):
                guard transaction.productID == productIdentifier else { continue }
                isEntitled = transaction.revocationDate == nil && !transaction.isUpgraded
            case .unverified(let transaction, let error):
                guard transaction.productID == productIdentifier else { continue }
                verificationError = error
            }
        }

        status = isEntitled ? .unlocked : .locked
        if isEntitled {
            lastErrorMessage = nil
        } else if let verificationError {
            lastErrorMessage = verificationError.localizedDescription
        }
    }

    private func observeTransactions() async {
        for await result in Transaction.updates {
            switch result {
            case .verified(let transaction):
                guard transaction.productID == productIdentifier else { continue }
                await handle(transaction)
            case .unverified(let transaction, let error):
                guard transaction.productID == productIdentifier else { continue }
                lastErrorMessage = error.localizedDescription
            }
        }
    }

    private func verifiedTransaction(from result: VerificationResult<Transaction>) -> Transaction? {
        switch result {
        case .verified(let transaction):
            return transaction
        case .unverified(_, let error):
            lastErrorMessage = error.localizedDescription
            return nil
        }
    }

    private func handle(_ transaction: Transaction) async {
        guard transaction.productID == productIdentifier else { return }
        status = transaction.revocationDate == nil && !transaction.isUpgraded ? .unlocked : .locked
        if status == .unlocked {
            lastErrorMessage = nil
        }
        await transaction.finish()
    }
}
