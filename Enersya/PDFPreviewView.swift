//
//  PDFPreviewView.swift
//  Enersya
//
//  Created by Esau Gutiérrez on 11/10/25.
//

// PDFPreviewView.swift

import SwiftUI
import QuickLook
import UIKit

struct PDFPreviewView: UIViewControllerRepresentable {
    let url: URL
    // 1. NUEVA PROPIEDAD: Objeto dismiss del entorno
    @Environment(\.dismiss) var dismissAction
    
    // Crea y configura el controlador de vista previa
    func makeUIViewController(context: Context) -> UINavigationController {
        let controller = QLPreviewController()
        // Le pasamos el objeto dismiss al coordinador al crearlo
        context.coordinator.dismiss = dismissAction
        
        controller.dataSource = context.coordinator
        
        let navController = UINavigationController(rootViewController: controller)
        
        // Configuramos el botón de cerrar en el controlador de QuickLook
        controller.navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: context.coordinator,
            action: #selector(context.coordinator.dismissPreview)
        )
        
        return navController
    }
    
    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}
    
    // El Coordinador se crea igual, pero se inicializará con el dismiss en makeUIViewController
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, QLPreviewControllerDataSource {
        var parent: PDFPreviewView
        // 2. NUEVA PROPIEDAD: Almacenar la acción de dismiss
        var dismiss: DismissAction?
        
        init(_ parent: PDFPreviewView) {
            self.parent = parent
        }
        
        // Función para cerrar la vista previa (llamada por el botón "Done")
        @objc func dismissPreview() {
            // 3. USO CORREGIDO: Llamar a la acción de dismiss de SwiftUI
            self.dismiss?()
        }

        func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
            return 1
        }
        
        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            return parent.url as QLPreviewItem
        }
    }
}
