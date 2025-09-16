import SwiftUI
import AVFoundation
import UIKit
import PhotosUI
import Observation

struct PhotoPermissionView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var viewModel = PhotoPermissionViewModel()
    @State private var pickerItem: PhotosPickerItem?

    var body: some View {
        @Bindable var viewModel = viewModel

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
                } else {
                    if status == .denied || status == .restricted {
                        Button(action: { viewModel.openSettings() }) {
                            Text("Allow Camera Access")
                        }
                          .primaryButton()
                    } else {
                        Button(action: { viewModel.requestCameraPermission() }) {
                            Text("Allow Camera Access")
                        }
                          .primaryButton()
                    }
                }
                PhotosPicker(selection: $pickerItem, matching: .images, photoLibrary: .shared()) {
                    Text("Upload from Photos")
                }
            } else {
                PhotosPicker(selection: $pickerItem, matching: .images, photoLibrary: .shared()) {
                    Text("Upload from Photos")
                }
            }
        }
        .padding()
        .background(Color.white)
        .navigationTitle("Add Photo")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $viewModel.showCameraPicker) {
            CameraView { captured in
                viewModel.selectedImage = captured
                viewModel.navigateToConfirm = viewModel.selectedImage != nil
            }
            .ignoresSafeArea()
        }
        .navigationDestination(isPresented: $viewModel.navigateToConfirm) {
            ConfirmPhotoView(image: viewModel.selectedImage)
        }
        .onChange(of: pickerItem) { _, newItem in
            guard let item = newItem else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    viewModel.selectedImage = uiImage
                    viewModel.navigateToConfirm = true
                }
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                viewModel.updateCameraAuthorization()
            }
        }
    }
}

#Preview {
    PhotoPermissionView()
}
