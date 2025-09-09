import SwiftUI
import AVFoundation
import Vision
import UIKit

// MARK: - SwiftUI Camera Screen
struct CameraView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var camera = CameraViewModel()
    // Feature flag: set to true to reveal debug HUD and calibration controls
    @State private var debugEnabled = false

    var onCapture: (UIImage) -> Void

    var body: some View {
        ZStack {
            CameraPreview(session: camera.session)
                .ignoresSafeArea()

            // Overlay border indicating detection/compliance status
            GeometryReader { geo in
                let status = camera.complianceStatus
                let color: Color = {
                    switch status {
                    case .compliant: return .green
                    case .noFace, .notCompliant: return .red
                    case .detecting: return .yellow
                    }
                }()

                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(color, lineWidth: 5)
                    .padding(24)

                // Optional guidance text
                VStack {
                    HStack { Spacer() }
                    Spacer()
                    Text(camera.statusMessage)
                        .font(.footnote)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(.ultraThinMaterial, in: Capsule())
                        .padding(.bottom, 150)
                }

                if debugEnabled, let d = camera.debugInfo {
                    VStack(alignment: .leading, spacing: 4) {
                        if let tf = camera.targetFaceHeight, let tx = camera.targetCenterX, let ty = camera.targetCenterY {
                            Text(String(format: "targets: face %.1f%%%% ±10%%%%, center (x=%.3f y=%.3f) ±0.10, yaw/roll ±18°", tf * 100, tx, ty))
                        } else {
                            Text("targets: face 23–40%, center ±0.20, yaw/roll ±10°")
                        }
                        Text("faceHeight: \(String(format: "%.1f%%", d.faceHeightRatio * 100))")
                        Text(String(format: "center: x=%.3f y=%.3f", d.centerX, d.centerY))
                        Text(String(format: "offset: x=%.3f y=%.3f", d.centerOffsetX, d.centerOffsetY))
                        Text("yaw: \(d.yawDeg.map { String(format: "%.1f°", $0) } ?? "--")  roll: \(d.rollDeg.map { String(format: "%.1f°", $0) } ?? "--")")
                        Text("checks: size=\(d.sizeOK ? "OK" : "NO"), center=\(d.centerOK ? "OK" : "NO"), yaw=\(d.yawOK ? "OK" : "NO"), roll=\(d.rollOK ? "OK" : "NO")")
                    }
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(8)
                    .padding(.top, 60)
                    .padding(.leading, 16)
                }
            }

            // Top controls
            VStack {
                HStack(spacing: 8) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.black.opacity(0.5), in: Circle())
                    }
                    Spacer()
                    if debugEnabled {
                        Button(action: { camera.calibrateFromCurrent() }) {
                            Text("SET")
                                .font(.caption.bold())
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.black.opacity(0.5), in: Capsule())
                        }
                        Button(action: { camera.resetCalibration() }) {
                            Text("CLR")
                                .font(.caption.bold())
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.black.opacity(0.5), in: Capsule())
                        }
                    }
                }
                .padding([.top, .leading, .trailing], 16)

                Spacer()

                // Shutter button
                Button {
                    camera.capturePhoto { image in
                        guard let image else { return }
                        onCapture(image)
                        dismiss()
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.15))
                            .frame(width: 80, height: 80)
                        Circle()
                            .stroke(Color.white, lineWidth: 3)
                            .frame(width: 72, height: 72)
                        Circle()
                            .fill(Color.white)
                            .frame(width: 60, height: 60)
                    }
                }
                .padding(.bottom, 32)
            }
        }
        .task { await camera.configure() }
        .onDisappear { camera.stopSession() }
    }
}

// MARK: - Preview Layer Wrapper
struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {}
}

final class PreviewView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    var videoPreviewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
}

// MARK: - ViewModel + Vision
final class CameraViewModel: NSObject, ObservableObject {
    enum ComplianceStatus { case detecting, noFace, notCompliant, compliant }

    @Published var complianceStatus: ComplianceStatus = .detecting
    @Published var statusMessage: String = "Fit head and shoulders in frame"
    @Published var debugInfo: DebugInfo?

    // Calibration targets (nil = use defaults)
    @Published var targetFaceHeight: CGFloat? = nil
    @Published var targetCenterX: CGFloat? = nil
    @Published var targetCenterY: CGFloat? = nil
    @Published var targetYawDeg: Double? = nil
    @Published var targetRollDeg: Double? = nil

    // Tolerances for calibration mode
    private let sizeTolerancePct: CGFloat = 0.10      // ±10% of target size
    private let centerToleranceAbs: CGFloat = 0.10    // ±0.10 in normalized space
    private let angleToleranceDegCal: Double = 18.0   // ±18° (~10% of 180°)

