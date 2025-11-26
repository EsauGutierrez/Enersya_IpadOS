//
//  EnersyaApp.swift
//  Enersya
//
//  Created by Esau Gutiérrez on 09/10/25.
//

// EnersyaApp.swift

import SwiftUI

@main
struct EnersyaApp: App {
    // 1. Crear el objeto del modelo de datos para toda la aplicación
    @StateObject var viewModel = ReporteViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                // 2. Inyectar el objeto en el entorno de vistas
                .environmentObject(viewModel)
        }
    }
}
