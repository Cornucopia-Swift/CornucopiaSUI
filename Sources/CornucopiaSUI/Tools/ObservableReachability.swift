//
//  Cornucopia – (C) Dr. Lauer Information Technology
//
import Combine
import Network

/// An observable reachability provider.
public final class ObservableReachability: ObservableObject {

    private let monitor: NWPathMonitor = .init()
    //private let ethernetMonitor: NWPathMonitor = NWPathMonitor.ethernetChannel
    private let queue: DispatchQueue = .global(qos: .background)

    static public let shared: ObservableReachability = .init()
    @Published public private(set) var isConnected: Bool = false
    @Published public private(set) var currentPath: NWPath? = nil

    private init() {
        self.monitor.pathUpdateHandler = { [weak self] path in

            guard let self else { return }

            switch path.status {
                case .satisfied:
                    DispatchQueue.main.async {
                        self.currentPath = path
                        self.isConnected = true
                    }

                default:
                    DispatchQueue.main.async {
                        self.currentPath = nil
                        self.isConnected = false
                    }
            }
        }
        self.monitor.start(queue: queue)
    }

    deinit {
        self.monitor.pathUpdateHandler = nil
    }
}
