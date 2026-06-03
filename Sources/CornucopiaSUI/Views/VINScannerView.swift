//
//  VINScannerView.swift
//  CornucopiaSUI
//

import SwiftUI

#if canImport(VisionKit) && os(iOS)
import VisionKit

@available(iOS 16.0, *)
@MainActor
struct VINScannerView: UIViewControllerRepresentable {

    let onRecognizedVIN: (String) -> Void

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let controller = DataScannerViewController(
            recognizedDataTypes: [.text()],
            qualityLevel: .balanced,
            recognizesMultipleItems: true,
            isHighFrameRateTrackingEnabled: false,
            isPinchToZoomEnabled: true,
            isGuidanceEnabled: false,
            isHighlightingEnabled: true
        )
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ controller: DataScannerViewController, context: Context) {
        context.coordinator.onRecognizedVIN = onRecognizedVIN

        guard DataScannerViewController.isSupported, DataScannerViewController.isAvailable else { return }
        guard !controller.isScanning else { return }
        try? controller.startScanning()
    }

    static func dismantleUIViewController(_ controller: DataScannerViewController, coordinator: Coordinator) {
        controller.stopScanning()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onRecognizedVIN: onRecognizedVIN)
    }

    final class Coordinator: NSObject, DataScannerViewControllerDelegate {

        var onRecognizedVIN: (String) -> Void
        private var lastRecognizedVIN: String?

        init(onRecognizedVIN: @escaping (String) -> Void) {
            self.onRecognizedVIN = onRecognizedVIN
        }

        func dataScanner(
            _ dataScanner: DataScannerViewController,
            didAdd addedItems: [RecognizedItem],
            allItems: [RecognizedItem]
        ) {
            scan(allItems)
        }

        func dataScanner(
            _ dataScanner: DataScannerViewController,
            didUpdate updatedItems: [RecognizedItem],
            allItems: [RecognizedItem]
        ) {
            scan(allItems)
        }

        private func scan(_ items: [RecognizedItem]) {
            for item in items {
                guard case let .text(text) = item else { continue }
                guard let vin = VINKeyboardInput.scannedVINCandidate(in: text.transcript) else { continue }
                guard vin != lastRecognizedVIN else { continue }
                lastRecognizedVIN = vin
                onRecognizedVIN(vin)
                return
            }
        }
    }
}
#endif

extension VINKeyboardInput {

    static var isVINCameraScanningSupported: Bool {
#if canImport(VisionKit) && os(iOS)
        if #available(iOS 16.0, *) {
            return DataScannerViewController.isSupported
        }
#endif
        return false
    }

    static func scannedVINCandidate(in transcript: String) -> String? {
        let characters = Array(transcript.uppercased())

        for startIndex in characters.indices {
            var candidate = ""
            var index = startIndex

            while index < characters.endIndex {
                let character = characters[index]

                if isValidVINCharacter(character) {
                    if candidate.count == 17 {
                        break
                    }
                    candidate.append(character)
                    if candidate.count == 17 {
                        let nextIndex = index + 1
                        guard nextIndex == characters.endIndex || !isValidVINCharacter(characters[nextIndex]) else {
                            break
                        }
                        return isCompleteScannedVIN(candidate) ? candidate : nil
                    }
                } else if isVINScanSeparator(character) {
                    if !canBridgeVINScanSeparator(after: candidate) {
                        break
                    }
                } else {
                    break
                }

                index += 1
            }
        }

        return nil
    }

    private static func isCompleteScannedVIN(_ candidate: String) -> Bool {
        guard hasKnownScannedWMI(candidate), hasEnoughScannedDigits(candidate) else {
            return false
        }

        return switch validateVIN(candidate) {
            case .valid, .validWithCheckDigitWarning:
                true
            case .empty, .incomplete, .invalidCharacters, .tooLong:
                false
        }
    }

    private static func hasKnownScannedWMI(_ candidate: String) -> Bool {
        guard candidate.count >= 3 else { return false }
        return VINIdentity.decoding(String(candidate.prefix(3)))?.manufacturer != nil
    }

    private static func hasEnoughScannedDigits(_ candidate: String) -> Bool {
        candidate.filter(\.isNumber).count >= 4
    }

    private static func isVINScanSeparator(_ character: Character) -> Bool {
        character.isWhitespace || character == "-" || character == "." || character == ":"
    }

    private static func canBridgeVINScanSeparator(after candidate: String) -> Bool {
        switch candidate.count {
            case 3, 6, 9, 11:
                true
            default:
                false
        }
    }
}
