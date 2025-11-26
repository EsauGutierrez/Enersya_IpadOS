//
//   NuevoReporteView.swift
//  Enersya
//
//  Created by Esau Gutiérrez on 09/10/25.
//

// En NuevoReporteView.swift

import SwiftUI

struct NuevoReporteView: View {
    @EnvironmentObject var viewModel: ReporteViewModel
    
    // Estados para los campos del formulario
    @State private var titulo: String = ""
    @State private var detalles: String = "" // Estado vacío para usar un placeholder
    @State private var firmaClienteData: Data?
    @State private var firmaTecnicoData: Data?
    @State private var fotoReporteData: Data?
    
    // Variable para controlar si el formulario está visible (se usa para cerrarlo)
    @Environment(\.dismiss) var dismiss
    
    // Helper para el texto placeholder
    private var detailsPlaceholder: String {
        return "Escribe aquí la descripción detallada del reporte, incluyendo observaciones y coordenadas..."
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Sección de Información Básica
                Section(header: Text("Información Básica")) {
                    TextField("Título del Reporte (Ej: Inspección 003)", text: $titulo)
                }
                
                // Sección de Detalles y Descripción (con corrección de Auto Layout)
                Section(header: Text("Detalles y Descripción")) {
                    ZStack(alignment: .topLeading) {
                        // TextEditor para escribir el contenido
                        TextEditor(text: $detalles)
                            .frame(height: 200)
                            .border(Color.gray.opacity(0.2))
                            .background(Color(.systemBackground))
                        
                        // Placeholder (Solo visible si el campo está vacío)
                        if detalles.isEmpty {
                            Text(detailsPlaceholder)
                                .foregroundColor(Color(uiColor: .placeholderText))
                                .padding(.top, 8)
                                .padding(.leading, 5)
                                .frame(height: 200, alignment: .topLeading)
                                // *** CORRECCIÓN DE BLOQUEO TÁCTIL ***
                                .allowsHitTesting(false)
                        }
                    }
                }
                
                Section(header: Text("Evidencia Fotográfica")) {
                    ImageCaptureView(fotoData: $fotoReporteData)
                }
                
                
                // NUEVA SECCIÓN: Firmas
                Section(header: Text("Firmas de Aceptación")) {
                    // Firma del Cliente
                    SignatureCaptureView(firmaData: $firmaClienteData, title: "Firma del Cliente")
                    
                    // Firma del Técnico
                    SignatureCaptureView(firmaData: $firmaTecnicoData, title: "Firma del Técnico")
                }
                
                
                
                // Sección del Botón Guardar
                Section {
                    Button("Guardar Reporte") {
                        // Validación de campos vacíos
                        guard !titulo.isEmpty && !detalles.isEmpty && firmaTecnicoData != nil else {
                            print("DEBUG: Campos incompletos o falta firma del técnico.")
                            return
                        }
                        
                        // Llama a la función del ViewModel para guardar el reporte
                        viewModel.agregarReporteConDatos(
                            titulo: titulo,
                            detalles: detalles,
                            firmaCliente: firmaClienteData,
                            firmaTecnico: firmaTecnicoData,
                            fotoReporte: fotoReporteData
                        )
                        
                        // Demorar el cierre permite que la lista se actualice primero.
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            dismiss()
                        }
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity) // Ocupa todo el ancho
                }
                
            }
            .navigationTitle("Nuevo Reporte")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
            }
        }
        // Para asegurar que el modal ocupe toda la pantalla en iPad
        .presentationDetents([.large])
    }
}
