import SwiftUI
import Observation

@Observable
final class ConfirmPhotoViewModel {
    var navigateToAnalysis = false

    func confirmPhoto() {
        navigateToAnalysis = true
    }
}

