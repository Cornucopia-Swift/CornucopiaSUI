//
//  Cornucopia – (C) Dr. Lauer Information Technology
//
import SwiftUI
import CornucopiaCore

private let logger = Cornucopia.Core.Logger()

/// A type that represents a path of navigation elements.
@MainActor
public final class NavigationController: ObservableObject {

    @Published public var path = NavigationPath()
    private var types: [String] = []

    public init() {}

    /// Pushes a new element onto the navigation stack.
    public func push<T: Hashable>(_ element: T) {

        logger.debug("Pushing \(element) on the navigation stack")
        self.types.append(String(describing: T.self))
        withAnimation {
            self.path.append(element)
        }
    }

    /// Pops a number of elements from the navigation stack.
    public func pop(_ count: Int = 1) {

        guard count > 0 else { return }
        logger.debug("Popping \(count) elements from the navigation stack")
        let numberToRemove = min(count, self.path.count)
        self.types.removeLast(numberToRemove)
        withAnimation {
            self.path.removeLast(numberToRemove)
        }
    }

    /// Pops all elements from the navigation stack.
    public func popToRoot() {

        logger.debug("Popping to root of the navigation stack")
        self.types.removeAll()
        withAnimation {
            self.path.removeLast(self.path.count)
        }
    }

    /// Returns whether the navigation stack contains a certain type of element.
    /// NOTE: This is not using equality, but type identity!
    public func pathContains<T: Hashable>(_ element: T) -> Bool {

        let typename = String(describing: T.self)
        return self.types.contains(typename)
    }
}

/// Allow instances of NavigationController to be shared via the Environment
public extension EnvironmentValues {
    @Entry var CC_navigationController: NavigationController? = nil
}
