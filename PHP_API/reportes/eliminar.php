
  <?php
  // ============================================
  // api/reportes/eliminar.php — DELETE: Eliminar
  // ============================================
  require_once '../config.php';

  $pdo = conectarDB();
  $usuario = validarToken($pdo);

  $body = json_decode(file_get_contents('php://input'), true);
  $reporteId = $body['id'] ?? '';

  // Verificar que el reporte pertenece al usuario
  $stmt = $pdo->prepare("SELECT id FROM reportes WHERE id = ? AND usuario_id = ?");
  $stmt->execute([$reporteId, $usuario['usuario_id']]);

  if (!$stmt->fetch()) {
      responder(403, ['error' => 'Reporte no encontrado']);
  }

  // Eliminar fotos físicas del servidor
  $stmt = $pdo->prepare("SELECT ruta FROM fotos_reporte WHERE reporte_id = ?");
  $stmt->execute([$reporteId]);
  foreach ($stmt->fetchAll() as $foto) {
      @unlink($_SERVER['DOCUMENT_ROOT'] . $foto['ruta']);
  }

  $pdo->prepare("DELETE FROM reportes WHERE id = ?")->execute([$reporteId]);

  responder(200, ['mensaje' => 'Reporte eliminado']);