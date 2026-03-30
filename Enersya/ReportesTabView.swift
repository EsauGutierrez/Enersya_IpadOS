//
//  ReportesTabView.swift
//  Enersya
//
//  Created by Esau Gutiérrez on 09/10/25.
//

// ReportesTabView.swift

import SwiftUI

struct ReportesTabView: View {
    @EnvironmentObject var viewModel: ReporteViewModel
    
    var body: some View {
        TabView {
            // Sección 1: Gestión de Reportes (AHORA con Tabla Centralizada)
            ReportesTableView() // <-- Nuevo nombre de la vista
                .tabItem {
                    Label("Reportes", systemImage: "list.bullet.rectangle.fill")
                }
            
            // Sección 2: Perfil y Ajustes
            PerfilView() // (Sin cambios)
                .tabItem {
                    Label("Perfil", systemImage: "person.crop.circle.fill")
                }
        }
    }
}

// Vista simple para la sección de Perfil/Ajustes
struct PerfilView: View {
    @EnvironmentObject var viewModel: ReporteViewModel
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Text("Hola, \(viewModel.usuarioActual?.nombre ?? "Usuario")")
                    .font(.largeTitle)
                
                Button("Cerrar Sesión", role: .destructive) {
                    viewModel.cerrarSesion()
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            }
            .navigationTitle("Ajustes de Perfil")
        }
        // *** ESTA ES LA LÍNEA QUE LO SOLUCIONA ***
        // Fuerza a que la vista ocupe todo el ancho disponible y no cree un Sidebar
        .navigationViewStyle(.stack)
    }
}
