# Drupal DEV Scripts

### Opción 1 (Local)

Asistente para montar un entorno drupal en local en pocos pasos.
Con posbilidad de elegit el perfil de instalación de drupal 8.

Pasos:

1. Abrir el terminal donde alojes tus proyectos y ejecutar:  
   * sh -c "$(curl -sSL https://raw.githubusercontent.com/biko2/drupal-dev-scripts/master/docker-launcher.sh)"
   
2. Escribir un nombre para tu proyecto. (ejem: biko2)

3. Elegir perfil instalación (Standard, Minimal o demo)

4. Al terminar podras acceder a tu proyecto drupal.

   * Acceso web
   Host: NOMBREPROYECTO.localhost  
   Usuario: admin  
   Contraseña: admin  
   
   * Base de datos
   Adminer -> adminer.localhost  
   Nombre: NOMBREPROYECTO  
   usuario: NOMBREPROYECTO  
   Contraseña: NOMBREPROYECTO  
   Servidor: NOMBREPROYECTO_mysql_1  
