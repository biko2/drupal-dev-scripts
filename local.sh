#!/bin/bash

# Crea un nuevo proyecto con drupal 8 y docker
# Instalación de drupal 8 ( default user:admin / pass:admin)

# Instalar dependencias tema y compilar


# Nombre del proyecto y base de datos
echo "Introduce un nombre para el nuevo proyecto en minúsculas y sin espacios. (Ejemplo: biko2)"
read PROYECTO

# Detener todos los servicios docker
docker stop $(docker ps -a)

# Detener conexiones virtuales no usadas
# docker network prune
# docker rm $(docker ps -q -f status=exited)
clear


# Descargar drupal-project don composer y crear carpeta de proyecto
# https://github.com/drupal-composer/drupal-project
composer create-project drupal-composer/drupal-project:8.x-dev $PROYECTO --stability dev --no-interaction
composer install


# Ruta proyecto
mypwd=$(pwd)
cd $mypwd/$PROYECTO


# Descargar imagen docker para drupal y copiar al raíz del proyecto
# https://github.com/biko2/drupal-dev
git clone https://github.com/biko2/drupal-dev.git tmp
sudo chown -R $USER /tmp
cp -r $mypwd/$PROYECTO/tmp/. $mypwd/$PROYECTO
sudo rm -r tmp
sudo chmod -R 777 $mypwd/$PROYECTO/web/sites/default/files


# Editamos el archivo docker.conf y establecemos nuestro ServerName
cd $mypwd/$PROYECTO/docker/web/vhosts
myhost=$PROYECTO.localhost
sed -i 's/drupal.localhost/'"$myhost"'/g' "docker.conf"


# Editamos el archivo .env para cambiar datos de conexión a la base de datos
cd $mypwd/$PROYECTO/
sed -i 's/docker/'"$PROYECTO"'/g' ".env"


# Iniciamos la imagen docker
cd $mypwd/$PROYECTO
docker-compose up -d
docker-compose ps


# Elección perfil instalación
echo "Elige el perfil de instalación drupal:  1)Standard 2)Minimal 3)Demo"
read n
case $n in
    1) perfil='standard';;
    2) perfil='minimal';;
    3) perfil='demo_umami';;
    *) invalid option;;
esac

# Instalamos drupal 8
hostbd=$PROYECTO'_mysql_1'
sudo docker-compose exec web drush site-install $perfil --locale=es --account-name=admin --account-pass=admin --db-url=mysql://$PROYECTO:$PROYECTO@$hostbd/$PROYECTO


# Parche para que el perfil demo funcione bien
if [ "$perfil" == "demo_umami" ]; then
  docker-compose exec web drush pmu demo_umami_content
  docker-compose exec web drush en demo_umami_content -y
fi



# Incluir modulos basicos
composer require 'drupal/ctools:^3.0' 'drupal/pathauto:^1.3' 'drupal/token:^1.5' 'drupal/admin_toolbar:^1.24' 'drupal/config_filter:^1.4' 'drupal/devel:^1.2' 'drupal/field_group:^3.0' 'drupal/config_ignore:^2.1' 'drupal/metatag:^1.7' 'drupal/google_tag:^1.1' 'drupal/paragraphs:^1.5' 'drupal/eu_cookie_compliance:^1.2' 'drupal/stage_file_proxy'


# Desinstalar modulos core no habituales
docker-compose exec web drush pmu color history search tour contact


# Incluir tema COG y subtema
echo "Desea instalar el tema COG y crear un subtema:  1)Si 2)No"
read t
case $t in
    1) composer require 'drupal/cog'
       cd $mypwd/$PROYECTO/web/themes
       mkdir custom
       cd $mypwd/$PROYECTO/web/themes/custom
       git clone https://github.com/biko2/front.git $PROYECTO
       cd $mypwd/$PROYECTO/web/themes/custom/$PROYECTO
       npm install
       cd $mypwd/$PROYECTO
       docker-compose exec web drush config-set system.theme default $PROYECTO
    ;;
    2) break
    ;;
    *) invalid option
    ;;
esac


# Permisos carpeta files
docker-compose exec web chmod -R 777 /var/www/html/web/sites/default/files

# Borramos caches drupal
docker-compose exec web drush cr

# Abrimos el navegador con nuestra web
xdg-open http://$myhost

# Entramos en la maquina docker
docker-compose exec web bash
