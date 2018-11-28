#!/bin/bash

# 1 - Crear sitio pantheon
# 2 - descargar en local
# 3 - ejecutar launcher
# 4 - descargar docker con settings.local.php
# 5 - mover docker a private
# 6 - averiguar variables entorno y cambiar
# 7 - levantar docker
# 8 - entrar bash docker
# 9 - importar bd --  `drush sql-connect` < example.sql
# 10 - borrar caches, cron y watchdog
# 11 - abrir ventana sitio
# 12 - instalar dependencias tema y compilar
# 13 - abrir terminal bash

# sh -c "$(curl -sSL https://raw.githubusercontent.com/biko2/drupal-dev-scripts/master/pantheon-launcher.sh | bash -s -- OLA)"


SITIO1=$1
SITIO2=$2
SITIO3=$3
SITIO4=$4
echo "1" $SITIO1 
echo "2" $SITIO2 
echo "3" $SITIO3 
echo "4" $SITIO4