<?php
// admin/dashboard.php
session_start();
if (!isset($_SESSION['admin_id'])) { header('Location: login.php'); exit; }
require_once '../api/config.php';

$pdo = conectarDB();

// --- Búsqueda y filtros ---
$busqueda  = trim($_GET['q'] ?? '');
$tecnico   = trim($_GET['tecnico'] ?? '');
$fechaDesde = trim($_GET['desde'] ?? '');
$fechaHasta = trim($_GET['hasta'] ?? '');
$pagina    = max(1, (int)($_GET['p'] ?? 1));
$porPagina = 20;
$offset    = ($pagina - 1) * $porPagina;

$where  = ['1=1'];
$params = [];

if ($busqueda) {
    $where[]  = '(r.cliente LIKE ? OR r.no_contrato LIKE ? OR r.folio LIKE ?)';
    $params[] = "%$busqueda%";
    $params[] = "%$busqueda%";
    $params[] = "%$busqueda%";
}
if ($tecnico) {
    $where[]  = 'r.usuario_id = ?';
    $params[] = $tecnico;
}
if ($fechaDesde) {
    $where[]  = 'DATE(r.fecha_creacion) >= ?';
    $params[] = $fechaDesde;
}
if ($fechaHasta) {
    $where[]  = 'DATE(r.fecha_creacion) <= ?';
    $params[] = $fechaHasta;
}

$whereSQL = implode(' AND ', $where);

// Total de registros
$totalStmt = $pdo->prepare("SELECT COUNT(*) FROM reportes r WHERE $whereSQL");
$totalStmt->execute($params);
$total      = (int)$totalStmt->fetchColumn();
$totalPaginas = max(1, ceil($total / $porPagina));

