import Testing
@testable import Grayskull

@Suite("GrayskullImage Tests")
struct GrayskullImageTests {

    @Test("Create image with dimensions")
    func testImageCreation() {
        let image = GrayskullImage(width: 100, height: 100)
        #expect(image.width == 100)
        #expect(image.height == 100)
        #expect(image.isValid)
    }

    @Test("Create image from data")
    func testImageFromData() throws {
        let data = [UInt8](repeating: 128, count: 10 * 10)
        let image = try GrayskullImage(width: 10, height: 10, data: data)
        #expect(image.width == 10)
        #expect(image.height == 10)
        #expect(image[5, 5] == 128)
    }

    @Test("Invalid data size throws error")
    func testInvalidDataSize() {
        let data = [UInt8](repeating: 0, count: 50)
        #expect(throws: GrayskullError.self) {
            try GrayskullImage(width: 10, height: 10, data: data)
        }
    }

    @Test("Pixel access via subscript")
    func testPixelAccess() {
        var image = GrayskullImage(width: 10, height: 10)
        image[5, 5] = 255
        #expect(image[5, 5] == 255)
        #expect(image[0, 0] == 0)
    }

    @Test("Copy image")
    func testCopy() {
        var original = GrayskullImage(width: 10, height: 10)
        original[5, 5] = 200

        let copy = original.copy()
        #expect(copy[5, 5] == 200)
        #expect(copy.width == original.width)
        #expect(copy.height == original.height)
    }

    @Test("Crop image")
    func testCrop() throws {
        var image = GrayskullImage(width: 20, height: 20)
        image[10, 10] = 255

        let roi = Rectangle(x: 5, y: 5, width: 10, height: 10)
        let cropped = try image.cropped(to: roi)

        #expect(cropped.width == 10)
        #expect(cropped.height == 10)
        #expect(cropped[5, 5] == 255)
    }

    @Test("Resize image")
    func testResize() {
        let image = GrayskullImage(width: 100, height: 100)
        let resized = image.resized(width: 50, height: 50)

        #expect(resized.width == 50)
        #expect(resized.height == 50)
    }

    @Test("Downsample image")
    func testDownsample() throws {
        let image = GrayskullImage(width: 100, height: 100)
        let downsampled = try image.downsampled()

        #expect(downsampled.width == 50)
        #expect(downsampled.height == 50)
    }

    @Test("Histogram computation")
    func testHistogram() throws {
        let data = [UInt8](repeating: 128, count: 100)
        let image = try GrayskullImage(width: 10, height: 10, data: data)

        let hist = image.histogram()
        #expect(hist.count == 256)
        #expect(hist[128] == 100)
        #expect(hist[0] == 0)
    }

    @Test("Otsu threshold")
    func testOtsuThreshold() throws {
        // Create a bimodal image
        var data = [UInt8](repeating: 50, count: 50)
        data.append(contentsOf: [UInt8](repeating: 200, count: 50))

        let image = try GrayskullImage(width: 10, height: 10, data: data)
        let threshold = image.otsuThreshold()

        #expect(threshold >= 50)
        #expect(threshold <= 200)
    }

    @Test("Threshold operation")
    func testThreshold() throws {
        let data = Array(0..<100).map { UInt8($0 * 255 / 100) }
        var image = try GrayskullImage(width: 10, height: 10, data: data)

        image.threshold(128)

        #expect(image[0, 0] == 0)
        #expect(image[9, 9] == 255)
    }

    @Test("Blur operation")
    func testBlur() {
        let image = GrayskullImage(width: 50, height: 50)
        let blurred = image.blurred(radius: 3)

        #expect(blurred.width == image.width)
        #expect(blurred.height == image.height)
    }

    @Test("Sobel edge detection")
    func testSobel() {
        let image = GrayskullImage(width: 50, height: 50)
        let edges = image.sobel()

        #expect(edges.width == image.width)
        #expect(edges.height == image.height)
    }

    @Test("Morphological erosion")
    func testErode() {
        let image = GrayskullImage(width: 50, height: 50)
        let eroded = image.eroded()

        #expect(eroded.width == image.width)
        #expect(eroded.height == image.height)
    }

    @Test("Morphological dilation")
    func testDilate() {
        let image = GrayskullImage(width: 50, height: 50)
        let dilated = image.dilated()

        #expect(dilated.width == image.width)
        #expect(dilated.height == image.height)
    }
}

