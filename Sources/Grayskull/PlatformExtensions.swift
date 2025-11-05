/// Platform-specific extensions for seamless integration with Apple frameworks.
///
/// This file provides bidirectional conversion between ``GrayskullImage`` and platform-native
/// image types including CoreGraphics, UIKit, AppKit, and SwiftUI.
///
/// ## Supported Platforms
///
/// - **CoreGraphics**: All Apple platforms (macOS, iOS, tvOS, watchOS, visionOS)
/// - **UIKit**: iOS, tvOS (not watchOS)
/// - **AppKit**: macOS (not Catalyst)
/// - **SwiftUI**: All platforms with SwiftUI support
///
/// ## Topics
///
/// ### CoreGraphics
///
/// - ``GrayskullImage/init(cgImage:)``
/// - ``GrayskullImage/toCGImage()``
/// - ``CoreGraphics/CGImage/toGrayskullImage()``
/// - ``CoreGraphics/CGImage/applyGrayskull(_:)``
///
/// ### UIKit
///
/// - ``GrayskullImage/init(uiImage:)``
/// - ``GrayskullImage/toUIImage()``
/// - ``UIKit/UIImage/toGrayskullImage()``
///
/// ### AppKit
///
/// - ``GrayskullImage/init(nsImage:)``
/// - ``GrayskullImage/toNSImage()``
/// - ``AppKit/NSImage/toGrayskullImage()``
///
/// ### SwiftUI
///
/// - ``SwiftUI/Image/init(grayskullImage:)``

import CGrayskull

// MARK: - CoreGraphics Extensions

#if canImport(CoreGraphics)
import CoreGraphics

extension GrayskullImage {
    /// Creates a Grayskull image from a CGImage by converting to grayscale.
    ///
    /// - Parameter cgImage: The source CGImage to convert
    /// - Throws: `GrayskullError.invalidImage` if conversion fails
    public init(cgImage: CGImage) throws {
        let width = cgImage.width
        let height = cgImage.height

        // Create a grayscale context
        let colorSpace = CGColorSpaceCreateDeviceGray()
        var grayscaleData = [UInt8](repeating: 0, count: width * height)

        guard let context = CGContext(
            data: &grayscaleData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else {
            throw GrayskullError.invalidImage
        }

        // Draw the image into grayscale context
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        // Create Grayskull image from grayscale data
        try self.init(width: UInt32(width), height: UInt32(height), data: grayscaleData)
    }

    /// Converts the Grayskull image to a CGImage.
    ///
    /// - Returns: A grayscale CGImage
    /// - Throws: `GrayskullError.invalidImage` if conversion fails
    public func toCGImage() throws -> CGImage {
        let colorSpace = CGColorSpaceCreateDeviceGray()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue)

        return try withPixelData { pixels in
            guard let provider = CGDataProvider(
                dataInfo: nil,
                data: pixels,
                size: Int(width * height),
                releaseData: { _, _, _ in }
            ), let cgImage = CGImage(
                width: Int(width),
                height: Int(height),
                bitsPerComponent: 8,
                bitsPerPixel: 8,
                bytesPerRow: Int(width),
                space: colorSpace,
                bitmapInfo: bitmapInfo,
                provider: provider,
                decode: nil,
                shouldInterpolate: false,
                intent: .defaultIntent
            ) else {
                throw GrayskullError.invalidImage
            }

            return cgImage
        }
    }
}
#endif

// MARK: - UIKit Extensions

#if canImport(UIKit) && !os(watchOS)
import UIKit

extension GrayskullImage {
    /// Creates a Grayskull image from a UIImage by converting to grayscale.
    ///
    /// - Parameter uiImage: The source UIImage to convert
    /// - Throws: `GrayskullError.invalidImage` if conversion fails or image has no CGImage
    public init(uiImage: UIImage) throws {
        guard let cgImage = uiImage.cgImage else {
            throw GrayskullError.invalidImage
        }
        try self.init(cgImage: cgImage)
    }

    /// Converts the Grayskull image to a UIImage.
    ///
    /// - Returns: A UIImage with grayscale content
    /// - Throws: `GrayskullError.invalidImage` if conversion fails
    public func toUIImage() throws -> UIImage {
        let cgImage = try toCGImage()
        return UIImage(cgImage: cgImage)
    }
}

extension UIImage {
    /// Converts this UIImage to a Grayskull image.
    ///
    /// - Returns: A GrayskullImage in grayscale
    /// - Throws: `GrayskullError.invalidImage` if conversion fails
    public func toGrayskullImage() throws -> GrayskullImage {
        try GrayskullImage(uiImage: self)
    }
}
#endif

// MARK: - AppKit Extensions

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit

extension GrayskullImage {
    /// Creates a Grayskull image from an NSImage by converting to grayscale.
    ///
    /// - Parameter nsImage: The source NSImage to convert
    /// - Throws: `GrayskullError.invalidImage` if conversion fails
    public init(nsImage: NSImage) throws {
        guard let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw GrayskullError.invalidImage
        }
        try self.init(cgImage: cgImage)
    }

    /// Converts the Grayskull image to an NSImage.
    ///
    /// - Returns: An NSImage with grayscale content
    /// - Throws: `GrayskullError.invalidImage` if conversion fails
    public func toNSImage() throws -> NSImage {
        let cgImage = try toCGImage()
        return NSImage(cgImage: cgImage, size: NSSize(width: CGFloat(width), height: CGFloat(height)))
    }
}

