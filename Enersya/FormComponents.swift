//
//  FormComponents.swift
//  Enersya
//
//  Created by Esau Gutierrez Tejeida on 01/12/25.
//

// FormComponents.swift
import SwiftUI

// Una fila que muestra Fase A, B, C para un set de datos (Amps, Volts, Hz)
struct FilaFaseInputView: View {
	let titulo: String
	@Binding var lectura: LecturaElectrica
	
	var body: some View {
		GridRow {
			Text(titulo)
				.font(.caption)
				.bold()
				.frame(maxWidth: .infinity, alignment: .leading)
			
			TextField("Amp", text: $lectura.amp)
				.textFieldStyle(.roundedBorder)
				.keyboardType(.decimalPad)
			
			TextField("Volts", text: $lectura.volts)
				.textFieldStyle(.roundedBorder)
				.keyboardType(.decimalPad)
			
			TextField("Hz", text: $lectura.hertz)
				.textFieldStyle(.roundedBorder)
				.keyboardType(.decimalPad)
		}
	}
}

// Encabezado de la tabla pequeña
struct HeaderTablaView: View {
	var body: some View {
		GridRow {
			Text("") // Espacio para etiqueta Fase
			Text("Amp").font(.caption).foregroundColor(.secondary)
			Text("Volts").font(.caption).foregroundColor(.secondary)
			Text("Hz").font(.caption).foregroundColor(.secondary)
		}
	}
}
