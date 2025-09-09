import SwiftUI
import AVFoundation
import UIKit

final class PhotoPermissionViewModel: ObservableObject {
    @Published var cameraAuthorized = AVCaptureDevice.authorizationStatus(for: .video) == .authorized
    @Published var cameraAvailable = UIImagePickerController.isSourceTypeAvailable(.camera)
    @Published var showCameraPicker = false
    @Published var showLibraryPicker = false
    @Published var selectedImage: UIImage?
    @Published var navigateToConfirm = false

    func requestCameraPermission() {
        guard cameraAvailable else {
            showLibraryPicker = true
            return
        }

        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                self.cameraAuthorized = granted
                self.showCameraPicker = granted && self.cameraAvailable
            }
        }
    }

    func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    func updateCameraAuthorization() {
        cameraAuthorized = AVCaptureDevice.authorizationStatus(for: .video) == .authorized
    }
}

