import SwiftUI
import UIKit
import Observation

@Observable
final class AnalysisResultViewModel {
    var processing = false
    var result: SkinToneResult?
    private let debug = true

    func analyze(image: UIImage?) {
        guard let image = image else { return }
        if debug { print("[Recolor] analyze(): start") }
        processing = true
        SkinToneExtractor().analyze(image: image) { [weak self] result in
            if self?.debug == true { print("[Recolor] analyze(): result=\(result != nil ? "ok" : "nil")") }
            self?.result = result
            self?.processing = false
        }
    }
}
