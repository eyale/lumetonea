import SwiftUI
import UIKit

final class AnalysisResultViewModel: ObservableObject {
    @Published var processing = false
    @Published var result: SkinToneResult?

    func analyze(image: UIImage?) {
        guard let image = image else { return }
        processing = true
        SkinToneExtractor().analyze(image: image) { [weak self] result in
            self?.result = result
            self?.processing = false
        }
    }
}

