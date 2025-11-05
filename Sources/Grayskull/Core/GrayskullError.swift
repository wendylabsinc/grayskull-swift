/// Errors that can occur during Grayskull operations.
///
/// These errors cover various failure modes including:
/// - Invalid image dimensions or parameters
/// - File I/O failures
/// - Image conversion errors
/// - Memory allocation issues
///
/// Each case maps to common computer vision error scenarios and is used across the API
/// to provide consistent error feedback.
public enum GrayskullError: Error, Sendable {
    /// Invalid image dimensions or parameters.
    ///
    /// Occurs when:
    /// - Width/height are zero or exceed supported limits
    /// - Region of interest is outside image bounds
    /// - Template sizes are incompatible for operations
    case invalidDimensions

    /// Error reading data from disk or other sources.
    ///
    /// Occurs during PGM file loading or other I/O-bound operations.
    case fileReadError

    /// Error writing data to disk or other destinations.
    ///
    /// Occurs when saving PGM files.
    case fileWriteError

    /// Error converting image data between formats.
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
