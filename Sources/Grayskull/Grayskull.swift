/// # Grayskull
///
/// A lightweight, ergonomic Swift wrapper for computer vision operations.
///
/// ## Overview
///
/// Grayskull provides a complete suite of image processing and computer vision algorithms optimized
/// for embedded systems, mobile devices, and high-performance applications. Built on a dependency-free
/// C library, it offers native Swift APIs with automatic memory management and full Swift 6.0 concurrency support.
///
/// ## Features
///
/// ### Image Processing
/// - Thresholding (binary, adaptive, Otsu's method)
/// - Morphological operations (erosion, dilation)
/// - Filtering and convolution
/// - Edge detection (Sobel)
/// - Histogram computation
///
/// ### Geometric Transformations
/// - Crop, resize, downsample
/// - Perspective correction
/// - Template matching
///
/// ### Feature Detection
/// - FAST corner detection
/// - ORB feature extraction
/// - Feature matching with Hamming distance
/// - Blob detection and analysis
/// - Contour tracing
///
/// ### Advanced Operations
/// - Integral images for O(1) region queries
/// - LBP cascade detection (Haar-like features)
/// - Multi-platform image conversion (CGImage, UIImage, NSImage)
///
/// ## Getting Started
///
/// ```swift
/// import Grayskull
///
/// // Create or load an image
/// let image = GrayskullImage(width: 640, height: 480)
///
/// // Apply image processing
/// let edges = image.sobel()
/// let binary = edges.thresholded(128)
///
/// // Detect features
/// let (labels, blobs) = binary.findBlobs(maxBlobs: 100)
/// let keypoints = image.detectFAST(maxKeypoints: 500, threshold: 20)
///
/// // Platform integration
/// #if canImport(UIKit)
/// let uiImage = UIImage(named: "photo")!
/// let processed = try uiImage.toGrayskullImage().sobel().toUIImage()
/// #endif
/// ```
///
/// ## Topics
///
/// ### Essentials
///
/// - ``GrayskullImage``
/// - ``Rectangle``
/// - ``Point``
/// - ``GrayskullError``
///
/// ### Computer Vision Types
///
/// - ``Blob``
/// - ``Contour``
/// - ``Keypoint``
/// - ``Match``
///
/// ### Advanced Structures
///
/// - ``IntegralImage``
/// - ``LBPCascade``
///
/// ## Platform Support
///
/// - macOS 13.0+
/// - iOS 16.0+
/// - tvOS 16.0+
/// - visionOS 1.0+
/// - Linux (any distribution with Swift support)
/// - WebAssembly (Swift WASM)
/// - Windows (Swift for Windows)
///
/// ## Performance
///
/// All operations execute at C-level performance with zero Swift overhead. The library is:
/// - Header-only C implementation
/// - Zero external dependencies
/// - SIMD-friendly algorithms
/// - Cache-coherent memory access patterns
/// - Thread-safe with platform-optimized locking
///
/// ## See Also
///
/// - [Grayskull C Library](https://github.com/zserge/grayskull)
/// - [API Coverage Documentation](API_COVERAGE.md)
/// - [Platform Extensions Guide](PlatformExtensions.swift)

import CGrayskull

// Use FoundationEssentials for smaller binaries when available
#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

#if !os(WASI)
#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#elseif canImport(Musl)
import Musl
#elseif os(Windows)
import WinSDK
#elseif canImport(ucrt)
import ucrt
#endif
#endif

// MARK: - Image

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
    private let storage: ImageStorage

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

// MARK: - Cross-Platform Mutex

#if !os(WASI)
/// A lightweight, cross-platform mutex for thread synchronization.
///
/// Uses the most efficient synchronization primitive available on each platform:
/// - Darwin (macOS/iOS/tvOS/watchOS/visionOS): `os_unfair_lock` for minimal overhead
/// - Linux/Windows: `pthread_mutex` for reliable cross-platform synchronization
///
/// This implementation avoids Objective-C dependencies (NSLock) for better performance
/// and compatibility with pure Swift environments.
private final class Mutex: @unchecked Sendable {
    #if canImport(Darwin)
    private var unfairLock = os_unfair_lock()

    func lock() {
        os_unfair_lock_lock(&unfairLock)
    }

    func unlock() {
        os_unfair_lock_unlock(&unfairLock)
    }
    #elseif os(Windows)
    private var criticalSection = CRITICAL_SECTION()

    init() {
        InitializeCriticalSection(&criticalSection)
    }

    deinit {
        DeleteCriticalSection(&criticalSection)
    }

    func lock() {
        EnterCriticalSection(&criticalSection)
    }

    func unlock() {
        LeaveCriticalSection(&criticalSection)
    }
    #else
    // pthread_mutex for Linux and other POSIX systems
    private var mutex = pthread_mutex_t()

    init() {
        pthread_mutex_init(&mutex, nil)
    }

    deinit {
        pthread_mutex_destroy(&mutex)
    }

    func lock() {
        pthread_mutex_lock(&mutex)
    }

    func unlock() {
        pthread_mutex_unlock(&mutex)
    }
    #endif
}
#endif

// MARK: - Image Storage

private final class ImageStorage: @unchecked Sendable {
    private var image: gs_image

