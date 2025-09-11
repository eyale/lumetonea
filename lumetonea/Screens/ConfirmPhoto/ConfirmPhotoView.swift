import SwiftUI
import UIKit
import Observation

struct ConfirmPhotoView: View {
    let image: UIImage?
    @State private var viewModel = ConfirmPhotoViewModel()
    let topHeight = UIScreen.main.bounds.height * 0.5

    var body: some View {
        VStack(spacing: 0) {
            imageView
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

    var imageView: some View {
        VStack(spacing: 0) {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .clipped()
                    .ignoresSafeArea(edges: .top)
            } else {
                Text("No image selected")
                    .primaryText()
            }
        }
        .frame(height: topHeight, alignment: .top)
    }
}

#Preview {
    ConfirmPhotoView(image: nil)
}
