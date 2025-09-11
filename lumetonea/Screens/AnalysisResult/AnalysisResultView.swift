import SwiftUI
import UIKit

struct AnalysisResultView: View {
    let image: UIImage?
    @State private var viewModel = AnalysisResultViewModel()
    let topHeight = UIScreen.main.bounds.height * 0.5

    var body: some View {
        @Bindable var viewModel = viewModel
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .clipped()
                        .ignoresSafeArea(edges: .top)
                } else {
                    Text("No image provided")
                        .primaryText()
                }
            }
            .frame(height: topHeight, alignment: .top)
            Spacer()
            controlsView
            Spacer()
        }
        .background(Color.white)
        .navigationTitle("Result")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { viewModel.analyze(image: image) }
    }

    var controlsView: some View {
        VStack(spacing: 16) {
            if let result = viewModel.result {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Results")
                        .font(.headline)
                        .primaryText()
                    Text("Undertone: \(result.temperature == .warm ? "Warm" : "Cool")")
                        .primaryText()
                    Text(result.temperature == .warm
                         ? "Warm = more red/yellow undertones (higher a*)."
                         : "Cool = more blue/green undertones (lower a*).")
                        .font(.footnote)
                        .foregroundColor(.gray)
                    Text("Shade: \(result.shade == .light ? "Light" : "Dark")")
                        .primaryText()
                    Text("Shade is based on L* (perceptual lightness). Higher L* looks lighter.")
                        .font(.footnote)
                        .foregroundColor(.gray)
                    Text(String(format: "LAB ≈ L=%.1f a=%.1f b=%.1f", result.lab.l, result.lab.a, result.lab.b))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }
        }
        .padding()
    }
}

#Preview {
    AnalysisResultView(image: UIImage(named: "develop/person"))
}