    #if !os(WASI)
    private let mutex = Mutex()
    #endif

    var width: UInt32 { UInt32(image.w) }
    var height: UInt32 { UInt32(image.h) }
    var isValid: Bool { gs_valid(image) != 0 }

    init(width: UInt32, height: UInt32) {
        #if os(WASI) || GS_NO_STDLIB
        // Allocate manually for embedded/WASM environments
        let data = UnsafeMutablePointer<UInt8>.allocate(capacity: Int(width * height))
        data.initialize(repeating: 0, count: Int(width * height))
        self.image = gs_image(w: width, h: height, data: data)
        #else
        self.image = gs_alloc(width, height)
        #endif
    }

    init(takingOwnership image: gs_image) {
        self.image = image
    }

    deinit {
        #if os(WASI) || GS_NO_STDLIB
        image.data.deallocate()
        #else
        gs_free(image)
        #endif
    }

    func withUnsafeImage<T>(_ body: (gs_image) throws -> T) rethrows -> T {
        #if !os(WASI)
        mutex.lock()
        defer { mutex.unlock() }
        #endif
        return try body(image)
    }

    func withPixelData<T>(_ body: ([UInt8]) throws -> T) rethrows -> T {
        try withUnsafeImage { img in
            let buffer = UnsafeBufferPointer(start: img.data, count: Int(img.w * img.h))
            return try body(Array(buffer))
        }
    }
}

// MARK: - Geometric Types

/// A rectangle in image coordinates.
///
/// Represents a rectangular region defined by its top-left corner position and dimensions.
/// Commonly used for:
/// - Cropping operations
/// - Bounding boxes for detected objects (blobs, faces, etc.)
/// - Region-of-interest selection
/// - Template matching results
///
/// ## Example
///
/// ```swift
/// let roi = Rectangle(x: 10, y: 10, width: 100, height: 100)
/// let cropped = try image.cropped(to: roi)
/// ```
///
/// - Note: All coordinates use `UInt32` to match image dimensions.
///
/// - SeeAlso: ``GrayskullImage/cropped(to:)``, ``Blob/boundingBox``, ``Contour/boundingBox``
public struct Rectangle: Sendable, Equatable {
    /// The x-coordinate of the rectangle's top-left corner.
    public var x: UInt32

    /// The y-coordinate of the rectangle's top-left corner.
    public var y: UInt32

    /// The width of the rectangle in pixels.
    public var width: UInt32

    /// The height of the rectangle in pixels.
    public var height: UInt32

    /// Creates a rectangle with the specified position and dimensions.
    ///
    /// - Parameters:
    ///   - x: The x-coordinate of the top-left corner
    ///   - y: The y-coordinate of the top-left corner
    ///   - width: The width in pixels
    ///   - height: The height in pixels
    public init(x: UInt32, y: UInt32, width: UInt32, height: UInt32) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }

    internal init(_ rect: gs_rect) {
        self.x = rect.x
        self.y = rect.y
        self.width = rect.w
        self.height = rect.h
    }

    internal var cValue: gs_rect {
        gs_rect(x: x, y: y, w: width, h: height)
    }
}

/// A point in image coordinates.
///
/// Represents a 2D position in an image using unsigned integer coordinates.
/// Used throughout the API for:
/// - Pixel access via subscripts
/// - Keypoint locations
/// - Blob centroids
/// - Corner detection results
/// - Contour starting points
///
/// ## Example
///
/// ```swift
/// let point = Point(x: 50, y: 100)
/// let pixelValue = image[point.x, point.y]
/// ```
///
/// - Note: Coordinates use `UInt32` to match image dimensions and prevent negative values.
///
/// - SeeAlso: ``Rectangle``, ``Keypoint/point``, ``Blob/centroid``
public struct Point: Sendable, Equatable {
    /// The x-coordinate (horizontal position).
    public var x: UInt32

    /// The y-coordinate (vertical position).
    public var y: UInt32

    /// Creates a point with the specified coordinates.
    ///
    /// - Parameters:
    ///   - x: The x-coordinate (column)
    ///   - y: The y-coordinate (row)
    public init(x: UInt32, y: UInt32) {
        self.x = x
        self.y = y
    }

    internal init(_ point: gs_point) {
        self.x = point.x
        self.y = point.y
    }

    internal var cValue: gs_point {
        gs_point(x: x, y: y)
    }
}

// MARK: - Computer Vision Types

/// A labeled blob (connected component) in a binary image.
///
/// Represents a region of connected foreground pixels discovered by blob detection.
/// Each blob contains:
/// - A unique label identifier
/// - The total area (number of pixels)
/// - A bounding box enclosing the blob
/// - The centroid (center of mass)
///
/// ## Usage
///
/// Blobs are typically obtained from ``GrayskullImage/findBlobs(maxBlobs:)``:
///
/// ```swift
/// let binary = image.thresholded(128)
/// let (labels, blobs) = binary.findBlobs(maxBlobs: 100)
///
/// for blob in blobs {
///     print("Blob \(blob.label): area=\(blob.area), center=(\(blob.centroid.x), \(blob.centroid.y))")
///
///     // Get the 4 corner points
///     let corners = binary.blobCorners(for: blob, labels: labels)
/// }
/// ```
///
/// - Note: Blob detection works on binary images where pixels > 128 are considered foreground.
///
/// - SeeAlso: ``GrayskullImage/findBlobs(maxBlobs:)``, ``GrayskullImage/blobCorners(for:labels:)``
public struct Blob: Sendable {
    /// Unique identifier for this blob (1-based).
    public let label: UInt16

