//
//   NuevoReporteView.swift
//  Enersya
//
//  Created by Esau Gutiérrez on 09/10/25.
//

// NuevoReporteView.swift
import SwiftUI

struct NuevoReporteView: View {
	@EnvironmentObject var viewModel: ReporteViewModel
	@Environment(\.dismiss) var dismiss
	
	// --- ESTADOS DE DATOS ---
	// Generales
	@State private var cliente: String = ""
	@State private var marca: String = ""
	@State private var modelo: String = ""
	@State private var serie: String = ""
	@State private var contrato: String = ""
	@State private var mesCorrespondiente: String = ""
	@State private var responsable: String = ""
	@State private var domicilio: String = ""
	@State private var efectuadoPor: String = ""
	@State private var telefono: String = ""
	
	// Actividades
	@State private var actividades = ActividadesChecklist()
	
	// Tablas Técnicas (Instancias vacías para llenar)
	@State private var salidaConsumo = ParametrosFase()
	@State private var salidaRegulado = ParametrosFase()
	@State private var salidaReserva = ParametrosFase()
	
	@State private var entradaConsumo = ParametrosFase()
	@State private var entradaVoltaje = ParametrosFase()
	
	// Campos sueltos
	@State private var condicionesSincronia: String = ""
	@State private var porcentajeCarga: String = ""
	@State private var temperatura: String = ""
	@State private var refacciones: String = ""
	@State private var observaciones: String = ""
	
	// Multimedia
	@State private var firmaClienteData: Data?
	@State private var firmaTecnicoData: Data?
	@State private var fotoReporteData: Data?
	
	// Control de UI (Qué acordeones están abiertos)
	@State private var isExpandedSalida = false
	@State private var isExpandedEntrada = false
	@State private var isExpandedActividades = true
	
