import azure.functions as func
import logging
import json
import os
from azure.storage.blob import BlobServiceClient
from datetime import datetime

app = func.FunctionApp(http_auth_level=func.AuthLevel.FUNCTION)

@app.route(route="health")
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
            "function_app": "basic-healthcare-functions"
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

@app.route(route="datalake/upload", methods=["POST"])
def upload_to_datalake(req: func.HttpRequest) -> func.HttpResponse:
    """
    Upload files to the data lake storage account
    """
    logging.info('Python HTTP trigger function for data lake upload.')
    
    try:
        # Get storage connection string from environment variables
        connection_string = os.environ.get('AzureWebJobsStorage')
        
        if not connection_string:
            return func.HttpResponse(
                json.dumps({"error": "Storage connection string not configured"}),
                status_code=500,
                headers={"Content-Type": "application/json"}
            )
        
        # Use connection string for authentication (simpler for initial deployment)
        blob_service_client = BlobServiceClient.from_connection_string(connection_string)
        
        # Get request body
        req_body = req.get_json()
        if not req_body:
            return func.HttpResponse(
                json.dumps({"error": "Request body is required"}),
                status_code=400,
                headers={"Content-Type": "application/json"}
            )
        
        container_name = req_body.get('container', 'healthcare-data')
        blob_name = req_body.get('blob_name')
        content = req_body.get('content')
        
        if not blob_name or not content:
            return func.HttpResponse(
                json.dumps({"error": "blob_name and content are required"}),
                status_code=400,
                headers={"Content-Type": "application/json"}
            )
        
        # Upload to blob storage
        blob_client = blob_service_client.get_blob_client(container=container_name, blob=blob_name)
        blob_client.upload_blob(content, overwrite=True)
        
        response = {
            "status": "success",
            "message": f"File {blob_name} uploaded successfully to {container_name}",
            "blob_url": blob_client.url
        }
        
        return func.HttpResponse(
            json.dumps(response),
            status_code=200,
            headers={"Content-Type": "application/json"}
        )
        
    except Exception as e:
        logging.error(f"Upload failed: {str(e)}")
        return func.HttpResponse(
            json.dumps({"error": f"Upload failed: {str(e)}"}),
            status_code=500,
            headers={"Content-Type": "application/json"}
        )

@app.route(route="datalake/list", methods=["GET"])
def list_datalake_files(req: func.HttpRequest) -> func.HttpResponse:
    """
    List files in the data lake storage account
    """
    logging.info('Python HTTP trigger function for listing data lake files.')
    
    try:
        # Get storage connection string from environment variables
        connection_string = os.environ.get('AzureWebJobsStorage')
        
        if not connection_string:
            return func.HttpResponse(
                json.dumps({"error": "Storage connection string not configured"}),
                status_code=500,
                headers={"Content-Type": "application/json"}
            )
        
        # Use connection string for authentication (simpler for initial deployment)
        blob_service_client = BlobServiceClient.from_connection_string(connection_string)
        
        container_name = req.params.get('container', 'healthcare-data')
        
        # List blobs in container
        container_client = blob_service_client.get_container_client(container_name)
        blobs = []
        
        for blob in container_client.list_blobs():
            blobs.append({
                "name": blob.name,
                "size": blob.size,
                "last_modified": blob.last_modified.isoformat() if blob.last_modified else None,
                "content_type": blob.content_settings.content_type if blob.content_settings else None
            })
        
        response = {
            "status": "success",
            "container": container_name,
            "blob_count": len(blobs),
            "blobs": blobs
        }
        
        return func.HttpResponse(
            json.dumps(response),
            status_code=200,
            headers={"Content-Type": "application/json"}
        )
        
    except Exception as e:
        logging.error(f"List operation failed: {str(e)}")
        return func.HttpResponse(
            json.dumps({"error": f"List operation failed: {str(e)}"}),
            status_code=500,
            headers={"Content-Type": "application/json"}
        )