    /// Total number of pixels in the blob.
    public let area: UInt32

    /// Smallest rectangle that contains all blob pixels.
    public let boundingBox: Rectangle

    /// Center of mass of the blob.
    public let centroid: Point

    internal init(_ blob: gs_blob) {
        self.label = blob.label
        self.area = blob.area
        self.boundingBox = Rectangle(blob.box)
        self.centroid = Point(blob.centroid)
    }
}

/// A contour traced in a binary image.
///
/// Represents a closed or open boundary of a shape, traced using a boundary-following algorithm.
/// Contains information about:
/// - The bounding box enclosing the contour
/// - The starting point where tracing began
/// - The total length (number of boundary pixels)
///
/// ## Usage
///
/// Contours are obtained by tracing from a starting point on a shape boundary:
///
/// ```swift
/// let binary = image.thresholded(128)
/// let contour = try binary.traceContour(startPoint: Point(x: 10, y: 10))
///
/// print("Contour length: \(contour.length)")
/// print("Bounding box: \(contour.boundingBox)")
/// ```
///
/// - Note: The image should be binary (thresholded) with foreground pixels > 128.
///
/// - SeeAlso: ``GrayskullImage/traceContour(startPoint:)``
public struct Contour: Sendable {
    /// Smallest rectangle that contains all contour pixels.
    public let boundingBox: Rectangle

    /// Starting point where the contour trace began.
    public let start: Point

    /// Total number of pixels in the contour boundary.
    public let length: UInt32

    internal init(_ contour: gs_contour) {
        self.boundingBox = Rectangle(contour.box)
        self.start = Point(contour.start)
        self.length = contour.length
    }
}

/// A keypoint detected by FAST or ORB feature detection.
///
/// Keypoints represent distinctive image locations suitable for:
/// - Feature matching across images
/// - Object tracking
/// - Image registration and alignment
/// - SLAM (Simultaneous Localization and Mapping)
///
/// ## Overview
///
/// FAST keypoints contain only position and response (corner strength).
/// ORB keypoints additionally include orientation angle and BRIEF descriptors
/// for robust matching.
///
/// ## Example
///
/// ```swift
/// // Detect FAST corners
/// let keypoints = image.detectFAST(maxKeypoints: 500, threshold: 20)
///
/// // Extract ORB features with descriptors
/// let orbFeatures = image.extractORB(maxKeypoints: 500, threshold: 20)
///
/// // Match features between two images
/// let matches = GrayskullImage.matchORB(
///     keypoints1: features1,
///     keypoints2: features2,
///     maxMatches: 100,
///     maxDistance: 64
/// )
/// ```
///
/// - Note: ORB descriptors are 256-bit BRIEF descriptors stored as 8 × 32-bit words.
///
/// - SeeAlso: ``GrayskullImage/detectFAST(maxKeypoints:threshold:)``, ``GrayskullImage/extractORB(maxKeypoints:threshold:)``, ``Match``
public struct Keypoint: Sendable {
    /// Location of the keypoint in image coordinates.
    public let point: Point

    /// Corner response strength (higher = more distinctive).
    public let response: UInt32

    /// Orientation angle in radians (ORB only, 0 for FAST).
    public let angle: Float

    /// 256-bit BRIEF descriptor as 8 × 32-bit words (ORB only, empty for FAST).
    public let descriptor: [UInt32]

    internal init(_ kp: gs_keypoint) {
        self.point = Point(kp.pt)
        self.response = kp.response
        self.angle = kp.angle
        self.descriptor = [
            kp.descriptor.0, kp.descriptor.1, kp.descriptor.2, kp.descriptor.3,
            kp.descriptor.4, kp.descriptor.5, kp.descriptor.6, kp.descriptor.7
        ]
    }
}

/// A match between two keypoints from different images.
///
/// Represents a correspondence between features detected in two images.
/// The match quality is measured by Hamming distance between descriptors
/// (lower distance = better match).
///
/// ## Usage
///
/// Matches are obtained from ``GrayskullImage/matchORB(keypoints1:keypoints2:maxMatches:maxDistance:)``:
///
/// ```swift
/// let features1 = image1.extractORB(maxKeypoints: 500, threshold: 20)
/// let features2 = image2.extractORB(maxKeypoints: 500, threshold: 20)
///
/// let matches = GrayskullImage.matchORB(
///     keypoints1: features1,
///     keypoints2: features2,
///     maxMatches: 100,
///     maxDistance: 64
/// )
///
/// for match in matches {
///     let kp1 = features1[Int(match.index1)]
///     let kp2 = features2[Int(match.index2)]
///     print("Match: (\(kp1.point.x), \(kp1.point.y)) <-> (\(kp2.point.x), \(kp2.point.y)), distance: \(match.distance)")
/// }
/// ```
///
/// - Note: Lower Hamming distance indicates better match quality. Typical threshold: 64 bits.
///
/// - SeeAlso: ``Keypoint``, ``GrayskullImage/matchORB(keypoints1:keypoints2:maxMatches:maxDistance:)``
public struct Match: Sendable {
    /// Index of the keypoint in the first image's feature list.
    public let index1: UInt32

