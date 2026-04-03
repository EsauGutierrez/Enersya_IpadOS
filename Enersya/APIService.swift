//
//  APIService.swift
//  Enersya
//

import Foundation

// MARK: - Modelos de Respuesta

struct LoginRespuesta: Codable {
    let token: String
    let usuario: UsuarioAPI
}

struct UsuarioAPI: Codable {
    let id: String
    let nombre: String
    let correo: String
}

struct CrearReporteRespuesta: Codable {
    let folio: Int
    let id: String
}

// Payload que serializa un Reporte hacia la API (sin imágenes, se suben por separado)
struct ReportePayload: Encodable {
    let id: String
    let cliente: String
    let mesCorrespondiente: String
    let responsable: String
    let domicilio: String
    let efectuadoPor: String
    let telefono: String
    let marca: String
    let modelo: String
    let noSerie: String
    let noContrato: String
    let fechaCreacion: String
    let actividades: ActividadesChecklist
    let salidaConsumo: ParametrosFase
    let salidaRegulado: ParametrosFase
    let salidaReserva: ParametrosFase
    let entradaConsumo: ParametrosFase
    let entradaVoltaje: ParametrosFase
    let parametrosBypass: ParametrosFase
    let condicionesSincronia: String
    let porcentajeCarga: String
    let temperatura: String
    let voltajeInversor: String
    let corrienteInversor: String
    let corrienteBateria: String
    let voltajeFlotacion: String
    let refacciones: String
    let detalles: String

    init(reporte: Reporte) {
        self.id                  = reporte.id.uuidString
        self.cliente             = reporte.cliente
        self.mesCorrespondiente  = reporte.mesCorrespondiente
        self.responsable         = reporte.responsable
        self.domicilio           = reporte.domicilio
        self.efectuadoPor        = reporte.efectuadoPor
        self.telefono            = reporte.telefono
        self.marca               = reporte.marca
        self.modelo              = reporte.modelo
        self.noSerie             = reporte.noSerie
        self.noContrato          = reporte.noContrato
        self.fechaCreacion       = ISO8601DateFormatter().string(from: reporte.fechaCreacion)
        self.actividades         = reporte.actividades
        self.salidaConsumo       = reporte.salidaConsumo
        self.salidaRegulado      = reporte.salidaRegulado
        self.salidaReserva       = reporte.salidaReserva
        self.entradaConsumo      = reporte.entradaConsumo
        self.entradaVoltaje      = reporte.entradaVoltaje
        self.parametrosBypass    = reporte.parametrosBypass
        self.condicionesSincronia = reporte.condicionesSincronia
        self.porcentajeCarga     = reporte.porcentajeCarga
        self.temperatura         = reporte.temperatura
        self.voltajeInversor     = reporte.voltajeInversor
        self.corrienteInversor   = reporte.corrienteInversor
        self.corrienteBateria    = reporte.corrienteBateria
        self.voltajeFlotacion    = reporte.voltajeFlotacion
        self.refacciones         = reporte.refacciones
        self.detalles            = reporte.detalles
    }
}

// MARK: - Errores

enum APIError: LocalizedError {
    case credencialesInvalidas
    case sinConexion
    case errorServidor

    var errorDescription: String? {
        switch self {
        case .credencialesInvalidas: return "Correo o contraseña incorrectos"
        case .sinConexion:           return "Sin conexión. Verifica tu internet."
        case .errorServidor:         return "Error en el servidor. Intenta más tarde."
        }
    }
}

// MARK: - APIService

class APIService {
    static let shared = APIService()
    private init() {}

    let baseURL = "https://www.enersya.com/api"

    private(set) var token: String? {
        get { UserDefaults.standard.string(forKey: "enersya_token") }
        set { UserDefaults.standard.set(newValue, forKey: "enersya_token") }
    }

    var estaAutenticado: Bool { token != nil }

    // MARK: - Autenticación

    func login(correo: String, contrasena: String) async throws -> LoginRespuesta {
        let url = URL(string: "\(baseURL)/auth/login.php")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["correo": correo, "contrasena": contrasena])

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw APIError.errorServidor }
        if http.statusCode == 401 { throw APIError.credencialesInvalidas }
        guard http.statusCode == 200 else { throw APIError.errorServidor }

        let respuesta = try JSONDecoder().decode(LoginRespuesta.self, from: data)
        self.token = respuesta.token
        return respuesta
    }

    func logout() async {
        guard let token else { return }
        let url = URL(string: "\(baseURL)/auth/logout.php")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        _ = try? await URLSession.shared.data(for: request)
        self.token = nil
    }

    // MARK: - Reportes

    func crearReporte(_ reporte: Reporte) async throws -> CrearReporteRespuesta {
        let url = URL(string: "\(baseURL)/reportes/crear.php")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        agregarToken(a: &request)
        request.httpBody = try JSONEncoder().encode(ReportePayload(reporte: reporte))

        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 201 else { throw APIError.errorServidor }

        let respuesta = try JSONDecoder().decode(CrearReporteRespuesta.self, from: data)

        // Subir fotos y firmas en segundo plano sin bloquear la UI
        Task {
            for (i, foto) in reporte.fotosReporte.enumerated() {
                try? await subirArchivo(reporteId: reporte.id.uuidString, data: foto, tipo: "foto", orden: i)
            }
            if let firma = reporte.firmaCliente {
                try? await subirArchivo(reporteId: reporte.id.uuidString, data: firma, tipo: "firma_cliente")
            }
            if let firma = reporte.firmaTecnico {
                try? await subirArchivo(reporteId: reporte.id.uuidString, data: firma, tipo: "firma_tecnico")
            }
        }

        return respuesta
    }

    func subirPDF(reporteId: String, pdfURL: URL) async throws {
        let pdfData = try Data(contentsOf: pdfURL)
        let url = URL(string: "\(baseURL)/reportes/subir_pdf.php")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        agregarToken(a: &request)

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        body.append("--\(boundary)\r\nContent-Disposition: form-data; name=\"reporte_id\"\r\n\r\n\(reporteId)\r\n".data(using: .utf8)!)
        body.append("--\(boundary)\r\nContent-Disposition: form-data; name=\"pdf\"; filename=\"reporte.pdf\"\r\nContent-Type: application/pdf\r\n\r\n".data(using: .utf8)!)
        body.append(pdfData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        _ = try await URLSession.shared.data(for: request)
    }

    func eliminarReporte(id: String) async throws {
        let url = URL(string: "\(baseURL)/reportes/eliminar.php")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        agregarToken(a: &request)
        request.httpBody = try JSONEncoder().encode(["id": id])

        let (_, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw APIError.errorServidor }
    }

    // MARK: - Archivos (privado)

    private func subirArchivo(reporteId: String, data: Data, tipo: String, orden: Int = 0) async throws {
        let url = URL(string: "\(baseURL)/archivos/subir.php")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        agregarToken(a: &request)

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        for (key, value) in ["reporte_id": reporteId, "tipo": tipo, "orden": "\(orden)"] {
            body.append("--\(boundary)\r\nContent-Disposition: form-data; name=\"\(key)\"\r\n\r\n\(value)\r\n".data(using: .utf8)!)
        }
        body.append("--\(boundary)\r\nContent-Disposition: form-data; name=\"archivo\"; filename=\"imagen.jpg\"\r\nContent-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(data)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        _ = try await URLSession.shared.data(for: request)
    }

    private func agregarToken(a request: inout URLRequest) {
        if let token { request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
    }
}
