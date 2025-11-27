//
//  SignatureModalView.swift
//  Enersya
//
//  Created by Esau Gutiérrez on 24/10/25.
//
// SignatureModalView.swift

import SwiftUI
import UIKit

// Necesitas mover la struct SignatureCanvas y la clase SignatureView a un archivo compartido
// o asegurarte de que estén accesibles (ej. dejándolos en este archivo temporalmente
// y luego moviendo SignatureView y su protocolo SignatureViewDelegate a un archivo separado)

// Asumiendo que SignatureCanvas, SignatureView, y SignatureViewDelegate son accesibles:

struct SignatureModalView: View {
    // Variable para almacenar el resultado de la firma
    @Binding var signatureResult: Data?
    
    // El objeto para cerrar el modal
    @Environment(\.dismiss) var dismiss
    
    // Estado local para la firma temporal mientras se dibuja
    @State private var currentSignatureData: Data?

    var title: String

    var body: some View {
        NavigationView {
            VStack(spacing: 15) {
                Text("Por favor, dibuje la \(title)")
                    .font(.headline)
                    .padding(.top)
                
                // 1. Lienzo de Dibujo
                SignatureCanvas(signatureData: $currentSignatureData)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                        .background(Color.white)
                                        .border(Color.gray, width:2)
                                        .padding(.horizontal)
                
                HStack(spacing: 40) {
                    // 2. Botón para Limpiar el Lienzo
                    Button("Borrar") {
                        currentSignatureData = nil
                        // En una app real, también llamarías a un método para limpiar el canvas en UIKit
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                    
                    // 3. Botón para Aceptar y Guardar
                    Button("Aceptar y Guardar") {
                        if currentSignatureData != nil {
                            // 3a. Almacena la firma en la variable de resultado
                            signatureResult = currentSignatureData
                        }
                        // 3b. Cierra el modal
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(currentSignatureData == nil) // Deshabilitar si no hay firma
                }
            }
            .padding()
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
    }
}