extension NSImage {
    /// Converts this NSImage to a Grayskull image.
    ///
    /// - Returns: A GrayskullImage in grayscale
    /// - Throws: `GrayskullError.invalidImage` if conversion fails
    public func toGrayskullImage() throws -> GrayskullImage {
        try GrayskullImage(nsImage: self)
    }
}
#endif

// MARK: - SwiftUI Integration

#if canImport(SwiftUI)
import SwiftUI

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension Image {
    /// Creates a SwiftUI Image from a GrayskullImage.
    ///
    /// - Parameter grayskullImage: The Grayskull image to display
    /// - Throws: `GrayskullError.invalidImage` if conversion fails
    public init(grayskullImage: GrayskullImage) throws {
        let cgImage = try grayskullImage.toCGImage()
        #if os(macOS)
        self.init(nsImage: NSImage(cgImage: cgImage, size: NSSize(width: CGFloat(grayskullImage.width), height: CGFloat(grayskullImage.height))))
        #else
        self.init(uiImage: UIImage(cgImage: cgImage))
        #endif
    }
}
#endif

// MARK: - Convenience CGImage Extensions

#if canImport(CoreGraphics)
extension CGImage {
    /// Converts this CGImage to a Grayskull image.
    ///
    /// - Returns: A GrayskullImage in grayscale
    /// - Throws: `GrayskullError.invalidImage` if conversion fails
    public func toGrayskullImage() throws -> GrayskullImage {
        try GrayskullImage(cgImage: self)
    }

    /// Applies a Grayskull processing operation to this CGImage.
    ///
    /// - Parameter operation: A closure that processes the GrayskullImage
    /// - Returns: A new CGImage with the operation applied
    /// - Throws: `GrayskullError.invalidImage` if conversion fails
    public func applyGrayskull(_ operation: (GrayskullImage) throws -> GrayskullImage) throws -> CGImage {
        let grayskullImage = try toGrayskullImage()
        let processed = try operation(grayskullImage)
        return try processed.toCGImage()
    }
}
#endif

// MARK: - Example Usage Documentation

/*

 # Platform Extensions Usage Examples

 ## UIKit (iOS/tvOS)

 ```swift
 import UIKit
 import Grayskull

 // From UIImage to Grayskull
 let uiImage = UIImage(named: "photo")!
 let grayskullImage = try GrayskullImage(uiImage: uiImage)

 // Or using extension
 let grayskullImage2 = try uiImage.toGrayskullImage()

 // Process and convert back
 let edges = grayskullImage.sobel()
 let resultImage = try edges.toUIImage()

 // One-liner processing
 let processed = try UIImage(named: "photo")!
     .toGrayskullImage()
     .sobel()
     .toUIImage()
 ```

 ## AppKit (macOS)

 ```swift
 import AppKit
 import Grayskull

 // From NSImage to Grayskull
 let nsImage = NSImage(named: "photo")!
 let grayskullImage = try GrayskullImage(nsImage: nsImage)

 // Or using extension
 let grayskullImage2 = try nsImage.toGrayskullImage()

 // Process and convert back
 let blurred = grayskullImage.blurred(radius: 5)
 let resultImage = try blurred.toNSImage()
 ```

 ## CoreGraphics (All Platforms)

 ```swift
 import CoreGraphics
 import Grayskull

 // From CGImage
 let cgImage: CGImage = ...
 let grayskullImage = try GrayskullImage(cgImage: cgImage)

 // Using extension
 let grayskullImage2 = try cgImage.toGrayskullImage()

 // Direct processing
 let processedCGImage = try cgImage.applyGrayskull { image in
     image.sobel().thresholded(128)
 }
 ```

 ## SwiftUI

 ```swift
 import SwiftUI
 import Grayskull

 struct ContentView: View {
     let grayskullImage: GrayskullImage

     var body: some View {
         // Convert GrayskullImage to SwiftUI Image
         try? Image(grayskullImage: grayskullImage)
             .resizable()
             .aspectRatio(contentMode: .fit)
     }
 }

 // Or in a processing pipeline
 struct ProcessedImageView: View {
     let originalImage: UIImage

     var body: some View {
         if let processed = try? originalImage
             .toGrayskullImage()
             .sobel(),
            let swiftUIImage = try? Image(grayskullImage: processed) {
             swiftUIImage
                 .resizable()
                 .aspectRatio(contentMode: .fit)
         }
     }
 }
 ```

 ## Advanced Processing Chains

 ```swift
 // UIKit
 let result = try UIImage(named: "document")!
     .toGrayskullImage()
     .adaptiveThreshold(radius: 15, constant: 10)
     .eroded()
     .dilated()
     .toUIImage()

 // AppKit
 let result = try NSImage(named: "scan")!
     .toGrayskullImage()
     .sobel()
     .thresholded(128)
     .toNSImage()

 // CGImage
 let result = try myCGImage
     .applyGrayskull { $0.blurred(radius: 3).sobel() }
 ```

 */
