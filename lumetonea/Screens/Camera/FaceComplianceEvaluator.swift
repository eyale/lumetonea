import Foundation
import Vision
import CoreVideo
import CoreGraphics

struct FaceDebugInfo {
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

struct FaceComplianceTargets {
    let targetFaceHeight: CGFloat?
    let targetCenterX: CGFloat?
    let targetCenterY: CGFloat?
    let targetYawDeg: Double?
    let targetRollDeg: Double?
    let sizeTolerancePct: CGFloat
    let centerToleranceAbs: CGFloat
    let angleToleranceDeg: Double
}

final class FaceComplianceEvaluator {
    func evaluate(face: VNFaceObservation, pixelBuffer: CVPixelBuffer, targets: FaceComplianceTargets) -> (Bool, FaceDebugInfo) {
        let frameWidth = CGFloat(CVPixelBufferGetWidth(pixelBuffer))
        let frameHeight = CGFloat(CVPixelBufferGetHeight(pixelBuffer))
        let rect = VNImageRectForNormalizedRect(face.boundingBox, Int(frameWidth), Int(frameHeight))

        let faceHeightRatio = (rect.height / frameHeight)
        let sizeOK: Bool = {
            if let t = targets.targetFaceHeight {
                let minT = max(0.0, t * (1.0 - targets.sizeTolerancePct))
                let maxT = min(1.0, t * (1.0 + targets.sizeTolerancePct))
                return faceHeightRatio >= minT && faceHeightRatio <= maxT
            } else {
                return faceHeightRatio >= 0.23 && faceHeightRatio <= 0.40
            }
        }()

        let center = CGPoint(x: rect.midX / frameWidth, y: rect.midY / frameHeight)
        let offsetX = center.x - 0.5
        let offsetY = center.y - 0.5
        let centerOK: Bool = {
            if let tx = targets.targetCenterX, let ty = targets.targetCenterY {
                return abs(center.x - tx) <= targets.centerToleranceAbs && abs(center.y - ty) <= targets.centerToleranceAbs
            } else {
                return abs(offsetX) <= 0.2 && abs(offsetY) <= 0.2
            }
        }()

        func angleDeltaDegrees(_ aRad: Double, _ bDegTarget: Double) -> Double {
            let bRad = bDegTarget * .pi / 180.0
            let diff = atan2(sin(aRad - bRad), cos(aRad - bRad))
            return abs(diff) * 180.0 / .pi
        }

        let yawOK: Bool = {
            guard let yaw = face.yaw?.doubleValue else { return true }
            if let target = targets.targetYawDeg {
                return angleDeltaDegrees(yaw, target) <= targets.angleToleranceDeg
            } else {
                return abs(yaw) <= (10.0 * .pi / 180.0)
            }
        }()
        let rollOK: Bool = {
            guard let roll = face.roll?.doubleValue else { return true }
            if let target = targets.targetRollDeg {
                return angleDeltaDegrees(roll, target) <= targets.angleToleranceDeg
            } else {
                let rollAbs = abs(roll)
                let normalized = min(rollAbs, abs(.pi - rollAbs))
                return normalized <= (10.0 * .pi / 180.0)
            }
        }()

        let compliant = sizeOK && centerOK && yawOK && rollOK

        let info = FaceDebugInfo(
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

    func guidance(face: VNFaceObservation, pixelBuffer: CVPixelBuffer, targets: FaceComplianceTargets) -> String {
        let frameWidth = CGFloat(CVPixelBufferGetWidth(pixelBuffer))
        let frameHeight = CGFloat(CVPixelBufferGetHeight(pixelBuffer))
        let rect = VNImageRectForNormalizedRect(face.boundingBox, Int(frameWidth), Int(frameHeight))

        let size = rect.height / frameHeight
        if let t = targets.targetFaceHeight {
            if size < t * (1.0 - targets.sizeTolerancePct) { return "Move closer" }
            if size > t * (1.0 + targets.sizeTolerancePct) { return "Move back" }
        } else {
            if size < 0.23 { return "Move closer" }
            if size > 0.40 { return "Move back" }
        }

        let center = CGPoint(x: rect.midX / frameWidth, y: rect.midY / frameHeight)
        if let tx = targets.targetCenterX, let ty = targets.targetCenterY {
            if center.x < tx - targets.centerToleranceAbs { return "Move right" }
            if center.x > tx + targets.centerToleranceAbs { return "Move left" }
            if center.y < ty - targets.centerToleranceAbs { return "Lower camera" }
            if center.y > ty + targets.centerToleranceAbs { return "Raise camera" }
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
}