    struct DebugInfo {
        let faceHeightRatio: CGFloat
        let centerX: CGFloat
        let centerY: CGFloat
        let centerOffsetX: CGFloat
        let centerOffsetY: CGFloat
        let yawDeg: Double?
        let rollDeg: Double?
        let sizeOK: Bool
        let centerOK: Bool
        let yawOK: Bool
        let rollOK: Bool
    }

    let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let queue = DispatchQueue(label: "camera.queue")
    private let sequenceRequestHandler = VNSequenceRequestHandler()
    private var photoDelegates: [PhotoCaptureDelegate] = [] // retain until callbacks fire

    private var lastAnalysisTime = CFAbsoluteTimeGetCurrent()

    func configure() async {
        guard await AVCaptureDevice.requestAccess(for: .video) else { return }

        session.beginConfiguration()
        session.sessionPreset = .photo

        // Input: front camera if available
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            session.commitConfiguration()
            return
        }
        session.addInput(input)

        // Photo output
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
            photoOutput.isHighResolutionCaptureEnabled = true
        }

        // Video frames for Vision
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        if session.canAddOutput(videoOutput) { session.addOutput(videoOutput) }
        videoOutput.setSampleBufferDelegate(self, queue: queue)

        // Mirror the front camera preview for natural UX
        if let conn = videoOutput.connection(with: .video), conn.isVideoMirroringSupported { conn.isVideoMirrored = true }

        session.commitConfiguration()
        session.startRunning()
    }

    func stopSession() {
        session.stopRunning()
    }

    func capturePhoto(completion: @escaping (UIImage?) -> Void) {
        let settings = AVCapturePhotoSettings()
        settings.flashMode = .off
        if let conn = photoOutput.connection(with: .video) {
            conn.videoOrientation = .portrait
            if conn.isVideoMirroringSupported { conn.isVideoMirrored = true }
        }
        let delegate = PhotoCaptureDelegate(owner: self) { image in
            DispatchQueue.main.async {
                completion(image)
            }
        }
        photoDelegates.append(delegate)
        photoOutput.capturePhoto(with: settings, delegate: delegate)
    }

    fileprivate func releaseCaptureDelegate(_ delegate: PhotoCaptureDelegate) {
        photoDelegates.removeAll { $0 === delegate }
    }
}

