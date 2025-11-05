import CGrayskull

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
