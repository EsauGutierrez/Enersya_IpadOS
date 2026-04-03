<?php
  // ============================================
  // api/reportes/crear.php — POST: Nuevo reporte
  // ============================================
  require_once '../config.php';

  $pdo = conectarDB();
  $usuario = validarToken($pdo);

  $r = json_decode(file_get_contents('php://input'), true);

  if (empty($r['id']) || empty($r['cliente'])) {
      responder(400, ['error' => 'Datos incompletos']);
  }

  // Obtener siguiente folio
  $folio = $pdo->query("SELECT COALESCE(MAX(folio), 0) + 1 FROM reportes")->fetchColumn();

  $stmt = $pdo->prepare("
      INSERT INTO reportes (
          id, folio, usuario_id, cliente, mes_correspondiente, responsable,
          domicilio, efectuado_por, telefono, marca, modelo, no_serie, no_contrato,
          fecha_creacion,
          act_rev_medidores, act_insp_externa, act_insp_interna, act_rev_ventiladores,
          act_rev_paneles, act_rev_filtros, act_limpieza_aerea, act_limpieza_int,
          salida_consumo, salida_regulado, salida_reserva,
          entrada_consumo, entrada_voltaje, parametros_bypass,
          condiciones_sincronia, porcentaje_carga, temperatura,
          voltaje_inversor, corriente_inversor, corriente_bateria, voltaje_flotacion,
          refacciones, detalles
      ) VALUES (
          ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?,
          ?, ?, ?, ?, ?, ?, ?, ?,
          ?, ?, ?, ?, ?, ?,
          ?, ?, ?, ?, ?, ?, ?, ?, ?
      )
  ");

  $act = $r['actividades'] ?? [];

  $stmt->execute([
      $r['id'], $folio, $usuario['usuario_id'],
      $r['cliente'], $r['mesCorrespondiente'] ?? '', $r['responsable'] ?? '',
      $r['domicilio'] ?? '', $r['efectuadoPor'] ?? '', $r['telefono'] ?? '',
      $r['marca'] ?? '', $r['modelo'] ?? '', $r['noSerie'] ?? '', $r['noContrato'] ?? '',
      $r['fechaCreacion'],
      // Actividades
      $act['revMedidores'] ?? 0, $act['inspExterna'] ?? 0, $act['inspInterna'] ?? 0,
      $act['revVentiladores'] ?? 0, $act['revPaneles'] ?? 0, $act['revFiltros'] ?? 0,
      $act['limpiezaAerea'] ?? 0, $act['limpiezaInt'] ?? 0,
      // Fases (JSON)
      json_encode($r['salidaConsumo'] ?? []),
      json_encode($r['salidaRegulado'] ?? []),
      json_encode($r['salidaReserva'] ?? []),
      json_encode($r['entradaConsumo'] ?? []),
      json_encode($r['entradaVoltaje'] ?? []),
      json_encode($r['parametrosBypass'] ?? []),
      // Campos sueltos
      $r['condicionesSincronia'] ?? '', $r['porcentajeCarga'] ?? '', $r['temperatura'] ?? '',
      $r['voltajeInversor'] ?? '', $r['corrienteInversor'] ?? '',
      $r['corrienteBateria'] ?? '', $r['voltajeFlotacion'] ?? '',
      $r['refacciones'] ?? '', $r['detalles'] ?? ''
  ]);

  responder(201, ['folio' => (int)$folio, 'id' => $r['id']]);
