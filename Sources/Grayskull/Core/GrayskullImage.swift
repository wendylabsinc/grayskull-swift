import CGrayskull

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// A grayscale image representation with automatic memory management.
///
/// `GrayskullImage` provides a Swift-friendly wrapper around the C `gs_image` structure,
/// offering ergonomic Swift APIs for computer vision operations. It handles memory allocation
/// and deallocation automatically through ARC, and provides thread-safe access to pixel data.
///
/// ## Overview
///
/// Images can be created from dimensions, raw pixel data, or platform-native image types
/// (CGImage, UIImage, NSImage). All operations return new images following value semantics,
/// making the API safe for concurrent use.
///
/// ## Topics
///
/// ### Creating Images
///
/// - ``init(width:height:)``
/// - ``init(width:height:data:)``
/// - ``init(contentsOfPGM:)``
/// - ``init(cgImage:)``
/// - ``init(uiImage:)``
/// - ``init(nsImage:)``
///
/// ### Image Properties
///
/// - ``width``
/// - ``height``
/// - ``isValid``
///
/// ### Pixel Access
///
/// - ``subscript(_:_:)``
/// - ``withPixelData(_:)``
///
/// ### Image Processing
///
/// - ``thresholded(_:)``
/// - ``adaptiveThreshold(radius:constant:)``
/// - ``otsuThreshold()``
/// - ``filtered(kernel:normalization:)``
/// - ``blurred(radius:)``
/// - ``sobel()``
/// - ``eroded()``
/// - ``dilated()``
///
/// ### Geometric Transformations
///
/// - ``copy()``
/// - ``cropped(to:)``
/// - ``resized(width:height:)``
/// - ``resizedNearest(width:height:)``
/// - ``downsampled()``
/// - ``perspectiveCorrected(corners:width:height:)``
///
/// ### Feature Detection
///
/// - ``detectFAST(maxKeypoints:threshold:)``
/// - ``extractORB(maxKeypoints:threshold:)``
/// - ``findBlobs(maxBlobs:)``
/// - ``traceContour(startPoint:)``
/// - ``blobCorners(for:labels:)``
///
/// ### Template Matching
///
/// - ``matchTemplate(_:)``
/// - ``findBestMatch()``
///
/// ### Advanced Operations
///
/// - ``histogram()``
/// - ``integralImage()``
///
/// - Note: This type is thread-safe and conforms to `Sendable`.
///
/// - SeeAlso: ``Rectangle``, ``Point``, ``Blob``, ``Keypoint``
public struct GrayskullImage: Sendable {
    let storage: ImageStorage

    /// The width of the image in pixels.
    public var width: UInt32 { storage.width }

    /// The height of the image in pixels.
    public var height: UInt32 { storage.height }

    /// Check if the image is valid (has data and non-zero dimensions).
    public var isValid: Bool { storage.isValid }

    /// Creates an image with the specified dimensions.
    ///
    /// - Parameters:
    ///   - width: The width of the image in pixels.
    ///   - height: The height of the image in pixels.
    public init(width: UInt32, height: UInt32) {
        self.storage = ImageStorage(width: width, height: height)
    }

    /// Creates an image from raw pixel data.
    ///
    /// - Parameters:
    ///   - width: The width of the image in pixels.
    ///   - height: The height of the image in pixels.
    ///   - data: The pixel data as an array of bytes (0-255).
    /// - Throws: `GrayskullError.invalidDimensions` if data size doesn't match width × height.
    public init(width: UInt32, height: UInt32, data: [UInt8]) throws {
        guard data.count == Int(width * height) else {
            throw GrayskullError.invalidDimensions
        }
        let storage = ImageStorage(width: width, height: height)
        storage.withUnsafeImage { img in
            data.withUnsafeBytes { buffer in
                let ptr = buffer.baseAddress!.assumingMemoryBound(to: UInt8.self)
                img.data.update(from: ptr, count: data.count)
            }
        }
        self.storage = storage
    }

    #if !os(WASI) && !os(Windows)
    /// Reads a PGM (Portable GrayMap) image from a file.
    ///
    /// - Parameter path: The path to the PGM file.
    /// - Throws: `GrayskullError.fileReadError` if the file cannot be read.
    public init(contentsOfPGM path: String) throws {
        let img = gs_read_pgm(path)
        guard gs_valid(img) != 0 else {
            throw GrayskullError.fileReadError
        }
        self.storage = ImageStorage(takingOwnership: img)
    }

    /// Writes the image to a PGM file.
    ///
    /// - Parameter path: The path where the PGM file should be written.
    /// - Throws: `GrayskullError.fileWriteError` if the file cannot be written.
    public func write(toPGM path: String) throws {
        let result = storage.withUnsafeImage { img in
            gs_write_pgm(img, path)
        }
        guard result == 0 else {
            throw GrayskullError.fileWriteError
        }
    }
    #endif

    /// Gets the pixel value at the specified coordinates.
    ///
    /// - Parameters:
    ///   - x: The x-coordinate (column).
    ///   - y: The y-coordinate (row).
    /// - Returns: The pixel value (0-255), or 0 if coordinates are out of bounds.
    public subscript(x: UInt32, y: UInt32) -> UInt8 {
        get {
            storage.withUnsafeImage { img in
                gs_get(img, x, y)
            }
        }
        set {
            storage.withUnsafeImage { img in
                gs_set(img, x, y, newValue)
            }
        }
    }

    /// Provides access to the raw pixel data.
    ///
    /// - Parameter body: A closure that receives the pixel data as an array.
    /// - Returns: The result of the closure.
    public func withPixelData<T>(_ body: ([UInt8]) throws -> T) rethrows -> T {
        try storage.withPixelData(body)
    }

    /// Performs an operation on the underlying C image structure.
    ///
    /// - Parameter body: A closure that receives the C image structure.
    /// - Returns: The result of the closure.
    internal func withUnsafeImage<T>(_ body: (gs_image) throws -> T) rethrows -> T {
        try storage.withUnsafeImage(body)
    }
}
