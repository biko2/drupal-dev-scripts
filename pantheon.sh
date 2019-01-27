#!/bin/bash

# - Configurar permisos carpeta files para usuario no docker (solucion dorado) configurar /etc/subuid  /etc/subgid y luego el /etc/docker/daemon.json


# Detener todos los servicios docker
docker stop $(docker ps -a -q)
clear

# Ruta proyecto
RUTA=$(pwd)

# Nombre proyecto
PROYECTO=$(basename $RUTA)

# Ruta docker
RUTADOCKER=$RUTA/private/$PROYECTO

# Host
myhost=$PROYECTO.localhost




# Comprobar que se ejecuta phanteon.sh en la carpeta correcta
checkpantheon=$(find $RUTA -maxdepth 1 -type f -name pantheon.yml)
if [ -n "$checkpantheon" ]; then
  echo "Asistente de inicio para sitios en Pantheon"
else
  echo "Error. Debe ejecutar el script dentro del proyecto)"
  exit 1
fi


# Comprobar si se ha instalado docker
checkinstalled=$(find $RUTADOCKER -maxdepth 1 -type f -name docker-compose.yml)
if [ -n "$checkinstalled" ]; then
  INSTALLED=true
else
  INSTALLED=false
fi




if [ "$INSTALLED" = false ] ; then

	# Descargar imagen docker
    # https://github.com/biko2/drupal-dev
	cd $RUTA
	mkdir private && cd private
	git clone https://github.com/biko2/drupal-dev.git $PROYECTO
	sudo chown -R $USER:$USER $PROYECTO
	rm -rf $RUTA/private/$PROYECTO/.git


	# Precommit
	# https://github.com/biko2/drupal-dev-precommit
	cd $RUTA/private && mkdir git_hooks && cd git_hooks
	wget https://raw.githubusercontent.com/biko2/drupal-dev-precommit/master/git_hooks/phpmd.xml
	wget https://raw.githubusercontent.com/biko2/drupal-dev-precommit/master/git_hooks/pre-commit
	chmod +x pre-commit

	cd $RUTA
	composer require "squizlabs/php_codesniffer=*" drupal/coder dealerdirect/phpcodesniffer-composer-installer phpmd/phpmd
	php vendor/bin/phpcs --config-set installed_paths vendor/drupal/coder/coder_sniffer

	cd .git/hooks
	ln -s $RUTA/private/git_hooks/pre-commit pre-commit


	# Automatic removal of .git directories from Composer dependencies
	cd $RUTA
	composer require topfloor/composer-cleanup-vcs-dirs


	# Editamos el archivo docker.conf y establecemos nuestro ServerName
	cd $RUTA/private/$PROYECTO/docker/web/vhosts
	sed -i 's/drupal.localhost/'"$myhost"'/g' "docker.conf"
	sed -i 's#/var/www/html/web#/var/www/html#g' "docker.conf"
	sed -i 's#/var/www/html/docker/web/docker#/var/www/html/private/'"$PROYECTO"'/docker/web/docker#g' "docker.conf"
	sed -i 's#/var/www/html/docker/web/adminer#/var/www/html/private/'"$PROYECTO"'/docker/web/adminer#g' "adminer.conf"


	# Editamos el archivo .env y docker-compose.yml
	cd $RUTADOCKER
	sed -i 's#./:/var/www/html#./../../:/var/www/html#g' "docker-compose.yml"
	sed -i 's#working_dir: /var/www/html/web#working_dir: /var/www/html#g' "docker-compose.yml"

fi




# Iniciamos la imagen docker
cd $RUTADOCKER
docker-compose up -d
docker-compose ps




# Proporcionamos un settings.local.php y editamos conexión bd
cd $RUTA/sites/default
if [ ! -f settings.local.php ]; then
	wget https://raw.githubusercontent.com/biko2/drupal-dev-scripts/master/settings.local.php

	cd $RUTADOCKER
	NAMEBD=$(docker ps | grep _mysql_ | awk '{print $NF}')
	echo "$NAMEBD"

	cd $RUTA/sites/default
	sed -i 's/mysql_1/'"$NAMEBD"'/g' "settings.local.php"
fi




# Permisos carpetas
cd $RUTA
FILES="./sites/default/files"

if [ ! -d "$FILES" ]; then
  cd $RUTADOCKER
  echo "Creando carpeta Files..."
  docker-compose exec web mkdir $FILES
  docker-compose exec web chmod -R 777 $FILES
fi




# Comprobar si existe una base de datos (SQL) en la raíz del proyecto
searchsql=$(find $RUTA -maxdepth 1 -type f -name *.sql -printf "%f\n")
cd $RUTA && chmod 777 $searchsql
if [ -n "$searchsql" ]; then
  echo "Se importara la siguiente base de datos" $searchsql
  mv $searchsql database.sql
  chmod 777 database.sql
else
  echo "No ha sido encontrada ninguna base de datos (.sql)"
fi




# Comprobar si esta instalado drupal
cd $RUTADOCKER
docker-compose exec web drush status bootstrap | grep -q Successful
DATABASE=$?

# Importar base de datos
if [ "$DATABASE" = 1 ]; then
	echo "No existen tablas en la base de datos."
	if [ -n "$searchsql" ]; then
		cd $RUTADOCKER
		docker-compose stop
		docker-compose up -d
		docker-compose exec web drush sql:query --file=./database.sql
		cd $RUTA
		rm database.sql
    fi
else
	echo "Drupal ya está instalado."
fi


# Borramos caches drupal
cd $RUTADOCKER
docker-compose exec web drush cr
docker-compose exec web drush status


# Abrimos el navegador con nuestra web
xdg-open https://media.giphy.com/media/dIxkmtCuuBQuM9Ux1E/giphy
xdg-open http://$myhost
xdg-open http://adminer.localhost

echo "bash"
docker-compose exec web bash
