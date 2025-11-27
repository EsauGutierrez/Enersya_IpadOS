//
//  ImageCaptureView.swift
//  Enersya
//
//  Created by Esau Gutiérrez on 13/10/25.
//
import Foundation
import UIKit // Necesario para UIImage/Data si lo usas aquí o en extensiones
import SwiftUI // <--- AGREGA ESTO (Importante para @Published y ObservableObject)
import Combine //
import PDFKit

class ReporteViewModel: ObservableObject {
	@Published var reportes: [Reporte] = []
	@Published var estaAutenticado: Bool = false
	@Published var usuarioActual: Usuario?
	
	// URL para guardar el archivo JSON
	private var reportesFileURL: URL {
		let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
		return documentDirectory.appendingPathComponent("enersya_reportes.json")
	}
	
	init() {
		cargarReportes()
	}
	
	// MARK: - Autenticación
	func iniciarSesion(correo: String, contrasena: String) -> Bool {
		if correo == "user@enersya.com" && contrasena == "1234" {
			self.usuarioActual = Usuario(nombre: "Técnico Enersya", correo: correo)
			self.estaAutenticado = true
			return true
		}
		return false
	}
	
	func cerrarSesion() {
		self.estaAutenticado = false
		self.usuarioActual = nil
	}
	
	// MARK: - Gestión de Reportes
	
	// Esta es la NUEVA función para guardar el reporte completo que viene del formulario
	func guardarNuevoReporte(_ reporte: Reporte) {
		reportes.append(reporte)
		guardarReportes()
	}
	
	// Función para eliminar
	func eliminarReporte(_ reporte: Reporte) {
		if let index = reportes.firstIndex(where: { $0.id == reporte.id }) {
			reportes.remove(at: index)
			guardarReportes()
			print("🗑️ Reporte eliminado: \(reporte.cliente)")
		}
	}
	
	// MARK: - Persistencia (Guardar/Cargar JSON)
	
	func guardarReportes() {
		do {
			let data = try JSONEncoder().encode(reportes)
			try data.write(to: reportesFileURL)
			print("✅ Reportes guardados.")
		} catch {
			print("❌ ERROR al guardar reportes: \(error.localizedDescription)")
		}
	}
	
	func cargarReportes() {
		guard FileManager.default.fileExists(atPath: reportesFileURL.path) else {
			cargarDatosDeMuestra() // Si no hay archivo, creamos uno de prueba
			guardarReportes()
			return
		}
		
		do {
			let data = try Data(contentsOf: reportesFileURL)
			reportes = try JSONDecoder().decode([Reporte].self, from: data)
		} catch {
			print("❌ ERROR al cargar reportes: \(error.localizedDescription)")
			cargarDatosDeMuestra()
		}
	}
	
	// MARK: - Datos de Prueba
	// AQUÍ ESTABA EL ERROR: Actualizamos esto para usar los nuevos campos
	private func cargarDatosDeMuestra() {
		let reporteMuestra = Reporte(
			// Nota: No enviamos 'id' porque se genera automáticamente en el struct
			
			// 1. Coincide con el orden de DataModels.swift
			cliente: "Empresa de Prueba S.A.",
			mesCorrespondiente: "Diciembre 2025",
			responsable: "Ing. Juan Pérez",
			domicilio: "Av. Vallarta 1234, Guadalajara",
			efectuadoPor: "Téc. Esaú",
			telefono: "33 1234 5678",
			
			marca: "Eaton",
			modelo: "9PX",
			noSerie: "S/N 123456",
			noContrato: "C-2024-001",
			
			fechaCreacion: Date(),
			usuarioID: "admin@enersya.com",
			
			// 2. Actividades
			actividades: ActividadesChecklist(revMedidores: true, inspExterna: true),
			
			// 3. Parámetros (Valores por defecto vacíos)
			salidaConsumo: ParametrosFase(),
			salidaRegulado: ParametrosFase(),
			salidaReserva: ParametrosFase(),
			condicionesSincronia: "Sí",
			porcentajeCarga: "45%",
			temperatura: "22°C",
			
			// 4. Entradas
			entradaConsumo: ParametrosFase(),
			entradaVoltaje: ParametrosFase(),
			voltajeInversor: "120",
			corrienteInversor: "10",
			corrienteBateria: "5",
			voltajeFlotacion: "13.5",
			
			// 5. Varios
			refacciones: "Ninguna",
			detalles: "Reporte de prueba generado automáticamente.",
			
			// 6. Multimedia
			firmaCliente: nil,
			firmaTecnico: nil,
			fotoReporte: nil
		)
		
		reportes = [reporteMuestra]
	}
}




