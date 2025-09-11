import SwiftUI
import UIKit
import Observation

struct ConfirmPhotoView: View {
    let image: UIImage?
    @State private var viewModel = ConfirmPhotoViewModel()

    var body: some View {
        @Bindable var viewModel = viewModel

        VStack(spacing: 0) {
            // Top image takes 2/3 of screen height, aligned to top, ignoring safe area
            if let image = image {
                let topHeight = UIScreen.main.bounds.height * (2.0/3.0)
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: topHeight, alignment: .top)
                    .clipped()
                    .ignoresSafeArea(edges: .top)
            } else {
                Text("No image selected")
                    .primaryText()
            }

            Spacer()

            // Controls area
            VStack(spacing: 16) {
                Button(action: { viewModel.confirmPhoto() }) {
                    Text("Confirm Photo")
                }
                .primaryButton()
                .padding()
            }
            .padding()
        }
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
