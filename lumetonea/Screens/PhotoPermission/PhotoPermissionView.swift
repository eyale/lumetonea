import SwiftUI
import AVFoundation
import UIKit

struct PhotoPermissionView: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var viewModel = PhotoPermissionViewModel()

    var body: some View {
        VStack(spacing: 24) {
            Text("We need access to your camera to let you take a photo.")
                .multilineTextAlignment(.center)
                .primaryText()

            let status = AVCaptureDevice.authorizationStatus(for: .video)

            if viewModel.cameraAvailable {
                if viewModel.cameraAuthorized {
                    Button(action: { viewModel.showCameraPicker = true }) {
                        Text("Take Photo")
                    }
                    .primaryButton()
                    .contentShape(Rectangle())
                } else {
                    if status == .denied || status == .restricted {
                        Button(action: { viewModel.openSettings() }) {
                            Text("Allow Camera Access")
                        }
                        .primaryButton()
                        .contentShape(Rectangle())
                    } else {
                        Button(action: { viewModel.requestCameraPermission() }) {
                            Text("Allow Camera Access")
                        }
                        .primaryButton()
                        .contentShape(Rectangle())
                    }
                }

                Button(action: { viewModel.showLibraryPicker = true }) {
                    Text("Upload from Photos")
                }
                .primaryButton()
                .contentShape(Rectangle())
            } else {
                Button(action: { viewModel.showLibraryPicker = true }) {
                    Text("Upload from Photos")
                }
                .primaryButton()
                .contentShape(Rectangle())
            }
        }
        .padding()
        .background(Color.white)
        .navigationTitle("Add Photo")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $viewModel.showCameraPicker) {
            ImagePicker(image: $viewModel.selectedImage, sourceType: .camera) {
                viewModel.navigateToConfirm = viewModel.selectedImage != nil
            }
            .ignoresSafeArea()
        }
        .fullScreenCover(isPresented: $viewModel.showLibraryPicker) {
            ImagePicker(image: $viewModel.selectedImage, sourceType: .photoLibrary) {
                viewModel.navigateToConfirm = viewModel.selectedImage != nil
            }
            .ignoresSafeArea()
        }
        .navigationDestination(isPresented: $viewModel.navigateToConfirm) {
            ConfirmPhotoView(image: viewModel.selectedImage)
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active {
                viewModel.updateCameraAuthorization()
            }
        }
    }
}

#Preview {
    PhotoPermissionView()
}