extension ReporteViewModel {
	
	func generarPDF(para reporte: Reporte) -> URL? {
		// Formato Carta (8.5 x 11 pulgadas)
		let pageSize = CGRect(x: 0, y: 0, width: 612, height: 792)
		let renderer = UIGraphicsPDFRenderer(bounds: pageSize, format: UIGraphicsPDFRendererFormat())
		
		// Nombre del archivo
		let nombreArchivo = "Reporte_\(reporte.noContrato)_\(UUID().uuidString.prefix(5)).pdf"
		let url = FileManager.default.temporaryDirectory.appendingPathComponent(nombreArchivo)
		
		let margin: CGFloat = 30
		var currentY: CGFloat = margin
		let usableWidth = pageSize.width - (2 * margin)
		
		do {
			try renderer.writePDF(to: url) { context in
				context.beginPage()
				let cgContext = context.cgContext
				
				// --- 1. ENCABEZADO ---
				// Logo (Placeholder)
				// --- 1. ENCABEZADO CON LOGO ---
				
				// Intentamos cargar la imagen llamada "LogoEnersya" desde los Assets
				if let logoImage = UIImage(named: "LogoEnersya") {
					// Definimos el ancho deseado para el logo (ej. 150 puntos)
					let logoWidth: CGFloat = 150
					
					// Calculamos la altura proporcional para que no se deforme
					let aspectRatio = logoImage.size.height / logoImage.size.width
					let logoHeight = logoWidth * aspectRatio
					
					// Dibujamos la imagen en la esquina superior izquierda (margin, currentY)
					let logoRect = CGRect(x: margin, y: currentY, width: logoWidth, height: logoHeight)
					logoImage.draw(in: logoRect)
					
					// Opcional: Si quieres poner la dirección o datos de contacto a la DERECHA del logo
					// como en tu hoja física, puedes agregar texto aquí:
					let direccionX = margin + logoWidth + 20
					let direccionWidth = usableWidth - logoWidth - 20
					var textY = currentY
					
					drawText("Soporte Continuo de Energía", font: .boldSystemFont(ofSize: 12), x: direccionX, y: &textY, width: direccionWidth)
					drawText("Pino Oriente No. 56, Fracc. Las Cañadas", font: .systemFont(ofSize: 9), x: direccionX, y: &textY, width: direccionWidth)
					drawText("Tonalá, Jal. Tel: 331370-3246", font: .systemFont(ofSize: 9), x: direccionX, y: &textY, width: direccionWidth)
					drawText("www.scei.com.mx", font: .systemFont(ofSize: 9, weight: .bold), color: .blue, x: direccionX, y: &textY, width: direccionWidth)
					
					// Movemos el cursor "currentY" hacia abajo.
					// Usamos la altura del logo o la del texto (la que sea mayor) + un margen
					currentY += max(logoHeight, (textY - currentY)) + 20
					
				} else {
					// FALLBACK: Si por alguna razón no encuentra la imagen, dibuja texto
					print("⚠️ No se encontró la imagen 'LogoEnersya' en Assets")
					drawText("enersya | SCEI", font: .boldSystemFont(ofSize: 22), color: .systemBlue, x: margin, y: &currentY, width: usableWidth)
					currentY += 30
				}
				
				// Título del Reporte
				drawBoxedHeader(context: cgContext, text: "REPORTE DE MANTENIMIENTO PREVENTIVO A EQUIPO UPS", x: margin, y: &currentY, width: usableWidth)
				currentY += 5
				
				// --- 2. DATOS GENERALES (Rejilla Compleja) ---
				// Calculamos altura: 6 filas * 20 puntos cada una = 120 puntos
				let datosHeight: CGFloat = 120
				drawGeneralDataGrid(context: cgContext, reporte: reporte, x: margin, y: currentY, width: usableWidth, height: datosHeight)
				currentY += datosHeight + 15
				
				// --- 3. CHECKLIST ---
				drawBoxedHeader(context: cgContext, text: "DESCRIPCIÓN DE ACTIVIDADES", x: margin, y: &currentY, width: usableWidth)
				drawChecklist(context: cgContext, actividades: reporte.actividades, x: margin, y: &currentY, width: usableWidth)
				currentY += 10
				
				// --- 4. TABLA: PARÁMETROS DE SALIDA ---
				drawBoxedHeader(context: cgContext, text: "REVISIÓN DE PARÁMETROS DE OPERACIÓN - SALIDA", x: margin, y: &currentY, width: usableWidth)
				
				// Definición de columnas y datos para SALIDA
				let headersSalida = ["Fase", "Consumo\nCarga (Amp)", "Voltaje\nRegulado", "Frecuencia\nRegulado", "Voltaje\nReserva", "Frecuencia\nReserva"]
				let columnWidthsSalida: [CGFloat] = [50, 90, 90, 90, 90, 90] // Ajusta anchos
				
				let datosSalida = [
					["A", reporte.salidaConsumo.faseA.amp, reporte.salidaRegulado.faseA.volts, reporte.salidaRegulado.faseA.hertz, reporte.salidaReserva.faseA.volts, reporte.salidaReserva.faseA.hertz],
					["B", reporte.salidaConsumo.faseB.amp, reporte.salidaRegulado.faseB.volts, reporte.salidaRegulado.faseB.hertz, reporte.salidaReserva.faseB.volts, reporte.salidaReserva.faseB.hertz],
					["C", reporte.salidaConsumo.faseC.amp, reporte.salidaRegulado.faseC.volts, reporte.salidaRegulado.faseC.hertz, reporte.salidaReserva.faseC.volts, reporte.salidaReserva.faseC.hertz]
				]
				
				drawTable(context: cgContext, headers: headersSalida, data: datosSalida, colWidths: columnWidthsSalida, x: margin, y: &currentY)
				
				// Datos extra debajo de la tabla salida
				drawText("Sincronía: \(reporte.condicionesSincronia)   |   % Carga: \(reporte.porcentajeCarga)   |   Temp: \(reporte.temperatura)", font: .systemFont(ofSize: 10), x: margin, y: &currentY, width: usableWidth)
				currentY += 10
				
				// --- 5. TABLA: PARÁMETROS DE ENTRADA ---
				drawBoxedHeader(context: cgContext, text: "PARÁMETROS DE ENTRADA Y BATERÍAS", x: margin, y: &currentY, width: usableWidth)
				
				let headersEntrada = ["Fase", "Consumo\nEntrada", "Voltaje\nEntrada", "Frecuencia\nEntrada", "Voltaje\nInversor", "Corriente\nInversor"]
				// Reutilizamos anchos similares
				let datosEntrada = [
					["A", reporte.entradaConsumo.faseA.amp, reporte.entradaVoltaje.faseA.volts, reporte.entradaVoltaje.faseA.hertz, reporte.voltajeInversor, reporte.corrienteInversor],
					["B", reporte.entradaConsumo.faseB.amp, reporte.entradaVoltaje.faseB.volts, reporte.entradaVoltaje.faseB.hertz, "-", "-"],
					["C", reporte.entradaConsumo.faseC.amp, reporte.entradaVoltaje.faseC.volts, reporte.entradaVoltaje.faseC.hertz, "V. Flot: \(reporte.voltajeFlotacion)", "Corr. Bat: \(reporte.corrienteBateria)"]
				]
				
				drawTable(context: cgContext, headers: headersEntrada, data: datosEntrada, colWidths: columnWidthsSalida, x: margin, y: &currentY)
				currentY += 15
				
				// --- 6. OBSERVACIONES ---
				drawBoxedHeader(context: cgContext, text: "OBSERVACIONES / REFACCIONES", x: margin, y: &currentY, width: usableWidth)
				let obsRect = CGRect(x: margin, y: currentY, width: usableWidth, height: 40)
				drawBorders(context: cgContext, rect: obsRect)
				drawTextInRect(reporte.refacciones + "\n" + reporte.detalles, rect: obsRect.insetBy(dx: 5, dy: 5), font: .systemFont(ofSize: 10), align: .left)
				currentY += 50
				
				// --- 7. FOTOS Y FIRMAS ---
				// (Lógica de salto de página si es necesario)
				if currentY > (pageSize.height - 200) {
					context.beginPage()
					currentY = margin
				}
				
				if let fotoData = reporte.fotoReporte, let image = UIImage(data: fotoData) {
					drawBoxedHeader(context: cgContext, text: "EVIDENCIA FOTOGRÁFICA", x: margin, y: &currentY, width: usableWidth)
					let imgRect = CGRect(x: margin, y: currentY, width: 200, height: 150)
					image.draw(in: imgRect)
					currentY += 160
				}
				
				// Firmas
				let sigY = currentY + 10
				drawSignatureBox(title: "Firma del Cliente", data: reporte.firmaCliente, rect: CGRect(x: margin, y: sigY, width: 200, height: 60))
				drawSignatureBox(title: "Firma del Técnico", data: reporte.firmaTecnico, rect: CGRect(x: pageSize.width - margin - 200, y: sigY, width: 200, height: 60))
			}
			return url
		} catch {
			print("❌ Error PDF: \(error.localizedDescription)")
			return nil
		}
	}
	
