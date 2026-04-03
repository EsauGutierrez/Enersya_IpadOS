<?php
  // ============================================
  // api/config.php — Configuración central
  // ============================================
  define('DB_HOST', 'localhost');                                                                                                                  
  define('DB_NAME', 'enersyac_Enersya_app');                                                                                                                 
  define('DB_USER', 'enersyac_iOS_app');
  define('DB_PASS', 'Enersya_ios_app2026');                                                                                                        
  define('TOKEN_EXPIRY_HOURS', 24);
                                                                                                                                                   
  function conectarDB(): PDO {
      $pdo = new PDO(                                                                                                                              
          "mysql:host=" . DB_HOST . ";dbname=" . DB_NAME . ";charset=utf8",
          DB_USER, DB_PASS,                                                                                                                        
          [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
      );                                                                                                                                           
      return $pdo;
  }                                                                                                                                                
   
  function responder(int $codigo, array $datos): void {                                                                                            
      http_response_code($codigo);
      header('Content-Type: application/json');                                                                                                    
      echo json_encode($datos);
      exit;                                                                                                                                        
  }               
  function validarToken(PDO $pdo): array {                                                                                                                                
      $headers = getallheaders();
      $authHeader = $headers['Authorization'] ?? '';                                                                                                                      
                                                                                                                                                                          
      // Compatible con PHP 7.0 (strpos en lugar de str_starts_with)                                                                                                      
      if (strpos($authHeader, 'Bearer ') !== 0) {                                                                                                                         
          responder(401, ['error' => 'Token requerido']);                                                                                                                 
      }                                                                                                                                                                   
   
      $token = substr($authHeader, 7);                                                                                                                                    
      $stmt = $pdo->prepare("                               
          SELECT s.usuario_id, u.nombre, u.correo
          FROM sesiones s                                                                                                                                                 
          JOIN usuarios u ON u.id = s.usuario_id
          WHERE s.token = ? AND s.expira_en > NOW()                                                                                                                       
      ");                                                                                                                                                                 
      $stmt->execute([$token]);
      $usuario = $stmt->fetch(PDO::FETCH_ASSOC);                                                                                                                          
                                                            
      if (!$usuario) {
          responder(401, ['error' => 'Token inválido o expirado']);
      }                                                                                                                                                                   
   
      return $usuario;                                                                                                                                                    
  } 