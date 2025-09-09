import SwiftUI
import UIKit

struct AnalysisResultView: View {
    let image: UIImage?
    @StateObject private var viewModel = AnalysisResultViewModel()

    var body: some View {
        VStack(spacing: 24) {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .frame(height: 300)
            } else {
                Text("No image provided")
                    .primaryText()
            }

            if viewModel.processing {
                ProgressView()
            }

            if let result = viewModel.result {
                Text("Tone: \(result.temperature == .warm ? "Warm" : "Cool"), \(result.shade == .light ? "Light" : "Dark")")
                    .primaryText()
            }
        }
        .padding()
        .background(Color.white)
        .navigationTitle("Result")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.analyze(image: image)
        }
    }
}

#Preview {
    AnalysisResultView(image: nil)
}

