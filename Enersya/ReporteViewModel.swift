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

@MainActor
class ReporteViewModel: ObservableObject {
    @Published var reportes: [Reporte] = []
    @Published var estaAutenticado: Bool = false
    @Published var usuarioActual: Usuario?
    @Published var cargando: Bool = false
    @Published var errorMensaje: String?

    private let api = APIService.shared

    private var reportesFileURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent("enersya_reportes.json")
    }

    init() {
        // Restaurar sesión si quedó un token guardado de la sesión anterior
        estaAutenticado = api.estaAutenticado
        if estaAutenticado { cargarReportesLocales() }
    }

    // MARK: - Autenticación

    func iniciarSesion(correo: String, contrasena: String) async {
        cargando = true
        errorMensaje = nil
        do {
            let respuesta = try await api.login(correo: correo, contrasena: contrasena)
            usuarioActual = Usuario(nombre: respuesta.usuario.nombre, correo: respuesta.usuario.correo)
            estaAutenticado = true
            cargarReportesLocales()
        } catch let error as APIError {
            errorMensaje = error.errorDescription
        } catch {
            errorMensaje = "Error de conexión. Verifica tu internet."
        }
        cargando = false
    }

    func cerrarSesion() async {
        await api.logout()
        estaAutenticado = false
        usuarioActual = nil
        reportes = []
    }

    // MARK: - Gestión de Reportes

    func guardarNuevoReporte(_ reporte: Reporte) async {
        // Guardado local inmediato para respuesta instantánea en la UI
        reportes.append(reporte)
        guardarReportesLocales()
        // Sincronización al servidor + subida de PDF en segundo plano
        Task {
            try? await api.crearReporte(reporte)
            if let pdfURL = generarPDF(para: reporte) {
                try? await api.subirPDF(reporteId: reporte.id.uuidString, pdfURL: pdfURL)
            }
        }
    }

    func eliminarReporte(_ reporte: Reporte) async {
        // Eliminación local inmediata
        if let index = reportes.firstIndex(where: { $0.id == reporte.id }) {
            reportes.remove(at: index)
            guardarReportesLocales()
        }
        // Sincronización al servidor en segundo plano
        Task { try? await api.eliminarReporte(id: reporte.id.uuidString) }
    }

    // MARK: - Persistencia Local (caché offline)

    private func guardarReportesLocales() {
        do {
            let data = try JSONEncoder().encode(reportes)
            try data.write(to: reportesFileURL)
        } catch {
            print("❌ Error al guardar: \(error.localizedDescription)")
        }
    }

    private func cargarReportesLocales() {
        guard FileManager.default.fileExists(atPath: reportesFileURL.path) else { return }
        do {
            let data = try Data(contentsOf: reportesFileURL)
            reportes = try JSONDecoder().decode([Reporte].self, from: data)
        } catch {
            print("❌ Error al cargar: \(error.localizedDescription)")
        }
    }
}




import UIKit
import PDFKit

extension ReporteViewModel {
    
    func generarPDF(para reporte: Reporte) -> URL? {
        // Formato Carta (8.5 x 11 pulgadas)
        let pageSize = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: pageSize, format: UIGraphicsPDFRendererFormat())
        
        let nombreArchivo = "Reporte_\(reporte.noContrato)_\(UUID().uuidString.prefix(5)).pdf"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(nombreArchivo)
        
        let margin: CGFloat = 30
        var currentY: CGFloat = margin
        let usableWidth = pageSize.width - (2 * margin)
        