	// MARK: - FUNCIONES DE DIBUJO AVANZADAS
	
	// Dibuja una tabla con cuadrícula
	private func drawTable(context: CGContext, headers: [String], data: [[String]], colWidths: [CGFloat], x: CGFloat, y: inout CGFloat) {
		let rowHeight: CGFloat = 20
		let headerHeight: CGFloat = 30
		
		// 1. Dibujar Encabezados
		var currentX = x
		for (i, header) in headers.enumerated() {
			let w = colWidths[i]
			let rect = CGRect(x: currentX, y: y, width: w, height: headerHeight)
			
			// Fondo Gris
			context.setFillColor(UIColor.systemGray5.cgColor)
			context.fill(rect)
			
			// Borde
			drawBorders(context: context, rect: rect)
			
			// Texto
			drawTextInRect(header, rect: rect, font: .boldSystemFont(ofSize: 9), align: .center)
			
			currentX += w
		}
		y += headerHeight
		
		// 2. Dibujar Datos
		for row in data {
			currentX = x
			for (i, text) in row.enumerated() {
				let w = colWidths[i]
				let rect = CGRect(x: currentX, y: y, width: w, height: rowHeight)
				
				drawBorders(context: context, rect: rect)
				drawTextInRect(text, rect: rect.insetBy(dx: 2, dy: 2), font: .systemFont(ofSize: 10), align: .center)
				
				currentX += w
			}
			y += rowHeight
		}
	}
	
