import SwiftUI
import UIKit

struct AnalysisResultView: View {
    let image: UIImage?
    @State private var viewModel = AnalysisResultViewModel()
    let topHeight = UIScreen.main.bounds.height * 0.5

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
                                .ignoresSafeArea(edges: .top)
                            if let torso = viewModel.torsoPoints, torso.count == 4 {
                                Path { path in
                                    let convert: (CGPoint) -> CGPoint = { pt in
                                        CGPoint(
                                            x: pt.x * size.width,
                                            y: (1 - pt.y) * size.height
                                        )
                                    }
                                    let pts = torso.map(convert)
                                    if viewModel.debug { print("[Recolor] drawing torso pts=\(pts)") }
                                    path.move(to: pts[0])
                                    path.addLine(to: pts[1])
                                    path.addLine(to: pts[2])
                                    path.addLine(to: pts[3])
                                    path.closeSubpath()
                                }
                                .fill(Color.green.opacity(0.35))
                            }
                        }
                        .onAppear {
                            if viewModel.debug {
                                print("[Recolor] GeometryReader size=\(size)")
                            }
                        }
                    }
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
