#!/bin/bash

cd /
sudo apt update -y ### Package list updaten.
sudo apt autoremove -y ### Packages die niet nodig zijn verwijderen.



#########################################
#   INSTALLEREN VAN BENODIGDE SOFTWARE  #
#########################################
sudo apt install apache2 -y ### Webserver
sudo apt install libapache2-mod-wsgi-py3 -y ### Mod om Apache met Flask te laten praten.
sudo a2enmod wsgi ### De WSGI mod enablen.
sudo apt install python3-pip -y ### Python package manager installeren.
sudo pip3 install Flask ### De Python Flask package installeren.
sudo pip3 install mysql-connector-python==8.0.29 ### De Python mysql-connector installeren. (Specefiek versie 8.0.29 installeren om te voorkomen dat het niet werkt en dat je error codes krijgt (zoals UFT-8 errors). )



#########################################
#     DOWNLOADEN VAN BENODIGDE FILES    #
#########################################

sudo wget server.sgrt.nl:7050/fysdatabase.sql ### Database files downloaden.
sudo wget server.sgrt.nl:7050/fys.zip ### De flask site (captive portal) downloaden.



#########################################
#      CONFIGUREREN VAN DE SYSTEMEN     #
#########################################   

### Mysql configuratie
sudo mysql -e "DELETE FROM mysql.user WHERE User='';" ### Annonieme users verwijderen.
sudo mysql -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');" ### Root users verwijderen die vanuit buitenaf berijkbaar zijn.
#sudo mysql -e "DROP DATABASE test;" ### Test database verwijderen (onnodige database).
sudo mysql -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';" ### De privileges van de test database verwijderen.
sudo mysql -e "FLUSH PRIVILEGES;" ### Alle veranderingen toepassen.
sudo mysql -e "CREATE USER 'flask'@'localhost' IDENTIFIED BY 'flask';" ### Creates the user flask on localhost with the password flask
sudo mysql -e "GRANT ALL PRIVILEGES ON fys.* TO 'flask'@'localhost' WITH GRANT OPTION;" ### Grants the SELECT query to the flask user
sudo mysql -e "FLUSH PRIVILEGES;" ### Flushes the old priviliges in order to update the old priviliges to the new ones we made in the past command
sudo mysql -u root < fysdatabase.sql ### Installs the database form the .sql file
#sudo mysql -e < fysdatabase.sql ### Installs the database form the .sql file

### User van Apache rechten geven om iptables rules toe te voegen en weg te halen (toevoegen van die rechten op regel 45).
#sed -i '45 i www-data ALL=(ALL) NOPASSWD: /usr/sbin/iptables' /etc/sudoers
sudo echo 'www-data ALL=(ALL) NOPASSWD: /usr/sbin/iptables' >> /etc/sudoers


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

from FlaskApp import app as application
application.secret_key = os.urandom(12)
EOF


sudo unzip fys.zip -d var/www/FlaskApp/FlaskApp/ ### De gedownloade Flask site (captive portal) uitpakken en in de goede map zetten.


### De standaard DNS server van Ubuntu uitzetten en de nieuwe configureren.
sudo systemctl disable systemd-resolved ### Ervoor zorgen dat de oude DNS server niet meer automatisch opstart bij een reboot.
sudo systemctl stop systemd-resolved ### De oude DNS server uitzetten.
sudo unlink /etc/resolv.conf ### De oude configuratie file verwijderen.


### Nieuw bestand aanmaken voor DNS nameservers, 8.8.8.8 is van Google, 1.1.1.1 is van Cloudflare.
sudo cat >> /etc/resolv.conf << EOF
nameserver 8.8.8.8
nameserver 1.1.1.1
EOF


sudo systemctl enable dnsmasq ### Ervoor zorgen dat de nieuwe DNS opstart na een reboot.
sudo systemctl restart dnsmasq ### Nieuwe DNS server aanzetten.


### Bestand aanmaken om een statisch ip te configureren voor wlan0 (de wifi interface).
sudo cat >> /etc/dhcpcd.conf << EOF 
interface wlan0
    static ip_adress=192.168.4.1/23
    nohook wpa_supplicant
