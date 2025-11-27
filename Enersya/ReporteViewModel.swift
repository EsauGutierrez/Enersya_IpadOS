//
//  ReporteViewModel.swift
//  Enersya
//
//  Created by Esau Gutiérrez on 09/10/25.
//

// ReporteViewModel.swift

import Foundation
import Combine
import UIKit // <-- Necesario para UIGraphicsPDFRenderer

// --- ESTRUCTURAS DEL MODELO ---
struct Reporte: Identifiable, Codable, Hashable { // <-- ¡AGREGAR Hashable AQUÍ!
    var id = UUID()
    var titulo: String
    var fechaCreacion: Date
    var detalles: String
    var usuarioID: String
    var firmaCliente: Data?     // Almacenará la imagen de la firma (PNG data)
    var firmaTecnico: Data?     // Almacenará la imagen de la firma del técnico
    var fotoReporte: Data?      // Almacenará la foto tomada (JPEG data)
}

struct Usuario: Identifiable, Codable {
    var id = UUID()
    var nombre: String
    var correo: String
}

// --- VIEW MODEL ---
class ReporteViewModel: ObservableObject {
    @Published var reportes: [Reporte] = []
    @Published var estaAutenticado: Bool = false
    @Published var usuarioActual: Usuario?
    
    // Propiedad calculada para obtener la URL donde se guardarán los reportes
    private var reportesFileURL: URL {
        // Obtenemos el directorio de documentos del usuario
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        // Creamos el nombre del archivo JSON
        return documentDirectory.appendingPathComponent("enersya_reportes.json")
    }
    
    init() {
        cargarReportes()
    }
    
    func iniciarSesion(correo: String, contrasena: String) -> Bool {
        if correo == "user@enersya.com" && contrasena == "1234" {
            self.usuarioActual = Usuario(nombre: "Admin", correo: correo)
            self.estaAutenticado = true
            return true
        }
        return false
    }
    
    func cerrarSesion() {
        self.estaAutenticado = false
        self.usuarioActual = nil
    }
    
    // MARK: - Persistencia de Datos (Guardar)
    