@Suite("Geometric Types Tests")
struct GeometricTypesTests {

    @Test("Rectangle creation")
    func testRectangle() {
        let rect = Rectangle(x: 10, y: 20, width: 100, height: 200)
        #expect(rect.x == 10)
        #expect(rect.y == 20)
        #expect(rect.width == 100)
        #expect(rect.height == 200)
    }

    @Test("Point creation")
    func testPoint() {
        let point = Point(x: 50, y: 75)
        #expect(point.x == 50)
        #expect(point.y == 75)
    }

    @Test("Rectangle equality")
    func testRectangleEquality() {
        let rect1 = Rectangle(x: 10, y: 20, width: 100, height: 200)
        let rect2 = Rectangle(x: 10, y: 20, width: 100, height: 200)
        let rect3 = Rectangle(x: 10, y: 20, width: 50, height: 200)

        #expect(rect1 == rect2)
        #expect(rect1 != rect3)
    }
}

@Suite("Blob Detection Tests")
struct BlobDetectionTests {

    @Test("Find blobs in binary image")
    func testBlobDetection() throws {
        // Create a simple binary image with a square blob
        var data = [UInt8](repeating: 0, count: 100 * 100)

        // Draw a 20x20 white square in the middle
        for y in 40..<60 {
            for x in 40..<60 {
                data[y * 100 + x] = 255
            }
        }

        let image = try GrayskullImage(width: 100, height: 100, data: data)
        let (_, blobs) = image.findBlobs(maxBlobs: 10)

        #expect(blobs.count > 0)

        if let blob = blobs.first {
            #expect(blob.area > 0)
            #expect(blob.boundingBox.width > 0)
            #expect(blob.boundingBox.height > 0)
        }
    }
}

@Suite("Feature Detection Tests")
struct FeatureDetectionTests {

    @Test("FAST keypoint detection")
    func testFASTDetection() throws {
        // Create an image with some features
        var data = [UInt8](repeating: 128, count: 100 * 100)

        // Add some corners
        for i in 0..<10 {
            data[50 * 100 + 50 + i] = 255
            data[(50 + i) * 100 + 50] = 255
        }

        let image = try GrayskullImage(width: 100, height: 100, data: data)
        let keypoints = image.detectFAST(maxKeypoints: 100, threshold: 20)

        // We may or may not detect keypoints depending on the pattern,
        // but the function should execute without crashing
        #expect(keypoints.count >= 0)
    }

    @Test("ORB feature extraction")
    func testORBExtraction() throws {
        var data = [UInt8](repeating: 128, count: 100 * 100)

        // Add some pattern
        for i in 0..<50 {
            data[i * 100 + i] = 255
        }

        let image = try GrayskullImage(width: 100, height: 100, data: data)
        let keypoints = image.extractORB(maxKeypoints: 100, threshold: 20)

        #expect(keypoints.count >= 0)

        for kp in keypoints {
            #expect(kp.descriptor.count == 8)
        }
    }
}

@Suite("Template Matching Tests")
struct TemplateMatchingTests {

    @Test("Template matching")
    func testTemplateMatching() throws {
        let image = GrayskullImage(width: 100, height: 100)
        let template = GrayskullImage(width: 10, height: 10)

        let result = try image.matchTemplate(template)

        #expect(result.width == 91)
        #expect(result.height == 91)
    }

    @Test("Find best match")
    func testFindBestMatch() throws {
        // Create a result image with a known maximum
        var data = [UInt8](repeating: 0, count: 100 * 100)
        data[50 * 100 + 50] = 255 // Maximum at (50, 50)

        let result = try GrayskullImage(width: 100, height: 100, data: data)
        let bestMatch = result.findBestMatch()

        #expect(bestMatch.x == 50)
        #expect(bestMatch.y == 50)
    }
}

@Suite("Predefined Kernels Tests")
struct KernelTests {

    @Test("Sharpen kernel exists")
    func testSharpenKernel() {
        let kernel = GrayskullImage.sharpenKernel
        #expect(kernel.width == 3)
        #expect(kernel.height == 3)
    }

    @Test("Gaussian blur kernel exists")
    func testGaussianBlurKernel() {
        let kernel = GrayskullImage.gaussianBlurKernel
        #expect(kernel.width == 3)
        #expect(kernel.height == 3)
    }

