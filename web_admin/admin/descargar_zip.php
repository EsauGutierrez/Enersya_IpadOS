<?php
// admin/descargar_zip.php — Genera y descarga un ZIP con los PDFs seleccionados
session_start();
if (!isset($_SESSION['admin_id'])) { header('Location: login.php'); exit; }
require_once '../api/config.php';

$ids = $_POST['ids'] ?? [];
if (empty($ids)) { header('Location: dashboard.php'); exit; }

// Sanitizar IDs (solo UUIDs válidos)
$ids = array_filter($ids, fn($id) => preg_match('/^[0-9a-f\-]{36}$/i', $id));
if (empty($ids)) { header('Location: dashboard.php'); exit; }

$pdo = conectarDB();
$placeholders = implode(',', array_fill(0, count($ids), '?'));
$stmt = $pdo->prepare("SELECT id, folio, cliente, pdf_ruta FROM reportes WHERE id IN ($placeholders) AND pdf_ruta IS NOT NULL");
$stmt->execute(array_values($ids));
$reportes = $stmt->fetchAll(PDO::FETCH_ASSOC);

if (empty($reportes)) {
    header('Location: dashboard.php?error=sin_pdf'); exit;
}

// Crear ZIP en memoria temporal
$zipPath = tempnam(sys_get_temp_dir(), 'enersya_') . '.zip';
$zip = new ZipArchive();

if ($zip->open($zipPath, ZipArchive::CREATE) !== true) {
    die('Error al crear el archivo ZIP');
}

foreach ($reportes as $r) {
    $rutaFisica = $_SERVER['DOCUMENT_ROOT'] . $r['pdf_ruta'];
    if (file_exists($rutaFisica)) {
        $nombreArchivo = 'Reporte_' . str_pad($r['folio'], 4, '0', STR_PAD_LEFT) . '_' . preg_replace('/[^a-zA-Z0-9]/', '_', $r['cliente']) . '.pdf';
        $zip->addFile($rutaFisica, $nombreArchivo);
    }
}
$zip->close();

// Enviar el ZIP al navegador
$nombreZip = 'Enersya_Reportes_' . date('Y-m-d') . '.zip';
header('Content-Type: application/zip');
header('Content-Disposition: attachment; filename="' . $nombreZip . '"');
header('Content-Length: ' . filesize($zipPath));
header('Pragma: no-cache');

readfile($zipPath);
unlink($zipPath);
exit;
