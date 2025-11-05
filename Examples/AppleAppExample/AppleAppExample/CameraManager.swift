//
//  CameraManager.swift
//  AppleAppExample
//
//  Created by Maximilian Alexander on 11/4/25.
//

import AVFoundation
import SwiftUI
import Grayskull

@MainActor
final class CameraManager: NSObject, ObservableObject {
    @Published var originalFrame: CGImage?
    @Published var processedFrame: CGImage?
    @Published var overlayData: OverlayData?
    @Published var isRunning = false
    @Published var error: String?
    @Published var operation: GrayskullOperation = .sobel
    @Published var availableCameras: [AVCaptureDevice] = []
    @Published var selectedCamera: AVCaptureDevice?

    private let captureSession = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let queue = DispatchQueue(label: "camera.queue", qos: .userInteractive)

    enum GrayskullOperation: String, CaseIterable, Identifiable {
        case blur = "blur"
        case thresh = "thresh"
        case adaptive = "adaptive"
        case erode = "erode"
        case dilate = "dilate"
        case sobel = "sobel"
        case otsu = "otsu"
        case blobs = "blobs"
        case keypoints = "keypoints"
        case orb = "orb"

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .blur: return "Gaussian Blur"
            case .thresh: return "Binary Threshold"
            case .adaptive: return "Adaptive Threshold"
            case .erode: return "Erode"
            case .dilate: return "Dilate"
            case .sobel: return "Edge Detection (Sobel)"
            case .otsu: return "Auto Threshold (Otsu)"
            case .blobs: return "Blob Detection"
            case .keypoints: return "FAST Keypoints"
            case .orb: return "ORB Features"
            }
        }
    }

    struct OverlayData {
        var blobs: [BlobAnnotation] = []
        var keypoints: [KeypointAnnotation] = []
        var orbFeatures: [ORBAnnotation] = []
    }

    struct BlobAnnotation {
        let rect: CGRect
        let label: UInt16
        let area: UInt32
    }

    struct KeypointAnnotation {
        let point: CGPoint
        let response: UInt32
    }

    struct ORBAnnotation {
        let point: CGPoint
        let angle: Float
        let response: UInt32
    }

    override init() {
        super.init()
        discoverCameras()
    }

    func discoverCameras() {
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [
                .builtInWideAngleCamera,
                .external,
                #if os(iOS)
                .builtInDualCamera,
                .builtInDualWideCamera,
                .builtInTripleCamera,
                .builtInUltraWideCamera,
                .builtInTelephotoCamera,
                #endif
            ],
            mediaType: .video,
            position: .unspecified
        )

        availableCameras = discoverySession.devices

        // Select front camera by default, or first available
        selectedCamera = availableCameras.first { $0.position == .front } ?? availableCameras.first
    }

    func checkPermissions() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return true
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .video)
        default:
            return false
        }
    }

    func switchCamera(to device: AVCaptureDevice) {
        selectedCamera = device
        if isRunning {
            stopSession()
            Task {
                try? await Task.sleep(nanoseconds: 100_000_000) // 100ms delay
                await startSession()
            }
        }
    }

    func startSession() async {
        guard await checkPermissions() else {
            error = "Camera permission denied"
            return
        }

        guard let camera = selectedCamera else {
            error = "No camera selected"
            return
        }

        captureSession.beginConfiguration()

        // Remove existing inputs
        captureSession.inputs.forEach { captureSession.removeInput($0) }

        // Setup camera input
        guard let input = try? AVCaptureDeviceInput(device: camera) else {
            error = "Failed to access camera"
            captureSession.commitConfiguration()
            return
        }

        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
        }

        // Setup video output
        videoOutput.setSampleBufferDelegate(self, queue: queue)
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]

        if !captureSession.outputs.contains(videoOutput) {
            if captureSession.canAddOutput(videoOutput) {
                captureSession.addOutput(videoOutput)
            }
        }

        captureSession.commitConfiguration()

        queue.async { [weak self] in
            self?.captureSession.startRunning()
            Task { @MainActor [weak self] in
                self?.isRunning = true
                self?.error = nil
            }
        }
    }

    func stopSession() {
        queue.async { [weak self] in
            self?.captureSession.stopRunning()
            Task { @MainActor [weak self] in
                self?.isRunning = false
            }
        }
    }

    private func processFrame(_ pixelBuffer: CVPixelBuffer) -> (processed: CGImage?, overlay: OverlayData?) {
        // Create CGImage from pixel buffer, then use platform extensions
        guard let cgImage = createCGImage(from: pixelBuffer) else {
            return (nil, nil)
        }

        // Use the new platform extension to convert and process
        guard let grayskullImage = try? cgImage.toGrayskullImage() else {
            return (nil, nil)
        }

        // Apply processing based on operation
        var overlayData: OverlayData?
        let processed: GrayskullImage

        switch operation {
        case .blur:
            processed = grayskullImage.filtered(kernel: GrayskullImage.gaussianBlurKernel, normalization: 16)

        case .thresh:
            processed = grayskullImage.thresholded(128)

        case .adaptive:
            processed = grayskullImage.adaptiveThreshold(radius: 5, constant: 10)

        case .erode:
            processed = grayskullImage.eroded()

        case .dilate:
            processed = grayskullImage.dilated()

        case .sobel:
            processed = grayskullImage.sobel()

        case .otsu:
            let threshold = grayskullImage.otsuThreshold()
            processed = grayskullImage.thresholded(threshold)

        case .blobs:
            let threshold = grayskullImage.otsuThreshold()
            let binary = grayskullImage.thresholded(threshold)
            let (_, blobs) = binary.findBlobs(maxBlobs: 100)

            // Create overlay data
            var blobAnnotations: [BlobAnnotation] = []
            for blob in blobs where blob.area > 50 { // Filter small blobs
                let rect = CGRect(
                    x: CGFloat(blob.boundingBox.x),
                    y: CGFloat(blob.boundingBox.y),
                    width: CGFloat(blob.boundingBox.width),
                    height: CGFloat(blob.boundingBox.height)
                )
                blobAnnotations.append(BlobAnnotation(rect: rect, label: blob.label, area: blob.area))
            }
            overlayData = OverlayData(blobs: blobAnnotations)
            processed = binary

        case .keypoints:
            let keypoints = grayskullImage.detectFAST(maxKeypoints: 200, threshold: 20)

            // Create overlay data
            var keypointAnnotations: [KeypointAnnotation] = []
            for kp in keypoints {
                let point = CGPoint(x: CGFloat(kp.point.x), y: CGFloat(kp.point.y))
                keypointAnnotations.append(KeypointAnnotation(point: point, response: kp.response))
            }
            overlayData = OverlayData(keypoints: keypointAnnotations)
            processed = grayskullImage

        case .orb:
            let features = grayskullImage.extractORB(maxKeypoints: 150, threshold: 20)

            // Create overlay data
            var orbAnnotations: [ORBAnnotation] = []
            for feat in features {
                let point = CGPoint(x: CGFloat(feat.point.x), y: CGFloat(feat.point.y))
                orbAnnotations.append(ORBAnnotation(point: point, angle: feat.angle, response: feat.response))
            }
            overlayData = OverlayData(orbFeatures: orbAnnotations)
            processed = grayskullImage
        }

        // Use platform extension to convert back to CGImage
        let processedCGImage = try? processed.toCGImage()

        return (processedCGImage, overlayData)
    }

    private func createCGImage(from pixelBuffer: CVPixelBuffer) -> CGImage? {
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)

        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else {
            return nil
        }

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipFirst.rawValue)

        guard let context = CGContext(
            data: baseAddress,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ) else {
            return nil
        }

        return context.makeImage()
    }
}

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    nonisolated func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }

        let original = createCGImage(from: pixelBuffer)
        let (processed, overlay) = processFrame(pixelBuffer)

        Task { @MainActor [weak self] in
            self?.originalFrame = original
            self?.processedFrame = processed
            self?.overlayData = overlay
        }
    }
}
