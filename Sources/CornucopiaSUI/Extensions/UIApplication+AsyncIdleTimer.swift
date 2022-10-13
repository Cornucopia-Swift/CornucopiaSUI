//
//  Cornucopia – (C) Dr. Lauer Information Technology
//
#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit

public extension UIApplication {

    /// Runs `body` while keeping the global idle timer disabled.
    func CC_withIdleTimerDisabled<ResultType: Sendable>(_ body: @escaping () async throws -> ResultType) async throws -> ResultType {
        await MainActor.run { UIApplication.shared.isIdleTimerDisabled = true }
        defer { UIApplication.shared.isIdleTimerDisabled = false }
        return try await body()
    }
}

#endif
