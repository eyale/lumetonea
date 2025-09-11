import UIKit
import Vision
import CoreImage
import CoreImage.CIFilterBuiltins

/// Result of the skin tone analysis including LAB color values, temperature and shade.
struct SkinToneResult {
    struct LAB {
        let l: CGFloat
        let a: CGFloat
        let b: CGFloat
    }

    enum Temperature {
        case warm
        case cool
    }

    enum Shade {
        case light
        case dark
    }

    let lab: LAB
    let temperature: Temperature
    let shade: Shade
}

private extension CGImagePropertyOrientation {
    init(_ ui: UIImage.Orientation) {
        switch ui {
        case .up: self = .up
        case .down: self = .down
        case .left: self = .left
        case .right: self = .right
        case .upMirrored: self = .upMirrored
        case .downMirrored: self = .downMirrored
        case .leftMirrored: self = .leftMirrored
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
    }
}

/// Utility responsible for sampling prominent skin areas on a face and estimating overall tone.
final class SkinToneExtractor {
    private let context = CIContext()
    private let debug = true

    /// Performs asynchronous skin tone analysis of the provided image.
    /// - Parameters:
    ///   - image: Source image containing a face.
    ///   - completion: Callback on the main thread with `SkinToneResult` or `nil` on failure.
    func analyze(image: UIImage, completion: @escaping (SkinToneResult?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            if self.debug {
                print("[SkinTone] analyze: start")
                print("[SkinTone] image.size=\(image.size), scale=\(image.scale), orientation=\(image.imageOrientation.rawValue)")
            }
            guard let cgImage = image.cgImage else {
                if self.debug { print("[SkinTone] no cgImage; aborting") }
                DispatchQueue.main.async { completion(nil) }
                return
            }

            let request = VNDetectFaceLandmarksRequest()
            let cgOrientation = CGImagePropertyOrientation(image.imageOrientation)
            if self.debug { print("[SkinTone] using CGImagePropertyOrientation=\(cgOrientation.rawValue)") }
            let handler = VNImageRequestHandler(cgImage: cgImage, orientation: cgOrientation, options: [:])

            do {
                try handler.perform([request])
                if self.debug { print("[SkinTone] VNDetectFaceLandmarksRequest performed") }
            } catch {
                if self.debug { print("[SkinTone] Vision error: \(error.localizedDescription)") }
                DispatchQueue.main.async { completion(nil) }
                return
            }

            if self.debug { print("[SkinTone] faces detected: \(request.results?.count ?? 0)") }
            guard let face = request.results?.first as? VNFaceObservation else {
                if self.debug { print("[SkinTone] no face; aborting") }
                DispatchQueue.main.async { completion(nil) }
                return
            }

            let colors = self.sampleSkinColors(from: cgImage, face: face)
            if self.debug { print("[SkinTone] sampled colors count: \(colors.count)") }
            guard !colors.isEmpty else {
                if self.debug { print("[SkinTone] no colors sampled; aborting") }
                DispatchQueue.main.async { completion(nil) }
                return
            }

            var labs: [SkinToneResult.LAB] = []
            for color in colors {
                if let lab = self.rgbToLab(color) {
                    labs.append(SkinToneResult.LAB(l: lab.0, a: lab.1, b: lab.2))
                }
            }
            if self.debug {
                for (idx, lab) in labs.enumerated() {
                    print(String(format: "[SkinTone] lab[%02d] L=%.1f a=%.1f b=%.1f", idx, lab.l, lab.a, lab.b))
                }
            }
            guard !labs.isEmpty else {
                if self.debug { print("[SkinTone] lab conversion empty; aborting") }
                DispatchQueue.main.async { completion(nil) }
                return
            }

            let sum = labs.reduce((l: CGFloat(0), a: CGFloat(0), b: CGFloat(0))) { acc, lab in
                (acc.l + lab.l, acc.a + lab.a, acc.b + lab.b)
            }
            let count = CGFloat(labs.count)
            let avg = SkinToneResult.LAB(l: sum.l / count, a: sum.a / count, b: sum.b / count)
            if self.debug {
                print(String(format: "[SkinTone] avg L=%.1f a=%.1f b=%.1f", avg.l, avg.a, avg.b))
            }

            let temperature: SkinToneResult.Temperature = avg.a >= 0 ? .warm : .cool
            let shade: SkinToneResult.Shade = avg.l >= 50 ? .light : .dark
            if self.debug {
                print("[SkinTone] temperature decision: a>=0 ? warm:cool -> a=\(String(format: "%.2f", avg.a)) => \(temperature == .warm ? "warm" : "cool")")
                print("[SkinTone] shade decision: L>=50 ? light:dark -> L=\(String(format: "%.2f", avg.l)) => \(shade == .light ? "light" : "dark")")
            }

            let result = SkinToneResult(lab: avg, temperature: temperature, shade: shade)
            DispatchQueue.main.async {
                if self.debug { print("[SkinTone] analyze: done") }
                completion(result)
            }
        }
    }

