//
//  Cornucopia – (C) Dr. Lauer Information Technology
//
import Combine
import Foundation
import Network
import OSLog

/// Observes the local network authorization.
/// Inspired by discussions and solutions at https://stackoverflow.com/questions/63940427/ios-14-how-to-trigger-local-network-dialog-and-check-user-answer
/// To save resources, this class stops further work as soon as the status has moved to `.granted`.
public class ObservableLocalNetworkAuthorization: NSObject, ObservableObject, NetServiceDelegate {

    public enum Status {

        case notDetermined
        case denied
        case granted
    }

    @Published public private(set) var status: Status = .notDetermined {
        didSet {
#if DEBUG
            print("LNA status now \(status)")
#endif
            switch status {
                case .granted:
                    self.shutdown()
                default:
                    break
            }
        }
    }

    private var browser: NWBrowser? = nil
    private var service: NetService? = nil

    public override init() {
        super.init()

        let service = NetService(domain: "local.", type:"_lnp._tcp.", name: "ObservableLocalNetworkAuthorization", port: 7891)
        service.delegate = self
        self.service = service

        let parameters = NWParameters()
        parameters.includePeerToPeer = true
        let browser = NWBrowser(for: .bonjour(type: "_bonjour._tcp", domain: nil), using: parameters)

        browser.stateUpdateHandler = { [weak self] state in
            os_log("NWBrowser status update: %@", log: OSLog.default, type: .debug, "\(state)")
            guard let self else { return }
            switch state {
                case .failed(_):
                    self.service?.publish()
                case .waiting(_):
                    self.status = .denied
                default:
                    break
            }
        }
        self.browser = browser
        browser.start(queue: .main)
        service.publish()
    }

    public func netServiceDidPublish(_ sender: NetService) {
        os_log("NetService did publish", log: OSLog.default, type: .debug)
        self.status = .granted
    }

    private func shutdown() {
        self.browser?.cancel()
        self.service?.stop()
    }
}
