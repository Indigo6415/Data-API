#!/bin/bash

cd /
sudo apt update -y ### Package list updaten.
sudo apt autoremove -y ### Packages die niet nodig zijn verwijderen.



#########################################
#   INSTALLEREN VAN BENODIGDE SOFTWARE  #
#########################################
sudo apt install apache2 -y ### Webserver
sudo apt install libapache2-mod-wsgi-py3 -y ### Mod om Apache met Flask te laten praten.
sudo apt install git -y
sudo a2enmod wsgi ### De WSGI mod enablen.
sudo apt install python3-pip -y ### Python package manager installeren.
sudo pip3 install Flask ### De Python Flask package installeren.
sudo pip3 install mysql-connector-python==8.0.29 ### De Python mysql-connector installeren. (Specefiek versie 8.0.29 installeren om te voorkomen dat het niet werkt en dat je error codes krijgt (zoals UFT-8 errors). )



#########################################
#     DOWNLOADEN VAN BENODIGDE FILES    #
#########################################

sudo git clone https://github.com/Indigo6415/Data-API.git

sudo mkdir -p /var/www/FlaskApp/FlaskApp/ ### Map aanmaken voor de Flask site (captive portal).
sudo ln -sf /usr/bin/python3 /usr/bin/python ### Python versie 3 de standaard Python maken.


### Apache configuratie file aanmaken voor de flask site (captive portal).
sudo cat >> /etc/apache2/sites-available/FlaskApp.conf << EOF
<VirtualHost *:80>
  WSGIScriptAlias / /var/www/FlaskApp/flaskapp.wsgi
  <Directory /var/www/FlaskApp/FlaskApp/>
    Order allow,deny
    Allow from all
  </Directory>
  Alias /static /var/www/FlaskApp/FlaskApp/static
    <Directory /var/www/FlaskApp/FlaskApp/static/>
    Order allow,deny
    Allow from all
  </Directory>
  ErrorLog ${APACHE_LOG_DIR}/error.log
  LogLevel warn
  CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF


sudo a2dissite 000-default
sudo a2ensite FlaskApp ### De flask configuratie (captive portal) activeren.


### WSGI file aanmaken voor Apache om de Flask website te kunnen runnen.
sudo cat >> /var/www/FlaskApp/flaskapp.wsgi << EOF
#!/usr/bin/python
import os
import sys
import logging
logging.basicConfig(stream=sys.stderr)
sys.path.insert(0,"/var/www/FlaskApp/")

from FlaskApp import application
application.secret_key = os.urandom(12)
EOF


sudo cp -r Data-API/. var/www/FlaskApp/FlaskApp/ ### De gedownloade Flask site (captive portal) uitpakken en in de goede map zetten.

sudo reboot