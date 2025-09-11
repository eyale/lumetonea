import SwiftUI
import UIKit

struct AnalysisResultView: View {
    let image: UIImage?
    @State private var viewModel = AnalysisResultViewModel()

    var body: some View {
        VStack(spacing: 0) {
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
                Text("No image provided")
                    .primaryText()
            }

            Spacer()
            VStack(spacing: 16) {
                if viewModel.processing {
                    ProgressView()
                }

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
        .background(Color.white)
        .navigationTitle("Result")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.analyze(image: image)
        }
    }
}

#Preview {
    AnalysisResultView(image: UIImage(named: "develop/person"))
}
