import SwiftUI
import UIKit

struct AnalysisResultView: View {
    let image: UIImage?
    @State private var viewModel = AnalysisResultViewModel()
    let topHeight = UIScreen.main.bounds.height * 0.5
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var nav: NavigationCoordinator

    // Appearance for the horizontal chin reference and the area below it
    private let lineColor: Color = .white
    private let lineOpacity: CGFloat = 0.95
    private let lineWidth: CGFloat = 2.0

    // Make underlayColor user-adjustable
    @State private var underlayColor: Color = .white
    @State private var underlayOpacity: CGFloat = 0.55

    var body: some View {
        @Bindable var viewModel = viewModel
        VStack(spacing: 0) {
            ZStack {
                if let image = image {
                    GeometryReader { geo in
                        let size = geo.size
                        ZStack(alignment: .top) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: size.width, height: size.height)
                                .clipped()

                            // Draw a horizontal line at the chin Y and fill below it
                            if let chinYNorm = viewModel.chinYNormalized {
                                // Convert Vision normalized Y (origin bottom, 0..1) to view Y (origin top)
                                let chinYView = (1 - chinYNorm) * size.height

                                // The horizontal chin reference line
                                Path { path in
                                    path.move(to: CGPoint(x: 0, y: chinYView))
                                    path.addLine(to: CGPoint(x: size.width, y: chinYView))
                                }
                                .stroke(lineColor.opacity(lineOpacity), lineWidth: lineWidth)

                                // Highlight under the chin line using the selected color and opacity
                                Rectangle()
                                    .fill(underlayColor.opacity(underlayOpacity))
                                    .frame(width: size.width, height: max(0, size.height - chinYView))
                                    .position(x: size.width / 2, y: chinYView + max(0, size.height - chinYView) / 2)
                            }
                        }
                        .onAppear {
                            if viewModel.debug {
                                print("[ChinOverlay] GeometryReader size=\(size)")
                            }
                        }
                    }
                    .ignoresSafeArea()
                    .frame(height: topHeight, alignment: .top)
                } else {
                    Text("No image provided")
                        .primaryText()
                }
            }
            Spacer()
            controlsView
            Spacer()
            ctaButtonView
        }
        .background(Color.white)
        .navigationTitle("Result")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { viewModel.analyze(image: image) }
    }

    var ctaButtonView: some View {
        Button(action: startOver) {
            Text("Start Over")
        }
        .primaryButton()
    }

    //

    var controlsView: some View {
        VStack(spacing: 16) {
            // Color controls for the underlay
            VStack(alignment: .leading, spacing: 8) {
                Text("Overlay Controls")
                    .font(.headline)
                    .primaryText()

                // ColorPicker to choose underlay color
                ColorPicker("Underlay Color", selection: $underlayColor, supportsOpacity: false)
                    .labelsHidden()
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Slider to adjust underlay opacity
                HStack {
                    Text("Opacity")
                        .font(.footnote)
                        .foregroundColor(.gray)
                    Slider(value: $underlayOpacity, in: 0...1)
                    Text(String(format: "%.0f%%", underlayOpacity * 100))
                        .font(.footnote.monospacedDigit())
                        .foregroundColor(.gray)
                        .frame(width: 44, alignment: .trailing)
                }
            }
            .padding(.horizontal)

            if let result = viewModel.result {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Results")
                        .font(.headline)
                        .primaryText()
                    Text("Undertone: \(result.temperature == .warm ? "Warm" : "Cool")")
                        .primaryText()
                        .minimumScaleFactor(0.5)
                    Text(result.temperature == .warm
                         ? "Warm = more red/yellow undertones (higher a*)."
                         : "Cool = more blue/green undertones (lower a*).")
                        .font(.footnote)
                        .foregroundColor(.gray)
                        .minimumScaleFactor(0.5)
                    Text("Shade: \(result.shade == .light ? "Light" : "Dark")")
                        .primaryText()
                        .minimumScaleFactor(0.5)
                    Text("Shade is based on L* (perceptual lightness). Higher L* looks lighter.")
                        .font(.footnote)
                        .foregroundColor(.gray)
                        .minimumScaleFactor(0.5)
                    Text(String(format: "LAB ≈ L=%.1f a=%.1f b=%.1f", result.lab.l, result.lab.a, result.lab.b))
                        .font(.caption)
                        .foregroundColor(.gray)
                        .minimumScaleFactor(0.5)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }
        }
        .padding()
    }

    private func startOver() {
        // Signal ConfirmPhotoView to pop again, then dismiss once here
        nav.popToRoot = true
        dismiss()
    }
}

#Preview {
    AnalysisResultView(image: UIImage(named: "develop/person"))
}
