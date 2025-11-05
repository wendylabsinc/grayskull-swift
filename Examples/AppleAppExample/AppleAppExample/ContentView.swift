//
//  ContentView.swift
//  AppleAppExample
//
//  Created by Maximilian Alexander on 11/4/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var camera = CameraManager()

    var body: some View {
        NavigationStack {
            CameraFeedView(camera: camera)
                .navigationTitle("Grayskull Demo")
                #if os(macOS)
                .navigationSubtitle(camera.selectedCamera?.localizedName ?? "No Camera")
                #endif
                .toolbar {
                    ToolbarItem(placement: .navigation) {
                        CameraSelectionMenu(camera: camera)
                    }

                    ToolbarItem(placement: .primaryAction) {
                        OperationMenu(camera: camera)
                    }
                }
        }
        .task {
            await camera.startSession()
        }
    }
}

// MARK: - Camera Selection Menu

struct CameraSelectionMenu: View {
    @ObservedObject var camera: CameraManager

    var body: some View {
        Menu {
            ForEach(camera.availableCameras, id: \.uniqueID) { device in
                Button(action: {
                    camera.switchCamera(to: device)
                }) {
                    HStack {
                        Text(cameraDisplayName(for: device))
                        if device.uniqueID == camera.selectedCamera?.uniqueID {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }

            if camera.availableCameras.isEmpty {
                Text("No cameras available")
                    .foregroundColor(.secondary)
            }
        } label: {
            Label(camera.selectedCamera?.localizedName ?? "Select Camera", systemImage: "video")
        }
    }

    private func cameraDisplayName(for device: AVCaptureDevice) -> String {
        var name = device.localizedName

        #if os(iOS)
        switch device.position {
        case .front:
            name += " (Front)"
        case .back:
            name += " (Back)"
        default:
            break
        }
        #endif

        return name
    }
}

// MARK: - Operation Menu

struct OperationMenu: View {
    @ObservedObject var camera: CameraManager

    var body: some View {
        Menu {
            Section("Image Processing") {
                operationButton(.blur, icon: "cloud")
                operationButton(.thresh, icon: "chart.bar.fill")
                operationButton(.adaptive, icon: "slider.horizontal.3")
                operationButton(.erode, icon: "minus.circle")
                operationButton(.dilate, icon: "plus.circle")
                operationButton(.sobel, icon: "waveform.path.ecg")
                operationButton(.otsu, icon: "chart.line.uptrend.xyaxis")
            }

            Section("Feature Detection") {
                operationButton(.blobs, icon: "square.3.layers.3d")
                operationButton(.keypoints, icon: "circle.grid.cross")
                operationButton(.orb, icon: "scope")
            }
        } label: {
            Label(camera.operation.displayName, systemImage: operationIcon(for: camera.operation))
        }
    }

    private func operationButton(_ op: CameraManager.GrayskullOperation, icon: String) -> some View {
        Button(action: {
            camera.operation = op
        }) {
            HStack {
                Label(op.displayName, systemImage: icon)
                if camera.operation == op {
                    Spacer()
                    Image(systemName: "checkmark")
                }
            }
        }
    }

    private func operationIcon(for operation: CameraManager.GrayskullOperation) -> String {
        switch operation {
        case .blur: return "cloud"
        case .thresh: return "chart.bar.fill"
        case .adaptive: return "slider.horizontal.3"
        case .erode: return "minus.circle"
        case .dilate: return "plus.circle"
        case .sobel: return "waveform.path.ecg"
        case .otsu: return "chart.line.uptrend.xyaxis"
        case .blobs: return "square.3.layers.3d"
        case .keypoints: return "circle.grid.cross"
        case .orb: return "scope"
        }
    }
}

// MARK: - Camera Feed View

struct CameraFeedView: View {
    @ObservedObject var camera: CameraManager

    var body: some View {
        #if os(macOS)
        MacOSCameraFeedView(camera: camera)
        #elseif os(iOS)
        IOSCameraFeedView(camera: camera)
        #elseif os(visionOS)
        VisionOSCameraFeedView(camera: camera)
        #endif
    }
}

// MARK: - macOS View

#if os(macOS)
struct MacOSCameraFeedView: View {
    @ObservedObject var camera: CameraManager

    var body: some View {
        HStack(spacing: 0) {
            // Original feed
            CameraView(title: "Original", image: camera.originalFrame)
                .frame(maxWidth: .infinity)

            Divider()

            // Processed feed with overlays
            ZStack {
                CameraView(title: "Grayskull Processed", image: camera.processedFrame)

                // Overlay annotations
                if let overlay = camera.overlayData {
                    GeometryReader { geometry in
                        OverlayView(overlay: overlay, imageSize: imageSize(for: camera.processedFrame, in: geometry.size))
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
    }

    private func imageSize(for cgImage: CGImage?, in containerSize: CGSize) -> CGSize {
        guard let cgImage = cgImage else { return .zero }
        let imageSize = CGSize(width: cgImage.width, height: cgImage.height)
        return AVMakeRect(aspectRatio: imageSize, insideRect: CGRect(origin: .zero, size: containerSize)).size
    }
}

struct CameraView: View {
    let title: String
    let image: CGImage?

    var body: some View {
        VStack(spacing: 0) {
            Text(title)
                .font(.headline)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(Color(NSColor.controlBackgroundColor))

            if let image = image {
                Image(decorative: image, scale: 1.0)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Spacer()
                Text("No camera feed")
                    .foregroundColor(.secondary)
                Spacer()
            }
        }
    }
}
#endif

// MARK: - iOS View

#if os(iOS)
struct IOSCameraFeedView: View {
    @ObservedObject var camera: CameraManager

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Original feed
                VStack {
                    Text("Original")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color(UIColor.secondarySystemBackground))

                    if let image = camera.originalFrame {
                        Image(decorative: image, scale: 1.0)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 250)
                    } else {
                        Text("No camera feed")
                            .foregroundColor(.secondary)
                            .frame(height: 250)
                    }
                }
                .background(Color(UIColor.systemBackground))
                .cornerRadius(12)
                .shadow(radius: 2)

                // Processed feed with overlays
                VStack {
                    Text("Grayskull Processed")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color(UIColor.secondarySystemBackground))

                    ZStack {
                        if let image = camera.processedFrame {
                            Image(decorative: image, scale: 1.0)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 250)
                        } else {
                            Text("Processing...")
                                .foregroundColor(.secondary)
                                .frame(height: 250)
                        }

                        // Overlay annotations
                        if let overlay = camera.overlayData, let cgImage = camera.processedFrame {
                            GeometryReader { geometry in
                                let imageSize = AVMakeRect(
                                    aspectRatio: CGSize(width: cgImage.width, height: cgImage.height),
                                    insideRect: CGRect(origin: .zero, size: geometry.size)
                                ).size
                                OverlayView(overlay: overlay, imageSize: imageSize)
                            }
                            .frame(height: 250)
                        }
                    }
                }
                .background(Color(UIColor.systemBackground))
                .cornerRadius(12)
                .shadow(radius: 2)

                if let error = camera.error {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding()
                }
            }
            .padding()
        }
    }
}
#endif

