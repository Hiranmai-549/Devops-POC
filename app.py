import socket
from flask import Flask

app = Flask(__name__)

@app.route('/')
def gethostname():
    return f"Container ID is: {socket.gethostname()} This is the dev branch."

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
