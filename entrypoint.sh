# Reverse proxy, program will display docker container ip otherwise.
sudo a2enmod proxy
sudo a2enmod proxy_http

# Start apache on the foreground, otherwise it quits after booting.
apache2ctl -D FOREGROUND