// MARK: - visionOS View

#if os(visionOS)
struct VisionOSCameraFeedView: View {
    @ObservedObject var camera: CameraManager

    var body: some View {
        HStack(spacing: 40) {
            // Original feed
            VStack {
                Text("Original")
                    .font(.headline)

                if let image = camera.originalFrame {
                    Image(decorative: image, scale: 1.0)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 400, height: 400)
                        .cornerRadius(20)
                } else {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.secondary.opacity(0.2))
                        .frame(width: 400, height: 400)
                        .overlay {
                            Text("No camera feed")
                                .foregroundColor(.secondary)
                        }
                }
            }

            // Processed feed with overlays
            VStack {
                Text("Grayskull Processed")
                    .font(.headline)

                ZStack {
                    if let image = camera.processedFrame {
                        Image(decorative: image, scale: 1.0)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 400, height: 400)
                            .cornerRadius(20)
                    } else {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.secondary.opacity(0.2))
                            .frame(width: 400, height: 400)
                            .overlay {
                                Text("Processing...")
                                    .foregroundColor(.secondary)
                            }
                    }

                    // Overlay annotations
                    if let overlay = camera.overlayData, let cgImage = camera.processedFrame {
                        let imageSize = CGSize(width: cgImage.width, height: cgImage.height)
                        let displaySize = AVMakeRect(
                            aspectRatio: imageSize,
                            insideRect: CGRect(x: 0, y: 0, width: 400, height: 400)
                        ).size
                        OverlayView(overlay: overlay, imageSize: displaySize)
                            .frame(width: 400, height: 400)
                    }
                }
            }
        }
        .padding()
    }
}
#endif

// MARK: - Overlay View

struct OverlayView: View {
    let overlay: CameraManager.OverlayData
    let imageSize: CGSize

    var body: some View {
        Canvas { context, size in
            // Scale factor to map from image coordinates to display coordinates
            let scaleX = size.width / imageSize.width
            let scaleY = size.height / imageSize.height

            // Draw blob boxes (red)
            for blob in overlay.blobs {
                let scaledRect = CGRect(
                    x: blob.rect.origin.x * scaleX,
                    y: blob.rect.origin.y * scaleY,
                    width: blob.rect.width * scaleX,
                    height: blob.rect.height * scaleY
                )

                context.stroke(
                    Path(roundedRect: scaledRect, cornerRadius: 4),
                    with: .color(.red),
                    lineWidth: 2
                )

                // Draw area label
                let text = Text("Area: \(blob.area)")
                    .font(.caption)
                    .foregroundColor(.red)
                context.draw(text, at: CGPoint(x: scaledRect.minX + 5, y: scaledRect.minY - 5))
            }

            // Draw keypoints (green circles)
            for kp in overlay.keypoints {
                let scaledPoint = CGPoint(
                    x: kp.point.x * scaleX,
                    y: kp.point.y * scaleY
                )

                context.fill(
                    Path(ellipseIn: CGRect(x: scaledPoint.x - 4, y: scaledPoint.y - 4, width: 8, height: 8)),
                    with: .color(.green)
                )
            }

            // Draw ORB features (blue circles with orientation lines)
            for orb in overlay.orbFeatures {
                let scaledPoint = CGPoint(
                    x: orb.point.x * scaleX,
                    y: orb.point.y * scaleY
                )

                // Circle
                context.stroke(
                    Path(ellipseIn: CGRect(x: scaledPoint.x - 6, y: scaledPoint.y - 6, width: 12, height: 12)),
                    with: .color(.blue),
                    lineWidth: 2
                )

                // Orientation line
                let lineLength: CGFloat = 15
                let endX = scaledPoint.x + cos(CGFloat(orb.angle)) * lineLength
                let endY = scaledPoint.y + sin(CGFloat(orb.angle)) * lineLength

                var path = Path()
                path.move(to: scaledPoint)
                path.addLine(to: CGPoint(x: endX, y: endY))

                context.stroke(
                    path,
                    with: .color(.blue),
                    lineWidth: 2
                )
            }
        }
    }
}

#Preview {
    ContentView()
}
