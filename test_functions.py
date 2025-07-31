import pytest
import azure.functions as func
from function_app import health_check, status_check
import json

def test_health_check():
    # Create a mock HTTP request
    req = func.HttpRequest(
        method='GET',
        body=b'',
        url='http://localhost/api/health',
        headers={}
    )
    
    # Call the function
    response = health_check(req)
    
    # Assert the response
    assert response.status_code == 200
    
    # Parse the JSON response
    response_json = json.loads(response.get_body().decode())
    assert response_json['status'] == 'healthy'
    assert 'Basic Healthcare Functions' in response_json['message']
    assert response_json['version'] == '1.0.0'

def test_status_check():
    # Create a mock HTTP request
    req = func.HttpRequest(
        method='GET',
        body=b'',
        url='http://localhost/api/status',
        headers={}
    )
    
    # Call the function
    response = status_check(req)
    
    # Assert the response
    assert response.status_code == 200
    
    # Parse the JSON response
    response_json = json.loads(response.get_body().decode())
    assert response_json['status'] == 'operational'
    assert response_json['service'] == 'basic-healthcare-functions'
    assert 'endpoints' in response_json
