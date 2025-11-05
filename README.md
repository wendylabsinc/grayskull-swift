# grayskull-swift

![iOS](https://img.shields.io/badge/iOS-000000?style=flat&logo=ios&logoColor=white)
![macOS](https://img.shields.io/badge/macOS-000000?style=flat&logo=macos&logoColor=white)
![tvOS](https://img.shields.io/badge/tvOS-000000?style=flat&logo=apple&logoColor=white)
![watchOS](https://img.shields.io/badge/watchOS-000000?style=flat&logo=apple&logoColor=white)
![visionOS](https://img.shields.io/badge/visionOS-000000?style=flat&logo=apple&logoColor=white)
![Android](https://img.shields.io/badge/Android-3DDC84?style=flat&logo=android&logoColor=white)
![Windows](https://img.shields.io/badge/Windows-0078D6?style=flat&logo=windows&logoColor=white)
![Linux](https://img.shields.io/badge/Linux-FCC624?style=flat&logo=linux&logoColor=black)

An ergonomic Swift wrapper around the [Grayskull](https://github.com/zserge/grayskull) C library — a tiny, dependency-free computer vision library for embedded systems, drones, and robotics.

## About

This project provides a cross-platform Swift wrapper around the Grayskull C library, which is included as a git submodule. The wrapper provides:

- **Ergonomic Swift API** with proper memory management and thread safety
- **Swift 6.0+ concurrency** support with `Sendable` conformance
- **Value semantics** for safe, functional-style image processing
- **Platform integration** with CGImage, UIImage, NSImage, and SwiftUI Image
- **Comprehensive test coverage** with Swift Testing framework
- **Cross-platform support** including iOS, macOS, tvOS, watchOS, visionOS, Linux, Windows, and Android
- **Swift Embedded and WASM support** for resource-constrained environments

## Features

Grayskull provides a complete suite of computer vision operations:

### Image Processing
- Crop, resize (bilinear & nearest-neighbor), downsample
- Histogram computation & Otsu's thresholding
- Adaptive thresholding
- Convolution filters (sharpen, emboss, blur, Gaussian blur)
- Morphological operations (erosion, dilation)
- Edge detection (Sobel)

### Computer Vision
- Connected components (blob detection)
- Contour tracing
- FAST corner detection
- ORB (Oriented FAST and Rotated BRIEF) feature extraction
- Feature matching with Hamming distance
- Template matching
- Integral images
- LBP cascade detection (Haar-like features)

## Installation

### Swift Package Manager

Add this to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/wendylabsinc/grayskull-swift.git", from: "0.0.1")
]
```

Or in Xcode, go to File > Add Package Dependencies and enter the repository URL.

### Git Submodule

When cloning this repository, make sure to initialize the submodule:

```bash
git clone --recurse-submodules https://github.com/wendylabsinc/grayskull-swift.git
```

Or if you've already cloned:

```bash
git submodule update --init --recursive
```

## Usage

### Basic Image Operations

```swift
import Grayskull

// Create a new image
let image = GrayskullImage(width: 640, height: 480)

// Create from pixel data
let data = [UInt8](repeating: 128, count: 100 * 100)
let image = try GrayskullImage(width: 100, height: 100, data: data)

// Access pixels
var image = GrayskullImage(width: 100, height: 100)
image[50, 50] = 255  // Set pixel at (50, 50) to white

// Copy and crop
let copy = image.copy()
let roi = Rectangle(x: 10, y: 10, width: 50, height: 50)
let cropped = try image.cropped(to: roi)

// Resize
let resized = image.resized(width: 320, height: 240)
let downsampled = try image.downsampled()  // 2x downsampling
```

### Image Processing

```swift
// Thresholding
let threshold = image.otsuThreshold()
let binary = image.thresholded(threshold)

// Adaptive thresholding
let adaptive = image.adaptiveThreshold(radius: 5, constant: 10)

// Edge detection
let edges = image.sobel()

// Blur
let blurred = image.blurred(radius: 3)

// Morphological operations
let eroded = image.eroded()
let dilated = image.dilated()

// Custom filters
let filtered = image.filtered(
    kernel: GrayskullImage.gaussianBlurKernel,
    normalization: 16
)
```

### Feature Detection

```swift
// FAST corner detection
let keypoints = image.detectFAST(maxKeypoints: 500, threshold: 20)

// ORB feature extraction
let orbFeatures = image.extractORB(maxKeypoints: 500, threshold: 20)

// Feature matching
let image1Features = image1.extractORB()
let image2Features = image2.extractORB()
let matches = GrayskullImage.matchORB(
    keypoints1: image1Features,
    keypoints2: image2Features,
    maxMatches: 100,
    maxDistance: 64.0
)

print("Found \(matches.count) matches")
for match in matches {
    print("Match: kp1[\(match.index1)] <-> kp2[\(match.index2)], distance: \(match.distance)")
}
```

### Blob Detection

```swift
// Find connected components
let binary = image.thresholded(128)
let (labels, blobs) = binary.findBlobs(maxBlobs: 100)

for blob in blobs {
    print("Blob \(blob.label):")
    print("  Area: \(blob.area) pixels")
    print("  Bounding box: \(blob.boundingBox)")
    print("  Centroid: (\(blob.centroid.x), \(blob.centroid.y))")
}
```

### Template Matching

```swift
// Match a template in an image
let template = GrayskullImage(width: 20, height: 20)
let result = try image.matchTemplate(template)
let bestMatch = result.findBestMatch()
print("Best match at: (\(bestMatch.x), \(bestMatch.y))")
```

### Platform Integration (iOS, macOS, visionOS)

Grayskull provides seamless integration with platform-native image types:

```swift
#if canImport(CoreGraphics)
import CoreGraphics
import Grayskull

// From CGImage
let cgImage: CGImage = ...
let grayskullImage = try GrayskullImage(cgImage: cgImage)

// Or using extension
let grayskullImage = try cgImage.toGrayskullImage()

// Process and convert back
let processed = try cgImage.applyGrayskull { image in
    image.sobel().thresholded(128)
}
#endif
```

#### UIKit (iOS, tvOS)

```swift
#if canImport(UIKit)
import UIKit
import Grayskull

// From UIImage
let uiImage = UIImage(named: "photo")!
let grayskullImage = try GrayskullImage(uiImage: uiImage)

// Or using extension
let grayskullImage = try uiImage.toGrayskullImage()

// Process and convert back
let edges = grayskullImage.sobel()
let resultImage = try edges.toUIImage()

// One-liner processing
let processed = try UIImage(named: "photo")!
    .toGrayskullImage()
    .sobel()
    .toUIImage()
#endif
```

#### AppKit (macOS)

```swift
#if canImport(AppKit)
import AppKit
import Grayskull

// From NSImage
let nsImage = NSImage(named: "photo")!
let grayskullImage = try GrayskullImage(nsImage: nsImage)

// Or using extension
let grayskullImage = try nsImage.toGrayskullImage()

// Process and convert back
let blurred = grayskullImage.blurred(radius: 5)
let resultImage = try blurred.toNSImage()
#endif
```

#### SwiftUI

```swift
#if canImport(SwiftUI)
import SwiftUI
import Grayskull

struct ContentView: View {
    let grayskullImage: GrayskullImage

    var body: some View {
        // Convert GrayskullImage to SwiftUI Image
        try? Image(grayskullImage: grayskullImage)
            .resizable()
            .aspectRatio(contentMode: .fit)
    }
}

// Or in a processing pipeline
struct ProcessedImageView: View {
    let originalImage: UIImage

    var body: some View {
        if let processed = try? originalImage
            .toGrayskullImage()
            .sobel(),
           let swiftUIImage = try? Image(grayskullImage: processed) {
            swiftUIImage
                .resizable()
                .aspectRatio(contentMode: .fit)
        }
    }
}
#endif
```

### File I/O (Desktop platforms)

```swift
// Read PGM image
let image = try GrayskullImage(contentsOfPGM: "input.pgm")

// Process
let edges = image.sobel()

// Write result
try edges.write(toPGM: "output.pgm")
```

## Swift Embedded & WASM Support

This wrapper includes support for Swift Embedded and WebAssembly environments:

- **Conditional compilation** for platforms without standard library (`GS_NO_STDLIB`)
- **FoundationEssentials** - Uses lightweight FoundationEssentials when available for smaller Linux binaries
- **Manual memory management** for embedded environments
- **No file I/O dependencies** on WASI/embedded platforms
- **Lock-free operation** on WASI for single-threaded environments
- **Minimal footprint** suitable for microcontrollers and embedded systems

### Building for WASM

```bash
# Requires SwiftWasm toolchain
swift build --triple wasm32-unknown-wasi
```

### Building for Linux with smaller binaries

The package automatically uses `FoundationEssentials` instead of full `Foundation` when available, resulting in significantly smaller binary sizes on Linux:

```bash
# Standard build uses FoundationEssentials automatically
swift build -c release

# Check binary size
ls -lh .build/release/
```

### Swift Embedded

For Swift Embedded, the code automatically adapts:
- Uses manual memory allocation instead of `malloc`/`free` when `GS_NO_STDLIB` is defined
- Disables file I/O on WASI and Windows
- Removes thread synchronization on WASI (single-threaded environment)

Note: On WASI, thread safety is not enforced. Ensure single-threaded access or provide external synchronization.

## Architecture

The wrapper consists of three layers:

1. **CGrayskull** - C module that bridges the header-only grayskull library
2. **Grayskull (Swift)** - Ergonomic Swift wrapper with value semantics
3. **ImageStorage** - Thread-safe reference-counted storage with automatic cleanup

### Thread Safety

All image operations are thread-safe on supported platforms. The internal `ImageStorage` class uses a lightweight, cross-platform mutex:
- **Darwin (macOS/iOS/etc.)**: `os_unfair_lock` for optimal performance
- **Linux/Windows**: `pthread_mutex` for reliable synchronization
- **WASI**: Lock-free (single-threaded environment)

This ensures safe concurrent access without any Objective-C dependencies.

### Memory Management

The wrapper uses automatic reference counting (ARC) to manage memory:

- Images are allocated when created
- Memory is automatically freed when no longer referenced
- Copy-on-write semantics for efficient copying
- No manual memory management required

## Requirements

- Swift 6.0 or later
- Platforms:
  - macOS 13.0+
  - iOS 16.0+
  - tvOS 16.0+
  - watchOS 9.0+
  - visionOS 1.0+
  - Linux (any distribution with Swift support)
  - Windows (with Swift for Windows)

## Performance

Grayskull is designed for embedded systems and is extremely lightweight:

- **Header-only C library** - no runtime dependencies
- **Zero allocations** for most operations (when using preallocated buffers)
- **SIMD-friendly** algorithms
- **Cache-coherent** memory access patterns

## Examples

See the `Tests/GrayskullTests` directory for comprehensive examples of all features.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

When contributing:
1. Ensure all tests pass: `swift test`
2. Add tests for new features
3. Update documentation as needed
4. Follow Swift API design guidelines

## Credits

- **Grayskull C library**: [zserge/grayskull](https://github.com/zserge/grayskull)
- **Swift wrapper**: This project

## License

This project follows the same license as the underlying Grayskull library. Please see the LICENSE file in the grayskull submodule for details.

## Related Projects

- [Grayskull](https://github.com/zserge/grayskull) - The original C library
- [OpenCV](https://opencv.org/) - Full-featured computer vision library (much larger)
- [Vision](https://developer.apple.com/documentation/vision) - Apple's computer vision framework