	// Dibuja la rejilla de datos generales (Cliente, Marca, etc)
	// Rejilla de datos generales idéntica a la imagen física
	private func drawGeneralDataGrid(context: CGContext, reporte: Reporte, x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) {
		// Dibujar borde exterior
		let rect = CGRect(x: x, y: y, width: width, height: height)
		drawBorders(context: context, rect: rect)
		
		let rowCount: CGFloat = 6
		let rowH = height / rowCount
		
		// --- DIBUJAR LÍNEAS HORIZONTALES ---
		for i in 1..<Int(rowCount) {
			let lineY = y + (rowH * CGFloat(i))
			context.move(to: CGPoint(x: x, y: lineY))
			context.addLine(to: CGPoint(x: x + width, y: lineY))
		}
		context.strokePath()
		
		// --- FILA 1: Usuario (Completa) ---
		let y1 = y
		drawLabelValue(label: "USUARIO:", value: reporte.cliente, rect: CGRect(x: x, y: y1, width: width, height: rowH))
		
		// --- FILA 2: Mes (60%) | No. Contrato (40%) ---
		let y2 = y + rowH
		let xContrato = x + (width * 0.60)
		// Línea vertical
		context.move(to: CGPoint(x: xContrato, y: y2)); context.addLine(to: CGPoint(x: xContrato, y: y2 + rowH)); context.strokePath()
		
		drawLabelValue(label: "CORRESPONDIENTE AL MES DE:", value: reporte.mesCorrespondiente, rect: CGRect(x: x, y: y2, width: width * 0.60, height: rowH))
		drawLabelValue(label: "Nº DE CONT.:", value: reporte.noContrato, rect: CGRect(x: xContrato, y: y2, width: width * 0.40, height: rowH))
		
		// --- FILA 3: Marca (33%) | Modelo (33%) | Serie (33%) ---
		let y3 = y + (rowH * 2)
		let w3 = width / 3
		// Líneas verticales
		context.move(to: CGPoint(x: x + w3, y: y3)); context.addLine(to: CGPoint(x: x + w3, y: y3 + rowH))
		context.move(to: CGPoint(x: x + (w3 * 2), y: y3)); context.addLine(to: CGPoint(x: x + (w3 * 2), y: y3 + rowH)); context.strokePath()
		
		drawLabelValue(label: "MARCA:", value: reporte.marca, rect: CGRect(x: x, y: y3, width: w3, height: rowH))
		drawLabelValue(label: "MODELO:", value: reporte.modelo, rect: CGRect(x: x + w3, y: y3, width: w3, height: rowH))
		drawLabelValue(label: "Nº DE SERIE:", value: reporte.noSerie, rect: CGRect(x: x + (w3 * 2), y: y3, width: w3, height: rowH))
		
		// --- FILA 4: Responsable (Completa) ---
		let y4 = y + (rowH * 3)
		drawLabelValue(label: "RESPONSABLE:", value: reporte.responsable, rect: CGRect(x: x, y: y4, width: width, height: rowH))
		
		// --- FILA 5: Domicilio (Completa) ---
		let y5 = y + (rowH * 4)
		drawLabelValue(label: "DOMICILIO:", value: reporte.domicilio, rect: CGRect(x: x, y: y5, width: width, height: rowH))
		
		// --- FILA 6: Efectuado por (40%) | Telefono (30%) | Fecha (30%) ---
		let y6 = y + (rowH * 5)
		let xTel = x + (width * 0.40)
		let xFecha = x + (width * 0.70)
		// Líneas verticales
		context.move(to: CGPoint(x: xTel, y: y6)); context.addLine(to: CGPoint(x: xTel, y: y6 + rowH))
		context.move(to: CGPoint(x: xFecha, y: y6)); context.addLine(to: CGPoint(x: xFecha, y: y6 + rowH)); context.strokePath()
		
		drawLabelValue(label: "EFECTUADO POR:", value: reporte.efectuadoPor, rect: CGRect(x: x, y: y6, width: width * 0.40, height: rowH))
		drawLabelValue(label: "TELEFONO:", value: reporte.telefono, rect: CGRect(x: xTel, y: y6, width: width * 0.30, height: rowH))
		
		// Formato de Fecha
		let fechaString = reporte.fechaCreacion.formatted(date: .numeric, time: .omitted)
		drawLabelValue(label: "FECHA:", value: fechaString, rect: CGRect(x: xFecha, y: y6, width: width * 0.30, height: rowH))
	}
	
