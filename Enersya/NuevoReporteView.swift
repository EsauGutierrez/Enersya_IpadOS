//
//   NuevoReporteView.swift
//  Enersya
//
//  Created by Esau Gutiérrez on 09/10/25.
//

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
    
    // Tablas Técnicas
    @State private var salidaConsumo = ParametrosFase()
    @State private var salidaRegulado = ParametrosFase()
    @State private var salidaReserva = ParametrosFase()
    
    @State private var entradaConsumo = ParametrosFase()
    @State private var entradaVoltaje = ParametrosFase()
    @State private var parametrosBypass = ParametrosFase()
    
    // Campos sueltos (Añadimos los de Baterías que faltaban)
    @State private var condicionesSincronia: String = ""
    @State private var porcentajeCarga: String = ""
    @State private var temperatura: String = ""
    @State private var voltajeInversor: String = ""
    @State private var corrienteInversor: String = ""
    @State private var corrienteBateria: String = ""
    @State private var voltajeFlotacion: String = ""
    @State private var refacciones: String = ""
    @State private var observaciones: String = ""
    
    // Multimedia
    @State private var firmaClienteData: Data?
    @State private var firmaTecnicoData: Data?
    @State private var fotosReporteData: [Data] = []
    
    // Control de UI (Acordeones)
    @State private var isExpandedActividades = true
    @State private var isExpandedEntrada = false
    @State private var isExpandedBypass = false
    @State private var isExpandedSalida = false
    @State private var isExpandedBaterias = false // Nuevo acordeón
    @State private var guardando = false
    
    var body: some View {
        NavigationView {
            Form { 
                // SECCIÓN 1: DATOS GENERALES
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
                
                // SECCIÓN 2: CHECKLIST
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
                
                // SECCIÓN 3: PARÁMETROS DE ENTRADA (MOVIDO ARRIBA)
                DisclosureGroup("Parámetros de Entrada", isExpanded: $isExpandedEntrada) {
                    VStack(alignment: .leading) {
                        Text("Consumo y Voltaje de Entrada").font(.headline).padding(.top)
                        // Grid expandido (Sin ScrollView)
                        Grid {
                            HeaderTablaView()
                            FilaFaseInputView(titulo: "Fase A", lectura: $entradaConsumo.faseA)
                            FilaFaseInputView(titulo: "Fase B", lectura: $entradaConsumo.faseB)
                            FilaFaseInputView(titulo: "Fase C", lectura: $entradaConsumo.faseC)
                        }
                    }
                    .padding(.vertical)
                }
                // SECCIÓN 3.5: PARÁMETROS DE BY PASS
                DisclosureGroup("Parámetros de By Pass", isExpanded: $isExpandedBypass) {
                    VStack(alignment: .leading) {
                        Text("Lecturas de By Pass").font(.headline).padding(.top)
                        Grid {
                            HeaderTablaView()
                            FilaFaseInputView(titulo: "Fase A", lectura: $parametrosBypass.faseA)
                            FilaFaseInputView(titulo: "Fase B", lectura: $parametrosBypass.faseB)
                            FilaFaseInputView(titulo: "Fase C", lectura: $parametrosBypass.faseC)
                        }
                    }
                    .padding(.vertical)
                }
                // SECCIÓN 4: PARÁMETROS DE SALIDA (AHORA ANCHO)
                DisclosureGroup("Parámetros de Salida", isExpanded: $isExpandedSalida) {
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
                        
                        // Campos extra
                        HStack {
                            Text("Respalda (Sincronía):")
                            TextField("Sí/No", text: $condicionesSincronia)
                        }.padding(.top)
                        HStack {
                            TextField("% Carga Usada", text: $porcentajeCarga)
                            TextField("Temp. Ambiente (°C)", text: $temperatura)
                        }
                    }
                    .padding(.vertical)
                }
                
                // SECCIÓN 5: BATERÍAS E INVERSOR (SECCIÓN INDEPENDIENTE)
                DisclosureGroup("Bancos de Baterías e Inversor", isExpanded: $isExpandedBaterias) {
                    VStack(alignment: .leading) {
                        HStack {
                            // Ahora usamos variables reales en lugar de Binding.constant
                            TextField("Volt. Ent. Inversor (Volts CD)", text: $voltajeInversor)
                            TextField("Corriente Ent. Inv. (Amp CD)", text: $corrienteInversor)
                        }
                        HStack {
                            TextField("Voltaje de Flotación", text: $voltajeFlotacion)
                            TextField("Corriente de Batería", text: $corrienteBateria)
                        }
                    }
                    .padding(.vertical)
                }
                
                // SECCIÓN 6: REFACCIONES Y OBSERVACIONES
                Section(header: Text("Refacciones y Observaciones")) {
                    TextField("Refacciones Empleadas", text: $refacciones)
                    TextEditor(text: $observaciones)
                        .frame(height: 100)
                        .overlay(
                            observaciones.isEmpty ? Text("Observaciones generales...").foregroundColor(.gray).padding(8).allowsHitTesting(false) : nil,
                            alignment: .topLeading
                        )
                }
                
                // SECCIÓN 7: MULTIMEDIA
                Section(header: Text("Evidencia y Validación")) {
                    ImageCaptureView(fotos: $fotosReporteData)
                    SignatureCaptureView(firmaData: $firmaClienteData, title: "Firma del Cliente")
                    SignatureCaptureView(firmaData: $firmaTecnicoData, title: "Firma del Técnico")
                }
                
                // BOTONES
                Section {
                    HStack(spacing: 16) {
                        Button("Cancelar") {
                            dismiss()
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                        .frame(maxWidth: .infinity)
                        
                        Button("Guardar Reporte Completo") {
                            guard !cliente.isEmpty else { return }
                            
                            let nuevoReporte = Reporte(
                                folio: viewModel.reportes.count + 1, // Folio dinámico
                                cliente: cliente,
                                mesCorrespondiente: mesCorrespondiente,
                                responsable: responsable,
                                domicilio: domicilio,
                                efectuadoPor: efectuadoPor,
                                telefono: telefono,
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
                                parametrosBypass: parametrosBypass,
                                
                                // ¡AQUÍ GUARDAMOS LOS DATOS REALES DE LAS BATERÍAS!
                                voltajeInversor: voltajeInversor,
                                corrienteInversor: corrienteInversor,
                                corrienteBateria: corrienteBateria,
                                voltajeFlotacion: voltajeFlotacion,
                                
                                refacciones: refacciones,
                                detalles: observaciones,
                                firmaCliente: firmaClienteData,
                                firmaTecnico: firmaTecnicoData,
                                fotosReporte: fotosReporteData
                            )
                            
                            Task {
                                guardando = true
                                await withTaskGroup(of: Void.self) { group in
                                    group.addTask { await viewModel.guardarNuevoReporte(nuevoReporte) }
                                    group.addTask { try? await Task.sleep(nanoseconds: 1_500_000_000) }
                                    await group.waitForAll()
                                }
                                guardando = false
                                dismiss()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .frame(maxWidth: .infinity)
                    }
                    .font(.headline)
                }
            }
            .navigationTitle("Nuevo Mantenimiento")
        }
        .disabled(guardando)
        .overlay {
            if guardando {
                ZStack {
                    Color.black.opacity(0.45)
                        .ignoresSafeArea()

                    VStack(spacing: 24) {
                        Image("LogoEnersya")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 160)

                        ProgressView()
                            .progressViewStyle(.circular)
                            .scaleEffect(1.6)
                            .tint(.white)

                        Text("Guardando reporte...")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    .padding(40)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
                }
            }
        }
    }
}
