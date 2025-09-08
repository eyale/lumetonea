import SwiftUI
import UIKit

struct ConfirmPhotoView: View {
    let image: UIImage?

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

            Button(action: {
                // Handle confirmation logic
            }) {
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
}

#Preview {
    ConfirmPhotoView(image: nil)
}