// MARK: - Sample Buffer Delegate
extension CameraViewModel: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let now = CFAbsoluteTimeGetCurrent()
        // Throttle Vision to ~8 Hz
        guard now - lastAnalysisTime > 0.12 else { return }
        lastAnalysisTime = now

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let request = VNDetectFaceLandmarksRequest { [weak self] req, err in
            guard let self else { return }

            if let faces = req.results as? [VNFaceObservation], let face = faces.first {
                // Evaluate compliance heuristics and collect debug info
                let (compliant, info) = self.evaluate(face: face, frameSize: pixelBuffer)
                DispatchQueue.main.async {
                    self.complianceStatus = compliant ? .compliant : .notCompliant
                    self.statusMessage = compliant ? "Good! Hold steady." : self.guidance(for: face, frameSize: pixelBuffer)
                    self.debugInfo = info
                }
            } else {
                DispatchQueue.main.async {
                    self.complianceStatus = .noFace
                    self.statusMessage = "No face detected"
                    self.debugInfo = nil
                }
            }
        }

        // Front camera buffers are mirrored; set orientation accordingly
        let orientation: CGImagePropertyOrientation = .leftMirrored

        do {
            try sequenceRequestHandler.perform([request], on: pixelBuffer, orientation: orientation)
        } catch {
            // If Vision fails, do not spam the UI
        }
    }

    private func evaluate(face: VNFaceObservation, frameSize pixelBuffer: CVPixelBuffer) -> (Bool, DebugInfo) {
        let frameWidth = CGFloat(CVPixelBufferGetWidth(pixelBuffer))
        let frameHeight = CGFloat(CVPixelBufferGetHeight(pixelBuffer))
        let rect = VNImageRectForNormalizedRect(face.boundingBox, Int(frameWidth), Int(frameHeight))

        // Heuristics derived from passport guidelines or calibrated targets
        let faceHeightRatio = (rect.height / frameHeight)
        let sizeOK: Bool = {
            if let t = targetFaceHeight {
                let minT = max(0.0, t * (1.0 - sizeTolerancePct))
                let maxT = min(1.0, t * (1.0 + sizeTolerancePct))
                return faceHeightRatio >= minT && faceHeightRatio <= maxT
            } else {
                // default: face height ~23–40% of frame to include head + shoulders
                return faceHeightRatio >= 0.23 && faceHeightRatio <= 0.40
            }
        }()

        // - Centering: face center within 20% of frame center
        let center = CGPoint(x: rect.midX / frameWidth, y: rect.midY / frameHeight)
        let offsetX = center.x - 0.5
        let offsetY = center.y - 0.5
        let centerOK: Bool = {
            if let tx = targetCenterX, let ty = targetCenterY {
                return abs(center.x - tx) <= centerToleranceAbs && abs(center.y - ty) <= centerToleranceAbs
            } else {
                return abs(offsetX) <= 0.2 && abs(offsetY) <= 0.2
            }
        }()

        // - Pose: near frontal — small yaw/roll if available
        func angleDeltaDegrees(_ aRad: Double, _ bDegTarget: Double) -> Double {
            // Convert target to radians and compute smallest angular difference
            let bRad = bDegTarget * .pi / 180.0
            let diff = atan2(sin(aRad - bRad), cos(aRad - bRad))
            return abs(diff) * 180.0 / .pi
        }

        let yawOK: Bool = {
            guard let yaw = face.yaw?.doubleValue else { return true }
            if let target = targetYawDeg {
                return angleDeltaDegrees(yaw, target) <= angleToleranceDegCal
            } else {
                return abs(yaw) <= (10.0 * .pi / 180.0)
            }
        }()
        let rollOK: Bool = {
            guard let roll = face.roll?.doubleValue else { return true }
            if let target = targetRollDeg {
                return angleDeltaDegrees(roll, target) <= angleToleranceDegCal
            } else {
                // Normalize roll so that ±π (180°) also counts as level
                let rollAbs = abs(roll)
                let normalized = min(rollAbs, abs(.pi - rollAbs))
                return normalized <= (10.0 * .pi / 180.0)
            }
        }()

        let compliant = sizeOK && centerOK && yawOK && rollOK

        let info = DebugInfo(
            faceHeightRatio: faceHeightRatio,
            centerX: center.x,
            centerY: center.y,
            centerOffsetX: offsetX,
            centerOffsetY: offsetY,
            yawDeg: face.yaw.map { $0.doubleValue * 180.0 / .pi },
            rollDeg: face.roll.map { $0.doubleValue * 180.0 / .pi },
            sizeOK: sizeOK,
            centerOK: centerOK,
            yawOK: yawOK,
            rollOK: rollOK
        )

        return (compliant, info)
    }

    private func guidance(for face: VNFaceObservation, frameSize pixelBuffer: CVPixelBuffer) -> String {
        let frameWidth = CGFloat(CVPixelBufferGetWidth(pixelBuffer))
        let frameHeight = CGFloat(CVPixelBufferGetHeight(pixelBuffer))
        let rect = VNImageRectForNormalizedRect(face.boundingBox, Int(frameWidth), Int(frameHeight))

        let size = rect.height / frameHeight
        if let t = targetFaceHeight {
            if size < t * (1.0 - sizeTolerancePct) { return "Move closer" }
            if size > t * (1.0 + sizeTolerancePct) { return "Move back" }
        } else {
            if size < 0.23 { return "Move closer" }
            if size > 0.40 { return "Move back" }
        }

        let center = CGPoint(x: rect.midX / frameWidth, y: rect.midY / frameHeight)
        if let tx = targetCenterX, let ty = targetCenterY {
            if center.x < tx - centerToleranceAbs { return "Move right" }
            if center.x > tx + centerToleranceAbs { return "Move left" }
            if center.y < ty - centerToleranceAbs { return "Lower camera" }
            if center.y > ty + centerToleranceAbs { return "Raise camera" }
        } else {
            if center.x < 0.3 { return "Move right" }
            if center.x > 0.7 { return "Move left" }
            if center.y < 0.3 { return "Lower camera" }
            if center.y > 0.7 { return "Raise camera" }
        }

        if let yaw = face.yaw?.doubleValue, abs(yaw) > (10.0 * .pi / 180.0) { return "Face camera directly" }
        if let roll = face.roll?.doubleValue, abs(roll) > (10.0 * .pi / 180.0) { return "Keep head level" }

        return "Adjust position"
    }

    // MARK: - Calibration API
    func calibrateFromCurrent() {
        guard let d = debugInfo else { return }
        targetFaceHeight = d.faceHeightRatio
        targetCenterX = d.centerX
        targetCenterY = d.centerY
        targetYawDeg = d.yawDeg
        targetRollDeg = d.rollDeg
    }

    func resetCalibration() {
        targetFaceHeight = nil
        targetCenterX = nil
        targetCenterY = nil
        targetYawDeg = nil
        targetRollDeg = nil
    }
}

// MARK: - Photo Capture Delegate
private final class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    private let completion: (UIImage?) -> Void
    private weak var owner: CameraViewModel?
    init(owner: CameraViewModel, completion: @escaping (UIImage?) -> Void) {
        self.owner = owner
        self.completion = completion
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil else { completion(nil); return }
        guard let data = photo.fileDataRepresentation(), var image = UIImage(data: data) else { completion(nil); return }

        // Normalize orientation and mirror to match preview
        if let cg = image.cgImage {
            image = UIImage(cgImage: cg, scale: image.scale, orientation: .leftMirrored)
        }
        completion(image)
        owner?.releaseCaptureDelegate(self)
    }
}
