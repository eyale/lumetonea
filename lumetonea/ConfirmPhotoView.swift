import SwiftUI
import UIKit

struct ConfirmPhotoView: View {
    let image: UIImage?

    @Environment(\.dismiss) private var dismiss

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

            Button("Confirm Photo") {
                // Handle confirmation logic
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.black)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .padding()
        .background(Color.white)
        .navigationTitle("Confirm")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Back") { dismiss() }
            }
        }
    }
}

#Preview {
    ConfirmPhotoView(image: nil)
}