	private func drawChecklist(context: CGContext, actividades: ActividadesChecklist, x: CGFloat, y: inout CGFloat, width: CGFloat) {
		let items = [
			("Rev. Medidores", actividades.revMedidores), ("Insp. Externa", actividades.inspExterna),
			("Insp. Interna", actividades.inspInterna), ("Ventiladores", actividades.revVentiladores),
			("Paneles", actividades.revPaneles), ("Filtros Aire", actividades.revFiltros),
			("Limpieza Aérea", actividades.limpiezaAerea), ("Limpieza Int.", actividades.limpiezaInt)
		]
		
		let rowHeight: CGFloat = 15
		let colWidth = width / 2
		var currentX = x
		
		for (index, item) in items.enumerated() {
			let check = item.1 ? "[ X ]" : "[   ]"
			let text = "\(check) \(item.0)"
			
			let rect = CGRect(x: currentX, y: y, width: colWidth, height: rowHeight)
			drawBorders(context: context, rect: rect) // Borde opcional para que parezca tabla
			drawTextInRect(text, rect: rect.insetBy(dx: 5, dy: 0), font: .systemFont(ofSize: 10), align: .left)
			
			// Lógica de columnas (2 columnas)
			if index % 2 != 0 {
				currentX = x
				y += rowHeight
			} else {
				currentX += colWidth
			}
		}
		if items.count % 2 != 0 { y += rowHeight } // Ajuste final si es impar
	}
	
