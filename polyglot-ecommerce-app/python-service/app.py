from flask import Flask
app = Flask(__name__)

@app.route('/')
def home():
    return "Python Service Running"

app.run(host='0.0.0.0', port=5000)