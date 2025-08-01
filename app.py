from flask import Flask, jsonify
from datetime import datetime
import os

app = Flask(__name__)

@app.route('/health', methods=['GET'])
def health_check():
    """
    Simple health check endpoint for AKS deployment
    """
    return jsonify({
        "status": "healthy",
        "message": "Basic Healthcare AKS - Python is running",
        "timestamp": datetime.now().isoformat(),
        "service": "basic-healthcare-aks",
        "version": "1.0.0",
        "environment": os.environ.get('ENVIRONMENT', 'development')
    }), 200

@app.route('/', methods=['GET'])
def root():
    """
    Root endpoint
    """
    return jsonify({
        "service": "Basic Healthcare AKS",
        "endpoints": [
            "/health",
            "/"
        ]
    }), 200

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 8080))
    app.run(host='0.0.0.0', port=port, debug=False)
