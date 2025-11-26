//
//  ReportesTableView.swift
//  Enersya
//
//  Created by Esau Gutiérrez on 10/10/25.
//

// ReportesTableView.swift (Reemplazará la lógica de ReportesSplitView)

import SwiftUI

struct ReportesTableView: View {
    @EnvironmentObject var viewModel: ReporteViewModel
    
    // Estado para la búsqueda
    @State private var searchText: String = ""
    
    // Estado para la ordenación (0: Título, 1: Fecha)
    @State private var sortCriteria: Int = 1 // Por defecto, ordenamos por Fecha
    @State private var sortAscending: Bool = false // Por defecto, Fecha Descendente
    @State private var showingNewReportSheet = false //Mostrar modal de nuevo reporte

    
    // Propiedad calculada para aplicar filtrado y ordenación
    var filteredAndSortedReports: [Reporte] {
        var reportes = viewModel.reportes
        
        // --- 1. FILTRADO (BÚSQUEDA) ---
        if !searchText.isEmpty {
            reportes = reportes.filter { reporte in
                reporte.titulo.localizedCaseInsensitiveContains(searchText) ||
                reporte.detalles.localizedCaseInsensitiveContains(searchText) ||
                reporte.usuarioID.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // --- 2. ORDENACIÓN ---
        reportes.sort { r1, r2 in
            let result: Bool
            switch sortCriteria {
            case 0: // Ordenar por Título
                result = r1.titulo < r2.titulo
            case 1: // Ordenar por Fecha de Creación
                result = r1.fechaCreacion < r2.fechaCreacion
            default:
                result = r1.fechaCreacion < r2.fechaCreacion
            }
            return sortAscending ? result : !result // Aplicar ascendente/descendente
        }
        
        return reportes
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 1. Encabezado de la Tabla y Controles de Ordenación
                ReportesTableHeader(sortCriteria: $sortCriteria, sortAscending: $sortAscending)
                    .frame(height: 40)
                    .background(Color(.systemGray5))
                
                // 2. Listado de Datos
                List {
                    ForEach(filteredAndSortedReports) { reporte in
                        // Usamos NavigationLink para la navegación a la vista de detalle
                        NavigationLink {
                            // La vista de Detalle ahora se presenta de forma completa
                            ReporteDetalleView(reporte: reporte)
                                .environmentObject(viewModel)
                        } label: {
                            ReportesTableRow(reporte: reporte)
                        }
                    }
                }
                .listStyle(.plain) // Elimina los estilos de celda del listado por defecto
            }
            .navigationTitle("Reportes de Enersya")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        // Acción: Abrir el formulario para un nuevo reporte
                        // Reutilizamos la lógica del sheet de la vista anterior
                        // NOTA: Para implementar esto, usaremos un sheet en el ContentView o ReportesTabView
                        // Para simplificar, por ahora, solo imprime la acción.
                        print("Abrir Nuevo Reporte Modal")
                        showingNewReportSheet = true
                    } label: {
                        Label("Nuevo Reporte", systemImage: "plus.circle.fill")
                    }
                }
            }
        }
        // NUEVA SECCIÓN: Adjuntar el modal a la vista
        .sheet(isPresented: $showingNewReportSheet) {
            // El formulario se presenta y se le inyecta el ViewModel
            NuevoReporteView()
                .environmentObject(viewModel)
        }
        // --- BARRAS DE BÚSQUEDA (searchable) ---
        // Este modificador agrega la barra de búsqueda automáticamente a la NavigationView
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
        .navigationViewStyle(.stack) // Para asegurar que ocupe todo el espacio
    }
}

// Vista para el encabezado de la tabla (con botones de ordenación)
struct ReportesTableHeader: View {
    @Binding var sortCriteria: Int
    @Binding var sortAscending: Bool
    
    var body: some View {
        HStack {
            Spacer().frame(width: 20)
            
            // Columna Título
            SortButton(title: "Título", criteria: 0, currentCriteria: $sortCriteria, isAscending: $sortAscending)
                .frame(width: 250, alignment: .leading)
            
            Spacer()
            
            // Columna Fecha
            SortButton(title: "Fecha", criteria: 1, currentCriteria: $sortCriteria, isAscending: $sortAscending)
                .frame(width: 150, alignment: .leading)
            
            // Columna Usuario
            Text("Usuario")
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(width: 150, alignment: .leading)
            
            Spacer()
        }
    }
}

// Botón re-utilizable para la ordenación
struct SortButton: View {
    let title: String
    let criteria: Int
    @Binding var currentCriteria: Int
    @Binding var isAscending: Bool
    
    var body: some View {
        Button {
            // Si el criterio es el mismo, invertimos la dirección.
            if currentCriteria == criteria {
                isAscending.toggle()
            } else {
                // Si cambiamos el criterio, restablecemos a descendente (o el default deseado).
                currentCriteria = criteria
                isAscending = false
            }
        } label: {
            HStack {
                Text(title)
                if currentCriteria == criteria {
                    Image(systemName: isAscending ? "arrow.up" : "arrow.down")
                }
            }
            .font(.subheadline)
            .fontWeight(.medium)
        }
        .buttonStyle(.plain)
    }
}

// Vista para la fila de la tabla
struct ReportesTableRow: View {
    let reporte: Reporte
    
    var body: some View {
        HStack {
            // Columna Título
            Text(reporte.titulo)
                .lineLimit(1)
                .frame(width: 250, alignment: .leading)
            
            Spacer()
            
            // Columna Fecha
            Text(reporte.fechaCreacion.formatted(date: .abbreviated, time: .shortened))
                .frame(width: 150, alignment: .leading)
            
            // Columna Usuario
            Text(reporte.usuarioID)
                .lineLimit(1)
                .frame(width: 150, alignment: .leading)
            
            Spacer()
        }
    }
}