        do {
            try renderer.writePDF(to: url) { context in
                context.beginPage()
                let cgContext = context.cgContext
                
                // --- 1. ENCABEZADO CON LOGO Y FOLIO ---
                let startY = currentY
                if let logoImage = UIImage(named: "LogoEnersya") {
                    let logoWidth: CGFloat = 150
                    let aspectRatio = logoImage.size.height / logoImage.size.width
                    let logoHeight = logoWidth * aspectRatio
                    
                    let logoRect = CGRect(x: margin, y: currentY, width: logoWidth, height: logoHeight)
                    logoImage.draw(in: logoRect)
                    
                    let direccionX = margin + logoWidth + 20
                    let direccionWidth = usableWidth - logoWidth - 100 // Dejamos espacio para el folio
                    var textY = currentY
                    
                    drawText("Enersya, energia y asesoría", font: .boldSystemFont(ofSize: 12), x: direccionX, y: &textY, width: direccionWidth)
                    drawText("Tel: 331370-3246", font: .systemFont(ofSize: 9), x: direccionX, y: &textY, width: direccionWidth)
                    drawText("www.enersya.com", font: .systemFont(ofSize: 9, weight: .bold), color: .blue, x: direccionX, y: &textY, width: direccionWidth)
                    
                    currentY += max(logoHeight, (textY - currentY)) + 20
                } else {
                    drawText("enersya | SCEI", font: .boldSystemFont(ofSize: 22), color: .systemBlue, x: margin, y: &currentY, width: usableWidth)
                    currentY += 30
                }
                
                // Dibujar FOLIO rojo en la esquina superior derecha
                let folioString = String(format: "%04d", reporte.folio)
                let folioStyle = NSMutableParagraphStyle()
                folioStyle.alignment = .right
                let folioAttr: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 18),
                    .foregroundColor: UIColor.red,
                    .paragraphStyle: folioStyle
                ]
                NSAttributedString(string: folioString, attributes: folioAttr).draw(in: CGRect(x: pageSize.width - margin - 100, y: startY + 20, width: 100, height: 25))
                
                // Título del Reporte
                drawBoxedHeader(context: cgContext, text: "REPORTE DE MANTENIMIENTO PREVENTIVO A EQUIPO UPS", x: margin, y: &currentY, width: usableWidth)
                currentY += 5
                
                // --- 2. DATOS GENERALES ---
                let datosHeight: CGFloat = 120
                drawGeneralDataGrid(context: cgContext, reporte: reporte, x: margin, y: currentY, width: usableWidth, height: datosHeight)
                currentY += datosHeight + 15
                
                // --- 3. CHECKLIST ---
                drawBoxedHeader(context: cgContext, text: "DESCRIPCIÓN DE ACTIVIDADES", x: margin, y: &currentY, width: usableWidth)
                drawChecklist(context: cgContext, actividades: reporte.actividades, x: margin, y: &currentY, width: usableWidth)
                currentY += 10
                
                // --- CÁLCULO DE COLUMNAS PARA ANCHO COMPLETO ---
                // Dividimos el ancho total: La primera columna (Fase) es más pequeña, las demás se reparten el resto.
                let widthFase: CGFloat = 35
                let widthParam = (usableWidth - widthFase) / 5
                let columnWidths: [CGFloat] = [widthFase, widthParam, widthParam, widthParam, widthParam, widthParam]
                
                // --- 4. TABLA: PARÁMETROS DE SALIDA ---
                drawBoxedHeader(context: cgContext, text: "REVISIÓN DE PARÁMETROS DE OPERACIÓN - SALIDA", x: margin, y: &currentY, width: usableWidth)
                
                let headersSalida = ["Fase", "Consumo\nCarga (Amp)", "Voltaje\nRegulado", "Frecuencia\nRegulado", "Voltaje\nReserva", "Frecuencia\nReserva"]
                let datosSalida = [
                    ["A", reporte.salidaConsumo.faseA.amp, reporte.salidaRegulado.faseA.volts, reporte.salidaRegulado.faseA.hertz, reporte.salidaReserva.faseA.volts, reporte.salidaReserva.faseA.hertz],
                    ["B", reporte.salidaConsumo.faseB.amp, reporte.salidaRegulado.faseB.volts, reporte.salidaRegulado.faseB.hertz, reporte.salidaReserva.faseB.volts, reporte.salidaReserva.faseB.hertz],
                    ["C", reporte.salidaConsumo.faseC.amp, reporte.salidaRegulado.faseC.volts, reporte.salidaRegulado.faseC.hertz, reporte.salidaReserva.faseC.volts, reporte.salidaReserva.faseC.hertz]
                ]
                
                drawTable(context: cgContext, headers: headersSalida, data: datosSalida, colWidths: columnWidths, x: margin, y: &currentY)
                
