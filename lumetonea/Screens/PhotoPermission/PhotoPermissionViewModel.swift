import SwiftUI
import AVFoundation
import UIKit
import Observation

@Observable
final class PhotoPermissionViewModel {
    var cameraAuthorized = AVCaptureDevice.authorizationStatus(for: .video) == .authorized
    var cameraAvailable = UIImagePickerController.isSourceTypeAvailable(.camera)
    var showCameraPicker = false
    var showLibraryPicker = false
    var selectedImage: UIImage?
    var navigateToConfirm = false

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

