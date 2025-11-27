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

import SwiftUI

struct LoginView: View {
	@EnvironmentObject var viewModel: ReporteViewModel
	
	// Estados para los campos
	@State private var email: String = ""
	@State private var password: String = ""
	@State private var showingAlert = false
	
	var body: some View {
		ZStack {
			// 1. FONDO BLANCO LIMPIO
			Color.white
				.ignoresSafeArea()
			
			// 2. CONTENIDO CENTRAL
			VStack(spacing: 40) {
				
				// --- LOGO DE LA EMPRESA ---
				// Usamos el mismo asset que en el PDF
				Image("LogoEnersya")
					.resizable()
					.scaledToFit()
					.frame(height: 80) // Altura controlada
					.padding(.bottom, 20)
				
				// --- TEXTOS DE BIENVENIDA ---
				VStack(spacing: 8) {
					Text("¡Bienvenido!")
						.font(.system(size: 34, weight: .bold))
						.foregroundColor(.black)
					
					Text("Por favor inicia sesión para usar la plataforma.")
						.font(.body)
						.foregroundColor(.gray)
				}
				
				// --- CAMPOS DE TEXTO ---
				VStack(spacing: 20) {
					
					// Campo E-mail
					HStack(spacing: 15) {
						Image(systemName: "envelope")
							.foregroundColor(.blue)
							.frame(width: 20)
						
						ZStack(alignment: .leading) {
							if email.isEmpty {
								Text("Correo Electrónico")
									.foregroundColor(.gray)
							}
							TextField("", text: $email)
								.keyboardType(.emailAddress)
								.autocapitalization(.none)
						}
					}
					.padding()
					.background(Color(.systemGray6)) // Fondo gris claro
					.cornerRadius(12)
					
					// Campo Password
					HStack(spacing: 15) {
						Image(systemName: "lock")
							.foregroundColor(.blue)
							.frame(width: 20)
						
						ZStack(alignment: .leading) {
							if password.isEmpty {
								Text("Contraseña")
									.foregroundColor(.gray)
							}
							SecureField("", text: $password)
						}
					}
					.padding()
					.background(Color(.systemGray6))
					.cornerRadius(12)
					
					// Link "Olvidaste contraseña"
					HStack {
						Spacer()
						Button("¿Olvidaste tu contraseña?") {
							// Acción pendiente
						}
						.font(.footnote)
						.foregroundColor(.blue)
					}
				}
				
				// --- BOTÓN DE LOGIN ---
				Button(action: {
					// Acción de Login
					let exito = viewModel.iniciarSesion(correo: email, contrasena: password)
					if !exito {
						showingAlert = true
					}
				}) {
					Text("INICIAR SESIÓN")
						.font(.headline)
						.foregroundColor(.white)
						.frame(maxWidth: .infinity)
						.padding()
						.background(Color.blue)
						.cornerRadius(12)
						.shadow(color: .blue.opacity(0.3), radius: 5, x: 0, y: 5)
				}
				.padding(.top, 10)
				
			}
			.padding(40)
			// Limitamos el ancho para que en iPad se vea como una tarjeta centrada
			// y no se estire de borde a borde de la pantalla gigante.
			.frame(maxWidth: 500)
		}
		.alert("Error", isPresented: $showingAlert) {
			Button("OK", role: .cancel) { }
		} message: {
			Text("Correo o contraseña incorrectos.\n(Prueba: user@enersya.com / 1234)")
		}
	}
}

// Previsualización para que veas cómo queda
struct LoginView_Previews: PreviewProvider {
	static var previews: some View {
		LoginView()
			.environmentObject(ReporteViewModel())
			// Forzamos modo iPad landscape para ver el diseño real
			.previewInterfaceOrientation(.landscapeLeft)
			.previewDevice("iPad Pro (12.9-inch) (6th generation)")
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
