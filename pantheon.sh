#!/bin/bash

# - Configurar permisos carpeta files para usuario no docker (solucion dorado) configurar /etc/subuid  /etc/subgid y luego el /etc/docker/daemon.json
# - comprobar si existe carpeta docker /private/PROYECTO (2ª vez)

# sh -c "$(curl -sSL -H 'Cache-Control: no-cache' https://raw.githubusercontent.com/biko2/drupal-dev-scripts/master/pantheon.sh)"


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
cd $RUTA && chmod 777 $searchsql
if [ -n "$searchsql" ]; then
  echo "Se importara la siguiente base de datos" $searchsql
  mv $searchsql database.sql
else
  echo "Error. No ha sido encontrada ninguna base de datos (.sql)"
  exit 1
fi



# Descargar imagen docker
# https://github.com/biko2/drupal-dev
cd $RUTA
mkdir private && cd private
git clone https://github.com/biko2/drupal-dev.git $PROYECTO
sudo chown -R $USER:$USER $PROYECTO
rm -rf $RUTA/private/$PROYECTO/.git



# Precommit
https://github.com/biko2/drupal-dev-precommit
cd $RUTA/private && mkdir git_hooks && cd git_hooks
wget https://raw.githubusercontent.com/biko2/drupal-dev-precommit/master/git_hooks/phpmd.xml
wget https://raw.githubusercontent.com/biko2/drupal-dev-precommit/master/git_hooks/pre-commit
chmod +x pre-commit

# cd $RUTA
cd $RUTA
composer require "squizlabs/php_codesniffer=*" drupal/coder dealerdirect/phpcodesniffer-composer-installer phpmd/phpmd
php vendor/bin/phpcs --config-set installed_paths vendor/drupal/coder/coder_sniffer

cd .git/hooks
ln -s $RUTA/private/git_hooks/pre-commit pre-commit



# Automatic removal of .git directories from Composer dependencies
# https://www.drupaleasy.com/quicktips/automatic-removal-git-directories-composer-dependencies
cd $RUTA
composer require topfloor/composer-cleanup-vcs-dirs



# Editamos el archivo docker.conf y establecemos nuestro ServerName
cd $RUTA/private/$PROYECTO/docker/web/vhosts
myhost=$PROYECTO.localhost
sed -i 's/drupal.localhost/'"$myhost"'/g' "docker.conf"
sed -i 's#/var/www/html/web#/var/www/html#g' "docker.conf"
sed -i 's#/var/www/html/docker/web/docker#/var/www/html/private/'"$PROYECTO"'/docker/web/docker#g' "docker.conf"

# Config path adminer
sed -i 's#/var/www/html/docker/web/adminer#/var/www/html/private/'"$PROYECTO"'/docker/web/adminer#g' "adminer.conf"


# Editamos el archivo .env y docker-compose.yml
cd $RUTADOCKER
sed -i 's/docker/'"$PROYECTO"'/g' ".env"
sed -i 's#./:/var/www/html#./../../:/var/www/html#g' "docker-compose.yml"
sed -i 's#working_dir: /var/www/html/web#working_dir: /var/www/html#g' "docker-compose.yml"



# Iniciamos la imagen docker
cd $RUTADOCKER
docker-compose up -d
docker-compose ps



# Proporcionamos un settings.local.php y editamos conexión bd
cd $RUTA/sites/default
if [ ! -f settings.local.php ]; then
    wget https://raw.githubusercontent.com/biko2/drupal-dev-scripts/master/settings.local.php
fi

cd $RUTADOCKER
NAMEBD=$(docker ps | grep _mysql_ | awk '{print $NF}')
echo "$NAMEBD"

cd $RUTA/sites/default
sed -i 's/docker/'"$PROYECTO"'/g' "settings.local.php"
sed -i 's/mysql_1/'"$NAMEBD"'/g' "settings.local.php"






# Permisos carpetas
cd $RUTADOCKER
FILES="/sites/default/files"
ROOTDOCKER="/var/www/html"


if [ ! -d "$RUTA$FILES" ]; then
  docker-compose exec web mkdir $ROOTDOCKER$FILES
fi
docker-compose exec web chmod -R 777 $ROOTDOCKER$FILES


# Importar base de datos
cd $RUTA
wget https://raw.githubusercontent.com/biko2/drupal-dev-scripts/master/import-database.sh
cd $RUTADOCKER
docker-compose exec web drush sql-drop
docker-compose exec web drush sqlc < database.sql
# docker-compose exec web bash ./import-database.sh


# Borramos caches drupal
cd $RUTADOCKER
docker-compose exec web drush cr
docker-compose exec web drush status
sleep 10

# Abrimos el navegador con nuestra web
xdg-open http://$myhost
xdg-open http://adminer.localhost
xdg-open https://media.giphy.com/media/dIxkmtCuuBQuM9Ux1E/giphy