    func guardarReportes() {
        do {
            // 1. Codificar la lista de reportes a formato JSON
            let data = try JSONEncoder().encode(reportes)
            
            // 2. Escribir los datos al archivo
            try data.write(to: reportesFileURL)
            print("✅ Reportes guardados exitosamente en: \(reportesFileURL.path)")
        } catch {
            print("❌ ERROR al guardar reportes: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Persistencia de Datos (Cargar)
    
    func cargarReportes() {
        // 1. Verificar si el archivo existe
        guard FileManager.default.fileExists(atPath: reportesFileURL.path) else {
            // Si no existe, inicializamos con un reporte de ejemplo y guardamos.
            cargarDatosDeMuestra()
            guardarReportes()
            return
        }
        
        do {
            // 2. Leer los datos del archivo
            let data = try Data(contentsOf: reportesFileURL)
            
            // 3. Decodificar los datos JSON a la lista de reportes
            reportes = try JSONDecoder().decode([Reporte].self, from: data)
            print("✅ Reportes cargados exitosamente. Cantidad: \(reportes.count)")
        } catch {
            print("❌ ERROR al cargar reportes: \(error.localizedDescription)")
            // Si hay un error de carga, inicializamos con datos de muestra para evitar un crash
            cargarDatosDeMuestra()
        }
    }
    
    
    func agregarReporteConDatos(titulo: String, detalles: String, firmaCliente: Data?, firmaTecnico: Data?, fotoReporte: Data?) {
        guard let usuarioID = usuarioActual?.correo else { return }

        let nuevoReporte = Reporte(
            titulo: titulo,
            fechaCreacion: Date(),
            detalles: detalles,
            usuarioID: usuarioID,
            firmaCliente: firmaCliente, // <-- Asignación de nuevos datos
            firmaTecnico: firmaTecnico, // <-- Asignación de nuevos datos
            fotoReporte: fotoReporte    // <-- Asignación de nuevos datos
        )
        reportes.append(nuevoReporte)
        
        guardarReportes()
    }
	
	func eliminarReporte(_ reporte: Reporte) {
			// Buscamos el índice del reporte en el array principal usando su ID
			if let index = reportes.firstIndex(where: { $0.id == reporte.id }) {
				reportes.remove(at: index)
				// IMPORTANTE: Guardar los cambios inmediatamente
				guardarReportes()
				print("🗑️ Reporte eliminado: \(reporte.titulo)")
			}
		}
    
    // Función de muestra (para la primera ejecución)
    private func cargarDatosDeMuestra() {
        // Si no hay datos, inicializa con al menos un reporte
        reportes = [
            Reporte(titulo: "Inspección Inicial (Muestra)", fechaCreacion: Calendar.current.date(byAdding: .day, value: -5, to: Date())!, detalles: "Este es un reporte de muestra cargado por defecto.", usuarioID: "admin@enersya.com")
        ]
    }
}



extension ReporteViewModel {
		
		func generarPDF(para reporte: Reporte) -> URL? {
			// 1. Configuración de página A4
			let pageSize = CGRect(x: 0, y: 0, width: 595.2, height: 841.8)
			let renderer = UIGraphicsPDFRenderer(bounds: pageSize, format: UIGraphicsPDFRendererFormat())
			
			let nombreArchivo = "Reporte_\(UUID().uuidString).pdf"
			let url = FileManager.default.temporaryDirectory.appendingPathComponent(nombreArchivo)

			// Configuración de márgenes
			let margin: CGFloat = 40
			var currentY: CGFloat = margin
			let usableWidth = pageSize.width - (2 * margin)
			
			do {
				try renderer.writePDF(to: url) { context in
					context.beginPage()
					
					// --- A. ENCABEZADO ---
					// Título
					let titleFont = UIFont.systemFont(ofSize: 26, weight: .bold)
					let titleAttributes: [NSAttributedString.Key: Any] = [.font: titleFont]
					let titleString = NSAttributedString(string: reporte.titulo, attributes: titleAttributes)
					titleString.draw(at: CGPoint(x: margin, y: currentY))
					currentY += titleString.size().height + 10
					
					// Metadatos (Fecha y Usuario)
					let metaFont = UIFont.systemFont(ofSize: 12)
					let metaText = "Fecha: \(reporte.fechaCreacion.formatted(date: .long, time: .shortened)) | Técnico: \(reporte.usuarioID)"
					metaText.draw(at: CGPoint(x: margin, y: currentY), withAttributes: [.font: metaFont, .foregroundColor: UIColor.gray])
					currentY += 20
					
					// Línea separadora
					let contextCG = context.cgContext
					contextCG.setStrokeColor(UIColor.lightGray.cgColor)
					contextCG.setLineWidth(1.0)
					contextCG.move(to: CGPoint(x: margin, y: currentY))
					contextCG.addLine(to: CGPoint(x: pageSize.width - margin, y: currentY))
					contextCG.strokePath()
					currentY += 20
					
					// --- B. DETALLES (TEXTO) ---
					let bodyFont = UIFont.systemFont(ofSize: 12)
					let bodyAttributes: [NSAttributedString.Key: Any] = [.font: bodyFont]
					let bodyString = NSAttributedString(string: "Descripción:\n" + reporte.detalles, attributes: bodyAttributes)
					
					// Calcular altura necesaria para el texto
					let textHeight = bodyString.boundingRect(
						with: CGSize(width: usableWidth, height: .greatestFiniteMagnitude),
						options: .usesLineFragmentOrigin,
						context: nil
					).height
					
					let textRect = CGRect(x: margin, y: currentY, width: usableWidth, height: textHeight)
					bodyString.draw(in: textRect)
					
					currentY += textHeight + 20 // Actualizamos Y basándonos en el texto escrito
					
					// --- C. FOTO DEL REPORTE ---
					if let fotoData = reporte.fotoReporte, let image = UIImage(data: fotoData) {
						// Título de sección
						"EVIDENCIA FOTOGRÁFICA:".draw(at: CGPoint(x: margin, y: currentY), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 12)])
						currentY += 15
						
						// Definir tamaño de imagen (máximo media página de alto, ancho completo)
						let maxHeight: CGFloat = 250
						let aspectRatio = image.size.width / image.size.height
						let targetHeight = min(usableWidth / aspectRatio, maxHeight)
						let targetWidth = targetHeight * aspectRatio
						
						// Centrar imagen
						let xOffset = (usableWidth - targetWidth) / 2
						
						let imageRect = CGRect(x: margin + xOffset, y: currentY, width: targetWidth, height: targetHeight)
						image.draw(in: imageRect)
						
						currentY += targetHeight + 30
					}
					
					// Chequeo de seguridad: Si estamos muy abajo, nueva página para firmas
					if currentY > (pageSize.height - 150) {
						context.beginPage()
						currentY = margin
					}
					
					// --- D. FIRMAS ---
					let signatureWidth = (usableWidth - 20) / 2 // Dos columnas
					let signatureHeight: CGFloat = 80
					let signatureY = currentY
					
					// 1. Firma Cliente (Izquierda)
					drawSignatureBlock(
						title: "Firma del Cliente",
						data: reporte.firmaCliente,
						rect: CGRect(x: margin, y: signatureY, width: signatureWidth, height: signatureHeight)
					)
					
					// 2. Firma Técnico (Derecha)
					drawSignatureBlock(
						title: "Firma del Técnico",
						data: reporte.firmaTecnico,
						rect: CGRect(x: margin + signatureWidth + 20, y: signatureY, width: signatureWidth, height: signatureHeight)
					)
				}
				return url
				
			} catch {
				print("❌ ERROR al generar PDF: \(error.localizedDescription)")
				return nil
			}
		}
		
		// Función auxiliar para dibujar bloques de firma
		private func drawSignatureBlock(title: String, data: Data?, rect: CGRect) {
			// Dibujar línea de firma
			let lineY = rect.maxY - 15
			let path = UIBezierPath()
			path.move(to: CGPoint(x: rect.minX + 10, y: lineY))
			path.addLine(to: CGPoint(x: rect.maxX - 10, y: lineY))
			UIColor.black.setStroke()
			path.lineWidth = 1
			path.stroke()
			
			// Texto debajo de la línea
			let style = NSMutableParagraphStyle()
			style.alignment = .center
			let attributes: [NSAttributedString.Key: Any] = [
				.font: UIFont.systemFont(ofSize: 10),
				.paragraphStyle: style
			]
			
			title.draw(in: CGRect(x: rect.minX, y: lineY + 5, width: rect.width, height: 15), withAttributes: attributes)
			
			// Dibujar la imagen de la firma si existe
			if let data = data, let image = UIImage(data: data) {
				// Ajustar imagen para que "flote" sobre la línea
				let imageRect = CGRect(x: rect.minX + 10, y: rect.minY, width: rect.width - 20, height: rect.height - 20)
				image.draw(in: imageRect)
			}
	}
}