                // Datos extra: Cambio a "Respalda:" y Grados °C automáticos
                let tempStr = reporte.temperatura.contains("°C") ? reporte.temperatura : "\(reporte.temperatura) °C"
                drawText("Respalda: \(reporte.condicionesSincronia)   |   % Carga: \(reporte.porcentajeCarga)   |   Temp: \(tempStr)", font: .systemFont(ofSize: 10), x: margin, y: &currentY, width: usableWidth)
                currentY += 10
                
                // --- 5. TABLA: PARÁMETROS DE ENTRADA ---
                drawBoxedHeader(context: cgContext, text: "PARÁMETROS DE ENTRADA Y BATERÍAS", x: margin, y: &currentY, width: usableWidth)
                
                let headersEntrada = ["Fase", "Consumo\nEntrada (Amp)", "Voltaje\nEntrada", "Frecuencia\nEntrada", "Voltaje\nInversor", "Corriente\nInversor"]
                let datosEntrada = [
                    ["A", reporte.entradaConsumo.faseA.amp, reporte.entradaConsumo.faseA.volts, reporte.entradaConsumo.faseA.hertz, reporte.voltajeInversor, reporte.corrienteInversor],
                    ["B", reporte.entradaConsumo.faseB.amp, reporte.entradaConsumo.faseB.volts, reporte.entradaConsumo.faseB.hertz, "-", "-"],
                    ["C", reporte.entradaConsumo.faseC.amp, reporte.entradaConsumo.faseC.volts, reporte.entradaConsumo.faseC.hertz, "V. Flot: \(reporte.voltajeFlotacion)", "Corr. Bat: \(reporte.corrienteBateria)"]
                ]
                
                drawTable(context: cgContext, headers: headersEntrada, data: datosEntrada, colWidths: columnWidths, x: margin, y: &currentY)
                currentY += 15
                
                // *** NUEVA SECCIÓN PARA EL PDF: PARÁMETROS DE BY PASS ***
                drawBoxedHeader(context: cgContext, text: "REVISIÓN DE PARÁMETROS - BY PASS", x: margin, y: &currentY, width: usableWidth)
                
                // Usamos 6 columnas para mantener el diseño, dejando las dos últimas vacías con un guión "-"
                let headersBypass = ["Fase", "Consumo\n(Amp)", "Voltaje", "Frecuencia", "-", "-"]
                let datosBypass = [
                    ["A", reporte.parametrosBypass.faseA.amp, reporte.parametrosBypass.faseA.volts, reporte.parametrosBypass.faseA.hertz, "-", "-"],
                    ["B", reporte.parametrosBypass.faseB.amp, reporte.parametrosBypass.faseB.volts, reporte.parametrosBypass.faseB.hertz, "-", "-"],
                    ["C", reporte.parametrosBypass.faseC.amp, reporte.parametrosBypass.faseC.volts, reporte.parametrosBypass.faseC.hertz, "-", "-"]
                ]
                
                drawTable(context: cgContext, headers: headersBypass, data: datosBypass, colWidths: columnWidths, x: margin, y: &currentY)
                currentY += 15
                
                // --- 6. REFACCIONES Y OBSERVACIONES (separadas) ---
                let seccionWidth = (usableWidth - 10) / 2
                let seccionHeight: CGFloat = 50

                // Encabezado izquierdo: Refacciones
                let refHeaderRect = CGRect(x: margin, y: currentY, width: seccionWidth, height: 16)
                cgContext.setFillColor(UIColor.systemGray4.cgColor)
                cgContext.fill(refHeaderRect)
                drawBorders(context: cgContext, rect: refHeaderRect)
                drawTextInRect("REFACCIONES EMPLEADAS", rect: refHeaderRect, font: .boldSystemFont(ofSize: 8), align: .center)

                // Encabezado derecho: Observaciones
                let obsHeaderRect = CGRect(x: margin + seccionWidth + 10, y: currentY, width: seccionWidth, height: 16)
                cgContext.setFillColor(UIColor.systemGray4.cgColor)
                cgContext.fill(obsHeaderRect)
                drawBorders(context: cgContext, rect: obsHeaderRect)
                drawTextInRect("OBSERVACIONES GENERALES", rect: obsHeaderRect, font: .boldSystemFont(ofSize: 8), align: .center)

                currentY += 16

