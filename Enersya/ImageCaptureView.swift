import SwiftUI
import UIKit

// Puente con la cámara nativa de iOS
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var imageData: Data?
    @Environment(\.dismiss) var dismiss
    var sourceType: UIImagePickerController.SourceType = .camera

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera) ? sourceType : .photoLibrary
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        var parent: ImagePicker
        init(_ parent: ImagePicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                // Comprimimos la imagen para que el PDF no pese 50MB
                parent.imageData = uiImage.jpegData(compressionQuality: 0.6)
            }
            parent.dismiss()
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { parent.dismiss() }
    }
}

// Vista de la Galería Horizontal
struct ImageCaptureView: View {
    @Binding var fotos: [Data] // AHORA ES UN ARREGLO
    @State private var showingImagePicker = false
    @State private var tempImageData: Data?
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Fotografías Capturadas: \(fotos.count)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    // Botón de Agregar (Siempre visible al inicio)
                    Button {
                        showingImagePicker = true
                    } label: {
                        VStack {
                            Image(systemName: "camera.fill").font(.largeTitle)
                            Text("Agregar").font(.caption)
                        }
                        .frame(width: 100, height: 100)
                        .background(Color(.systemGray6))
                        .foregroundColor(.blue)
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.blue, style: StrokeStyle(lineWidth: 1, dash: [5])))
                    }
                    
                    // Lista de Fotos Tomadas
                    ForEach(fotos.indices, id: \.self) { index in
                        if let uiImage = UIImage(data: fotos[index]) {
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                
                                // Botón para eliminar foto
                                Button {
                                    fotos.remove(at: index)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.red)
                                        .background(Color.white.clipShape(Circle()))
                                }
                                .offset(x: 5, y: -5)
                            }
                        }
                    }
                }
                .padding(.vertical, 5)
            }
        }
        .sheet(isPresented: $showingImagePicker, onDismiss: {
            if let nuevaFoto = tempImageData {
                fotos.append(nuevaFoto) // Agrega la foto al array
                tempImageData = nil
            }
        }) {
            ImagePicker(imageData: $tempImageData, sourceType: .camera)
        }
    }
}
