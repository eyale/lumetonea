import SwiftUI
import AVFoundation
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

// ViewModel, evaluator, and capture delegate moved to:
// - CameraViewModel.swift
// - FaceComplianceEvaluator.swift
