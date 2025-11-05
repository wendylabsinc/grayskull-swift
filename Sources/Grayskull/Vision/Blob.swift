import CGrayskull

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
