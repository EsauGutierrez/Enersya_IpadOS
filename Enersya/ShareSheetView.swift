//
//  ShareSheetView.swift
//  Enersya
//
//  Created by Esau Gutiérrez on 09/10/25.
//
// ShareSheetView.swift

import SwiftUI
import UIKit

// Envuelve el UIActivityViewController (la hoja de compartir nativa de iOS)
struct ShareSheetView: UIViewControllerRepresentable {
    // El 'items' son los datos que se van a compartir (ej. la URL del PDF)
    let activityItems: [Any]
    
    // Esta función crea el controlador de UIKit que queremos usar
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        // Opcional: Para iPads, el UIActivityViewController necesita un origen.
        // Si no se define, se presenta como un modal centrado, pero es mejor usar el popover.
        controller.popoverPresentationController?.sourceView = UIView()
        return controller
    }

    // Esta función se requiere pero no hace nada para una hoja de compartir
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
