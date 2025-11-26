//
//  ReportesSplitView.swift
//  Enersya
//
//  Created by Esau Gutiérrez on 09/10/25.
//

// ReportesSplitView.swift

import SwiftUI

struct ReportesSplitView: View {
    @EnvironmentObject var viewModel: ReporteViewModel
    
    
    // Estado para la vista de detalle
    @State private var reporteSeleccionado: Reporte?

    // Estado para el modal de nuevo reporte
    @State private var mostrarFormularioNuevoReporte = false
    
    var body: some View {
        // NavigationSplitView: Master-Detail en iPad
        NavigationSplitView {
            // Columna 1: Sidebar / Listado de Reportes
            ReportesListView(reporteSeleccionado: $reporteSeleccionado, mostrarFormularioNuevoReporte: $mostrarFormularioNuevoReporte)
        } detail: {
            // Columna 2: Detalle del Reporte
            if let reporte = reporteSeleccionado {
                ReporteDetalleView(reporte: reporte)
            } else {
                Text("Selecciona un reporte de la lista.")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
        }
        .sheet(isPresented: $mostrarFormularioNuevoReporte) {
            // Presenta el formulario como un modal
            NuevoReporteView()
                .environmentObject(viewModel)
        }
    }
}

// Agregado al archivo ReportesSplitView.swift

struct ReporteDetalleView: View {
    let reporte: Reporte
    @EnvironmentObject var viewModel: ReporteViewModel
    
    @State private var pdfURL: URL? = nil
    @State private var isSharing = false
    // Cambiamos el nombre de isSharing para que refleje la nueva funcionalidad
    @State private var showingPDFPreview = false
    // Mantenemos isSharing para cuando se quiera COMPARTIR desde el botón en detalle
    

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(reporte.titulo)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Group {
                    HStack {
                        Image(systemName: "calendar")
                        Text("Fecha: \(reporte.fechaCreacion.formatted(date: .long, time: .shortened))")
                    }
                    HStack {
                        Image(systemName: "person.circle.fill")
                        Text("Generado por: \(reporte.usuarioID)")
                    }
                }
                .foregroundColor(.secondary)
                
                Divider()
                
                Text("Detalles del Reporte")
                    .font(.title2)
                    .padding(.bottom, 5)
                
                Text(reporte.detalles)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
                
                Button("Ver y Compartir PDF") { // Cambiamos el texto del botón
                    if let url = viewModel.generarPDF(para: reporte) {
                        self.pdfURL = url
                        self.showingPDFPreview = true // <-- Mostrar la vista previa
                    }
                }
                 .buttonStyle(.borderedProminent)
                 .controlSize(.large)
                 .frame(maxWidth: .infinity)
            }
            
            .sheet(isPresented: $showingPDFPreview) {
                if let url = pdfURL {
                    // La vista PDFPreviewView ahora recibirá automáticamente el Environment(\.dismiss)
                    PDFPreviewView(url: url)
                }
            }
             .padding()
             .navigationTitle("Detalle")
             .navigationBarTitleDisplayMode(.inline)
        }
        .navigationTitle("Detalle")
        .navigationBarTitleDisplayMode(.inline) // Estilo visual para iPad
    }
}

// Agregado al archivo ReportesSplitView.swift

struct ReportesListView: View {
    @EnvironmentObject var viewModel: ReporteViewModel
    @Binding var reporteSeleccionado: Reporte?
    @Binding var mostrarFormularioNuevoReporte: Bool
    
    var body: some View {
        List(viewModel.reportes, selection: $reporteSeleccionado) { reporte in
            // --- CAMBIO CLAVE AQUÍ ---
            Button {
                // 1. Al presionar el botón (la fila), actualizamos explícitamente el estado.
                reporteSeleccionado = reporte
            } label: {
                // 2. Este es el contenido visual de la fila (Label del botón)
                VStack(alignment: .leading) {
                    Text(reporte.titulo)
                        .font(.headline)
                    Text("Creado: \(reporte.fechaCreacion.formatted(date: .abbreviated, time: .shortened))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                // 3. Aseguramos que el texto mantenga el color por defecto de SwiftUI
                .foregroundColor(.primary)
            }
            // 4. Se requiere el .tag() para que la List reconozca la selección
            .tag(reporte)
            // 5. Opcional: Esto elimina el estilo de botón que SwiftUI aplica por defecto.
            .buttonStyle(.plain)
        }
        .navigationTitle("Reportes de Enersya")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    // Acción: Abrir el formulario para un nuevo reporte
                    mostrarFormularioNuevoReporte = true
                } label: {
                    Label("Nuevo Reporte", systemImage: "plus.circle.fill")
                }
            }
        }
    }
}
