-- ============================================
-- ENERSYA - Base de Datos
-- Versión: 1.0
-- Fecha: 2026-04-02
-- Importar en: PHPMyAdmin → Importar
-- ============================================

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "-06:00";

-- ============================================
-- Crear y seleccionar la base de datos
-- ============================================
CREATE DATABASE IF NOT EXISTS `enersya_db`
    DEFAULT CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE `enersya_db`;

-- ============================================
-- 1. TABLA: usuarios
-- ============================================
CREATE TABLE `usuarios` (
    `id`          INT           NOT NULL AUTO_INCREMENT,
    `nombre`      VARCHAR(100)  NOT NULL,
    `correo`      VARCHAR(100)  NOT NULL,
    `contrasena`  VARCHAR(255)  NOT NULL COMMENT 'Hash bcrypt',
    `activo`      TINYINT(1)    NOT NULL DEFAULT 1,
    `creado_en`   TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `correo` (`correo`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Usuario administrador inicial
-- Contraseña: Admin2026* (cámbiala después de importar)
INSERT INTO `usuarios` (`nombre`, `correo`, `contrasena`, `activo`) VALUES
('Administrador', 'admin@enersya.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 1);

-- ============================================
-- 2. TABLA: reportes
-- ============================================
CREATE TABLE `reportes` (
    `id`                    CHAR(36)      NOT NULL COMMENT 'UUID generado en la app',
    `folio`                 INT           NOT NULL,
    `usuario_id`            INT           NOT NULL,

    -- Datos Generales
    `cliente`               VARCHAR(200)  NOT NULL,
    `mes_correspondiente`   VARCHAR(50)   DEFAULT NULL,
    `responsable`           VARCHAR(100)  DEFAULT NULL,
    `domicilio`             VARCHAR(300)  DEFAULT NULL,
    `efectuado_por`         VARCHAR(100)  DEFAULT NULL,
    `telefono`              VARCHAR(20)   DEFAULT NULL,
    `marca`                 VARCHAR(100)  DEFAULT NULL,
    `modelo`                VARCHAR(100)  DEFAULT NULL,
    `no_serie`              VARCHAR(100)  DEFAULT NULL,
    `no_contrato`           VARCHAR(100)  DEFAULT NULL,
    `fecha_creacion`        DATETIME      NOT NULL,

    -- Checklist de Actividades
    `act_rev_medidores`     TINYINT(1)    NOT NULL DEFAULT 0,
    `act_insp_externa`      TINYINT(1)    NOT NULL DEFAULT 0,
    `act_insp_interna`      TINYINT(1)    NOT NULL DEFAULT 0,
    `act_rev_ventiladores`  TINYINT(1)    NOT NULL DEFAULT 0,
    `act_rev_paneles`       TINYINT(1)    NOT NULL DEFAULT 0,
    `act_rev_filtros`       TINYINT(1)    NOT NULL DEFAULT 0,
    `act_limpieza_aerea`    TINYINT(1)    NOT NULL DEFAULT 0,
    `act_limpieza_int`      TINYINT(1)    NOT NULL DEFAULT 0,

    -- Parámetros por Fase (JSON)
    `salida_consumo`        JSON          DEFAULT NULL,
    `salida_regulado`       JSON          DEFAULT NULL,
    `salida_reserva`        JSON          DEFAULT NULL,
    `entrada_consumo`       JSON          DEFAULT NULL,
    `entrada_voltaje`       JSON          DEFAULT NULL,
    `parametros_bypass`     JSON          DEFAULT NULL,

    -- Campos Sueltos
    `condiciones_sincronia` VARCHAR(100)  DEFAULT NULL,
    `porcentaje_carga`      VARCHAR(20)   DEFAULT NULL,
    `temperatura`           VARCHAR(20)   DEFAULT NULL,
    `voltaje_inversor`      VARCHAR(20)   DEFAULT NULL,
    `corriente_inversor`    VARCHAR(20)   DEFAULT NULL,
    `corriente_bateria`     VARCHAR(20)   DEFAULT NULL,
    `voltaje_flotacion`     VARCHAR(20)   DEFAULT NULL,

    -- Observaciones
    `refacciones`           TEXT          DEFAULT NULL,
    `detalles`              TEXT          DEFAULT NULL,

    -- Firmas
    `firma_cliente_ruta`    VARCHAR(500)  DEFAULT NULL,
    `firma_tecnico_ruta`    VARCHAR(500)  DEFAULT NULL,

    `creado_en`             TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `actualizado_en`        TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (`id`),
    UNIQUE KEY `folio` (`folio`),
    KEY `idx_usuario` (`usuario_id`),
    KEY `idx_fecha` (`fecha_creacion`),
    CONSTRAINT `fk_reporte_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- 3. TABLA: fotos_reporte
-- ============================================
CREATE TABLE `fotos_reporte` (
    `id`              INT           NOT NULL AUTO_INCREMENT,
    `reporte_id`      CHAR(36)      NOT NULL,
    `nombre_archivo`  VARCHAR(255)  NOT NULL,
    `ruta`            VARCHAR(500)  NOT NULL,
    `orden`           INT           NOT NULL DEFAULT 0,
    `subido_en`       TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (`id`),
    KEY `idx_reporte` (`reporte_id`),
    CONSTRAINT `fk_foto_reporte` FOREIGN KEY (`reporte_id`) REFERENCES `reportes` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- 4. TABLA: sesiones
-- ============================================
CREATE TABLE `sesiones` (
    `id`          INT           NOT NULL AUTO_INCREMENT,
    `usuario_id`  INT           NOT NULL,
    `token`       VARCHAR(255)  NOT NULL,
    `expira_en`   DATETIME      NOT NULL,
    `creado_en`   TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (`id`),
    UNIQUE KEY `token` (`token`),
    KEY `idx_token` (`token`),
    CONSTRAINT `fk_sesion_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
