import CGrayskull

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

    /// The width of the rectangle.
    public var width: UInt32

    /// The height of the rectangle.
    public var height: UInt32

    /// Creates a rectangle with the specified position and size.
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