	var body: some View {
		NavigationView {
			Form {
				// SECCIÓN 1: DATOS DEL EQUIPO (Siempre visible)
				Section(header: Text("Datos Generales")) {
					TextField("Usuario / Cliente", text: $cliente)
					
					TextField("Correspondiente al mes de", text: $mesCorrespondiente)
					
					HStack {
						TextField("Marca", text: $marca)
						TextField("Modelo", text: $modelo)
					}
					HStack {
						TextField("No. Serie", text: $serie)
						TextField("No. Contrato", text: $contrato)
					}
					
					TextField("Responsable", text: $responsable)
					TextField("Domicilio", text: $domicilio)
					
					HStack {
						TextField("Efectuado por", text: $efectuadoPor)
						TextField("Teléfono", text: $telefono)
					}
				}
				
				// SECCIÓN 2: CHECKLIST (Acordeón)
				DisclosureGroup("Descripción de Actividades", isExpanded: $isExpandedActividades) {
					Toggle("Rev. de Medidores", isOn: $actividades.revMedidores)
					Toggle("Inspección Externa", isOn: $actividades.inspExterna)
					Toggle("Inspección Interna", isOn: $actividades.inspInterna)
					Toggle("Rev. de Ventiladores", isOn: $actividades.revVentiladores)
					Toggle("Rev. de Paneles", isOn: $actividades.revPaneles)
					Toggle("Rev. Filtros de Aire", isOn: $actividades.revFiltros)
					Toggle("Limpieza Aérea", isOn: $actividades.limpiezaAerea)
					Toggle("Limpieza Int. UPS", isOn: $actividades.limpiezaInt)
				}
				
				// SECCIÓN 3: PARÁMETROS DE SALIDA (Tabla Compleja)
				DisclosureGroup("Parámetros de Salida", isExpanded: $isExpandedSalida) {
					ScrollView(.horizontal) { // Scroll horizontal por si acaso
						VStack(alignment: .leading) {
							Text("Consumo de la Carga").font(.headline).padding(.top)
							Grid {
								HeaderTablaView()
								FilaFaseInputView(titulo: "Fase A", lectura: $salidaConsumo.faseA)
								FilaFaseInputView(titulo: "Fase B", lectura: $salidaConsumo.faseB)
								FilaFaseInputView(titulo: "Fase C", lectura: $salidaConsumo.faseC)
							}
							
							Divider()
							Text("Voltaje y Frecuencia Regulado").font(.headline).padding(.top)
							Grid {
								HeaderTablaView()
								FilaFaseInputView(titulo: "Fase A", lectura: $salidaRegulado.faseA)
								FilaFaseInputView(titulo: "Fase B", lectura: $salidaRegulado.faseB)
								FilaFaseInputView(titulo: "Fase C", lectura: $salidaRegulado.faseC)
							}
							
							// Campos extra de esta sección
							HStack {
								Text("Condiciones Sincronía:")
								TextField("Sí/No", text: $condicionesSincronia)
							}.padding(.top)
							HStack {
								TextField("% Carga Usada", text: $porcentajeCarga)
								TextField("Temp. Ambiente", text: $temperatura)
							}
						}
						.padding(.vertical)
					}
				}
				
				// SECCIÓN 4: PARÁMETROS DE ENTRADA
				DisclosureGroup("Parámetros de Entrada y Baterías", isExpanded: $isExpandedEntrada) {
					VStack(alignment: .leading) {
						Text("Consumo de Entrada").font(.headline)
						Grid {
							HeaderTablaView()
							FilaFaseInputView(titulo: "Fase A", lectura: $entradaConsumo.faseA)
							FilaFaseInputView(titulo: "Fase B", lectura: $entradaConsumo.faseB)
							FilaFaseInputView(titulo: "Fase C", lectura: $entradaConsumo.faseC)
						}
						
						Divider().padding(.vertical)
						
						Text("Bancos de Baterías e Inversor").font(.headline)
						// Campos simples para valores únicos
						HStack {
							TextField("Volt. Ent. Inversor", text: Binding.constant("")) // Placeholder logic needed
							TextField("Corriente Ent. Inv.", text: Binding.constant(""))
						}
					}
				}
				
				// SECCIÓN 5: REFACCIONES Y OBSERVACIONES
				Section(header: Text("Refacciones y Observaciones")) {
					TextField("Refacciones Empleadas", text: $refacciones)
					TextEditor(text: $observaciones)
						.frame(height: 100)
						.overlay(
							observaciones.isEmpty ? Text("Observaciones generales...").foregroundColor(.gray).padding(8).allowsHitTesting(false) : nil,
							alignment: .topLeading
						)
				}
				
				// SECCIÓN 6: MULTIMEDIA (Foto y Firmas)
				Section(header: Text("Evidencia y Validación")) {
					ImageCaptureView(fotoData: $fotoReporteData)
					SignatureCaptureView(firmaData: $firmaClienteData, title: "Firma del Cliente")
					SignatureCaptureView(firmaData: $firmaTecnicoData, title: "Firma del Técnico")
				}
				
				// BOTÓN GUARDAR
				Section {
					Button("Guardar Reporte Completo") {
						guard !cliente.isEmpty else { return }
						
						// Creación del objeto Reporte complejo
						let nuevoReporte = Reporte(
							cliente: cliente,
							mesCorrespondiente: mesCorrespondiente, // Nuevo
							responsable: responsable,               // Nuevo
							domicilio: domicilio,                   // Nuevo
							efectuadoPor: efectuadoPor,             // Nuevo
							telefono: telefono,                     // Nuevo
							marca: marca,
							modelo: modelo,
							noSerie: serie,
							noContrato: contrato,
							fechaCreacion: Date(),
							usuarioID: viewModel.usuarioActual?.correo ?? "Desconocido",
							actividades: actividades,
							salidaConsumo: salidaConsumo,
							salidaRegulado: salidaRegulado,
							salidaReserva: salidaReserva,
							condicionesSincronia: condicionesSincronia,
							porcentajeCarga: porcentajeCarga,
							temperatura: temperatura,
							entradaConsumo: entradaConsumo,
							entradaVoltaje: entradaVoltaje,
							refacciones: refacciones,
							detalles: observaciones,
							firmaCliente: firmaClienteData,
							firmaTecnico: firmaTecnicoData,
							fotoReporte: fotoReporteData
						)
						
						viewModel.guardarNuevoReporte(nuevoReporte)
						
						DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
							dismiss()
						}
					}
					.frame(maxWidth: .infinity)
					.font(.headline)
				}
			}
			.navigationTitle("Nuevo Mantenimiento")
		}
	}
}
