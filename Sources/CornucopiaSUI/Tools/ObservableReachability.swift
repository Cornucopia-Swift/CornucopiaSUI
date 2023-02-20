//
//  Cornucopia – (C) Dr. Lauer Information Technology
//
import Combine
import Network

public class ObservableReachability: ObservableObject {

    let monitor: NWPathMonitor = .init()
    let queue: DispatchQueue = .global(qos: .background)

    @Published public private(set) var isConnected: Bool = false

    public init() {
        monitor.pathUpdateHandler = { path in

            switch path.status {
                case .satisfied:
                    DispatchQueue.main.async { self.isConnected = true }

                default:
                    DispatchQueue.main.async { self.isConnected = false }
            }
        }
        monitor.start(queue: queue)
    }
}
