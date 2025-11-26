//
//  ContentView.swift
//  Enersya
//
//  Created by Esau Gutiérrez on 09/10/25.
//

// ContentView.swift

import SwiftUI

// ContentView.swift

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var viewModel: ReporteViewModel
    @State private var correo: String = "user@enersya.com" // Valor de prueba
    @State private var contrasena: String = "1234" // Valor de prueba
    @State private var mostrarAlerta: Bool = false

    var body: some View {
        // Envolvemos el contenido en un NavigationView dentro de la vista
        NavigationView {
            VStack(spacing: 20) {
                Text("Bienvenido a Enersya")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                TextField("Correo electrónico", text: $correo)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)

                SecureField("Contraseña", text: $contrasena)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                Button("Iniciar Sesión") {
                    if !viewModel.iniciarSesion(correo: correo, contrasena: contrasena) {
                        mostrarAlerta = true
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                
                Spacer()
            }
            .padding(.horizontal, 100) // Formato visual para iPad
            .alert("Error de Acceso", isPresented: $mostrarAlerta) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Correo o contraseña incorrectos.")
            }
        }
        // Aplicamos el modificador esencial AQUÍ, a la raíz de la vista de navegación.
        // Esto fuerza el comportamiento de "stack" (pantalla completa) en iPad.
        .navigationViewStyle(.stack)
    }
}


// Vista contenedora principal que maneja el estado de autenticación
struct ContentView: View {
    @EnvironmentObject var viewModel: ReporteViewModel
    
    var body: some View {
        if !viewModel.estaAutenticado {
            // APLICAR el estilo de navegación 'Stack' aquí
            // Esto fuerza a que ocupe todo el ancho del iPad, no solo una barra lateral.
            NavigationView { // Necesitamos el NavigationView para la NavigationBar
                LoginView()
            }
            // ESTE es el modificador que resuelve el problema en iPad
            .navigationViewStyle(.stack)
            // NOTA: Si usas Xcode 14+ y iOS 16+, podrías probar con NavigationStack

        } else {
            // Cuando está autenticado, mostramos la vista principal (ReportesTabView)
            ReportesTabView()
        }
    }
}
