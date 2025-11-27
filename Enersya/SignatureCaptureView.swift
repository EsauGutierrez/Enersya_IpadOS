//
//  SignatureCaptureView.swift
//  Enersya
//
//  Created by Esau Gutiérrez on 13/10/25.
//

// SignatureCaptureView.swift

import SwiftUI
import UIKit

struct SignatureCaptureView: View {
    @Binding var firmaData: Data?
    let title: String
    
    // Estado para controlar la apertura del modal
    @State private var showingSignatureModal = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
            
            HStack {
                // 1. Botón para abrir el modal de firma
                Button {
                    showingSignatureModal = true
                } label: {
                    Label(firmaData == nil ? "Capturar Firma" : "Ver/Editar Firma",
                          systemImage: firmaData == nil ? "pencil.tip.crop.circle" : "pencil.tip.crop.circle.fill")
                }
                .buttonStyle(.bordered)
                
                // 2. Previsualización pequeña o indicador de firma
                if let firmaData = firmaData, let uiImage = UIImage(data: firmaData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 40)
                        .border(Color.green)
                    
                    // 3. Botón de Borrar
                    Button("Borrar", role: .destructive) {
                        self.firmaData = nil
                    }
                }
            }
        }
        // 4. Adjuntar el modal a la vista
        .fullScreenCover(isPresented: $showingSignatureModal) {
            SignatureModalView(signatureResult: $firmaData, title: title)
        }
    }
}
// NOTA: La clase SignatureView y su protocolo SignatureViewDelegate
// deben seguir estando en tu proyecto y accesibles para compilar.
