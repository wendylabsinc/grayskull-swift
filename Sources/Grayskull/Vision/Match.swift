import CGrayskull

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
