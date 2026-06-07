import SwiftUI
import UIKit

/// Bridges `UIImagePickerController` so the user can capture a photo with the
/// camera. SwiftUI's `PhotosPicker` only reads the photo library — there's no
/// native SwiftUI camera-capture view — so this UIKit wrapper fills the gap.
///
/// Present it in a `.fullScreenCover`; it dismisses itself on capture/cancel.
struct CameraPicker: UIViewControllerRepresentable {
    var onCapture: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPicker
        init(_ parent: CameraPicker) { self.parent = parent }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                parent.onCapture(image)
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

/// Whether this device can actually take a photo (false on the Simulator).
let cameraIsAvailable = UIImagePickerController.isSourceTypeAvailable(.camera)

/// A compact control that offers both photo sources behind a single tap target.
/// On devices with a camera it presents a menu ("Take Photo" / "Choose from
/// Library"); on the Simulator (no camera) it falls through straight to the
/// library so the flow stays usable. Use for inline "Replace"-style affordances;
/// for the primary empty state, prefer two explicit buttons for discoverability.
struct PhotoSourceMenu<Content: View>: View {
    var onCamera: () -> Void
    var onLibrary: () -> Void
    @ViewBuilder var content: () -> Content

    var body: some View {
        if cameraIsAvailable {
            Menu {
                Button { onCamera() } label: {
                    Label("Take Photo", systemImage: "camera.fill")
                }
                Button { onLibrary() } label: {
                    Label("Choose from Library", systemImage: "photo.on.rectangle")
                }
            } label: {
                content()
            }
        } else {
            Button(action: onLibrary) { content() }
        }
    }
}
