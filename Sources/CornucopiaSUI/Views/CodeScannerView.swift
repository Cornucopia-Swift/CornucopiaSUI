//
//  CodeScannerView.swift
//  CornucopiaSUI
//

import SwiftUI

#if canImport(VisionKit) && canImport(Vision) && os(iOS)
import Vision
import VisionKit

/// A live camera view that reports machine-readable codes as they are recognized.
///
/// Wraps VisionKit's `DataScannerViewController`, which handles framing, focus,
/// and highlighting, so callers only supply the symbologies they care about and
/// a closure. `VINScannerView` predates this and does the same thing for text;
/// this one is generic and public.
///
/// - Important: `DataScannerViewController` is unavailable in the Simulator and
///   on devices without a Neural Engine. Check ``isAvailable`` and offer a
///   manual path — a scanner that silently shows nothing is worse than a text
///   field.
@MainActor
public struct CodeScannerView: UIViewControllerRepresentable {

    /// Whether this device can scan at all.
    public static var isAvailable: Bool {
        DataScannerViewController.isSupported && DataScannerViewController.isAvailable
    }

    private let recognizedDataTypes: Set<DataScannerViewController.RecognizedDataType>
    private let recognizesMultipleItems: Bool
    private let onScan: (String) -> Void

    /// - Parameters:
    ///   - symbologies: Barcode symbologies to look for. Defaults to QR only,
    ///     because a scanner that also fires on EANs picked up from packaging in
    ///     the background is a nuisance.
    ///   - recognizesMultipleItems: Keep false when the first hit should win.
    ///   - onScan: Called on the main actor for every recognized payload,
    ///     possibly repeatedly for the same code while it stays in frame.
    public init(
        symbologies: [VNBarcodeSymbology] = [.qr],
        recognizesMultipleItems: Bool = false,
        onScan: @escaping (String) -> Void
    ) {
        self.recognizedDataTypes = [.barcode(symbologies: symbologies)]
        self.recognizesMultipleItems = recognizesMultipleItems
        self.onScan = onScan
    }

    public func makeUIViewController(context: Context) -> DataScannerViewController {
        let controller = DataScannerViewController(
            recognizedDataTypes: recognizedDataTypes,
            qualityLevel: .balanced,
            recognizesMultipleItems: recognizesMultipleItems,
            isHighFrameRateTrackingEnabled: false,
            isPinchToZoomEnabled: true,
            isGuidanceEnabled: true,
            isHighlightingEnabled: true
        )
        controller.delegate = context.coordinator
        return controller
    }

    public func updateUIViewController(_ controller: DataScannerViewController, context: Context) {
        context.coordinator.onScan = onScan
        guard Self.isAvailable, !controller.isScanning else { return }
        try? controller.startScanning()
    }

    public static func dismantleUIViewController(
        _ controller: DataScannerViewController,
        coordinator: Coordinator
    ) {
        controller.stopScanning()
        controller.delegate = nil
    }

    public func makeCoordinator() -> Coordinator { Coordinator(onScan: onScan) }

    @MainActor
    public final class Coordinator: NSObject, DataScannerViewControllerDelegate {

        var onScan: (String) -> Void
        /// The same code stays in frame across many callbacks; reporting it once
        /// per appearance keeps callers from having to debounce.
        private var lastReported: String?

        init(onScan: @escaping (String) -> Void) {
            self.onScan = onScan
        }

        public func dataScanner(
            _ scanner: DataScannerViewController,
            didAdd addedItems: [RecognizedItem],
            allItems: [RecognizedItem]
        ) {
            report(addedItems)
        }

        public func dataScanner(
            _ scanner: DataScannerViewController,
            didUpdate updatedItems: [RecognizedItem],
            allItems: [RecognizedItem]
        ) {
            report(updatedItems)
        }

        public func dataScanner(
            _ scanner: DataScannerViewController,
            didRemove removedItems: [RecognizedItem],
            allItems: [RecognizedItem]
        ) {
            if allItems.isEmpty { lastReported = nil }
        }

        private func report(_ items: [RecognizedItem]) {
            for case .barcode(let barcode) in items {
                guard let payload = barcode.payloadStringValue, payload != lastReported else { continue }
                lastReported = payload
                onScan(payload)
            }
        }
    }
}
#endif
