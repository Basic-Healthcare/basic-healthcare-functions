from flask import Flask, jsonify
from datetime import datetime
import os

app = Flask(__name__)

@app.route('/')
def root():
    return jsonify({
        "message": "Basic Healthcare AKS App",
        "status": "running",
        "timestamp": datetime.now().isoformat()
    })

@app.route('/health')
def health():
    return jsonify({
        "status": "healthy",
        "message": "Basic Healthcare AKS - Python is running",
        "timestamp": datetime.now().isoformat(),
        "version": "1.0.0",
        "platform": "kubernetes"
    })

@app.route('/status')
def status():
    return jsonify({
        "status": "operational",
        "service": "basic-healthcare-aks",
        "version": "1.0.0",
        "timestamp": datetime.now().isoformat(),
        "endpoints": [
            "/",
            "/health",
            "/status"
        ]
    })

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 8080))
    app.run(host='0.0.0.0', port=port)
