#!/bin/bash

# 4 - descargar docker con settings.local.php
# 7 - levantar docker
# 8 - entrar bash docker
# 9 - importar bd --  `drush sql-connect` < example.sql
# 10 - borrar caches, cron y watchdog
# 11 - abrir ventana sitio
# 12 - instalar dependencias tema y compilar
# 13 - abrir terminal bash
# curl -sSL https://raw.githubusercontent.com/biko2/drupal-dev-scripts/master/pantheon-launcher.sh | bash -s -- OLA


# Detener todos los servicios docker
docker stop $(docker ps -a)
clear


# Ruta proyecto
RUTA=$(pwd)

# Nombre proyecto
PROYECTO=$(basename $RUTA)


# Comprobar que se ejecuta phanteon.sh en la carpeta correcta
checkpantheon=$(find $RUTA -maxdepth 1 -type f -name pantheon.yml)
if [ -n "$checkpantheon" ]; then
  echo "Asistente de inicio para sitios en Pantheon"
else
  echo "Error. Debe ejecutar el script dentro del proyecto)"
  exit 1
fi


# Comprobar si existe una base de datos (SQL) en la raíz del proyecto
searchsql=$(find $RUTA -maxdepth 1 -type f -name *.sql)
if [ -n "$searchsql" ]; then
  echo "Se importara la siguiente base de datos" $searchsql
else
  echo "Error. No ha sido encontrada ninguna base de datos (.sql)"
  exit 1
fi


# Descargar imagen docker
# https://github.com/biko2/drupal-dev
cd $RUTA
mkdir private
cd private
git clone https://github.com/biko2/drupal-dev.git $PROYECTO
sudo chown -R $USER $PROYECTO



# Editamos el archivo docker.conf y establecemos nuestro ServerName
cd $RUTA/private/$PROYECTO/docker/web/vhosts
myhost=$PROYECTO.localhost
sed -i 's/drupal.localhost/'"$myhost"'/g' "docker.conf"



# Editamos el archivo .env para cambiar datos de conexión a la base de datos
cd $RUTA/private/$PROYECTO
sed -i 's/docker/'"$PROYECTO"'/g' ".env"






# Iniciamos la imagen docker
# cd $mypwd/$PROYECTO
# docker-compose up -d
# docker-compose ps


# Importar base de datos
# `drush sql-connect` < example.sql