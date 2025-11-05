import CGrayskull

extension GrayskullImage {
    /// A 3×3 sharpening kernel.
    public static let sharpenKernel = try! GrayskullImage(
        width: 3, height: 3,
        data: [0, 255, 0, 255, 5, 255, 0, 255, 0]
    )

    /// A 3×3 emboss kernel.
    public static let embossKernel = try! GrayskullImage(
        width: 3, height: 3,
        data: [254, 255, 0, 255, 1, 1, 0, 1, 2]
    )

    /// A 3×3 box blur kernel.
    public static let boxBlurKernel = try! GrayskullImage(
        width: 3, height: 3,
        data: [1, 1, 1, 1, 1, 1, 1, 1, 1]
    )

    /// A 3×3 Gaussian blur kernel.
    public static let gaussianBlurKernel = try! GrayskullImage(
        width: 3, height: 3,
        data: [1, 2, 1, 2, 4, 2, 1, 2, 1]
    )
}
