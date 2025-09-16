import SwiftUI
import UIKit
import Observation
import Vision

@Observable
final class AnalysisResultViewModel {
    var processing = false
    var result: SkinToneResult?

    // Previously used for torso overlay; you can keep it if useful.
    var torsoPoints: [CGPoint]?

    // New: normalized Y of the chin in full-image Vision coordinates (0…1, origin at bottom).
    // AnalysisResultView converts this to view space using (1 - y) * height.
    var chinYNormalized: CGFloat?

    let debug = true

    func analyze(image: UIImage?) {
        guard let image = image else { return }
        if debug { print("[Analyze] start") }
        processing = true

        // Run both detections; they’re independent.
        detectTorso(in: image)
        detectChin(in: image)

        // Existing skin tone analysis
        SkinToneExtractor().analyze(image: image) { [weak self] result in
            if self?.debug == true { print("[Analyze] skin tone result=\(result != nil ? "ok" : "nil")") }
            self?.result = result
            self?.processing = false
        }
    }

    private func detectTorso(in image: UIImage) {
        guard let cg = image.cgImage else { return }
        let request = VNDetectHumanBodyPoseRequest()
        let orientation = CGImagePropertyOrientation(image)
        if debug { print("[Torso] orientation=\(orientation.rawValue)") }
        let handler = VNImageRequestHandler(cgImage: cg, orientation: orientation, options: [:])
        do {
            try handler.perform([request])
            guard let obs = request.results?.first else {
                if debug { print("[Torso] no observations") }
                torsoPoints = nil
                return
            }
            let points = try? obs.recognizedPoints(.all)
            if debug { print("[Torso] points keys=\(points?.keys)") }
            guard let ls = points?[.leftShoulder],
                  let rs = points?[.rightShoulder],
                  let lh = points?[.leftHip],
                  let rh = points?[.rightHip],
                  ls.confidence > 0.1,
                  rs.confidence > 0.1,
                  lh.confidence > 0.1,
                  rh.confidence > 0.1 else {
                if debug { print("[Torso] missing or low-confidence points") }
                torsoPoints = nil
                return
            }
            torsoPoints = [ls, rs, rh, lh].map { CGPoint(x: CGFloat($0.x), y: CGFloat($0.y)) }
            if debug { print("[Torso] torsoPoints=\(torsoPoints ?? [])") }
        } catch {
            if debug { print("[Torso] error=\(error)") }
            torsoPoints = nil
        }
    }

    private func detectChin(in image: UIImage) {
        guard let cg = image.cgImage else { return }

        let request = VNDetectFaceLandmarksRequest()
        let orientation = CGImagePropertyOrientation(image)
        if debug { print("[Chin] orientation=\(orientation.rawValue)") }
        let handler = VNImageRequestHandler(cgImage: cg, orientation: orientation, options: [:])

        do {
            try handler.perform([request])
        } catch {
            if debug { print("[Chin] Vision error: \(error.localizedDescription)") }
            chinYNormalized = nil
            return
        }

        guard let face = request.results?.first as? VNFaceObservation else {
            if debug { print("[Chin] no face") }
            chinYNormalized = nil
            return
        }

        // Prefer faceContour if available; otherwise approximate using bounding box bottom.
        if let contour = face.landmarks?.faceContour, contour.pointCount > 0 {
            let normPoints = contour.normalizedPoints

            // Vision landmark points are normalized within the face bounding box (origin bottom-left of the face box).
            // Convert each to full-image normalized space using the face.boundingBox (also normalized in image space).
            // face.boundingBox: (x,y,width,height) in normalized image coordinates, origin bottom-left.
            var minY: CGFloat = .greatestFiniteMagnitude
            for p in normPoints {
                let px = CGFloat(p.x)
                let py = CGFloat(p.y)
                // Map to image-normalized coordinates
                let imgX = face.boundingBox.origin.x + px * face.boundingBox.size.width
                let imgY = face.boundingBox.origin.y + py * face.boundingBox.size.height
                if imgY < minY { minY = imgY }
                if debug {
                    // Uncomment to log mapped points
                    // print(String(format: "[Chin] mapped point (%.3f, %.3f) -> (%.3f, %.3f)", px, py, imgX, imgY))
                }
            }

            if minY.isFinite {
                chinYNormalized = min(max(minY, 0), 1) // clamp just in case
                if debug { print(String(format: "[Chin] chinYNormalized=%.4f", chinYNormalized ?? -1)) }
            } else {
                chinYNormalized = face.boundingBox.minY
                if debug { print(String(format: "[Chin] fallback chinYNormalized (bbox)=%.4f", chinYNormalized ?? -1)) }
            }
        } else {
            // Fallback: use bottom of face bounding box
            chinYNormalized = face.boundingBox.minY
            if debug { print(String(format: "[Chin] no contour; bbox.minY=%.4f", chinYNormalized ?? -1)) }
        }
    }
}
