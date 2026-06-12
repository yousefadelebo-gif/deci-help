"""
Custom Exception Handler for Decision Companion.

Provides consistent error response format across the API.
"""

from rest_framework.views import exception_handler
from rest_framework.response import Response
from rest_framework import status


def custom_exception_handler(exc, context):
    """
    Custom exception handler that provides consistent error format.
    
    Response format:
    {
        "success": false,
        "error": {
            "code": "ERROR_CODE",
            "message": "Error message",
            "details": {...}  # Optional
        }
    }
    """
    # Call REST framework's default exception handler first
    response = exception_handler(exc, context)
    
    if response is not None:
        custom_response = {
            'success': False,
            'error': {
                'code': get_error_code(response.status_code),
                'message': get_error_message(response.data),
                'details': response.data if isinstance(response.data, dict) else {'detail': response.data}
            }
        }
        response.data = custom_response
    
    return response


def get_error_code(status_code):
    """Map HTTP status code to error code string."""
    error_codes = {
        400: 'BAD_REQUEST',
        401: 'UNAUTHORIZED',
        403: 'FORBIDDEN',
        404: 'NOT_FOUND',
        405: 'METHOD_NOT_ALLOWED',
        409: 'CONFLICT',
        422: 'VALIDATION_ERROR',
        429: 'TOO_MANY_REQUESTS',
        500: 'INTERNAL_SERVER_ERROR',
    }
    return error_codes.get(status_code, 'ERROR')


def get_error_message(data):
    """Extract error message from response data."""
    if isinstance(data, dict):
        if 'detail' in data:
            return str(data['detail'])
        if 'message' in data:
            return str(data['message'])
        # Get first error message from validation errors
        for key, value in data.items():
            if isinstance(value, list) and value:
                return f"{key}: {value[0]}"
            elif isinstance(value, str):
                return f"{key}: {value}"
    elif isinstance(data, list) and data:
        return str(data[0])
    return str(data)