	// --- Helpers Genéricos ---
	
	private func drawText(_ text: String, font: UIFont, color: UIColor = .black, x: CGFloat, y: inout CGFloat, width: CGFloat) {
		let attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
		let string = NSAttributedString(string: text, attributes: attributes)
		let height = string.boundingRect(with: CGSize(width: width, height: .infinity), options: .usesLineFragmentOrigin, context: nil).height
		string.draw(in: CGRect(x: x, y: y, width: width, height: height))
		y += height + 2
	}
	
	private func drawBoxedHeader(context: CGContext, text: String, x: CGFloat, y: inout CGFloat, width: CGFloat) {
		let height: CGFloat = 20
		let rect = CGRect(x: x, y: y, width: width, height: height)
		context.setFillColor(UIColor.systemGray4.cgColor)
		context.fill(rect)
		drawBorders(context: context, rect: rect)
		
		let attributes: [NSAttributedString.Key: Any] = [
			.font: UIFont.boldSystemFont(ofSize: 10),
			.paragraphStyle: {
				let p = NSMutableParagraphStyle(); p.alignment = .center; return p
			}()
		]
		NSAttributedString(string: text, attributes: attributes).draw(in: rect.insetBy(dx: 0, dy: 4)) // Centrado vertical manual aprox
		y += height
	}
	
	private func drawBorders(context: CGContext, rect: CGRect) {
		context.setStrokeColor(UIColor.black.cgColor)
		context.setLineWidth(0.5)
		context.addRect(rect)
		context.strokePath()
	}
	
	private func drawTextInRect(_ text: String, rect: CGRect, font: UIFont, align: NSTextAlignment) {
		let style = NSMutableParagraphStyle()
		style.alignment = align
		let attributes: [NSAttributedString.Key: Any] = [.font: font, .paragraphStyle: style]
		
		// Calculamos centro vertical
		let size = text.size(withAttributes: attributes)
		let yOffset = (rect.height - size.height) / 2
		let textRect = CGRect(x: rect.origin.x, y: rect.origin.y + max(0, yOffset), width: rect.width, height: size.height)
		
		text.draw(in: textRect, withAttributes: attributes)
	}
	
	private func drawLabelValue(label: String, value: String, rect: CGRect) {
		let text = "\(label) \(value)"
		drawTextInRect(text, rect: rect.insetBy(dx: 4, dy: 0), font: .systemFont(ofSize: 10), align: .left)
	}
	
	private func drawSignatureBox(title: String, data: Data?, rect: CGRect) {
		let context = UIGraphicsGetCurrentContext()!
		drawBorders(context: context, rect: rect)
		
		let titleRect = CGRect(x: rect.minX, y: rect.maxY - 15, width: rect.width, height: 15)
		drawTextInRect(title, rect: titleRect, font: .systemFont(ofSize: 9), align: .center)
		
		// Línea
		context.move(to: CGPoint(x: rect.minX + 10, y: rect.maxY - 15))
		context.addLine(to: CGPoint(x: rect.maxX - 10, y: rect.maxY - 15))
		context.strokePath()
		
		if let data = data, let img = UIImage(data: data) {
			img.draw(in: CGRect(x: rect.minX + 10, y: rect.minY + 5, width: rect.width - 20, height: rect.height - 25))
		}
	}
}
