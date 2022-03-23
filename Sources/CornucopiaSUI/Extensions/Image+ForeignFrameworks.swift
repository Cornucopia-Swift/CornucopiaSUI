//
//  Cornucopia – (C) Dr. Lauer Information Technology
//
import SwiftUI

#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit

extension Image {

    public static func CC_fromData(_ data: Data) -> Self {
        let uiImage = UIImage(data: data) ?? UIImage()
        return Image(uiImage: uiImage)
    }
}
#elseif os(macOS)
import AppKit

extension Image {

    public static func CC_fromData(_ data: Data) -> Self {
        let nsImage = NSImage(data: data) ?? NSImage()
        return Image(nsImage: uiImage)
    }
}
#endif
