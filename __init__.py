# from flask import Flask, request
# from flask_limiter import Limiter
# from flask_limiter.util import get_remote_address
# import os

# # Initialize the flask instance called application
# application = Flask(__name__)
# application.secret_key = os.urandom(256)


# # Initialize the rate limiter called limiter
# limiter = Limiter(
#     get_remote_address,
#     app=application,
#     default_limits=["1 per minute"],
#     storage_uri="memory://",
#     strategy="fixed-window"
# )

# defaultRateLimit = "100 per minute"

# # Decorate the get_ip function with the flask route and the rate limiter
# @application.route("/api/get-ip", methods=["GET"])
# @limiter.limit(defaultRateLimit)
# def get_ip():
#     return request.remote_addr


# if __name__ == "__main__":
#     application.run(host="0.0.0.0", port=80, debug=False)


from flask import Flask, request
import threading
import os
import time

# Initialize the flask instance called application
application = Flask(__name__)
application.secret_key = os.urandom(256)

# Initialize a dictionary to store the number of requests made by each IP address
ip_count = {}

# Define a function to reset the count for each IP address every minute
def reset_ip_count():
    global ip_count
    ip_count = {}
    # Call this function again after 1 minute
    time.sleep(60)
    reset_ip_count()

# Start the reset_ip_count function in a separate thread
t = threading.Thread(target=reset_ip_count)
t.start()

# Decorate the get_ip function with the flask route and the rate limiter
@application.route("/api/get-ip/", methods=["GET"])
def get_ip():
    global ip_count
    # Get the IP address of the requester
    ip = request.remote_addr
    # If the IP address is not in the dictionary, add it with a count of 1
    if ip not in ip_count:
        ip_count[ip] = 1
    # If the IP address is in the dictionary, increment the count by 1
    else:
        ip_count[ip] += 1
    # If the count for the IP address is greater than 100, return an error
    if ip_count[ip] > 100:
        return "429, Too many requests"
    # Otherwise, return the IP address
    else:
        return ip


if __name__ == "__main__":
    application.run(host="0.0.0.0", port=80, debug=False)