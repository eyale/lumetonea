import UIKit

extension UIImage {
    /// Returns a copy of the image with its orientation normalized to `.up`,
    /// removing any mirrored or rotated state.
    func normalizedOrientation() -> UIImage {
        var image = self

        if image.imageOrientation.isMirrored {
            image = image.withHorizontallyFlippedOrientation()
        }
        if image.imageOrientation == .up { return image }

        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        image.draw(in: CGRect(origin: .zero, size: image.size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return normalizedImage ?? image
    }
}

private extension UIImage.Orientation {
    var isMirrored: Bool {
        switch self {
        case .upMirrored, .downMirrored, .leftMirrored, .rightMirrored:
            return true
        default:
            return false
        }
    }
}
