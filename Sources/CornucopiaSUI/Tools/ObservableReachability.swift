//
//  Cornucopia – (C) Dr. Lauer Information Technology
//
import Combine
import Network
import CornucopiaCore

private let logger = Cornucopia.Core.Logger()

/// An observable reachability provider.
public final class ObservableReachability: ObservableObject {

    private let monitor: NWPathMonitor = .init()
    //private let ethernetMonitor: NWPathMonitor = NWPathMonitor.ethernetChannel
    private let queue: DispatchQueue = .global(qos: .background)

    static public let shared: ObservableReachability = .init()
    @Published public private(set) var isConnected: Bool = false
    @Published public private(set) var currentPath: NWPath? = nil  {
        didSet {
            guard let path = self.currentPath else { return }
            self.isConnected = path.status == .satisfied
            switch path.status {
                case .satisfied:
                    logger.trace("Path satisfied via \(path.availableInterfaces), gateways: \(path.gateways)")

                default:
                    logger.trace("Path NOT satisfied.")
            }
        }
    }

    private init() {
        self.monitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            DispatchQueue.main.async { self.currentPath = path }
        }
        self.monitor.start(queue: queue)
    }

    deinit {
        self.monitor.pathUpdateHandler = nil
    }
}
