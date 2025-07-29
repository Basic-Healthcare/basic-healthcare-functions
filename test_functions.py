import pytest
import azure.functions as func
from function_app import health_check
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
