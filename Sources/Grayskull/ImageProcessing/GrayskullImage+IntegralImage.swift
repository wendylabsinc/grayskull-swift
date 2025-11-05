import CGrayskull

extension GrayskullImage {
    /// Computes the integral image (summed area table) for fast region queries.
    ///
    /// An integral image allows computing the sum of pixel values in any rectangular region
    /// in constant time (O(1)).
    ///
    /// - Returns: An `IntegralImage` that can be used for fast region sum queries.
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

/// Integral image (summed area table) for fast rectangular region queries.
///
/// An integral image is a data structure that allows computing the sum of pixel values
/// in any rectangular region in constant O(1) time, regardless of the region size.
///
/// ## Usage
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

    /// Internal initializer that takes the integral data directly.
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
    /// - Parameter rect: The rectangular region to sum.
    /// - Returns: Sum of all pixel values in the region.
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
