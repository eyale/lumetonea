import SwiftUI
import UIKit
import Observation
import Vision

@Observable
final class AnalysisResultViewModel {
    var processing = false
    var result: SkinToneResult?
    var torsoPoints: [CGPoint]?
    let debug = true

    func analyze(image: UIImage?) {
        guard let image = image else { return }
        if debug { print("[Recolor] analyze(): start") }
        processing = true
        detectTorso(in: image)
        SkinToneExtractor().analyze(image: image) { [weak self] result in
            if self?.debug == true { print("[Recolor] analyze(): result=\(result != nil ? "ok" : "nil")") }
            self?.result = result
            self?.processing = false
        }
    }
    private func detectTorso(in image: UIImage) {
        guard let cg = image.cgImage else { return }
        let request = VNDetectHumanBodyPoseRequest()
        let orientation = CGImagePropertyOrientation(image)
        if debug { print("[Recolor] detectTorso(): orientation=\(orientation.rawValue)") }
        let handler = VNImageRequestHandler(cgImage: cg, orientation: orientation, options: [:])
        do {
            try handler.perform([request])
            guard let obs = request.results?.first else {
                if debug { print("[Recolor] detectTorso(): no observations") }
                torsoPoints = nil
                return
            }
            let points = try? obs.recognizedPoints(.all)
            if debug { print("[Recolor] detectTorso(): points keys=\(points?.keys)") }
            guard let ls = points?[.leftShoulder],
                  let rs = points?[.rightShoulder],
                  let lh = points?[.leftHip],
                  let rh = points?[.rightHip],
                  ls.confidence > 0.1,
                  rs.confidence > 0.1,
                  lh.confidence > 0.1,
                  rh.confidence > 0.1 else {
                if debug { print("[Recolor] detectTorso(): missing or low-confidence points") }
                torsoPoints = nil
                return
            }
            if debug {
                print("[Recolor] detectTorso(): ls=\(ls), rs=\(rs), lh=\(lh), rh=\(rh)")
            }
            torsoPoints = [ls, rs, rh, lh].map { CGPoint(x: CGFloat($0.x), y: CGFloat($0.y)) }
            if debug {
                print("[Recolor] detectTorso(): torsoPoints=\(torsoPoints ?? [])")
            }
        } catch {
            if debug { print("[Recolor] detectTorso(): error=\(error)") }
            torsoPoints = nil
        }
    }
}
