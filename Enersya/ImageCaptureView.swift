//
//  ImageCaptureView.swift
//  Enersya
//
//  Created by Esau Gutiérrez on 13/10/25.
//

// ImageCaptureView.swift

import SwiftUI
import UIKit

// ----------------------------------------------------
// Bridge de UIKit para manejar la Cámara/Librería
// ----------------------------------------------------
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var imageData: Data?
    @Environment(\.dismiss) var dismiss

    var sourceType: UIImagePickerController.SourceType = .camera // Por defecto, abrir la cámara

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator // Asignamos el delegado
        picker.sourceType = sourceType // Define si es Cámara o Librería
        // Solo para dispositivos reales con cámara
        if sourceType == .camera && !UIImagePickerController.isSourceTypeAvailable(.camera) {
             picker.sourceType = .photoLibrary
        }
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        var parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                // Guardamos la imagen como JPEG data (más compacto que PNG para fotos)
                parent.imageData = uiImage.jpegData(compressionQuality: 0.8)
            }
            parent.dismiss() // Cierra el selector de imágenes
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss() // Cierra al cancelar
        }
    }
}

// ----------------------------------------------------
// La Vista de SwiftUI para el botón y la previsualización
// ----------------------------------------------------
struct ImageCaptureView: View {
    @Binding var fotoData: Data?
    @State private var showingImagePicker = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Foto del Reporte")
                .font(.headline)
            
            HStack {
                Button {
                    showingImagePicker = true
                } label: {
                    Label("Tomar/Seleccionar Foto", systemImage: "camera.fill")
                }
                .buttonStyle(.bordered)
                
                if fotoData != nil {
                    Button("Borrar Foto", role: .destructive) {
                        fotoData = nil
                    }
                }
            }
            
            // Previsualización de la foto
            if let fotoData = fotoData, let uiImage = UIImage(data: fotoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        // Presentar el selector de imágenes como un modal
        .sheet(isPresented: $showingImagePicker) {
            // Importante: En el iPad, querrás usar .camera para forzar la cámara
            ImagePicker(imageData: $fotoData, sourceType: .camera)
        }
    }
}
