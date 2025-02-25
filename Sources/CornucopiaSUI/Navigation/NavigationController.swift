//
//  Cornucopia – (C) Dr. Lauer Information Technology
//
import SwiftUI
import CornucopiaCore

private let logger = Cornucopia.Core.Logger()

/// A type that represents a path of navigation elements.
public final class NavigationController: ObservableObject {

    @Published public var path = NavigationPath()

    public init() {}

    public func push<T: Hashable>(_ element: T) {
        logger.debug("Pushing \(element) on the navigation stack")
        withAnimation {
            self.path.append(element)
        }
    }

    public func pop(_ count: Int = 1) {
        guard count > 0 else { return }
        logger.debug("Popping \(count) elements from the navigation stack")
        let numberToRemove = min(count, self.path.count)
        withAnimation {
            self.path.removeLast(numberToRemove)
        }
    }

    public func popToRoot() {
        logger.debug("Popping to root of the navigation stack")
        withAnimation {
            self.path.removeLast(self.path.count)
        }
    }
}

extension NavigationController {
    struct Key: EnvironmentKey {
        static let defaultValue: NavigationController? = nil
    }
}

public extension EnvironmentValues {

    var CC_navigationController: NavigationController? {
        get { self[NavigationController.Key.self] }
        set { self[NavigationController.Key.self] = newValue }
    }
}