    private func sampleSkinColors(from cgImage: CGImage, face: VNFaceObservation) -> [UIColor] {
        guard let landmarks = face.landmarks else { return [] }
        var points: [CGPoint] = []

        let imageSize = CGSize(width: cgImage.width, height: cgImage.height)
        let faceRect = VNImageRectForNormalizedRect(face.boundingBox, Int(imageSize.width), Int(imageSize.height))
        if debug {
            print(String(format: "[SkinTone] faceRect x=%.0f y=%.0f w=%.0f h=%.0f", faceRect.origin.x, faceRect.origin.y, faceRect.width, faceRect.height))
        }

        // Approximate cheek positions using the face bounding box
        let leftCheek = CGPoint(x: faceRect.minX + faceRect.width * 0.3, y: faceRect.midY)
        let rightCheek = CGPoint(x: faceRect.maxX - faceRect.width * 0.3, y: faceRect.midY)
        points.append(contentsOf: [leftCheek, rightCheek])
        if debug {
            print(String(format: "[SkinTone] pts cheeks L(%.0f,%.0f) R(%.0f,%.0f)", leftCheek.x, leftCheek.y, rightCheek.x, rightCheek.y))
        }

        // Estimate a forehead point using the eyes as a reference
        if let leftEye = landmarks.leftEye?.normalizedPoints.first,
           let rightEye = landmarks.rightEye?.normalizedPoints.first {
            let left = self.point(from: leftEye, in: face, imageSize: imageSize)
            let right = self.point(from: rightEye, in: face, imageSize: imageSize)
            let midX = (left.x + right.x) / 2
            let maxY = max(left.y, right.y)
            let foreheadY = min(faceRect.maxY, maxY + faceRect.height * 0.15)
            let forehead = CGPoint(x: midX, y: foreheadY)
            points.append(forehead)
            if debug {
                print(String(format: "[SkinTone] pt forehead (%.0f,%.0f)", forehead.x, forehead.y))
            }
        }

        return points.compactMap { self.averageColor(at: $0, in: cgImage, radius: 10) }
    }

    private func point(from normalized: CGPoint, in face: VNFaceObservation, imageSize: CGSize) -> CGPoint {
        let bounding = VNImageRectForNormalizedRect(face.boundingBox, Int(imageSize.width), Int(imageSize.height))
        let x = bounding.origin.x + normalized.x * bounding.size.width
        let y = bounding.origin.y + normalized.y * bounding.size.height
        return CGPoint(x: x, y: y)
    }

    private func averageColor(at point: CGPoint, in cgImage: CGImage, radius: CGFloat) -> UIColor? {
        // sampleRect is in a bottom-left origin space (Vision). Convert to CGImage pixel space (top-left origin)
        let rectBL = CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)
        let imgW = CGFloat(cgImage.width), imgH = CGFloat(cgImage.height)
        let clampedBL = rectBL.intersection(CGRect(x: 0, y: 0, width: imgW, height: imgH))
        guard clampedBL.width > 0, clampedBL.height > 0 else { return nil }
        let rectTL = CGRect(x: clampedBL.origin.x,
                            y: imgH - clampedBL.origin.y - clampedBL.height,
                            width: clampedBL.width,
                            height: clampedBL.height)

