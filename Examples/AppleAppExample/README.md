# Apple App Example - Grayskull Camera Demo

A cross-platform SwiftUI camera application demonstrating real-time Grayskull computer vision operations with visual annotations.

## Features

- **Cross-platform support**: macOS, iOS, and visionOS
- **Real-time camera processing** with Grayskull
- **Side-by-side comparison** of original and processed feeds
- **Camera selection** via toolbar dropdown
- **10 Grayskull operations** with specialized visualizations:

### Image Processing Operations
- **blur** - Gaussian blur filter
- **thresh** - Binary threshold (fixed at 128)
- **adaptive** - Adaptive threshold
- **erode** - Morphological erosion
- **dilate** - Morphological dilation
- **sobel** - Edge detection (Sobel operator)
- **otsu** - Automatic threshold selection

### Feature Detection Operations
- **blobs** - Connected component analysis (red boxes with area labels)
- **keypoints** - FAST corner detection (green filled circles)
- **orb** - ORB features with orientation (blue circles with directional lines)

## User Interface

### Navigation Stack
- **Title**: "Grayskull Demo"
- **Subtitle (macOS)**: Shows current camera name
- **Left Toolbar**: Camera selection dropdown with checkmark for active camera
- **Right Toolbar**: Operation menu with icons and current selection indicator

### Camera Feed Layout

**macOS**: Horizontal split view
- Left: Original camera feed
- Right: Grayskull processed feed with overlays

**iOS**: Vertical scrollable layout
- Top: Original camera feed (250pt height)
- Bottom: Processed feed with overlays (250pt height)

**visionOS**: Side-by-side spatial layout
- Left: Original (400×400pt)
- Right: Processed with overlays (400×400pt)

## Visual Annotations

### Blob Detection (Red)
- Bounding boxes around connected components
- Area labels showing pixel count
- Filters out blobs smaller than 50 pixels

### FAST Keypoints (Green)
- Filled circles at corner locations
- Up to 200 keypoints detected

### ORB Features (Blue)
- Hollow circles at feature locations
- Directional lines showing orientation
- Up to 150 features detected

## Camera Selection

The app automatically discovers all available cameras:
- **macOS**: Built-in cameras and external USB/Thunderbolt cameras
- **iOS**: Front, back, wide, ultra-wide, telephoto cameras (if available)
- **visionOS**: Available cameras for the platform

Switch cameras via the toolbar dropdown without stopping the feed.

## Setup

1. Open `AppleAppExample.xcodeproj` in Xcode
2. Add the Grayskull Swift Package:
   - File → Add Package Dependencies
   - Select "Add Local..."
   - Navigate to `../../` (parent directory)
   - Select "Grayskull" package
3. Select your target platform (macOS, iOS, or visionOS)
4. Build and run (⌘R)

## Permissions

The app requires camera permissions:
- **macOS**: Automatically requests on first launch
- **iOS**: Automatically requests on first launch
- **visionOS**: Automatically requests on first launch

Grant permissions in System Settings if denied.

## Code Structure

```
AppleAppExample/
├── AppleAppExampleApp.swift     # Main app entry point
├── ContentView.swift             # Navigation stack & platform views
│   ├── CameraSelectionMenu      # Toolbar camera dropdown
│   ├── OperationMenu            # Toolbar operation selector
│   ├── MacOSCameraFeedView      # macOS horizontal layout
│   ├── IOSCameraFeedView        # iOS vertical layout
│   ├── VisionOSCameraFeedView   # visionOS spatial layout
│   └── OverlayView              # Canvas-based annotations
├── CameraManager.swift           # Camera capture & processing
│   ├── GrayskullOperation       # 10 operations enum
│   ├── OverlayData              # Annotation data structures
│   └── AVCaptureDelegate        # Frame processing
└── Assets.xcassets/             # App assets
```

## Processing Pipeline

1. **Camera Capture**: AVFoundation captures frames (BGRA)
2. **Grayscale Conversion**: BGRA → Grayscale (luminance formula)
3. **Grayskull Processing**: Apply selected operation
4. **Feature Extraction**: For blobs/keypoints/orb, extract annotations
5. **Display**: Show processed image with Canvas overlays

## Performance

Real-time processing at 30 FPS on modern devices:

| Operation | Typical Time (M1 Mac) |
|-----------|----------------------|
| blur | ~5ms |
| thresh | ~2ms |
| adaptive | ~10ms |
| erode | ~8ms |
| dilate | ~8ms |
| sobel | ~5ms |
| otsu | ~3ms |
| blobs | ~15ms |
| keypoints | ~12ms |
| orb | ~20ms |

## Keyboard Shortcuts (macOS)

- **None currently** - All controls via toolbar menus

## Extending

### Adding New Operations

1. Add case to `GrayskullOperation` enum in `CameraManager.swift`:
```swift
enum GrayskullOperation: String, CaseIterable, Identifiable {
    case myOperation = "myop"
    // ...
}
```

2. Add display name:
```swift
var displayName: String {
    case .myOperation: return "My Operation"
    // ...
}
```

3. Implement processing in `processFrame(_:)`:
```swift
case .myOperation:
    processed = image.eroded().dilated()  // Example
```

4. Add icon in `OperationMenu`:
```swift
operationButton(.myOperation, icon: "star.fill")
```

### Adding Custom Overlays

1. Add data to `OverlayData` struct:
```swift
struct OverlayData {
    var customAnnotations: [CustomAnnotation] = []
    // ...
}
```

2. Populate in `processFrame(_:)`
3. Draw in `OverlayView` using Canvas API

## Troubleshooting

### No camera feed
- Check System Settings → Privacy & Security → Camera
- Ensure app has camera permission
- Try selecting different camera from toolbar

### Poor performance
- Some operations (ORB, blobs) are more intensive
- Performance varies by camera resolution
- Disable overlays if needed (switch to non-detection operation)

### Overlays not aligned
- Ensure `AVMakeRect` scaling is correct
- Check that imageSize calculation matches display size

### Build errors
- Clean build folder (⌘⇧K)
- Ensure Grayskull package is linked
- Check that all files are in target membership

## Technical Details

### Thread Safety
- Camera capture runs on background queue
- Frame processing on background queue
- UI updates on main actor (@MainActor)

### Memory Management
- Frames processed immediately, not queued
- Only latest frame kept in memory
- Automatic cleanup via ARC

### Coordinate Mapping
Overlays use Canvas with coordinate scaling:
```swift
let scaleX = displaySize.width / imageSize.width
let scaleY = displaySize.height / imageSize.height
```

This ensures annotations align with displayed image regardless of aspect ratio.

## Requirements

- Xcode 15.0+
- Swift 6.0+
- **macOS**: macOS 13.0+, Camera hardware
- **iOS**: iOS 16.0+, Camera hardware
- **visionOS**: visionOS 1.0+, Camera hardware

## License

Same license as the parent Grayskull Swift package.