EOF


### Bestand aanmaken om de kernel duidelijk te maken dat hij packets moet gaan forwarden.
sudo cat >> /etc/sysctl.d/routed-ap.conf << EOF 
net.ipv4.ip_forward=1
EOF


sudo iptables --policy FORWARD DROP ### In de Forward table standaard verkeer blokkeren. Dit omdat je wilt als mensen verbinden met de hotspot dat je niet wilt dat ze direcht op het internet kunnen.
### ^^^ Verkeer kan alleen naar het internet toe als er in de Forward table ip's worden geaccepteerd, dit doet de Flask site (Captive portal).


sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE ### Het interne subnet met NAT verbinden met het externe ip.

sudo iptables -A INPUT -p tcp -i wlan0 --dport 22 -j DROP
sudo iptables -A INPUT -p tcp -i wlan0 --sport 22 -j DROP


sudo netfilter-persistent save ### Bovenstaande iptables rules opslaan. Normaal gezien worden alle regels na een reboot verwijderd.


### Dnsmasq configureren.
sudo mv /etc/dnsmasq.conf /etc/dnsmasq.conf.orig ### Oude configuratie opslaan onder een nieuwe naam zodat er een nieuwe configuratie aangemaakt kan worden.
### Nieuwe file aanmaken voor de DHCP en DNS configuratie. 
sudo cat >> /etc/dnsmasq.conf << EOF
interface=wlan0
dhcp-range=192.168.4.5,192.168.5.250,255.255.254.0,4h
domain=wlan
address=/gw.wlan/192.168.4.1
address=/connectivitycheck.gstatic.com/192.168.4.1
address=/wpad.wlan/192.168.4.1
address=/msftconnecttest.com/192.168.4.1
address=/auoxxaiz.wlan/192.168.4.1
address=/captive.apple.com/192.168.4.1
address=/one.one.one.one/192.168.4.1
address=/captive.g.aapling.com/192.168.4.1
address=/clients4.google.com/192.168.4.1
address=/wpad.*/192.168.4.1
address=/*.wlan/192.168.4.1
address=/liipmwvgg.wlan/192.168.4.1
EOF


### Bestand aanmaken voor hotspot configuratie.
sudo cat >> /etc/hostapd/hostapd.conf << EOF
country_code=NL
interface=wlan0
ssid=$wifiname
hw_mode=g
channel=1
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=2
wpa_passphrase=CorendonWifi
wpa_key_mgmt=WPA-PSK
wpa_pairwise=CCMP
EOF

### Bestand aanmaken om statisch ip toe te dienen aan de wifi interface. Anders kan je errors krijgen zoals 'kan ip adress niet krijgen'.
sudo cat >> /etc/network/interfaces << EOF
# /etc/network/interfaces
auto wlan0
iface wlan0 inet static
address 192.168.4.1
netmask 255.255.254.0
EOF


sudo apt install ifupdown ### Package installeren om statisch ip toe te kunnen wijzen.
sudo systemctl enable networking ### Bovenstaande package enablenen zodat het opstart bij het rebooten.
sudo systemctl disable systemd-networkd ### Oude package disablenen zodat het niet meer opstart bij het rebooten.
sudo systemctl restart networking ### Nieuwe networking restarten.


sudo rfkill unblock wlan0 ### Is nodig bij sommige devices om te kunnen werken als acces point (Zoals een Rpi)


sudo systemctl unmask hostapd ### Ervoor zorgen dat de hotspot kan starten.
sudo systemctl enable hostapd ### Ervoor zorgen dat de hotspot start bij het rebooten.
sudo systemctl start hostapd ### Ervoor zorgen dat de hostspot gestart word.




#########################################
#    Laatste keer updaten voor reboot   #
#########################################

sudo apt update -y ### Voor het rebooten package list updaten.
sudo apt upgrade -y ### Voor het rebooten packages updaten.
sudo apt autoremove -y ### Voor het rebooten onnodige packages verwijderen.

clear

echo ""
echo "Installatie geslaagd"
echo ""
#echo "Routed Wireless Acces Point restarten over 10 seconden"

#sleep 15

#reboot
