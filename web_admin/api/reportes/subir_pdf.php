<?php
// api/reportes/subir_pdf.php — Recibe el PDF generado desde la app iOS
require_once '../config.php';

$pdo = conectarDB();
$usuario = validarToken($pdo);

$reporteId = $_POST['reporte_id'] ?? '';
$pdf       = $_FILES['pdf'] ?? null;

if (!$reporteId || !$pdf || $pdf['error'] !== UPLOAD_ERR_OK) {
    responder(400, ['error' => 'Datos incompletos']);
}

if ($pdf['type'] !== 'application/pdf') {
    responder(400, ['error' => 'Solo se permiten archivos PDF']);
}

$carpeta     = '/uploads/pdfs/';
$rutaFisica  = $_SERVER['DOCUMENT_ROOT'] . $carpeta;

if (!is_dir($rutaFisica)) {
    mkdir($rutaFisica, 0755, true);
}

$nombreArchivo = $reporteId . '.pdf';
$rutaFinal     = $carpeta . $nombreArchivo;

if (!move_uploaded_file($pdf['tmp_name'], $_SERVER['DOCUMENT_ROOT'] . $rutaFinal)) {
    responder(500, ['error' => 'Error al guardar el archivo']);
}

$stmt = $pdo->prepare("UPDATE reportes SET pdf_ruta = ? WHERE id = ? AND usuario_id = ?");
$stmt->execute([$rutaFinal, $reporteId, $usuario['usuario_id']]);

responder(200, ['ruta' => $rutaFinal]);
