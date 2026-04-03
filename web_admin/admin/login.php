<?php
// admin/login.php
session_start();
if (isset($_SESSION['admin_id'])) {
    header('Location: dashboard.php'); exit;
}

require_once '../api/config.php';
$error = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $correo    = trim($_POST['correo'] ?? '');
    $contrasena = trim($_POST['contrasena'] ?? '');

    $pdo  = conectarDB();
    $stmt = $pdo->prepare("SELECT id, nombre, contrasena, rol FROM usuarios WHERE correo = ? AND activo = 1");
    $stmt->execute([$correo]);
    $u = $stmt->fetch(PDO::FETCH_ASSOC);

    if ($u && password_verify($contrasena, $u['contrasena']) && $u['rol'] === 'admin') {
        $_SESSION['admin_id']     = $u['id'];
        $_SESSION['admin_nombre'] = $u['nombre'];
        header('Location: dashboard.php'); exit;
    }
    $error = 'Credenciales incorrectas o sin permisos de administrador.';
}
?>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Enersya — Admin</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <style>
        body { background: #f0f2f5; display: flex; align-items: center; justify-content: center; min-height: 100vh; }
        .card { width: 100%; max-width: 420px; border: none; border-radius: 16px; box-shadow: 0 8px 32px rgba(0,0,0,.12); }
        .logo { max-height: 70px; }
        .btn-primary { background: #0d6efd; border: none; border-radius: 8px; padding: .75rem; font-weight: 600; }
    </style>
</head>
<body>
<div class="card p-4 p-md-5">
    <div class="text-center mb-4">
        <img src="../assets/logo_enersya.png" class="logo mb-3" alt="Enersya">
        <h5 class="fw-bold text-dark">Panel de Administración</h5>
        <p class="text-muted small">Acceso exclusivo para administradores</p>
    </div>

    <?php if ($error): ?>
        <div class="alert alert-danger py-2 small"><?= htmlspecialchars($error) ?></div>
    <?php endif; ?>

    <form method="POST">
        <div class="mb-3">
            <label class="form-label small fw-semibold">Correo electrónico</label>
            <input type="email" name="correo" class="form-control" required autofocus>
        </div>
        <div class="mb-4">
            <label class="form-label small fw-semibold">Contraseña</label>
            <input type="password" name="contrasena" class="form-control" required>
        </div>
        <button type="submit" class="btn btn-primary w-100">Iniciar Sesión</button>
    </form>
</div>
</body>
</html>
