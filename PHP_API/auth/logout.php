  <?php
  // ============================================
  // api/auth/logout.php — POST: Cerrar sesión
  // ============================================
  require_once '../config.php';

  $pdo = conectarDB();
  $usuario = validarToken($pdo);

  $headers = getallheaders();
  $token = substr($headers['Authorization'], 7);

  $stmt = $pdo->prepare("DELETE FROM sesiones WHERE token = ?");
  $stmt->execute([$token]);

  responder(200, ['mensaje' => 'Sesión cerrada']);