    /// Index of the matched keypoint in the second image's feature list.
    public let index2: UInt32

    /// Hamming distance between descriptors (lower = better match).
    public let distance: UInt32

    internal init(_ match: gs_match) {
        self.index1 = match.idx1
        self.index2 = match.idx2
        self.distance = match.distance
    }
}

// MARK: - Errors

/// Errors that can occur during Grayskull operations.
///
/// These errors cover various failure modes including:
/// - Invalid image dimensions or parameters
/// - File I/O failures
/// - Image conversion errors
/// - Memory allocation issues
///
/// ## Example
///
/// ```swift
/// do {
///     let cropped = try image.cropped(to: Rectangle(x: 0, y: 0, width: 100, height: 100))
/// } catch GrayskullError.invalidDimensions {
///     print("Crop region is out of bounds")
/// } catch {
///     print("Unexpected error: \(error)")
/// }
/// ```
///
/// - SeeAlso: ``GrayskullImage``
public enum GrayskullError: Error, Sendable {
    /// The provided dimensions or parameters are invalid or out of bounds.
    ///
    /// Common causes:
    /// - Crop region extends beyond image bounds
    /// - Data size doesn't match width × height
    /// - Invalid number of corner points for perspective correction
    case invalidDimensions

    /// Failed to read image file from disk.
    ///
    /// Occurs when:
    /// - File doesn't exist
    /// - Insufficient permissions
    /// - Invalid PGM file format
    case fileReadError

    /// Failed to write image file to disk.
    ///
    /// Occurs when:
    /// - Insufficient disk space
    /// - Invalid file path
    /// - Insufficient permissions
    case fileWriteError

    /// Image data is invalid or corrupted.
    ///
    /// Occurs during:
    /// - CGImage/UIImage/NSImage conversion failures
    /// - Invalid pixel buffer data
    case invalidImage

    /// Insufficient space for the requested operation.
    ///
    /// Occurs when:
    /// - Maximum capacity exceeded (e.g., too many blobs, keypoints)
    /// - Output buffer too small
    case insufficientSpace
}

// MARK: - Image Processing Operations

extension GrayskullImage {
    /// Crops a region from the source image.
    ///
    /// - Parameter roi: The region of interest to crop.
    /// - Returns: A new image containing the cropped region.
    /// - Throws: `GrayskullError.invalidDimensions` if ROI is out of bounds.
    public func cropped(to roi: Rectangle) throws -> GrayskullImage {
        guard roi.x + roi.width <= width && roi.y + roi.height <= height else {
            throw GrayskullError.invalidDimensions
        }

        let result = GrayskullImage(width: roi.width, height: roi.height)
        result.storage.withUnsafeImage { dst in
            self.storage.withUnsafeImage { src in
                gs_crop(dst, src, roi.cValue)
            }
        }
        return result
    }

    /// Creates a copy of the image.
    public func copy() -> GrayskullImage {
        let result = GrayskullImage(width: width, height: height)
        result.storage.withUnsafeImage { dst in
            self.storage.withUnsafeImage { src in
                gs_copy(dst, src)
            }
        }
        return result
    }

    /// Resizes the image using bilinear interpolation.
    ///
    /// - Parameters:
    ///   - width: The target width.
    ///   - height: The target height.
    /// - Returns: A new resized image.
    public func resized(width: UInt32, height: UInt32) -> GrayskullImage {
        let result = GrayskullImage(width: width, height: height)
        result.storage.withUnsafeImage { dst in
            self.storage.withUnsafeImage { src in
                gs_resize(dst, src)
            }
        }
        return result
    }

    /// Resizes the image using nearest-neighbor interpolation.
    ///
    /// - Parameters:
    ///   - width: The target width.
    ///   - height: The target height.
    /// - Returns: A new resized image.
    public func resizedNearest(width: UInt32, height: UInt32) -> GrayskullImage {
        let result = GrayskullImage(width: width, height: height)
        result.storage.withUnsafeImage { dst in
            self.storage.withUnsafeImage { src in
                gs_resize_nn(dst, src)
            }
        }
        return result
    }

    /// Downsamples the image by a factor of 2.
    ///
    /// - Returns: A new image with half the width and height.
    /// - Throws: `GrayskullError.invalidDimensions` if dimensions are not even.
    public func downsampled() throws -> GrayskullImage {
        guard width >= 2 && height >= 2 && width % 2 == 0 && height % 2 == 0 else {
            throw GrayskullError.invalidDimensions
        }

        let result = GrayskullImage(width: width / 2, height: height / 2)
        result.storage.withUnsafeImage { dst in
            self.storage.withUnsafeImage { src in
                gs_downsample(dst, src)
            }
        }
        return result
    }

    /// Computes the histogram of the image.
    ///
    /// - Returns: An array of 256 values representing the histogram.
    public func histogram() -> [UInt32] {
        var hist: [UInt32] = Array(repeating: 0, count: 256)
        storage.withUnsafeImage { img in
            hist.withUnsafeMutableBufferPointer { buffer in
                gs_histogram(img, buffer.baseAddress!)
            }
        }
        return hist
    }