        guard let crop = cgImage.cropping(to: rectTL) else {
            if debug { print("[SkinTone] cgImage.cropping returned nil for rectTL=\(rectTL)") }
            return nil
        }

        let w = Int(rectTL.width)
        let h = Int(rectTL.height)
        let bytesPerPixel = 4
        let bytesPerRow = w * bytesPerPixel
        let bitsPerComponent = 8
        var buf = [UInt8](repeating: 0, count: w * h * bytesPerPixel)
        guard let ctx = CGContext(data: &buf,
                                  width: w,
                                  height: h,
                                  bitsPerComponent: bitsPerComponent,
                                  bytesPerRow: bytesPerRow,
                                  space: CGColorSpaceCreateDeviceRGB(),
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        ctx.draw(crop, in: CGRect(x: 0, y: 0, width: w, height: h))

        var rSum: UInt64 = 0, gSum: UInt64 = 0, bSum: UInt64 = 0, count: UInt64 = 0
        for y in 0..<h {
            let row = y * bytesPerRow
            for x in 0..<w {
                let i = row + x * bytesPerPixel
                rSum += UInt64(buf[i])
                gSum += UInt64(buf[i+1])
                bSum += UInt64(buf[i+2])
                count += 1
            }
        }
        guard count > 0 else { return nil }
        let r = CGFloat(Double(rSum) / Double(count)) / 255.0
        let g = CGFloat(Double(gSum) / Double(count)) / 255.0
        let b = CGFloat(Double(bSum) / Double(count)) / 255.0
        if debug {
            print(String(format: "[SkinTone] sample RGB r=%.3f g=%.3f b=%.3f at BL(%.0f,%.0f) TL(%.0f,%.0f) w=%.0f h=%.0f",
                         r, g, b, clampedBL.midX, clampedBL.midY, rectTL.midX, rectTL.midY, rectTL.width, rectTL.height))
        }
        return UIColor(red: r, green: g, blue: b, alpha: 1)
    }

    private func rgbToLab(_ color: UIColor) -> (CGFloat, CGFloat, CGFloat)? {
        // Convert sRGB -> CIE XYZ (D65) -> CIE L*a*b* using standard formulas
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard color.getRed(&r, green: &g, blue: &b, alpha: &a) else { return nil }

        func invGamma(_ u: CGFloat) -> CGFloat {
            return (u <= 0.04045) ? (u / 12.92) : pow((u + 0.055) / 1.055, 2.4)
        }

        let Rl = invGamma(r)
        let Gl = invGamma(g)
        let Bl = invGamma(b)

        // sRGB to XYZ (D65)
        let X = (0.4124564 * Rl + 0.3575761 * Gl + 0.1804375 * Bl)
        let Y = (0.2126729 * Rl + 0.7151522 * Gl + 0.0721750 * Bl)
        let Z = (0.0193339 * Rl + 0.1191920 * Gl + 0.9503041 * Bl)

        // Reference white (D65)
        let Xr: CGFloat = 0.95047
        let Yr: CGFloat = 1.00000
        let Zr: CGFloat = 1.08883

        func f(_ t: CGFloat) -> CGFloat {
            let delta: CGFloat = 6.0 / 29.0
            let delta3 = delta * delta * delta
            if t > delta3 { return pow(t, 1.0 / 3.0) }
            return t / (3 * delta * delta) + 4.0 / 29.0
        }

        let fx = f(X / Xr)
        let fy = f(Y / Yr)
        let fz = f(Z / Zr)

        let Lstar = 116 * fy - 16
        let astar = 500 * (fx - fy)
        let bstar = 200 * (fy - fz)

        return (Lstar, astar, bstar)
    }
}
