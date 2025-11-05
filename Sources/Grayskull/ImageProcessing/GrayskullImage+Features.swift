import CGrayskull

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
                    gs_orb_extract(
                        img,
                        kpsPtr.baseAddress!,
                        UInt32(maxKeypoints),
                        threshold,
                        scorePtr.baseAddress!
                    )
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
                    gs_match_orb(
                        kps1Ptr.baseAddress!,
                        UInt32(keypoints1.count),
                        kps2Ptr.baseAddress!,
                        UInt32(keypoints2.count),
                        matchesPtr.baseAddress!,
                        UInt32(maxMatches),
                        maxDistance
                    )
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
    ///   - corners: Array of 4 corner points defining the quadrilateral to transform.
    ///   - width: Width of the output image.
    ///   - height: Height of the output image.
    /// - Returns: A new perspective-corrected image.
    /// - Throws: `GrayskullError.invalidDimensions` if corners array doesn't have exactly 4 points.
    public func perspectiveCorrected(
        corners: [Point],
        width: UInt32,
        height: UInt32
    ) throws -> GrayskullImage {
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
