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
        // 1. Definición del Formato y Tamaño de Página (A4)
        let pageSize = CGRect(x: 0, y: 0, width: 595.2, height: 841.8)
        let renderer = UIGraphicsPDFRenderer(bounds: pageSize, format: UIGraphicsPDFRendererFormat())
        
        // 2. Definición del Archivo de Destino
        let nombreArchivo = "Reporte_\(UUID().uuidString).pdf" // Usamos UUID para asegurar unicidad
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(nombreArchivo)
        
        // 3. Márgenes y Posición Inicial
        let margin: CGFloat = 40
        var currentY: CGFloat = margin // Posición vertical inicial
        let usableWidth = pageSize.width - (2 * margin)
        
        do {
            try renderer.writePDF(to: url) { context in
                context.beginPage()
                
                // --- Dibujo de la estructura del reporte ---
                
                // Título (Fuente Grande y Negrita)
                let titleFont = UIFont.systemFont(ofSize: 28, weight: .bold)
                let titleAttributes: [NSAttributedString.Key: Any] = [.font: titleFont]
                let titleString = NSAttributedString(string: reporte.titulo, attributes: titleAttributes)
                
                let titleSize = titleString.size()
                
                // Dibuja el título
                titleString.draw(at: CGPoint(x: margin, y: currentY))
                currentY += titleSize.height + 20 // Mueve hacia abajo
                
                // Separador
                let lineRect = CGRect(x: margin, y: currentY, width: usableWidth, height: 1)
                context.cgContext.setFillColor(UIColor.lightGray.cgColor)
                context.cgContext.fill(lineRect)
                currentY += 10
                
                // Metadatos (Fuente Pequeña)
                let metaFont = UIFont.systemFont(ofSize: 12)
                let metaText = "Fecha: \(reporte.fechaCreacion.formatted(date: .long, time: .shortened)) | Usuario: \(reporte.usuarioID)"
                metaText.draw(at: CGPoint(x: margin, y: currentY), withAttributes: [.font: metaFont, .foregroundColor: UIColor.darkGray])
                currentY += 40
                
                // Detalles del Reporte (Fuente Normal)
                let bodyFont = UIFont.systemFont(ofSize: 14)
                let bodyAttributes: [NSAttributedString.Key: Any] = [.font: bodyFont]
                let bodyString = NSAttributedString(string: reporte.detalles, attributes: bodyAttributes)
                
                // Área donde se dibujará el cuerpo del texto
                let textRect = CGRect(x: margin, y: currentY, width: usableWidth, height: pageSize.height - currentY - margin)
                
                // Dibuja el texto dentro del área definida
                bodyString.draw(in: textRect)
                
                // --- Fin del dibujo ---
            }
            // Si llegamos aquí, el PDF se creó con éxito
            return url
            
        } catch {
            // Imprime el error exacto que impide la generación
            print("❌ ERROR al generar PDF: \(error.localizedDescription)")
            // Devuelve nil si hay un error
            return nil
        }
    }
}
