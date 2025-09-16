import SwiftUI
import UIKit
import Observation

struct ConfirmPhotoView: View {
    let image: UIImage?
    @State private var viewModel = ConfirmPhotoViewModel()
    let topHeight = UIScreen.main.bounds.height * 0.5
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var nav: NavigationCoordinator

    var body: some View {
        VStack(spacing: 0) {
            imageView
            Spacer()
            ctaButtonView
        }
        .background(Color.white)
        .navigationTitle("Confirm")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $viewModel.navigateToAnalysis) {
            AnalysisResultView(image: image)
        }
        .onChange(of: nav.popToRoot) { _, newValue in
            if newValue {
                nav.popToRoot = false
                dismiss()
            }
        }
    }

    var ctaButtonView: some View {
        Button {
            viewModel.confirmPhoto()
        } label: {
            Text("Confirm Photo")
        }
        .primaryButton()
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