    /// Computes the Otsu threshold for the image.
    ///
    /// - Returns: The optimal threshold value (0-255).
    public func otsuThreshold() -> UInt8 {
        storage.withUnsafeImage { img in
            gs_otsu_threshold(img)
        }
    }

    /// Applies a threshold to the image in-place.
    ///
    /// - Parameter threshold: The threshold value (0-255).
    public mutating func threshold(_ value: UInt8) {
        storage.withUnsafeImage { img in
            gs_threshold(img, value)
        }
    }

    /// Returns a thresholded copy of the image.
    ///
    /// - Parameter threshold: The threshold value (0-255).
    /// - Returns: A new binary image.
    public func thresholded(_ value: UInt8) -> GrayskullImage {
        let result = self.copy()
        result.storage.withUnsafeImage { img in
            gs_threshold(img, value)
        }
        return result
    }

    /// Applies adaptive thresholding.
    ///
    /// - Parameters:
    ///   - radius: The radius of the neighborhood.
    ///   - constant: A constant subtracted from the mean.
    /// - Returns: A new binary image.
    public func adaptiveThreshold(radius: UInt32, constant: Int32) -> GrayskullImage {
        let result = GrayskullImage(width: width, height: height)
        result.storage.withUnsafeImage { dst in
            self.storage.withUnsafeImage { src in
                gs_adaptive_threshold(dst, src, radius, constant)
            }
        }
        return result
    }

    /// Applies a convolution filter to the image.
    ///
    /// - Parameters:
    ///   - kernel: The convolution kernel image.
    ///   - normalization: The normalization factor.
    /// - Returns: A new filtered image.
    public func filtered(kernel: GrayskullImage, normalization: UInt32) -> GrayskullImage {
        let result = GrayskullImage(width: width, height: height)
        result.storage.withUnsafeImage { dst in
            self.storage.withUnsafeImage { src in
                kernel.storage.withUnsafeImage { kern in
                    gs_filter(dst, src, kern, normalization)
                }
            }
        }
        return result
    }

    /// Applies a box blur to the image.
    ///
    /// - Parameter radius: The blur radius.
    /// - Returns: A new blurred image.
    public func blurred(radius: UInt32) -> GrayskullImage {
        let result = GrayskullImage(width: width, height: height)
        result.storage.withUnsafeImage { dst in
            self.storage.withUnsafeImage { src in
                gs_blur(dst, src, radius)
            }
        }
        return result
    }

    /// Applies morphological erosion.
    ///
    /// - Returns: A new eroded image.
    public func eroded() -> GrayskullImage {
        let result = GrayskullImage(width: width, height: height)
        result.storage.withUnsafeImage { dst in
            self.storage.withUnsafeImage { src in
                gs_erode(dst, src)
            }
        }
        return result
    }

    /// Applies morphological dilation.
    ///
    /// - Returns: A new dilated image.
    public func dilated() -> GrayskullImage {
        let result = GrayskullImage(width: width, height: height)
        result.storage.withUnsafeImage { dst in
            self.storage.withUnsafeImage { src in
                gs_dilate(dst, src)
            }
        }
        return result
    }

    /// Computes the Sobel edge detection.
    ///
    /// - Returns: A new image with detected edges.
    public func sobel() -> GrayskullImage {
        let result = GrayskullImage(width: width, height: height)
        result.storage.withUnsafeImage { dst in
            self.storage.withUnsafeImage { src in
                gs_sobel(dst, src)
            }
        }
        return result
    }
}

// MARK: - Connected Components

extension GrayskullImage {
    /// Finds connected components (blobs) in a binary image.
    ///
    /// - Parameter maxBlobs: The maximum number of blobs to find.
    /// - Returns: A tuple containing the label map and array of found blobs.
    public func findBlobs(maxBlobs: Int = 1000) -> (labels: [UInt16], blobs: [Blob]) {
        var labels = [UInt16](repeating: 0, count: Int(width * height))
        var cBlobs = [gs_blob](repeating: gs_blob(), count: maxBlobs)

        let count = storage.withUnsafeImage { img in
            labels.withUnsafeMutableBufferPointer { labelsPtr in
                cBlobs.withUnsafeMutableBufferPointer { blobsPtr in
                    gs_blobs(img, labelsPtr.baseAddress!, blobsPtr.baseAddress!, UInt32(maxBlobs))
                }
            }
        }

        let blobs = (0..<Int(count)).map { Blob(cBlobs[$0]) }
        return (labels, blobs)
    }
}

// MARK: - Feature Detection

extension GrayskullImage {
    /// Detects FAST keypoints in the image.
    ///
    /// - Parameters:
    ///   - maxKeypoints: The maximum number of keypoints to detect.
    ///   - threshold: The FAST threshold (default: 20).
    /// - Returns: An array of detected keypoints.
    public func detectFAST(maxKeypoints: Int = 500, threshold: UInt32 = 20) -> [Keypoint] {
        let scoremap = GrayskullImage(width: width, height: height)
        var cKeypoints = [gs_keypoint](repeating: gs_keypoint(), count: maxKeypoints)

        let count = scoremap.storage.withUnsafeImage { scoreImg in
            storage.withUnsafeImage { img in
                cKeypoints.withUnsafeMutableBufferPointer { kpsPtr in
                    gs_fast(img, scoreImg, kpsPtr.baseAddress!, UInt32(maxKeypoints), threshold)
                }
            }
        }

        return (0..<Int(count)).map { Keypoint(cKeypoints[$0]) }
    }

