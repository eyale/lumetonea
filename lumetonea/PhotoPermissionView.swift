import SwiftUI
import AVFoundation
import UIKit

struct PhotoPermissionView: View {
    @Environment(\.scenePhase) private var scenePhase
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

            if cameraAvailable {
                if cameraAuthorized {
                    Button(action: { showCameraPicker = true }) {
                        Text("Take Photo")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .foregroundColor(.white)
                            .background(Color.navyBlue)
                            .cornerRadius(8)
                    }
                    .contentShape(Rectangle())
                } else {
                    if status == .denied || status == .restricted {
                        Button(action: { openSettings() }) {
                            Text("Allow Camera Access")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .foregroundColor(.white)
                                .background(Color.navyBlue)
                                .cornerRadius(8)
                        }
                        .contentShape(Rectangle())
                    } else {
                        Button(action: { requestCameraPermission() }) {
                            Text("Allow Camera Access")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .foregroundColor(.white)
                                .background(Color.navyBlue)
                                .cornerRadius(8)
                        }
                        .contentShape(Rectangle())
                    }
                }

                Button(action: { showLibraryPicker = true }) {
                    Text("Upload from Photos")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundColor(.white)
                        .background(Color.navyBlue)
                        .cornerRadius(8)
                }
                .contentShape(Rectangle())
            } else {
                Button(action: { showLibraryPicker = true }) {
                    Text("Upload from Photos")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundColor(.white)
                        .background(Color.navyBlue)
                        .cornerRadius(8)
                }
                .contentShape(Rectangle())
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
        .onChange(of: scenePhase) { phase in
            if phase == .active {
                cameraAuthorized = AVCaptureDevice.authorizationStatus(for: .video) == .authorized
            }
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

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

#Preview {
    PhotoPermissionView()
}

