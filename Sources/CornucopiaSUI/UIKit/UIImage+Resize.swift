//
//  File.swift
//  
//
//  Created by Dr. Michael Lauer on 26.03.24.
//
#if canImport(UIKit)
import UIKit

extension UIImage {

    public func CC_resized(height newHeight: CGFloat) -> UIImage {

        let scale = newHeight / self.size.height
        let newWidth = self.size.width * scale
        UIGraphicsBeginImageContextWithOptions(CGSize(width: newWidth, height: newHeight), false, 0.0)
        self.draw(in: CGRect(x:0, y:0, width: newWidth, height: newHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }
}

#endif
