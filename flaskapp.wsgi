#!/usr/bin/python
import os
import sys
import logging
logging.basicConfig(stream=sys.stderr)
sys.path.insert(0,"/var/www/FlaskApp/")

from FlaskApp import application
application.secret_key = os.urandom(256)