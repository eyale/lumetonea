import SwiftUI
import UIKit

struct ConfirmPhotoView: View {
    let image: UIImage?
    @State private var processing = false
    @State private var result: SkinToneResult?

    var body: some View {
        VStack(spacing: 24) {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .frame(height: 300)
            } else {
                Text("No image selected")
                    .foregroundColor(.black)
            }

            if processing {
                ProgressView()
            }

            if let result = result {
                Text("Tone: \(result.temperature == .warm ? "Warm" : "Cool"), \(result.shade == .light ? "Light" : "Dark")")
                    .foregroundColor(.black)
            }

            Button(action: { processImage() }) {
                Text("Confirm Photo")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.navyBlue)
                    .cornerRadius(8)
            }
            .contentShape(Rectangle())
        }
        .padding()
        .background(Color.white)
        .navigationTitle("Confirm")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func processImage() {
        guard let image = image else { return }
        processing = true
        SkinToneExtractor().analyze(image: image) { result in
            self.result = result
            self.processing = false
        }
    }
}

#Preview {
    ConfirmPhotoView(image: nil)
}