    /// Extracts ORB (Oriented FAST and Rotated BRIEF) features.
    ///
    /// - Parameters:
    ///   - maxKeypoints: The maximum number of keypoints to extract.
    ///   - threshold: The FAST threshold (default: 20).
    /// - Returns: An array of ORB keypoints with descriptors.
    public func extractORB(maxKeypoints: Int = 500, threshold: UInt32 = 20) -> [Keypoint] {
        var scoremapBuffer = [UInt8](repeating: 0, count: Int(width * height))
        var cKeypoints = [gs_keypoint](repeating: gs_keypoint(), count: maxKeypoints)

        let count = storage.withUnsafeImage { img in
            scoremapBuffer.withUnsafeMutableBufferPointer { scorePtr in
                cKeypoints.withUnsafeMutableBufferPointer { kpsPtr in
                    gs_orb_extract(img, kpsPtr.baseAddress!, UInt32(maxKeypoints),
                                   threshold, scorePtr.baseAddress!)
                }
            }
        }

        return (0..<Int(count)).map { Keypoint(cKeypoints[$0]) }
    }

    /// Matches ORB keypoints between two sets.
    ///
    /// - Parameters:
    ///   - keypoints1: The first set of keypoints.
    ///   - keypoints2: The second set of keypoints.
    ///   - maxMatches: The maximum number of matches to find.
    ///   - maxDistance: The maximum Hamming distance for a match (default: 64).
    /// - Returns: An array of matches.
    public static func matchORB(
        keypoints1: [Keypoint],
        keypoints2: [Keypoint],
        maxMatches: Int = 100,
        maxDistance: Float = 64.0
    ) -> [Match] {
        var cKps1 = keypoints1.map { kp -> gs_keypoint in
            var gskp = gs_keypoint()
            gskp.pt = kp.point.cValue
            gskp.response = kp.response
            gskp.angle = kp.angle
            gskp.descriptor = (
                kp.descriptor[0], kp.descriptor[1], kp.descriptor[2], kp.descriptor[3],
                kp.descriptor[4], kp.descriptor[5], kp.descriptor[6], kp.descriptor[7]
            )
            return gskp
        }

        var cKps2 = keypoints2.map { kp -> gs_keypoint in
            var gskp = gs_keypoint()
            gskp.pt = kp.point.cValue
            gskp.response = kp.response
            gskp.angle = kp.angle
            gskp.descriptor = (
                kp.descriptor[0], kp.descriptor[1], kp.descriptor[2], kp.descriptor[3],
                kp.descriptor[4], kp.descriptor[5], kp.descriptor[6], kp.descriptor[7]
            )
            return gskp
        }

        var cMatches = [gs_match](repeating: gs_match(), count: maxMatches)

        let count = cKps1.withUnsafeMutableBufferPointer { kps1Ptr in
            cKps2.withUnsafeMutableBufferPointer { kps2Ptr in
                cMatches.withUnsafeMutableBufferPointer { matchesPtr in
                    gs_match_orb(kps1Ptr.baseAddress!, UInt32(keypoints1.count),
                                 kps2Ptr.baseAddress!, UInt32(keypoints2.count),
                                 matchesPtr.baseAddress!, UInt32(maxMatches), maxDistance)
                }
            }
        }

        return (0..<Int(count)).map { Match(cMatches[$0]) }
    }

    /// Performs template matching.
    ///
    /// - Parameter template: The template image to match.
    /// - Returns: A result image where higher values indicate better matches.
    /// - Throws: `GrayskullError.invalidDimensions` if template is larger than image.
    public func matchTemplate(_ template: GrayskullImage) throws -> GrayskullImage {
        guard template.width <= width && template.height <= height else {
            throw GrayskullError.invalidDimensions
        }

        let resultWidth = width - template.width + 1
        let resultHeight = height - template.height + 1
        let result = GrayskullImage(width: resultWidth, height: resultHeight)

        result.storage.withUnsafeImage { resultImg in
            storage.withUnsafeImage { img in
                template.storage.withUnsafeImage { tmplImg in
                    gs_match_template(img, tmplImg, resultImg)
                }
            }
        }

        return result
    }

    /// Finds the best match location in a template matching result.
    ///
    /// - Returns: The point with the highest match score.
    public func findBestMatch() -> Point {
        storage.withUnsafeImage { img in
            Point(gs_find_best_match(img))
        }
    }

