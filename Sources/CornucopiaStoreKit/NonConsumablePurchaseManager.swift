import Combine
import Foundation
import StoreKit

@MainActor
open class NonConsumablePurchaseManager: ObservableObject {

    public enum Status: Equatable, Sendable {
        case unknown
        case locked
        case unlocked
    }

    public enum PurchaseOutcome: Equatable, Sendable {
        case purchased
        case pending
        case userCancelled
        case unavailable
        case failed
    }

    public let productIdentifier: String

    @Published public private(set) var status: Status = .unknown
    @Published public private(set) var products: [Product] = []
    @Published public private(set) var isProcessingPurchase = false
    @Published public private(set) var lastErrorMessage: String?

    public var product: Product? {
        products.first { $0.id == productIdentifier }
    }

    public var isUnlocked: Bool {
        status == .unlocked
    }

    private let productUnavailableMessage: String
    private var updatesTask: Task<Void, Never>?
    private var bootstrapTask: Task<Void, Never>?

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

    public func loadProductsIfNeeded() async {
        guard products.isEmpty else { return }
        await loadProducts()
    }

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
