//
//  Cornucopia – (C) Dr. Lauer Information Technology
//

#if os(iOS) || os(macOS) || os(tvOS)
import SwiftUI
import AVKit
#if canImport(UIKit)
import UIKit
#endif

@available(iOS 16.0, macOS 13.0, *)
public struct DevicePickerView: View {

    public struct Configuration {

        public static let `default`: Configuration = .init()

        public var activeTintColor: Color?
        public var normalTintColor: Color?
        public var prioritizesVideoDevices: Bool?
        public var showsVolumeSlider: Bool?

        public init(activeTintColor: Color? = nil,
                    normalTintColor: Color? = nil,
                    prioritizesVideoDevices: Bool? = nil,
                    showsVolumeSlider: Bool? = nil) {
            self.activeTintColor = activeTintColor
            self.normalTintColor = normalTintColor
            self.prioritizesVideoDevices = prioritizesVideoDevices
            self.showsVolumeSlider = showsVolumeSlider
        }

        fileprivate func apply(to view: AVRoutePickerView) {
#if canImport(UIKit)
            if let activeTintColor {
                view.activeTintColor = UIColor(activeTintColor)
            }
            if let normalTintColor {
                view.tintColor = UIColor(normalTintColor)
            }
            if let prioritizesVideoDevices {
                view.prioritizesVideoDevices = prioritizesVideoDevices
            }
            if let showsVolumeSlider {
                if #available(iOS 18.0, *) {
                    // showsVolumeSlider was removed in iOS 18
                } else {
                    view.setValue(showsVolumeSlider, forKey: "showsVolumeSlider")
                }
            }
#endif
        }
    }

    private let configuration: Configuration
    private let configure: (AVRoutePickerView) -> Void

    public init(configuration: Configuration = .default,
                configure: @escaping (AVRoutePickerView) -> Void = { _ in }) {
        self.configuration = configuration
        self.configure = configure
    }

    public var body: some View {
        Representable(configuration: configuration, configure: configure)
    }
}

@available(iOS 16.0, macOS 13.0, *)
private struct Representable: DevicePickerRepresentable {

    let configuration: DevicePickerView.Configuration
    let configure: (AVRoutePickerView) -> Void

#if canImport(UIKit)
    func makeUIView(context: Context) -> AVRoutePickerView {
        configuredView()
    }

    func updateUIView(_ uiView: AVRoutePickerView, context: Context) {
        configuration.apply(to: uiView)
        configure(uiView)
    }
#elseif canImport(AppKit)
    func makeNSView(context: Context) -> AVRoutePickerView {
        configuredView()
    }

    func updateNSView(_ nsView: AVRoutePickerView, context: Context) {
        configuration.apply(to: nsView)
        configure(nsView)
    }
#endif

    private func configuredView() -> AVRoutePickerView {
        let view = AVRoutePickerView()
        configuration.apply(to: view)
        configure(view)
        return view
    }
}

#if canImport(UIKit)
@available(iOS 16.0, *)
private typealias DevicePickerRepresentable = UIViewRepresentable
#elseif canImport(AppKit)
@available(macOS 13.0, *)
private typealias DevicePickerRepresentable = NSViewRepresentable
#endif

#if DEBUG
@available(iOS 16.0, macOS 13.0, *)
struct DevicePickerView_Previews: PreviewProvider {

    static var previews: some View {
        Group {
            DevicePickerView()
                .previewDisplayName("Default")
            DevicePickerView(configuration: .init(activeTintColor: .orange,
                                                  normalTintColor: .blue,
                                                  prioritizesVideoDevices: true,
                                                  showsVolumeSlider: true))
                .previewDisplayName("Custom Configuration")
            DevicePickerView { view in
                view.setValue(true, forKey: "automaticallyShowsLargeContentViewer")
            }
            .previewDisplayName("Custom Closure")
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif

#endif
