import Foundation
import SwiftUI
import AVFoundation
import Vision
import UIKit

final class CameraViewModel: NSObject, ObservableObject {
    enum ComplianceStatus { case detecting, noFace, notCompliant, compliant }

    @Published var complianceStatus: ComplianceStatus = .detecting
    @Published var statusMessage: String = "Fit head and shoulders in frame"
    @Published var debugInfo: FaceDebugInfo?

    // Calibration targets (nil = use defaults)
    @Published var targetFaceHeight: CGFloat? = nil
    @Published var targetCenterX: CGFloat? = nil
    @Published var targetCenterY: CGFloat? = nil
    @Published var targetYawDeg: Double? = nil
    @Published var targetRollDeg: Double? = nil

    // Tolerances
    private let sizeTolerancePct: CGFloat = 0.10
    private let centerToleranceAbs: CGFloat = 0.10
    private let angleToleranceDegCal: Double = 18.0

    let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let queue = DispatchQueue(label: "camera.queue")
    private let sequenceRequestHandler = VNSequenceRequestHandler()
    private var photoDelegates: [PhotoCaptureDelegate] = []
    private let evaluator = FaceComplianceEvaluator()

    private var lastAnalysisTime = CFAbsoluteTimeGetCurrent()

    func configure() async {
        guard await AVCaptureDevice.requestAccess(for: .video) else { return }

        session.beginConfiguration()
        session.sessionPreset = .photo

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            session.commitConfiguration()
            return
        }
        session.addInput(input)

        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
            photoOutput.isHighResolutionCaptureEnabled = true
        }

        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        if session.canAddOutput(videoOutput) { session.addOutput(videoOutput) }
        videoOutput.setSampleBufferDelegate(self, queue: queue)

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
            DispatchQueue.main.async { completion(image) }
        }
        photoDelegates.append(delegate)
        photoOutput.capturePhoto(with: settings, delegate: delegate)
    }

    fileprivate func releaseCaptureDelegate(_ delegate: PhotoCaptureDelegate) {
        photoDelegates.removeAll { $0 === delegate }
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

// MARK: - Sample Buffer Delegate
extension CameraViewModel: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let now = CFAbsoluteTimeGetCurrent()
        guard now - lastAnalysisTime > 0.12 else { return }
        lastAnalysisTime = now

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let faceRequest = VNDetectFaceLandmarksRequest { [weak self] req, _ in
            guard let self else { return }

            if let faces = req.results as? [VNFaceObservation], let face = faces.first {
                let targets = FaceComplianceTargets(
                    targetFaceHeight: self.targetFaceHeight,
                    targetCenterX: self.targetCenterX,
                    targetCenterY: self.targetCenterY,
                    targetYawDeg: self.targetYawDeg,
                    targetRollDeg: self.targetRollDeg,
                    sizeTolerancePct: self.sizeTolerancePct,
                    centerToleranceAbs: self.centerToleranceAbs,
                    angleToleranceDeg: self.angleToleranceDegCal
                )

                let (compliant, info) = self.evaluator.evaluate(face: face, pixelBuffer: pixelBuffer, targets: targets)
                let guidance = self.evaluator.guidance(face: face, pixelBuffer: pixelBuffer, targets: targets)

                DispatchQueue.main.async {
                    self.complianceStatus = compliant ? .compliant : .notCompliant
                    self.statusMessage = compliant ? "Good! Hold steady." : guidance
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

        let orientation: CGImagePropertyOrientation = .leftMirrored
        do { try sequenceRequestHandler.perform([faceRequest], on: pixelBuffer, orientation: orientation) } catch {}
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
        guard error == nil else { completion(nil); owner?.releaseCaptureDelegate(self); return }
        guard let data = photo.fileDataRepresentation(), var image = UIImage(data: data) else { completion(nil); owner?.releaseCaptureDelegate(self); return }
        if let cg = image.cgImage {
            image = UIImage(cgImage: cg, scale: image.scale, orientation: .leftMirrored)
        }
        completion(image)
        owner?.releaseCaptureDelegate(self)
    }
}

