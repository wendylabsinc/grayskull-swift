import CGrayskull

extension GrayskullImage {
    /// Traces a contour starting from a given point in a binary image.
    ///
    /// Uses boundary-following algorithm to extract shape boundaries. The image should be
    /// a binary image (thresholded) where pixels > 128 are considered foreground.
    ///
    /// - Parameter startPoint: Starting point on the contour (must be a foreground pixel).
    /// - Returns: Contour information including bounding box, start point, and length.
    /// - Throws: `GrayskullError.invalidDimensions` if the image dimensions are invalid.
    public func traceContour(startPoint: Point) throws -> Contour {
        // Create a visited image to track which pixels have been visited.
        let visited = GrayskullImage(width: width, height: height)

        var cContour = gs_contour(
            box: gs_rect(x: startPoint.x, y: startPoint.y, w: 1, h: 1),
            start: gs_point(x: startPoint.x, y: startPoint.y),
            length: 0
        )

        visited.storage.withUnsafeImage { visitedImg in
            storage.withUnsafeImage { img in
                gs_trace_contour(img, visitedImg, &cContour)
            }
        }

        return Contour(cContour)
    }
}