    /// Applies perspective correction using 4 corner points.
    ///
    /// The corners array should contain 4 points in the order: [topLeft, topRight, bottomRight, bottomLeft].
    /// The output image will have the specified dimensions with the perspective-corrected content.
    ///
    /// - Parameters:
    ///   - corners: Array of 4 corner points defining the quadrilateral to transform
    ///   - width: Width of the output image
    ///   - height: Height of the output image
    /// - Returns: A new perspective-corrected image
    /// - Throws: `GrayskullError.invalidDimensions` if corners array doesn't have exactly 4 points
    public func perspectiveCorrected(corners: [Point], width: UInt32, height: UInt32) throws -> GrayskullImage {
        guard corners.count == 4 else {
            throw GrayskullError.invalidDimensions
        }

        let result = GrayskullImage(width: width, height: height)

        // Convert Swift Points to C gs_point array
        var cCorners = corners.map { gs_point(x: $0.x, y: $0.y) }

        result.storage.withUnsafeImage { dstImg in
            storage.withUnsafeImage { srcImg in
                gs_perspective_correct(dstImg, srcImg, &cCorners)
            }
        }

        return result
    }
}

// MARK: - Contour Tracing

extension GrayskullImage {
    /// Traces a contour starting from a given point in a binary image.
    ///
    /// Uses boundary-following algorithm to extract shape boundaries. The image should be
    /// a binary image (thresholded) where pixels > 128 are considered foreground.
    ///
    /// - Parameter startPoint: Starting point on the contour (must be a foreground pixel)
    /// - Returns: Contour information including bounding box, start point, and length
    /// - Throws: `GrayskullError.invalidDimensions` if the image dimensions are invalid
    public func traceContour(startPoint: Point) throws -> Contour {
        // Create a visited image to track which pixels have been visited
        let visited = GrayskullImage(width: width, height: height)

        var cContour = gs_contour(
            box: gs_rect(x: startPoint.x, y: startPoint.y, w: 1, h: 1),
            start: gs_point(x: startPoint.x, y: startPoint.y),
            length: 0
        )

        visited.storage.withUnsafeImage { visitedImg in
            storage.withUnsafeImage { img in
                gs_trace_contour(img, visitedImg, &cContour)
            }
        }

        return Contour(cContour)
    }

    /// Computes the integral image (summed area table) for fast region queries.
    ///
    /// An integral image allows computing the sum of pixel values in any rectangular region
    /// in constant time (O(1)).
    ///
    /// - Returns: An IntegralImage that can be used for fast region sum queries
    public func integralImage() -> IntegralImage {
        let size = Int(width * height)
        var integralData = [UInt32](repeating: 0, count: size)

        storage.withUnsafeImage { img in
            integralData.withUnsafeMutableBufferPointer { buffer in
                let mutableData = UnsafeMutablePointer<UInt32>(mutating: buffer.baseAddress!)
                gs_integral(img, mutableData)
            }
        }

        return IntegralImage(width: width, height: height, data: integralData)
    }
}

// MARK: - Blob Corners

extension GrayskullImage {
    /// Finds the 4 extreme corners of a blob.
    ///
    /// Returns corners in the order: [topLeft, topRight, bottomRight, bottomLeft].
    /// The algorithm finds corners by analyzing the sum and difference of x and y coordinates
    /// to identify the most extreme points.
    ///
    /// - Parameters:
    ///   - blob: The blob to find corners for
    ///   - labels: Label map from `findBlobs(maxBlobs:)` call
    /// - Returns: Array of 4 corner points
    public func blobCorners(for blob: Blob, labels: [UInt16]) -> [Point] {
        var corners = [gs_point](repeating: gs_point(x: 0, y: 0), count: 4)
        var cBlob = gs_blob(
            label: blob.label,
            area: blob.area,
            box: gs_rect(x: blob.boundingBox.x, y: blob.boundingBox.y, w: blob.boundingBox.width, h: blob.boundingBox.height),
            centroid: gs_point(x: blob.centroid.x, y: blob.centroid.y)
        )

        storage.withUnsafeImage { img in
            labels.withUnsafeBufferPointer { labelsPtr in
                let mutableLabels = UnsafeMutablePointer(mutating: labelsPtr.baseAddress!)
                gs_blob_corners(img, mutableLabels, &cBlob, &corners)
            }
        }

        return corners.map { Point($0) }
    }
}

// MARK: - Integral Image

/// Integral image (summed area table) for fast rectangular region queries.
///
/// An integral image is a data structure that allows computing the sum of pixel values
/// in any rectangular region in constant O(1) time, regardless of the region size.
///
/// ## Overview
///
/// The integral image at position (x, y) contains the sum of all pixels in the rectangle
/// from (0, 0) to (x, y). This enables fast computation of region sums using only 4 lookups.
///
/// ## Common Use Cases
///
/// - **LBP Cascade Detection**: Fast Haar-like feature evaluation
/// - **Adaptive Thresholding**: Efficient neighborhood mean computation
/// - **Box Filtering**: Constant-time box blur operations
/// - **Template Matching**: Accelerated normalized cross-correlation
///
/// ## Example
///
/// ```swift
/// let image = GrayskullImage(width: 100, height: 100)
/// let integral = image.integralImage()
///
/// // Sum of a 10×10 region at (20, 20) - O(1) operation
/// let regionSum = integral.sum(rect: Rectangle(x: 20, y: 20, width: 10, height: 10))
///
/// // Use for LBP detection
/// if let cascade = loadCascade() {
///     let detections = cascade.detect(in: integral, maxDetections: 100)
/// }
/// ```
///
/// ## Performance
///
/// - **Construction**: O(w × h) one-time computation
/// - **Region sum query**: O(1) using 4 array lookups
/// - **Memory**: 4 bytes per pixel (UInt32 storage)
///
/// - Note: The integral image stores cumulative sums as `UInt32`, supporting images up to ~16 megapixels with full dynamic range.
///
/// - SeeAlso: ``GrayskullImage/integralImage()``, ``LBPCascade``
public struct IntegralImage: Sendable {
    /// Width of the source image in pixels.
    public let width: UInt32

