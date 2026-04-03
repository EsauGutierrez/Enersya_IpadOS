<?php
  // ============================================
  // api/auth/login.php — POST: Iniciar sesión
  // ============================================
  require_once '../config.php';

  if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
      responder(405, ['error' => 'Método no permitido']);
  }

  $body = json_decode(file_get_contents('php://input'), true);
  $correo    = trim($body['correo'] ?? '');
  $contrasena = trim($body['contrasena'] ?? '');

  if (!$correo || !$contrasena) {
      responder(400, ['error' => 'Correo y contraseña requeridos']);
  }

  $pdo = conectarDB();
  $stmt = $pdo->prepare("SELECT id, nombre, correo, contrasena FROM usuarios WHERE correo = ? AND activo = 1");
  $stmt->execute([$correo]);
  $usuario = $stmt->fetch(PDO::FETCH_ASSOC);

  if (!$usuario || !password_verify($contrasena, $usuario['contrasena'])) {
      responder(401, ['error' => 'Credenciales incorrectas']);
  }

  // Generar token de sesión
  $token = bin2hex(random_bytes(32));
  $expira = date('Y-m-d H:i:s', strtotime('+' . TOKEN_EXPIRY_HOURS . ' hours'));

  $stmt = $pdo->prepare("INSERT INTO sesiones (usuario_id, token, expira_en) VALUES (?, ?, ?)");
  $stmt->execute([$usuario['id'], $token, $expira]);

  responder(200, [
      'token'   => $token,
      'expira'  => $expira,
      'usuario' => [
          'id'     => $usuario['id'],
          'nombre' => $usuario['nombre'],
          'correo' => $usuario['correo'],
      ]
  ]);

