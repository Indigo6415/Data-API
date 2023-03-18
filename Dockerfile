# FROM python:3.9
FROM ubuntu:latest

# Install packages required for running the website
RUN apt-get update && apt-get install -y apache2 \
        sudo \
        python3-pip \
        libapache2-mod-wsgi-py3 ;

# Install packages required for running the website
COPY requirements.txt /app/requirements.txt
RUN pip install -r /app/requirements.txt

# ----------- DEBUG ONLY ------------
RUN apt install nano
# ----------- DEBUG ONLY ------------

# Create the FlaskApp directory
RUN mkdir -p /var/www/FlaskApp/FlaskApp/

# Copy the FlaskApp.conf file into apache2
COPY FlaskApp.conf /etc/apache2/sites-available

# Copy everything into the /app directory
COPY . /var/www/FlaskApp/FlaskApp
WORKDIR /var/www/FlaskApp/FlaskApp

# RUN a2enmod wsgi
# Disable the default configuration and enable the new one
RUN a2dissite 000-default
RUN a2ensite FlaskApp

COPY flaskapp.wsgi /var/www/FlaskApp

WORKDIR /

COPY ctf_db.sql /

# start the service
# RUN sudo service mysql start && sleep 10

# RUN service --status-all && sleep 10

# # Configure the database
# RUN mysql -u root < ctf_db.sql

# # Anonieme user verwijderen
# RUN mysql -e "DELETE FROM mysql.user WHERE User='';"

# # Root users verwijderen die vanaf buitenaf kunnen verbinden
# RUN mysql -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"

# # Nieuwe user aanmaken om mee te verbinden
# RUN  mysql -e "CREATE USER 'ctf'@'localhost' IDENTIFIED BY 'super1s2t3r3o5n6gu7n7g89u0e0ssablepassword';"

# # De juiste privileges instellen zodat de user read en write kan uitvoeren.
# RUN mysql -e "GRANT ALL PRIVILEGES ON ctf_db.* TO 'ctf'@'localhost' WITH GRANT OPTION;"

# # Flush de privileges zodat de oude privileges hierboven worden toegepast
# RUN mysql -e "FLUSH PRIVILEGES;"

EXPOSE 80/tcp

# EXPOSE 3306

COPY ./entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

CMD ["/bin/bash", "/entrypoint.sh"]