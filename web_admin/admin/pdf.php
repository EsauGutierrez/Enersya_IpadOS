<?php
// admin/pdf.php — Sirve el PDF de forma segura (requiere sesión admin)
session_start();
if (!isset($_SESSION['admin_id'])) { header('Location: login.php'); exit; }
require_once '../api/config.php';

$id = trim($_GET['id'] ?? '');
$descargar = isset($_GET['dl']);

if (!$id) { http_response_code(400); die('ID no proporcionado'); }

$pdo  = conectarDB();
$stmt = $pdo->prepare("SELECT pdf_ruta, cliente, folio FROM reportes WHERE id = ?");
$stmt->execute([$id]);
$reporte = $stmt->fetch(PDO::FETCH_ASSOC);

if (!$reporte || !$reporte['pdf_ruta']) {
    http_response_code(404); die('PDF no encontrado');
}

$rutaFisica = $_SERVER['DOCUMENT_ROOT'] . $reporte['pdf_ruta'];
if (!file_exists($rutaFisica)) {
    http_response_code(404); die('Archivo no encontrado en el servidor');
}

$nombreDescarga = 'Reporte_' . str_pad($reporte['folio'], 4, '0', STR_PAD_LEFT) . '_' . preg_replace('/[^a-zA-Z0-9]/', '_', $reporte['cliente']) . '.pdf';

header('Content-Type: application/pdf');
header('Content-Length: ' . filesize($rutaFisica));

if ($descargar) {
    header('Content-Disposition: attachment; filename="' . $nombreDescarga . '"');
} else {
    header('Content-Disposition: inline; filename="' . $nombreDescarga . '"');
}

readfile($rutaFisica);
exit;
