from flask import Flask, render_template, request
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address
import os
import json

# Initialize the flask instance called application
application = Flask(__name__)
application.secret_key = os.urandom(256)

# Initialize the rate limiter called limiter
limiter = Limiter(
    get_remote_address,
    app=application,
    default_limits=["1 per minute"],
    storage_uri="memory://",
    strategy="fixed-window"
)

# Decorate the get_ip function with the flask route and the rate limiter
@application.route("/api/ip", methods=["GET"])
@limiter.limit("100 per minute")
def get_ip():
    return request.remote_addr


if __name__ == "__main__":
    application.run(host="0.0.0.0", port=80, debug=False)