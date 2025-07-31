import azure.functions as func
import logging
import json
from datetime import datetime

app = func.FunctionApp(http_auth_level=func.AuthLevel.FUNCTION)

def health_check(req: func.HttpRequest) -> func.HttpResponse:
    """
    Simple health check endpoint to verify the function is running
    """
    logging.info('Python HTTP trigger function processed a health check request.')
    
    try:
        # Basic health check response
        response_data = {
            "status": "healthy",
            "message": "Basic Healthcare Functions - Python is running",
            "timestamp": datetime.now().isoformat(),
            "function_app": "basic-healthcare-functions",
            "version": "1.0.0"
        }
        
        return func.HttpResponse(
            json.dumps(response_data),
            status_code=200,
            headers={"Content-Type": "application/json"}
        )
    except Exception as e:
        logging.error(f"Health check failed: {str(e)}")
        return func.HttpResponse(
            json.dumps({"error": "Health check failed", "details": str(e)}),
            status_code=500,
            headers={"Content-Type": "application/json"}
        )

def status_check(req: func.HttpRequest) -> func.HttpResponse:
    """
    Extended status endpoint with basic system information
    """
    logging.info('Status check requested.')
    
    try:
        import platform
        import sys
        
        status_data = {
            "status": "operational",
            "service": "basic-healthcare-functions",
            "version": "1.0.0", 
            "timestamp": datetime.now().isoformat(),
            "python_version": sys.version,
            "platform": platform.platform(),
            "endpoints": [
                "/api/health",
                "/api/status"
            ]
        }
        
        return func.HttpResponse(
            json.dumps(status_data, indent=2),
            status_code=200,
            headers={"Content-Type": "application/json"}
        )
    except Exception as e:
        logging.error(f"Status check failed: {str(e)}")
        return func.HttpResponse(
            json.dumps({"error": "Status check failed", "details": str(e)}),
            status_code=500,
            headers={"Content-Type": "application/json"}
        )

# Register the functions with the app
app.route(route="health")(health_check)
app.route(route="status")(status_check)
