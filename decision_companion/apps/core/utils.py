"""
Utility functions and helpers for Decision Companion.
"""

from .models import ActivityLog


def log_activity(user, action, description='', request=None, metadata=None):
    """
    Log user activity.
    
    Args:
        user: User instance (can be None for anonymous actions)
        action: ActivityLog.ActionType choice
        description: Optional description
        request: Optional request object for IP and user agent
        metadata: Optional JSON metadata
    """
    ip_address = None
    user_agent = ''
    
    if request:
        ip_address = get_client_ip(request)
        user_agent = request.META.get('HTTP_USER_AGENT', '')
    
    ActivityLog.objects.create(
        user=user,
        action=action,
        description=description,
        ip_address=ip_address,
        user_agent=user_agent,
        metadata=metadata or {}
    )


def get_client_ip(request):
    """Extract client IP address from request."""
    x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
    if x_forwarded_for:
        ip = x_forwarded_for.split(',')[0]
    else:
        ip = request.META.get('REMOTE_ADDR')
    return ip
