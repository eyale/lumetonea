import SwiftUI
import UIKit
import Observation

struct ConfirmPhotoView: View {
    let image: UIImage?
    @State private var viewModel = ConfirmPhotoViewModel()

    var body: some View {
        @Bindable var viewModel = viewModel

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

