import CGrayskull

/// Keypoint representing a detected feature in the image.
///
/// Used for FAST and ORB feature detection. Contains location, response strength, orientation,
/// and descriptor data for ORB features.
///
/// ## Usage
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
