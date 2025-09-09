import SwiftUI
import UIKit

struct ConfirmPhotoView: View {
    let image: UIImage?
    @StateObject private var viewModel = ConfirmPhotoViewModel()

    var body: some View {
        VStack(spacing: 24) {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .frame(height: 300)
            } else {
                Text("No image selected")
                    .primaryText()
            }

            Button(action: { viewModel.confirmPhoto() }) {
                Text("Confirm Photo")
            }
            .primaryButton()
        }
        .padding()
        .background(Color.white)
        .navigationTitle("Confirm")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $viewModel.navigateToAnalysis) {
            AnalysisResultView(image: image)
        }
    }
}

#Preview {
    ConfirmPhotoView(image: nil)
}

