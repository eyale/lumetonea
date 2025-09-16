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

    // Sheets
    @State private var showResultsSheet: Bool = false
    @State private var showInfoSheet: Bool = false

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
        .onAppear {
            viewModel.analyze(image: image)
            // Auto-open the results sheet once results are available
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                if viewModel.result != nil {
                    showResultsSheet = true
                }
            }
        }
        .sheet(isPresented: $showInfoSheet) {
            InfoSheetView()
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showResultsSheet) {
            ResultsSheetView(result: viewModel.result)
                .presentationDetents([.height(260), .medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    var ctaButtonView: some View {
        HStack {
            Button(action: { showResultsSheet = true }) {
                Label("Show Results", systemImage: "chevron.up.circle")
            }
            .buttonStyle(.bordered)

            Spacer()

            Button(action: startOver) {
                Text("Start Over")
            }
            .primaryButton()
        }
        .padding(.horizontal)
        .padding(.bottom)
    }

    // MARK: - Controls (color + opacity + info)
    var controlsView: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Overlay Controls")
                    .font(.headline)
                    .primaryText()

                // ColorPicker to choose underlay color + HEX readout
                HStack(spacing: 12) {
                    ColorPicker("Underlay Color", selection: $underlayColor, supportsOpacity: false)
                        .labelsHidden()

                    // HEX of the selected color
                    Text(hexString(for: underlayColor))
                        .font(.caption.monospaced())
                        .foregroundColor(.gray)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.12), in: Capsule())
                }
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

                // Info icon under the opacity slider
                HStack {
                    Button {
                        showInfoSheet = true
                    } label: {
                        Label("What does this do?", systemImage: "info.circle")
                            .font(.footnote)
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.navyBlue)

                    Spacer()
                }
            }
            .padding(.horizontal)
        }
        .padding(.top, 8)
    }

    private func startOver() {
        // Signal ConfirmPhotoView to pop again, then dismiss once here
        nav.popToRoot = true
        dismiss()
    }

    // MARK: - Helpers
    private func hexString(for color: Color) -> String {
        // Convert SwiftUI.Color to sRGB components and format as #RRGGBB
        #if canImport(UIKit)
        let ui = UIColor(color)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        if ui.getRed(&r, green: &g, blue: &b, alpha: &a) {
            let R = Int(round(r * 255))
            let G = Int(round(g * 255))
            let B = Int(round(b * 255))
            return String(format: "#%02X%02X%02X", R, G, B)
        }
        #endif
        return "#FFFFFF"
    }
}

// MARK: - Results Bottom Sheet
private struct ResultsSheetView: View {
    let result: SkinToneResult?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Capsule()
                .fill(Color.secondary.opacity(0.25))
                .frame(width: 40, height: 5)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 8)

            Text("Results")
                .font(.headline)
                .primaryText()

            if let result {
                VStack(alignment: .leading, spacing: 8) {
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
            } else {
                Text("Analyzing...")
                    .foregroundColor(.gray)
            }

            Spacer(minLength: 0)
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

// MARK: - Info Sheet
private struct InfoSheetView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Capsule()
                .fill(Color.secondary.opacity(0.25))
                .frame(width: 40, height: 5)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 8)

            Text("Overlay Info")
                .font(.headline)
                .primaryText()

            Text("The horizontal line aligns with the detected chin. The area below the line is highlighted using your selected color and opacity. Use this to preview how different shirt colors might look.")
                .font(.body)
                .foregroundColor(.gray)

            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

#Preview {
    AnalysisResultView(image: UIImage(named: "develop/person"))
}
