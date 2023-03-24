//
//  Cornucopia – (C) Dr. Lauer Information Technology
//
import Combine
import Dispatch
import CornucopiaCore

/// A debounced observable busy provider.
public final class ObservableBusyness: ObservableObject, Cornucopia.Core.BusynessObserver {

    private let debounceInterval: DispatchTimeInterval

    @Published var busy: Bool = false

    var newWorkItem: DispatchWorkItem {
        DispatchWorkItem() { [weak self] in
            guard let self else { return }
            let newBusy = self.numberOfRequests > 0
            guard newBusy != busy else { return }
            self.busy = newBusy
        }
    }
    @Cornucopia.Core.Protected
    var workItem: DispatchWorkItem? = nil

    @Cornucopia.Core.Protected
    var numberOfRequests: Int = 0

    public init(debounceInterval: DispatchTimeInterval) {
        self.debounceInterval = debounceInterval
    }

    public func enterBusy() {
        self.numberOfRequests += 1
        self.workItem?.cancel()
        self.workItem = self.newWorkItem
        DispatchQueue.main.asyncAfter(deadline: .now() + self.debounceInterval, execute: self.workItem!)
    }

    public func leaveBusy() {
        self.numberOfRequests -= 1
        self.workItem?.cancel()
        self.workItem = self.newWorkItem
        DispatchQueue.main.asyncAfter(deadline: .now() + self.debounceInterval, execute: self.workItem!)
    }
}
