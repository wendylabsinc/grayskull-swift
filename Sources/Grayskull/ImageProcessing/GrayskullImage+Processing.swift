import CGrayskull

extension GrayskullImage {
    /// Crops a region from the source image.
    ///
    /// - Parameter roi: The region of interest to crop.
    /// - Returns: A new image containing the cropped region.
    /// - Throws: `GrayskullError.invalidDimensions` if ROI is out of bounds.
    public func cropped(to roi: Rectangle) throws -> GrayskullImage {
        guard roi.x + roi.width <= width && roi.y + roi.height <= height else {
            throw GrayskullError.invalidDimensions
        }

        let result = GrayskullImage(width: roi.width, height: roi.height)
        result.storage.withUnsafeImage { dst in
            storage.withUnsafeImage { src in
                gs_crop(dst, src, roi.cValue)
            }
        }
        return result
    }

    /// Creates a copy of the image.
    public func copy() -> GrayskullImage {
        let result = GrayskullImage(width: width, height: height)
        result.storage.withUnsafeImage { dst in
            storage.withUnsafeImage { src in
                gs_copy(dst, src)
            }
        }
        return result
    }

    /// Resizes the image using bilinear interpolation.
    ///
    /// - Parameters:
    ///   - width: The target width.
    ///   - height: The target height.
    /// - Returns: A new resized image.
    public func resized(width: UInt32, height: UInt32) -> GrayskullImage {
        let result = GrayskullImage(width: width, height: height)
        result.storage.withUnsafeImage { dst in
            storage.withUnsafeImage { src in
                gs_resize(dst, src)
            }
        }
        return result
    }

    /// Resizes the image using nearest-neighbor interpolation.
    ///
    /// - Parameters:
    ///   - width: The target width.
    ///   - height: The target height.
    /// - Returns: A new resized image.
    public func resizedNearest(width: UInt32, height: UInt32) -> GrayskullImage {
        let result = GrayskullImage(width: width, height: height)
        result.storage.withUnsafeImage { dst in
            storage.withUnsafeImage { src in
                gs_resize_nn(dst, src)
            }
        }
        return result
    }

    /// Downsamples the image by a factor of 2.
    ///
    /// - Returns: A new image with half the width and height.
    /// - Throws: `GrayskullError.invalidDimensions` if dimensions are not even.
    public func downsampled() throws -> GrayskullImage {
        guard width >= 2 && height >= 2 && width % 2 == 0 && height % 2 == 0 else {
            throw GrayskullError.invalidDimensions
        }

        let result = GrayskullImage(width: width / 2, height: height / 2)
        result.storage.withUnsafeImage { dst in
            storage.withUnsafeImage { src in
                gs_downsample(dst, src)
            }
        }
        return result
    }

    /// Computes the histogram of the image.
    ///
    /// - Returns: An array of 256 values representing the histogram.
    public func histogram() -> [UInt32] {
        var hist: [UInt32] = Array(repeating: 0, count: 256)
        storage.withUnsafeImage { img in
            hist.withUnsafeMutableBufferPointer { buffer in
                gs_histogram(img, buffer.baseAddress!)
            }
        }
        return hist
    }

    /// Computes the Otsu threshold for the image.
    ///
    /// - Returns: The optimal threshold value (0-255).
    public func otsuThreshold() -> UInt8 {
        storage.withUnsafeImage { img in
            gs_otsu_threshold(img)
        }
    }

    /// Applies a threshold to the image in-place.
    ///
    /// - Parameter threshold: The threshold value (0-255).
    public mutating func threshold(_ value: UInt8) {
        storage.withUnsafeImage { img in
            gs_threshold(img, value)
        }
    }

    /// Returns a thresholded copy of the image.
    ///
    /// - Parameter threshold: The threshold value (0-255).
    /// - Returns: A new binary image.
    public func thresholded(_ value: UInt8) -> GrayskullImage {
        let result = copy()
        result.storage.withUnsafeImage { img in
            gs_threshold(img, value)
        }
        return result
    }

    /// Applies adaptive thresholding.
    ///
    /// - Parameters:
    ///   - radius: The radius of the neighborhood.
    ///   - constant: A constant subtracted from the mean.
    /// - Returns: A new binary image.
    public func adaptiveThreshold(radius: UInt32, constant: Int32) -> GrayskullImage {
        let result = GrayskullImage(width: width, height: height)
        result.storage.withUnsafeImage { dst in
            storage.withUnsafeImage { src in
                gs_adaptive_threshold(dst, src, radius, constant)
            }
        }
        return result
    }

    /// Applies a convolution filter to the image.
    ///
    /// - Parameters:
    ///   - kernel: The convolution kernel image.
    ///   - normalization: The normalization factor.
    /// - Returns: A new filtered image.
    public func filtered(kernel: GrayskullImage, normalization: UInt32) -> GrayskullImage {
        let result = GrayskullImage(width: width, height: height)
        result.storage.withUnsafeImage { dst in
            storage.withUnsafeImage { src in
                kernel.storage.withUnsafeImage { kern in
                    gs_filter(dst, src, kern, normalization)
                }
            }
        }
        return result
    }

    /// Applies a box blur to the image.
    ///
    /// - Parameter radius: The blur radius.
    /// - Returns: A new blurred image.
    public func blurred(radius: UInt32) -> GrayskullImage {
        let result = GrayskullImage(width: width, height: height)
        result.storage.withUnsafeImage { dst in
            storage.withUnsafeImage { src in
                gs_blur(dst, src, radius)
            }
        }
        return result
    }

    /// Applies morphological erosion.
    ///
    /// - Returns: A new eroded image.
    public func eroded() -> GrayskullImage {
        let result = GrayskullImage(width: width, height: height)
        result.storage.withUnsafeImage { dst in
            storage.withUnsafeImage { src in
                gs_erode(dst, src)
            }
        }
        return result
    }

    /// Applies morphological dilation.
    ///
    /// - Returns: A new dilated image.
    public func dilated() -> GrayskullImage {
        let result = GrayskullImage(width: width, height: height)
        result.storage.withUnsafeImage { dst in
            storage.withUnsafeImage { src in
                gs_dilate(dst, src)
            }
        }
        return result
    }

    /// Computes the Sobel edge detection.
    ///
    /// - Returns: A new image with detected edges.
    public func sobel() -> GrayskullImage {
        let result = GrayskullImage(width: width, height: height)
        result.storage.withUnsafeImage { dst in
            storage.withUnsafeImage { src in
                gs_sobel(dst, src)
            }
        }
        return result
    }
}
