//
//  DataModels.swift
//  Enersya
//
//  Created by Esau Gutierrez Tejeida on 01/12/25.
//

// DataModels.swift
import Foundation

struct Usuario: Identifiable, Codable {
	var id = UUID()
	var nombre: String
	var correo: String
}

// 1. Estructura para una lectura eléctrica individual (Amp, Volts, Hz)
struct LecturaElectrica: Codable, Hashable {
	var amp: String = ""
	var volts: String = ""
	var hertz: String = ""
}

// 2. Estructura para agrupar las 3 fases (A, B, C)
struct ParametrosFase: Codable, Hashable {
	var faseA: LecturaElectrica = LecturaElectrica()
	var faseB: LecturaElectrica = LecturaElectrica()
	var faseC: LecturaElectrica = LecturaElectrica()
}

// 3. Estructura para el checklist de actividades (Booleanos)
struct ActividadesChecklist: Codable, Hashable {
	var revMedidores: Bool = false
	var inspExterna: Bool = false
	var inspInterna: Bool = false
	var revVentiladores: Bool = false
	var revPaneles: Bool = false
	var revFiltros: Bool = false
	var limpiezaAerea: Bool = false
	var limpiezaInt: Bool = false
}

// 4. Modelo Principal del Reporte (Actualizado)
struct Reporte: Identifiable, Codable, Hashable {
	var id = UUID()
    var folio: Int
	
	// 1. DATOS GENERALES (Orden Lógico)
	var cliente: String
	var mesCorrespondiente: String      // Nuevo
	var responsable: String             // Nuevo
	var domicilio: String               // Nuevo
	var efectuadoPor: String            // Nuevo
	var telefono: String                // Nuevo
	
	var marca: String
	var modelo: String
	var noSerie: String
	var noContrato: String
	
	var fechaCreacion: Date
	var usuarioID: String
	
	// 2. ACTIVIDADES
	var actividades: ActividadesChecklist = ActividadesChecklist()
	
	// 3. PARÁMETROS SALIDA
	var salidaConsumo: ParametrosFase = ParametrosFase()
	var salidaRegulado: ParametrosFase = ParametrosFase()
	var salidaReserva: ParametrosFase = ParametrosFase()
	var condicionesSincronia: String = ""
	var porcentajeCarga: String = ""
	var temperatura: String = ""
	
	// 4. PARÁMETROS ENTRADA
	var entradaConsumo: ParametrosFase = ParametrosFase()
	var entradaVoltaje: ParametrosFase = ParametrosFase()
    var parametrosBypass: ParametrosFase = ParametrosFase()
	var voltajeInversor: String = ""
	var corrienteInversor: String = ""
	var corrienteBateria: String = ""
	var voltajeFlotacion: String = ""
	
	// 5. VARIOS
	var refacciones: String = ""
	var detalles: String = ""
	
	// 6. MULTIMEDIA
	var firmaCliente: Data?
	var firmaTecnico: Data?
    var fotosReporte: [Data] = []
	
	// Propiedad calculada
	var titulo: String {
		return "\(cliente) - \(marca)"
	}
}