    /// Height of the source image in pixels.
    public let height: UInt32

    private let data: [UInt32]

    /// Internal initializer that takes the integral data directly
    internal init(width: UInt32, height: UInt32, data: [UInt32]) {
        self.width = width
        self.height = height
        self.data = data
    }

    /// Computes the sum of pixels in a rectangular region in O(1) time.
    ///
    /// This operation is extremely fast regardless of region size, using the integral
    /// image lookup table.
    ///
    /// - Parameter rect: The rectangular region to sum
    /// - Returns: Sum of all pixel values in the region
    public func sum(rect: Rectangle) -> UInt32 {
        data.withUnsafeBufferPointer { buffer in
            let ptr = UnsafePointer<UInt32>(buffer.baseAddress!)
            return gs_integral_sum(ptr, width, rect.x, rect.y, rect.width, rect.height)
        }
    }

    /// Access to the raw integral image data for advanced use cases.
    internal func withUnsafeData<T>(_ body: (UnsafePointer<UInt32>) throws -> T) rethrows -> T {
        try data.withUnsafeBufferPointer { buffer in
            try body(buffer.baseAddress!)
        }
    }
}

// MARK: - LBP Cascade Detection

/// LBP (Local Binary Pattern) cascade classifier for object detection.
///
/// LBP cascades are used for detecting objects like faces, pedestrians, or other patterns
/// using Haar-like features. The cascade file format must match the grayskull C library format.
///
/// Note: This API requires cascade files in the grayskull format. File I/O is not available
/// on WASI/embedded platforms.
#if !os(WASI) && !os(Windows)
public struct LBPCascade {
    private let cascade: gs_lbp_cascade

    /// Window width for detection
    public var windowWidth: UInt16 { cascade.window_w }

    /// Window height for detection
    public var windowHeight: UInt16 { cascade.window_h }

    /// Creates an LBP cascade from a pre-populated gs_lbp_cascade structure.
    ///
    /// Note: Loading cascade files from disk requires custom parsing logic
    /// that depends on the cascade file format. This initializer accepts
    /// a pre-configured cascade structure.
    ///
    /// - Parameter cascade: Pre-configured LBP cascade structure
    public init(cascade: gs_lbp_cascade) {
        self.cascade = cascade
    }

    /// Detects objects in an image using multi-scale sliding window approach.
    ///
    /// This performs LBP-based object detection across multiple scales, using
    /// an integral image for efficient computation.
    ///
    /// - Parameters:
    ///   - integralImage: Pre-computed integral image
    ///   - maxDetections: Maximum number of detections to return
    ///   - scaleFactor: Scale increment for multi-scale detection (typically 1.1)
    ///   - minScale: Minimum detection scale (typically 1.0)
    ///   - maxScale: Maximum detection scale (typically 3.0)
    ///   - step: Sliding window step size in pixels (typically 1 or 2)
    /// - Returns: Array of detected object bounding boxes
    public func detect(
        in integralImage: IntegralImage,
        maxDetections: Int = 100,
        scaleFactor: Float = 1.1,
        minScale: Float = 1.0,
        maxScale: Float = 3.0,
        step: Int = 1
    ) -> [Rectangle] {
        var rects = [gs_rect](repeating: gs_rect(x: 0, y: 0, w: 0, h: 0), count: maxDetections)

        let numDetected = integralImage.withUnsafeData { iiPtr in
            var mutableCascade = cascade
            return gs_lbp_detect(
                &mutableCascade,
                iiPtr,
                integralImage.width,
                integralImage.height,
                &rects,
                UInt32(maxDetections),
                scaleFactor,
                minScale,
                maxScale,
                Int32(step)
            )
        }

        return rects.prefix(Int(numDetected)).map { Rectangle($0) }
    }
}
#endif

// MARK: - Predefined Kernels

extension GrayskullImage {
    /// A 3×3 sharpening kernel.
    public static let sharpenKernel = try! GrayskullImage(
        width: 3, height: 3,
        data: [0, 255, 0, 255, 5, 255, 0, 255, 0]
    )

    /// A 3×3 emboss kernel.
    public static let embossKernel = try! GrayskullImage(
        width: 3, height: 3,
        data: [254, 255, 0, 255, 1, 1, 0, 1, 2]
    )

    /// A 3×3 box blur kernel.
    public static let boxBlurKernel = try! GrayskullImage(
        width: 3, height: 3,
        data: [1, 1, 1, 1, 1, 1, 1, 1, 1]
    )

    /// A 3×3 Gaussian blur kernel.
    public static let gaussianBlurKernel = try! GrayskullImage(
        width: 3, height: 3,
        data: [1, 2, 1, 2, 4, 2, 1, 2, 1]
    )
}
