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

EXPOSE 80/tcp

# EXPOSE 3306

COPY ./entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

CMD ["/bin/bash", "/entrypoint.sh"]