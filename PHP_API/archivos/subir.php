<?php
  // ============================================
  // api/archivos/subir.php — POST: Fotos y firmas
  // ============================================
  require_once '../config.php';

  $pdo = conectarDB();
  $usuario = validarToken($pdo);

  $reporteId = $_POST['reporte_id'] ?? '';
  $tipo      = $_POST['tipo'] ?? '';  // 'foto', 'firma_cliente', 'firma_tecnico'
  $archivo   = $_FILES['archivo'] ?? null;

  if (!$reporteId || !$tipo || !$archivo) {
      responder(400, ['error' => 'Datos incompletos']);
  }

  // Verificar que el reporte pertenece al usuario
  $stmt = $pdo->prepare("SELECT id FROM reportes WHERE id = ? AND usuario_id = ?");
  $stmt->execute([$reporteId, $usuario['usuario_id']]);
  if (!$stmt->fetch()) {
      responder(403, ['error' => 'Acceso denegado']);
  }

  // Validar tipo de archivo
  $extension = strtolower(pathinfo($archivo['name'], PATHINFO_EXTENSION));
  if (!in_array($extension, ['jpg', 'jpeg', 'png'])) {
      responder(400, ['error' => 'Solo se permiten imágenes JPG/PNG']);
  }

  // Guardar archivo
  $nombreArchivo = uniqid('', true) . '.' . $extension;
  $carpeta = "/uploads/{$reporteId}/";
  $rutaFisica = $_SERVER['DOCUMENT_ROOT'] . $carpeta;

  if (!is_dir($rutaFisica)) {
      mkdir($rutaFisica, 0755, true);
  }

  $rutaFinal = $carpeta . $nombreArchivo;
  move_uploaded_file($archivo['tmp_name'], $_SERVER['DOCUMENT_ROOT'] . $rutaFinal);

  // Guardar referencia en BD
  if ($tipo === 'foto') {
      $orden = (int)($_POST['orden'] ?? 0);
      $stmt = $pdo->prepare("INSERT INTO fotos_reporte (reporte_id, nombre_archivo, ruta, orden) VALUES (?, ?,
  ?, ?)");
      $stmt->execute([$reporteId, $nombreArchivo, $rutaFinal, $orden]);
  } else {
      $columna = $tipo === 'firma_cliente' ? 'firma_cliente_ruta' : 'firma_tecnico_ruta';
      $stmt = $pdo->prepare("UPDATE reportes SET {$columna} = ? WHERE id = ?");
      $stmt->execute([$rutaFinal, $reporteId]);
  }

  responder(200, ['ruta' => $rutaFinal]);
