import SwiftUI
import AVFoundation
import UIKit

struct PhotoPermissionView: View {
    @State private var cameraAuthorized = AVCaptureDevice.authorizationStatus(for: .video) == .authorized
    @State private var showCameraPicker = false
    @State private var showLibraryPicker = false
    @State private var selectedImage: UIImage?
    @State private var navigateToConfirm = false

    var body: some View {
        VStack(spacing: 24) {
            Text("We need access to your camera to let you take a photo.")
                .multilineTextAlignment(.center)
                .foregroundColor(.black)

            if cameraAuthorized {
                Button("Take Photo") {
                    showCameraPicker = true
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.black)
                .foregroundColor(.white)
                .cornerRadius(8)
            } else {
                Button("Allow Camera Access") {
                    requestCameraPermission()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.black)
                .foregroundColor(.white)
                .cornerRadius(8)

                let status = AVCaptureDevice.authorizationStatus(for: .video)
                if status == .denied || status == .restricted {
                    Button("Upload from Photos") {
                        showLibraryPicker = true
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.black)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            }

            NavigationLink(destination: ConfirmPhotoView(image: selectedImage), isActive: $navigateToConfirm) {
                EmptyView()
            }
        }
        .padding()
        .background(Color.white)
        .sheet(isPresented: $showCameraPicker) {
            ImagePicker(image: $selectedImage, sourceType: .camera) {
                navigateToConfirm = selectedImage != nil
            }
        }
        .sheet(isPresented: $showLibraryPicker) {
            ImagePicker(image: $selectedImage, sourceType: .photoLibrary) {
                navigateToConfirm = selectedImage != nil
            }
        }
    }

    private func requestCameraPermission() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                cameraAuthorized = granted
                showCameraPicker = granted
            }
        }
    }
}

#Preview {
    PhotoPermissionView()
}

