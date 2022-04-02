//
//  Cornucopia – (C) Dr. Lauer Information Technology
//
import UIKit
import SwiftUI

/// An Image Picker View – wrapping the ``UIImagePickerController`` from UIKit:
/// ```swift
/// .sheet(isPresented: $showImagePicker) {
///     ImagePicker(sourceType: .photoLibrary, selectedImage: self.$image)
/// ```
public struct ImagePickerView: UIViewControllerRepresentable {

    @Environment(\.dismiss) private var dismiss
    var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @Binding var selectedImage: UIImage

    public func makeUIViewController(context: UIViewControllerRepresentableContext<ImagePickerView>) -> UIImagePickerController {

        let imagePicker = UIImagePickerController()
        imagePicker.allowsEditing = false
        imagePicker.sourceType = sourceType
        imagePicker.delegate = context.coordinator

        return imagePicker
    }

    public func updateUIViewController(_ uiViewController: UIImagePickerController, context: UIViewControllerRepresentableContext<ImagePickerView>) {
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    public init(selectedImage: Binding<UIImage>) {
        self._selectedImage = selectedImage
    }
}

extension ImagePickerView {

    public final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

        var parent: ImagePickerView

        init(_ parent: ImagePickerView) {
            self.parent = parent
        }

        public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {

            if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
                parent.selectedImage = image
            }

            parent.dismiss()
        }
    }
}
