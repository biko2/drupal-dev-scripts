#!/bin/bash

# 12 - instalar dependencias tema y compilar
# 13 - adminer
# sh -c "$(curl -sSL https://raw.githubusercontent.com/biko2/drupal-dev-scripts/master/pantheon.sh)"


# Detener todos los servicios docker
docker stop $(docker ps -a)
clear

# Ruta proyecto
RUTA=$(pwd)

# Nombre proyecto
PROYECTO=$(basename $RUTA)

# Ruta docker
RUTADOCKER=$RUTA/private/$PROYECTO


# Comprobar que se ejecuta phanteon.sh en la carpeta correcta
checkpantheon=$(find $RUTA -maxdepth 1 -type f -name pantheon.yml)
if [ -n "$checkpantheon" ]; then
  echo "Asistente de inicio para sitios en Pantheon"
else
  echo "Error. Debe ejecutar el script dentro del proyecto)"
  exit 1
fi


# Comprobar si existe una base de datos (SQL) en la raíz del proyecto
searchsql=$(find $RUTA -maxdepth 1 -type f -name *.sql -printf "%f\n")
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


# Permisos files
sudo chmod -R 777 $RUTA/sites/default/files


# Editamos el archivo docker.conf y establecemos nuestro ServerName
cd $RUTA/private/$PROYECTO/docker/web/vhosts
myhost=$PROYECTO.localhost
sed -i 's/drupal.localhost/'"$myhost"'/g' "docker.conf"
sed -i 's#/var/www/html/web#/var/www/html#g' "docker.conf"
sed -i 's#/var/www/html/docker/web/docker#/var/www/html/private/'"$PROYECTO"'/docker/web/docker#g' "docker.conf"




# Editamos el archivo .env y docker-compose.yml
cd $RUTADOCKER
sed -i 's/docker/'"$PROYECTO"'/g' ".env"
sed -i 's#./:/var/www/html#./../../:/var/www/html#g' "docker-compose.yml"
sed -i 's#working_dir: /var/www/html/web#working_dir: /var/www/html#g' "docker-compose.yml"




# Proporcionamos un settings.local.php
cd $RUTA/sites/default
if [ ! -f settings.local.php ]; then
    wget https://raw.githubusercontent.com/biko2/drupal-dev-scripts/master/settings.local.php
fi


# Editamos el archivo settings.local.php
cd $RUTA/sites/default
HOST=$PROYECTO'_mysql_1'
sed -i 's/docker/'"$PROYECTO"'/g' "settings.local.php"
sed -i 's/localhost_bd/'"$HOST"'/g' "settings.local.php"


# Iniciamos la imagen docker
cd $RUTADOCKER
docker-compose up -d
docker-compose ps


# Permisos carpeta files
docker-compose exec web bash -c "cd /var/www/html/sites/default && mkdir files && cd files && mkdir translations && mkdir private"
docker-compose exec web bash -c "cd /var/www/html/sites/default && chmod -R 777 files"


echo $searchsql

# Importar base de datos
cd $RUTADOCKER
docker-compose exec web bash -c "drush sql-cli < $searchsql"

# Borramos caches drupal
docker-compose exec web drush cr
docker-compose exec web drush status

# Abrimos el navegador con nuestra web
# xdg-open http://$myhost

# Entramos en la maquina docker
# docker-compose exec web bash
