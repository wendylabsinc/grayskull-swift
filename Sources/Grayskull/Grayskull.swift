/// # Grayskull
///
/// A lightweight, ergonomic Swift wrapper for computer vision operations.
///
/// ## Overview
///
/// Grayskull provides a complete suite of image processing and computer vision algorithms optimized
/// for embedded systems, mobile devices, and high-performance applications. Built on a dependency-free
/// C library, it offers native Swift APIs with automatic memory management and full Swift 6.0 concurrency support.
///
/// ## Features
///
/// ### Image Processing
/// - Thresholding (binary, adaptive, Otsu's method)
/// - Morphological operations (erosion, dilation)
/// - Filtering and convolution
/// - Edge detection (Sobel)
/// - Histogram computation
///
/// ### Geometric Transformations
/// - Crop, resize, downsample
/// - Perspective correction
/// - Template matching
///
/// ### Feature Detection
/// - FAST corner detection
/// - ORB feature extraction
/// - Feature matching with Hamming distance
/// - Blob detection and analysis
/// - Contour tracing
///
/// ### Advanced Operations
/// - Integral images for O(1) region queries
/// - LBP cascade detection (Haar-like features)
/// - Multi-platform image conversion (CGImage, UIImage, NSImage)
///
/// ## Getting Started
///
/// ```swift
/// import Grayskull
///
/// // Create or load an image
/// let image = GrayskullImage(width: 640, height: 480)
///
/// // Apply image processing
/// let edges = image.sobel()
/// let binary = edges.thresholded(128)
///
/// // Detect features
/// let (labels, blobs) = binary.findBlobs(maxBlobs: 100)
/// let keypoints = image.detectFAST(maxKeypoints: 500, threshold: 20)
///
/// // Platform integration
/// #if canImport(UIKit)
/// let uiImage = UIImage(named: "photo")!
/// let processed = try uiImage.toGrayskullImage().sobel().toUIImage()
/// #endif
/// ```
///
/// ## Topics
///
/// ### Essentials
///
/// - ``GrayskullImage``
/// - ``Rectangle``
/// - ``Point``
/// - ``GrayskullError``
///
/// ### Computer Vision Types
///
/// - ``Blob``
/// - ``Contour``
/// - ``Keypoint``
/// - ``Match``
///
/// ### Advanced Structures
///
/// - ``IntegralImage``
/// - ``LBPCascade``
///
/// ## Platform Support
///
/// - macOS 13.0+
/// - iOS 16.0+
/// - tvOS 16.0+
/// - visionOS 1.0+
/// - Linux (any distribution with Swift support)
/// - WebAssembly (Swift WASM)
/// - Windows (Swift for Windows)
///
/// ## Performance
///
/// All operations execute at C-level performance with zero Swift overhead. The library is:
/// - Header-only C implementation
/// - Zero external dependencies
/// - SIMD-friendly algorithms
/// - Cache-coherent memory access patterns
/// - Thread-safe with platform-optimized locking
///
/// ## See Also
///
/// - [Grayskull C Library](https://github.com/zserge/grayskull)
/// - [API Coverage Documentation](API_COVERAGE.md)
/// - [Platform Extensions Guide](PlatformExtensions.swift)
