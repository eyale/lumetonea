import SwiftUI
import AVFoundation
import UIKit

struct PhotoPermissionView: View {
    @State private var cameraAuthorized = AVCaptureDevice.authorizationStatus(for: .video) == .authorized
    @State private var cameraAvailable = UIImagePickerController.isSourceTypeAvailable(.camera)
    @State private var showCameraPicker = false
    @State private var showLibraryPicker = false
    @State private var selectedImage: UIImage?
    @State private var navigateToConfirm = false

    var body: some View {
        VStack(spacing: 24) {
            Text("We need access to your camera to let you take a photo.")
                .multilineTextAlignment(.center)
                .foregroundColor(.black)

            let status = AVCaptureDevice.authorizationStatus(for: .video)

            if cameraAuthorized && cameraAvailable {
                Button("Take Photo") {
                    showCameraPicker = true
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.black)
                .foregroundColor(.white)
                .cornerRadius(8)
            } else {
                if cameraAvailable && status != .denied && status != .restricted {
                    Button("Allow Camera Access") {
                        requestCameraPermission()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.black)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }

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
        .padding()
        .background(Color.white)
        .navigationTitle("Add Photo")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showCameraPicker) {
            ImagePicker(image: $selectedImage, sourceType: .camera) {
                navigateToConfirm = selectedImage != nil
            }
            .ignoresSafeArea()
        }
        .fullScreenCover(isPresented: $showLibraryPicker) {
            ImagePicker(image: $selectedImage, sourceType: .photoLibrary) {
                navigateToConfirm = selectedImage != nil
            }
            .ignoresSafeArea()
        }
        .navigationDestination(isPresented: $navigateToConfirm) {
            ConfirmPhotoView(image: selectedImage)
        }
    }

    private func requestCameraPermission() {
        guard cameraAvailable else {
            showLibraryPicker = true
            return
        }

        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                cameraAuthorized = granted
                showCameraPicker = granted && cameraAvailable
            }
        }
    }
}

#Preview {
    PhotoPermissionView()
}