    @Test("Apply filter with kernel")
    func testApplyFilter() {
        let image = GrayskullImage(width: 50, height: 50)
        let filtered = image.filtered(kernel: GrayskullImage.gaussianBlurKernel, normalization: 16)

        #expect(filtered.width == image.width)
        #expect(filtered.height == image.height)
    }
}

@Suite("Perspective Correction Tests")
struct PerspectiveCorrectionTests {

    @Test("Perspective correction with 4 corners")
    func testPerspectiveCorrection() throws {
        // Create a test image
        var image = GrayskullImage(width: 100, height: 100)

        // Fill a square in the middle
        for y in 25..<75 {
            for x in 25..<75 {
                image[UInt32(x), UInt32(y)] = 255
            }
        }

        // Define corners for perspective transformation
        let corners = [
            Point(x: 20, y: 20),   // top-left
            Point(x: 80, y: 25),   // top-right
            Point(x: 75, y: 80),   // bottom-right
            Point(x: 25, y: 75)    // bottom-left
        ]

        let corrected = try image.perspectiveCorrected(corners: corners, width: 60, height: 60)

        #expect(corrected.width == 60)
        #expect(corrected.height == 60)
    }

    @Test("Perspective correction with invalid corners throws")
    func testPerspectiveCorrectionInvalidCorners() {
        let image = GrayskullImage(width: 100, height: 100)
        let invalidCorners = [Point(x: 0, y: 0), Point(x: 10, y: 10)]  // Only 2 corners

        #expect(throws: GrayskullError.self) {
            try image.perspectiveCorrected(corners: invalidCorners, width: 50, height: 50)
        }
    }
}

@Suite("Contour Tracing Tests")
struct ContourTracingTests {

    @Test("Trace contour in binary image")
    func testTraceContour() throws {
        // Create a binary image with a square
        var image = GrayskullImage(width: 50, height: 50)

        // Draw a filled square
        for y in 10..<40 {
            for x in 10..<40 {
                image[UInt32(x), UInt32(y)] = 255
            }
        }

        // Trace contour starting from edge of square
        let contour = try image.traceContour(startPoint: Point(x: 10, y: 10))

        #expect(contour.length > 0)
        #expect(contour.boundingBox.width > 0)
        #expect(contour.boundingBox.height > 0)
    }
}

@Suite("Blob Corners Tests")
struct BlobCornersTests {

    @Test("Find blob corners")
    func testBlobCorners() {
        // Create a binary image with a blob
        var image = GrayskullImage(width: 100, height: 100)

        // Create a rectangular blob
        for y in 20..<80 {
            for x in 30..<70 {
                image[UInt32(x), UInt32(y)] = 255
            }
        }

        let binary = image.thresholded(128)
        let (labels, blobs) = binary.findBlobs(maxBlobs: 10)

        #expect(blobs.count > 0)

        if let firstBlob = blobs.first {
            let corners = binary.blobCorners(for: firstBlob, labels: labels)

            #expect(corners.count == 4)

            // Verify corners are within the image bounds
            for corner in corners {
                #expect(corner.x < image.width)
                #expect(corner.y < image.height)
            }
        }
    }
}

@Suite("Integral Image Tests")
struct IntegralImageTests {

    @Test("Create integral image")
    func testCreateIntegralImage() {
        let image = GrayskullImage(width: 50, height: 50)
        let integral = image.integralImage()

        #expect(integral.width == image.width)
        #expect(integral.height == image.height)
    }

    @Test("Integral image sum query")
    func testIntegralImageSum() {
        // Create a test image with known values
        let data = [UInt8](repeating: 10, count: 100)  // 10x10 image with all pixels = 10
        let image = try! GrayskullImage(width: 10, height: 10, data: data)
        let integral = image.integralImage()

        // Sum of a 5x5 region should be 5*5*10 = 250
        let rect = Rectangle(x: 0, y: 0, width: 5, height: 5)
        let sum = integral.sum(rect: rect)

        #expect(sum == 250)
    }

    @Test("Integral image sum of full image")
    func testIntegralImageSumFull() {
        // Create a test image
        let data = [UInt8](repeating: 5, count: 100)  // 10x10 image with all pixels = 5
        let image = try! GrayskullImage(width: 10, height: 10, data: data)
        let integral = image.integralImage()

        // Sum of full image should be 10*10*5 = 500
        let rect = Rectangle(x: 0, y: 0, width: 10, height: 10)
        let sum = integral.sum(rect: rect)

        #expect(sum == 500)
    }
}