// Reportes de la página actual
$stmt = $pdo->prepare("
    SELECT r.id, r.folio, r.cliente, r.no_contrato, r.marca, r.modelo,
           r.fecha_creacion, r.pdf_ruta, u.nombre AS tecnico
    FROM reportes r
    JOIN usuarios u ON u.id = r.usuario_id
    WHERE $whereSQL
    ORDER BY r.fecha_creacion DESC
    LIMIT $porPagina OFFSET $offset
");
$stmt->execute($params);
$reportes = $stmt->fetchAll(PDO::FETCH_ASSOC);

// Stats
$statsStmt = $pdo->query("
    SELECT
        COUNT(*) AS total,
        SUM(MONTH(fecha_creacion) = MONTH(NOW()) AND YEAR(fecha_creacion) = YEAR(NOW())) AS este_mes
    FROM reportes
");
$stats = $statsStmt->fetch(PDO::FETCH_ASSOC);

$tecnicos = $pdo->query("SELECT id, nombre FROM usuarios WHERE rol = 'tecnico' AND activo = 1 ORDER BY nombre")->fetchAll(PDO::FETCH_ASSOC);
?>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Enersya — Dashboard</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.css" rel="stylesheet">
    <style>
        body { background: #f0f2f5; }
        .navbar { background: #fff; box-shadow: 0 2px 8px rgba(0,0,0,.08); }
        .logo { height: 40px; }
        .stat-card { border: none; border-radius: 12px; box-shadow: 0 2px 12px rgba(0,0,0,.07); }
        .stat-icon { width: 48px; height: 48px; border-radius: 12px; display: flex; align-items: center; justify-content: center; font-size: 1.4rem; }
        .table-card { border: none; border-radius: 12px; box-shadow: 0 2px 12px rgba(0,0,0,.07); overflow: hidden; }
        .table thead th { background: #f8f9fa; border-bottom: 2px solid #e9ecef; font-size: .8rem; text-transform: uppercase; letter-spacing: .05em; color: #6c757d; }
        .table tbody tr:hover { background: #f8f9ff; }
        .badge-folio { background: #e8f0fe; color: #1a56db; font-weight: 700; border-radius: 6px; padding: 4px 8px; }
        .btn-accion { width: 32px; height: 32px; padding: 0; display: inline-flex; align-items: center; justify-content: center; border-radius: 8px; }
        .sin-pdf { color: #adb5bd; font-size: .8rem; }
    </style>
</head>
<body>

<!-- NAVBAR -->
<nav class="navbar navbar-expand-lg px-4 py-2 mb-4">
    <a class="navbar-brand" href="#">
        <img src="../assets/logo_enersya.png" class="logo" alt="Enersya">
    </a>
    <span class="navbar-text ms-3 text-muted small">Panel de Administración</span>
    <div class="ms-auto d-flex align-items: center; gap-3">
        <span class="text-muted small me-3"><i class="bi bi-person-circle"></i> <?= htmlspecialchars($_SESSION['admin_nombre']) ?></span>
        <a href="logout.php" class="btn btn-outline-danger btn-sm">
            <i class="bi bi-box-arrow-right"></i> Cerrar sesión
        </a>
    </div>
</nav>

<div class="container-fluid px-4">

    <!-- STATS -->
    <div class="row g-3 mb-4">
        <div class="col-sm-6 col-md-3">
            <div class="card stat-card p-3">
                <div class="d-flex align-items-center gap-3">
                    <div class="stat-icon bg-primary bg-opacity-10 text-primary"><i class="bi bi-file-earmark-text"></i></div>
                    <div>
                        <div class="fs-4 fw-bold"><?= number_format($stats['total']) ?></div>
                        <div class="text-muted small">Total reportes</div>
                    </div>
                </div>
            </div>
        </div>
        <div class="col-sm-6 col-md-3">
            <div class="card stat-card p-3">
                <div class="d-flex align-items-center gap-3">
                    <div class="stat-icon bg-success bg-opacity-10 text-success"><i class="bi bi-calendar-month"></i></div>
                    <div>
                        <div class="fs-4 fw-bold"><?= number_format($stats['este_mes']) ?></div>
                        <div class="text-muted small">Este mes</div>
                    </div>
                </div>
            </div>
        </div>
        <div class="col-sm-6 col-md-3">
            <div class="card stat-card p-3">
                <div class="d-flex align-items-center gap-3">
                    <div class="stat-icon bg-warning bg-opacity-10 text-warning"><i class="bi bi-people"></i></div>
                    <div>
                        <div class="fs-4 fw-bold"><?= count($tecnicos) ?></div>
                        <div class="text-muted small">Técnicos activos</div>
                    </div>
                </div>
            </div>
        </div>
        <div class="col-sm-6 col-md-3">
            <div class="card stat-card p-3">
                <div class="d-flex align-items-center gap-3">
                    <div class="stat-icon bg-info bg-opacity-10 text-info"><i class="bi bi-file-earmark-pdf"></i></div>
                    <div>
                        <?php $conPdf = $pdo->query("SELECT COUNT(*) FROM reportes WHERE pdf_ruta IS NOT NULL")->fetchColumn(); ?>
                        <div class="fs-4 fw-bold"><?= number_format($conPdf) ?></div>
                        <div class="text-muted small">PDFs disponibles</div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <!-- FILTROS Y TABLA -->
    <div class="card table-card mb-4">
        <div class="card-body p-0">

            <!-- Filtros -->
            <form method="GET" class="p-3 border-bottom bg-white">
                <div class="row g-2 align-items-end">
                    <div class="col-md-3">
                        <label class="form-label small fw-semibold mb-1">Buscar</label>
                        <input type="text" name="q" class="form-control form-control-sm" placeholder="Cliente, contrato, folio..." value="<?= htmlspecialchars($busqueda) ?>">
                    </div>
                    <div class="col-md-2">
                        <label class="form-label small fw-semibold mb-1">Técnico</label>
                        <select name="tecnico" class="form-select form-select-sm">
                            <option value="">Todos</option>
                            <?php foreach ($tecnicos as $t): ?>
                                <option value="<?= $t['id'] ?>" <?= $tecnico == $t['id'] ? 'selected' : '' ?>>
                                    <?= htmlspecialchars($t['nombre']) ?>
                                </option>
                            <?php endforeach; ?>
                        </select>
                    </div>
                    <div class="col-md-2">
                        <label class="form-label small fw-semibold mb-1">Desde</label>
                        <input type="date" name="desde" class="form-control form-control-sm" value="<?= htmlspecialchars($fechaDesde) ?>">
                    </div>
                    <div class="col-md-2">
                        <label class="form-label small fw-semibold mb-1">Hasta</label>
                        <input type="date" name="hasta" class="form-control form-control-sm" value="<?= htmlspecialchars($fechaHasta) ?>">
                    </div>
                    <div class="col-md-3 d-flex gap-2">
                        <button type="submit" class="btn btn-primary btn-sm px-3">
                            <i class="bi bi-search"></i> Filtrar
                        </button>
                        <a href="dashboard.php" class="btn btn-outline-secondary btn-sm px-3">
                            <i class="bi bi-x-circle"></i> Limpiar
                        </a>
                    </div>
                </div>
            </form>

            <!-- Barra de acciones bulk -->
            <div class="px-3 py-2 border-bottom bg-light d-flex align-items-center gap-3">
                <span class="text-muted small"><?= number_format($total) ?> reporte(s) encontrado(s)</span>
                <div class="ms-auto">
                    <button id="btnDescargarZip" class="btn btn-success btn-sm px-3" onclick="descargarZip()" disabled>
                        <i class="bi bi-file-zip"></i> Descargar seleccionados (.zip)
                    </button>
                </div>
            </div>

            <!-- Tabla -->
            <div class="table-responsive">
                <table class="table table-hover mb-0 align-middle">
                    <thead>
                        <tr>
                            <th class="ps-3" style="width:40px">
                                <input type="checkbox" id="selectAll" class="form-check-input">
                            </th>
                            <th>Folio</th>
                            <th>Cliente</th>
                            <th>Contrato</th>
                            <th>Técnico</th>
                            <th>Fecha</th>
                            <th>PDF</th>
                            <th class="text-center">Acciones</th>
                        </tr>
                    </thead>
                    <tbody>
                        <?php if (empty($reportes)): ?>
                            <tr>
                                <td colspan="8" class="text-center text-muted py-5">
                                    <i class="bi bi-inbox fs-2 d-block mb-2"></i>
                                    No se encontraron reportes
                                </td>
                            </tr>
                        <?php else: ?>
                            <?php foreach ($reportes as $r): ?>
                            <tr>
                                <td class="ps-3">
                                    <?php if ($r['pdf_ruta']): ?>
                                        <input type="checkbox" class="form-check-input check-reporte" value="<?= htmlspecialchars($r['id']) ?>">
                                    <?php else: ?>
                                        <input type="checkbox" class="form-check-input" disabled>
                                    <?php endif; ?>
                                </td>
                                <td><span class="badge-folio"><?= str_pad($r['folio'], 4, '0', STR_PAD_LEFT) ?></span></td>
                                <td class="fw-semibold"><?= htmlspecialchars($r['cliente']) ?></td>
                                <td class="text-muted small"><?= htmlspecialchars($r['no_contrato']) ?></td>
                                <td class="small"><?= htmlspecialchars($r['tecnico']) ?></td>
                                <td class="small text-muted"><?= date('d/m/Y', strtotime($r['fecha_creacion'])) ?></td>
                                <td>
                                    <?php if ($r['pdf_ruta']): ?>
                                        <span class="badge bg-success-subtle text-success"><i class="bi bi-check-circle-fill"></i> Disponible</span>
                                    <?php else: ?>
                                        <span class="sin-pdf"><i class="bi bi-hourglass-split"></i> Pendiente</span>
                                    <?php endif; ?>
                                </td>
                                <td class="text-center">
                                    <?php if ($r['pdf_ruta']): ?>
                                        <a href="pdf.php?id=<?= urlencode($r['id']) ?>" target="_blank"
                                           class="btn btn-outline-primary btn-accion me-1" title="Ver PDF">
                                            <i class="bi bi-eye"></i>
                                        </a>
                                        <a href="pdf.php?id=<?= urlencode($r['id']) ?>&dl=1"
                                           class="btn btn-outline-success btn-accion" title="Descargar PDF">
                                            <i class="bi bi-download"></i>
                                        </a>
                                    <?php else: ?>
                                        <span class="text-muted small">—</span>
                                    <?php endif; ?>
                                </td>
                            </tr>
                            <?php endforeach; ?>
                        <?php endif; ?>
                    </tbody>
                </table>
            </div>

            <!-- Paginación -->
            <?php if ($totalPaginas > 1): ?>
            <div class="px-3 py-2 border-top d-flex justify-content-between align-items-center">
                <span class="text-muted small">Página <?= $pagina ?> de <?= $totalPaginas ?></span>
                <nav>
                    <ul class="pagination pagination-sm mb-0">
                        <?php for ($i = max(1, $pagina - 2); $i <= min($totalPaginas, $pagina + 2); $i++): ?>
                            <li class="page-item <?= $i === $pagina ? 'active' : '' ?>">
                                <a class="page-link" href="?<?= http_build_query(array_merge($_GET, ['p' => $i])) ?>"><?= $i ?></a>
                            </li>
                        <?php endfor; ?>
                    </ul>
                </nav>
            </div>
            <?php endif; ?>
        </div>
    </div>

</div><!-- /container -->

<!-- Form oculto para ZIP -->
<form id="formZip" method="POST" action="descargar_zip.php">
    <div id="inputsZip"></div>
</form>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
<script>
// Select all
document.getElementById('selectAll').addEventListener('change', function () {
    document.querySelectorAll('.check-reporte').forEach(c => c.checked = this.checked);
    actualizarBoton();
});
document.querySelectorAll('.check-reporte').forEach(c => {
    c.addEventListener('change', actualizarBoton);
});

function actualizarBoton() {
    const seleccionados = document.querySelectorAll('.check-reporte:checked').length;
    document.getElementById('btnDescargarZip').disabled = seleccionados === 0;
    document.getElementById('btnDescargarZip').textContent = seleccionados > 0
        ? `⬇ Descargar ${seleccionados} PDF(s) (.zip)`
        : '⬇ Descargar seleccionados (.zip)';
}

function descargarZip() {
    const ids = [...document.querySelectorAll('.check-reporte:checked')].map(c => c.value);
    const container = document.getElementById('inputsZip');
    container.innerHTML = ids.map(id => `<input type="hidden" name="ids[]" value="${id}">`).join('');
    document.getElementById('formZip').submit();
}
</script>
</body>
</html>
