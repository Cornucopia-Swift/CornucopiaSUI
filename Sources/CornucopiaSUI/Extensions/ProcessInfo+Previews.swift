//
//  Cornucopia – (C) Dr. Lauer Information Technology
//
import Foundation

fileprivate let XcodeRunningForPreviews: Bool = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"

public extension ProcessInfo {

    /// True, if the process is running under the Xcode preview environment.
    @inline(__always) static var CC_isRunningInPreview: Bool { XcodeRunningForPreviews }

}
