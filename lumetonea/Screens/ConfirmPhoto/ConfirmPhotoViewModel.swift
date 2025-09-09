import SwiftUI

final class ConfirmPhotoViewModel: ObservableObject {
    @Published var navigateToAnalysis = false

    func confirmPhoto() {
        navigateToAnalysis = true
    }
}

