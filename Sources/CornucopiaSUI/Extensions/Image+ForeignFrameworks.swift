//
//  Cornucopia – (C) Dr. Lauer Information Technology
//
import SwiftUI

#if canImport(UIKit)
import UIKit

extension Image {

    public static func CC_fromData(_ data: Data) -> Self {
        let uiImage = UIImage(data: data) ?? UIImage()
        return Image(uiImage: uiImage)
    }
}
#endif

#if canImport(AppKit)
import AppKit

extension Image {

    public static func CC_fromData(_ data: Data) -> Self {
        let nsImage = NSImage(data: data) ?? NSImage()
        return Image(nsImage: nsImage)
    }
}
#endif
