import CGrayskull

/// A point in image coordinates.
///
/// Represents a pixel position in the image. Used extensively for geometric computations,
/// contour tracing, and feature matching.
public struct Point: Sendable, Equatable {
    /// The x-coordinate of the point.
    public var x: UInt32

    /// The y-coordinate of the point.
    public var y: UInt32

    /// Creates a point with the specified coordinates.
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
