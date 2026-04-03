  <?php
  // ============================================
  // api/reportes/listar.php — GET: Mis reportes
  // ============================================
  require_once '../config.php';

  $pdo = conectarDB();
  $usuario = validarToken($pdo);

  $stmt = $pdo->prepare("
      SELECT id, folio, cliente, no_contrato, fecha_creacion, marca, modelo
      FROM reportes
      WHERE usuario_id = ?
      ORDER BY fecha_creacion DESC
  ");
  $stmt->execute([$usuario['usuario_id']]);
  $reportes = $stmt->fetchAll(PDO::FETCH_ASSOC);

  responder(200, ['reportes' => $reportes]);