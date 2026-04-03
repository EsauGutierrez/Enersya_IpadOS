-- ============================================
-- ENERSYA - Actualización BD para Web Admin
-- Ejecutar en PHPMyAdmin sobre enersyac_Enersya_app
-- ============================================

ALTER TABLE `reportes` ADD COLUMN `pdf_ruta` VARCHAR(500) DEFAULT NULL;

ALTER TABLE `usuarios` ADD COLUMN `rol` ENUM('tecnico','admin') DEFAULT 'tecnico';

UPDATE `usuarios` SET `rol` = 'admin' WHERE `correo` = 'jgutierrez@enersya.com';
