import UIKit
import Vision
import CoreImage
import CoreImage.CIFilterBuiltins

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

final class SkinToneExtractor {
    private let context = CIContext()

    func analyze(image: UIImage, completion: @escaping (SkinToneResult?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            guard let cgImage = image.cgImage else {
                DispatchQueue.main.async { completion(nil) }
                return
            }

            let request = VNDetectFaceLandmarksRequest()
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

            do {
                try handler.perform([request])
            } catch {
                DispatchQueue.main.async { completion(nil) }
                return
            }

            guard let face = request.results?.first as? VNFaceObservation else {
                DispatchQueue.main.async { completion(nil) }
                return
            }

            let colors = self.sampleSkinColors(from: cgImage, face: face)
            guard !colors.isEmpty else {
                DispatchQueue.main.async { completion(nil) }
                return
            }

            var labs: [SkinToneResult.LAB] = []
            for color in colors {
                if let lab = self.rgbToLab(color) {
                    labs.append(SkinToneResult.LAB(l: lab.0, a: lab.1, b: lab.2))
                }
            }
            guard !labs.isEmpty else {
                DispatchQueue.main.async { completion(nil) }
                return
            }

            let sum = labs.reduce((l: CGFloat(0), a: CGFloat(0), b: CGFloat(0))) { acc, lab in
                (acc.l + lab.l, acc.a + lab.a, acc.b + lab.b)
            }
            let count = CGFloat(labs.count)
            let avg = SkinToneResult.LAB(l: sum.l / count, a: sum.a / count, b: sum.b / count)

            let temperature: SkinToneResult.Temperature = avg.a >= 0 ? .warm : .cool
            let shade: SkinToneResult.Shade = avg.l >= 50 ? .light : .dark

            let result = SkinToneResult(lab: avg, temperature: temperature, shade: shade)
            DispatchQueue.main.async { completion(result) }
        }
    }

    private func sampleSkinColors(from cgImage: CGImage, face: VNFaceObservation) -> [UIColor] {
        guard let landmarks = face.landmarks else { return [] }
        var points: [CGPoint] = []

        let imageSize = CGSize(width: cgImage.width, height: cgImage.height)
        let faceRect = VNImageRectForNormalizedRect(face.boundingBox, Int(imageSize.width), Int(imageSize.height))

        // Approximate cheek positions using the face bounding box
        let leftCheek = CGPoint(x: faceRect.minX + faceRect.width * 0.3, y: faceRect.midY)
        let rightCheek = CGPoint(x: faceRect.maxX - faceRect.width * 0.3, y: faceRect.midY)
        points.append(contentsOf: [leftCheek, rightCheek])

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
        let rect = CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)
        let ciImage = CIImage(cgImage: cgImage).cropped(to: rect)
        let filter = CIFilter.areaAverage()
        filter.inputImage = ciImage
        guard let output = filter.outputImage else { return nil }
        var bitmap = [UInt8](repeating: 0, count: 4)
        context.render(output,
                       toBitmap: &bitmap,
                       rowBytes: 4,
                       bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
                       format: .RGBA8,
                       colorSpace: CGColorSpaceCreateDeviceRGB())
        return UIColor(red: CGFloat(bitmap[0]) / 255.0,
                       green: CGFloat(bitmap[1]) / 255.0,
                       blue: CGFloat(bitmap[2]) / 255.0,
                       alpha: 1)
    }

    private func rgbToLab(_ color: UIColor) -> (CGFloat, CGFloat, CGFloat)? {
        // Convert the color into the generic Lab color space using Core Graphics
        guard let labColor = color.cgColor.converted(to: CGColorSpace(name: CGColorSpace.genericLab)!,
                                                    intent: .perceptual,
                                                    options: nil),
              let components = labColor.components,
              components.count >= 3 else {
            return nil
        }

        // Components are in 0-1 range; scale to conventional Lab values
        let l = components[0] * 100.0
        let a = (components[1] * 255.0) - 128.0
        let b = (components[2] * 255.0) - 128.0
        return (CGFloat(l), CGFloat(a), CGFloat(b))
    }
}
