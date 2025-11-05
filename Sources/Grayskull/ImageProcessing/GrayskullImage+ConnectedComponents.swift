import CGrayskull

extension GrayskullImage {
    /// Finds connected components (blobs) in a binary image.
    ///
    /// - Parameter maxBlobs: The maximum number of blobs to find.
    /// - Returns: A tuple containing the label map and array of found blobs.
    public func findBlobs(maxBlobs: Int = 1000) -> (labels: [UInt16], blobs: [Blob]) {
        var labels = [UInt16](repeating: 0, count: Int(width * height))
        var cBlobs = [gs_blob](repeating: gs_blob(), count: maxBlobs)

        let count = storage.withUnsafeImage { img in
            labels.withUnsafeMutableBufferPointer { labelsPtr in
                cBlobs.withUnsafeMutableBufferPointer { blobsPtr in
                    gs_blobs(img, labelsPtr.baseAddress!, blobsPtr.baseAddress!, UInt32(maxBlobs))
                }
            }
        }

        let blobs = (0..<Int(count)).map { Blob(cBlobs[$0]) }
        return (labels, blobs)
    }

    /// Finds the 4 extreme corners of a blob.
    ///
    /// Returns corners in the order: [topLeft, topRight, bottomRight, bottomLeft].
    /// The algorithm finds corners by analyzing the sum and difference of x and y coordinates
    /// to identify the most extreme points.
    ///
    /// - Parameters:
    ///   - blob: The blob to find corners for.
    ///   - labels: Label map from `findBlobs(maxBlobs:)` call.
    /// - Returns: Array of 4 corner points.
    public func blobCorners(for blob: Blob, labels: [UInt16]) -> [Point] {
        var corners = [gs_point](repeating: gs_point(x: 0, y: 0), count: 4)
        var cBlob = gs_blob(
            label: blob.label,
            area: blob.area,
            box: gs_rect(
                x: blob.boundingBox.x,
                y: blob.boundingBox.y,
                w: blob.boundingBox.width,
                h: blob.boundingBox.height
            ),
            centroid: gs_point(x: blob.centroid.x, y: blob.centroid.y)
        )

        storage.withUnsafeImage { img in
            labels.withUnsafeBufferPointer { labelsPtr in
                let mutableLabels = UnsafeMutablePointer(mutating: labelsPtr.baseAddress!)
                gs_blob_corners(img, mutableLabels, &cBlob, &corners)
            }
        }

        return corners.map { Point($0) }
    }
}
