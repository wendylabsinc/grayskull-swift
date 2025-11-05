#if !os(WASI) && !os(Windows)
import CGrayskull

/// LBP (Local Binary Pattern) cascade classifier for object detection.
///
/// LBP cascades are used for detecting objects like faces, pedestrians, or other patterns
/// using Haar-like features. The cascade file format must match the grayskull C library format.
///
/// Note: This API requires cascade files in the grayskull format. File I/O is not available
/// on WASI/embedded platforms.
public struct LBPCascade {
    private let cascade: gs_lbp_cascade

    /// Window width for detection.
    public var windowWidth: UInt16 { cascade.window_w }

    /// Window height for detection.
    public var windowHeight: UInt16 { cascade.window_h }

    /// Creates an LBP cascade from a pre-populated `gs_lbp_cascade` structure.
    ///
    /// Note: Loading cascade files from disk requires custom parsing logic
    /// that depends on the cascade file format. This initializer accepts
    /// a pre-configured cascade structure.
    ///
    /// - Parameter cascade: Pre-configured LBP cascade structure.
    public init(cascade: gs_lbp_cascade) {
        self.cascade = cascade
    }

    /// Detects objects in an image using multi-scale sliding window approach.
    ///
    /// This performs LBP-based object detection across multiple scales, using
    /// an integral image for efficient computation.
    ///
    /// - Parameters:
    ///   - integralImage: Pre-computed integral image.
    ///   - maxDetections: Maximum number of detections to return.
    ///   - scaleFactor: Scale increment for multi-scale detection (typically 1.1).
    ///   - minScale: Minimum detection scale (typically 1.0).
    ///   - maxScale: Maximum detection scale (typically 3.0).
    ///   - step: Sliding window step size in pixels (typically 1 or 2).
    /// - Returns: Array of detected object bounding boxes.
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
