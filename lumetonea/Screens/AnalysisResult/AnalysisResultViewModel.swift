import SwiftUI
import UIKit
import Observation

@Observable
final class AnalysisResultViewModel {
    var processing = false
    var result: SkinToneResult?

    func analyze(image: UIImage?) {
        guard let image = image else { return }
        processing = true
        SkinToneExtractor().analyze(image: image) { [weak self] result in
            self?.result = result
            self?.processing = false
        }
    }
}