                // Contenido izquierdo: Refacciones
                let refContentRect = CGRect(x: margin, y: currentY, width: seccionWidth, height: seccionHeight)
                drawBorders(context: cgContext, rect: refContentRect)
                drawTextInRect(reporte.refacciones, rect: refContentRect.insetBy(dx: 4, dy: 4), font: .systemFont(ofSize: 9), align: .left)

                // Contenido derecho: Observaciones
                let obsContentRect = CGRect(x: margin + seccionWidth + 10, y: currentY, width: seccionWidth, height: seccionHeight)
                drawBorders(context: cgContext, rect: obsContentRect)
                drawTextInRect(reporte.detalles, rect: obsContentRect.insetBy(dx: 4, dy: 4), font: .systemFont(ofSize: 9), align: .left)

                currentY += seccionHeight + 10
                
                // --- 7. EVIDENCIA FOTOGRÁFICA (GALERÍA) ---
                if !reporte.fotosReporte.isEmpty {
                    if currentY > (pageSize.height - 200) {
                        context.beginPage()
                        currentY = margin
                    }
                    
                    drawBoxedHeader(context: cgContext, text: "EVIDENCIA FOTOGRÁFICA", x: margin, y: &currentY, width: usableWidth)
                    currentY += 10
                    
                    let spacing: CGFloat = 10
                    let photoWidth = (usableWidth - spacing) / 2
                    let photoHeight: CGFloat = 160
                    
                    for (index, fotoData) in reporte.fotosReporte.enumerated() {
                        if let image = UIImage(data: fotoData) {
                            let isRightColumn = index % 2 != 0
                            let xPos = isRightColumn ? (margin + photoWidth + spacing) : margin
                            
                            if !isRightColumn {
                                if currentY + photoHeight > (pageSize.height - margin) {
                                    context.beginPage()
                                    currentY = margin
                                }
                            }
                            
                            let imgRect = CGRect(x: xPos, y: currentY, width: photoWidth, height: photoHeight)
                            drawBorders(context: cgContext, rect: imgRect)
                            
                            let imageRatio = image.size.width / image.size.height
                            let rectRatio = imgRect.width / imgRect.height
                            var drawRect = imgRect
                            
                            if imageRatio > rectRatio {
                                let newWidth = imgRect.height * imageRatio
                                drawRect = CGRect(x: imgRect.midX - newWidth/2, y: imgRect.minY, width: newWidth, height: imgRect.height)
                            } else {
                                let newHeight = imgRect.width / imageRatio
                                drawRect = CGRect(x: imgRect.minX, y: imgRect.midY - newHeight/2, width: imgRect.width, height: newHeight)
                            }
                            
                            cgContext.saveGState()
                            cgContext.addRect(imgRect)
                            cgContext.clip()
                            image.draw(in: drawRect)
                            cgContext.restoreGState()
                            
                            if isRightColumn {
                                currentY += photoHeight + spacing
                            }
                        }
                    }
                    if reporte.fotosReporte.count % 2 != 0 {
                        currentY += photoHeight + spacing
                    }
                    currentY += 10
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
    
    private func drawTable(context: CGContext, headers: [String], data: [[String]], colWidths: [CGFloat], x: CGFloat, y: inout CGFloat) {
        let rowHeight: CGFloat = 20
        let headerHeight: CGFloat = 30
        var currentX = x
        for (i, header) in headers.enumerated() {
            let w = colWidths[i]
            let rect = CGRect(x: currentX, y: y, width: w, height: headerHeight)
            context.setFillColor(UIColor.systemGray5.cgColor)
            context.fill(rect)
            drawBorders(context: context, rect: rect)
            drawTextInRect(header, rect: rect, font: .boldSystemFont(ofSize: 9), align: .center)
            currentX += w
        }
        y += headerHeight
        
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
    
    private func drawGeneralDataGrid(context: CGContext, reporte: Reporte, x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) {
        let rect = CGRect(x: x, y: y, width: width, height: height)
        drawBorders(context: context, rect: rect)
        
        let rowCount: CGFloat = 6
        let rowH = height / rowCount
        
        for i in 1..<Int(rowCount) {
            let lineY = y + (rowH * CGFloat(i))
            context.move(to: CGPoint(x: x, y: lineY))
            context.addLine(to: CGPoint(x: x + width, y: lineY))
        }
        context.strokePath()
        
        let y1 = y
        drawLabelValue(label: "USUARIO:", value: reporte.cliente, rect: CGRect(x: x, y: y1, width: width, height: rowH))
        
        let y2 = y + rowH
        let xContrato = x + (width * 0.60)
        context.move(to: CGPoint(x: xContrato, y: y2)); context.addLine(to: CGPoint(x: xContrato, y: y2 + rowH)); context.strokePath()
        drawLabelValue(label: "CORRESPONDIENTE AL MES DE:", value: reporte.mesCorrespondiente, rect: CGRect(x: x, y: y2, width: width * 0.60, height: rowH))
        drawLabelValue(label: "Nº DE CONT.:", value: reporte.noContrato, rect: CGRect(x: xContrato, y: y2, width: width * 0.40, height: rowH))
        
        let y3 = y + (rowH * 2)
        let w3 = width / 3
        context.move(to: CGPoint(x: x + w3, y: y3)); context.addLine(to: CGPoint(x: x + w3, y: y3 + rowH))
        context.move(to: CGPoint(x: x + (w3 * 2), y: y3)); context.addLine(to: CGPoint(x: x + (w3 * 2), y: y3 + rowH)); context.strokePath()
        drawLabelValue(label: "MARCA:", value: reporte.marca, rect: CGRect(x: x, y: y3, width: w3, height: rowH))
        drawLabelValue(label: "MODELO:", value: reporte.modelo, rect: CGRect(x: x + w3, y: y3, width: w3, height: rowH))
        drawLabelValue(label: "Nº DE SERIE:", value: reporte.noSerie, rect: CGRect(x: x + (w3 * 2), y: y3, width: w3, height: rowH))
        
        let y4 = y + (rowH * 3)
        drawLabelValue(label: "RESPONSABLE:", value: reporte.responsable, rect: CGRect(x: x, y: y4, width: width, height: rowH))
        
        let y5 = y + (rowH * 4)
        drawLabelValue(label: "DOMICILIO:", value: reporte.domicilio, rect: CGRect(x: x, y: y5, width: width, height: rowH))
        
        let y6 = y + (rowH * 5)
        let xTel = x + (width * 0.40)
        let xFecha = x + (width * 0.70)
        context.move(to: CGPoint(x: xTel, y: y6)); context.addLine(to: CGPoint(x: xTel, y: y6 + rowH))
        context.move(to: CGPoint(x: xFecha, y: y6)); context.addLine(to: CGPoint(x: xFecha, y: y6 + rowH)); context.strokePath()
        
        drawLabelValue(label: "EFECTUADO POR:", value: reporte.efectuadoPor, rect: CGRect(x: x, y: y6, width: width * 0.40, height: rowH))
        drawLabelValue(label: "TELEFONO:", value: reporte.telefono, rect: CGRect(x: xTel, y: y6, width: width * 0.30, height: rowH))
        
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
            // *** CAMBIAMOS LA X POR LA PALOMITA AQUÍ ***
            let check = item.1 ? "[ ✓ ]" : "[   ]"
            let text = "\(check) \(item.0)"
            
            let rect = CGRect(x: currentX, y: y, width: colWidth, height: rowHeight)
            drawBorders(context: context, rect: rect)
            drawTextInRect(text, rect: rect.insetBy(dx: 5, dy: 0), font: .systemFont(ofSize: 10), align: .left)
            
            if index % 2 != 0 {
                currentX = x
                y += rowHeight
            } else {
                currentX += colWidth
            }
        }
        if items.count % 2 != 0 { y += rowHeight }
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
        NSAttributedString(string: text, attributes: attributes).draw(in: rect.insetBy(dx: 0, dy: 4))
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
        
        context.move(to: CGPoint(x: rect.minX + 10, y: rect.maxY - 15))
        context.addLine(to: CGPoint(x: rect.maxX - 10, y: rect.maxY - 15))
        context.strokePath()
        
        if let data = data, let img = UIImage(data: data) {
            img.draw(in: CGRect(x: rect.minX + 10, y: rect.minY + 5, width: rect.width - 20, height: rect.height - 25))
        }
    }
}
