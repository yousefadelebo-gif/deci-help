"""
Custom Permissions for Decision Companion.

Defines role-based permissions for USER and ADMIN roles.
"""

from rest_framework import permissions


class IsAdmin(permissions.BasePermission):
    """
    Permission class that allows access only to admin users.
    """
    
    def has_permission(self, request, view):
        return (
            request.user and
            request.user.is_authenticated and
            request.user.role == 'ADMIN'
        )


class IsAdminOrReadOnly(permissions.BasePermission):
    """
    Permission class that allows read access to all authenticated users
    but write access only to admin users.
    """
    
    def has_permission(self, request, view):
        if request.method in permissions.SAFE_METHODS:
            return request.user and request.user.is_authenticated
        return (
            request.user and
            request.user.is_authenticated and
            request.user.role == 'ADMIN'
        )


class IsOwnerOrAdmin(permissions.BasePermission):
    """
    Permission class that allows access to object owners or admin users.
    """
    
    def has_object_permission(self, request, view, obj):
        # Admin can access anything
        if request.user.role == 'ADMIN':
            return True
        
        # Check if user owns the object
        if hasattr(obj, 'user'):
            return obj.user == request.user
        if hasattr(obj, 'owner'):
            return obj.owner == request.user
        
        return False


class IsOwner(permissions.BasePermission):
    """
    Permission class that allows access only to object owners.
    """
    
    def has_object_permission(self, request, view, obj):
        if hasattr(obj, 'user'):
            return obj.user == request.user
        if hasattr(obj, 'owner'):
            return obj.owner == request.user
        return False


class IsAuthenticatedOrGuest(permissions.BasePermission):
    """
    Permission class that allows access to authenticated users
    including guest users.
    """
    
    def has_permission(self, request, view):
        return request.user and request.user.is_authenticated


class IsNotGuest(permissions.BasePermission):
    """
    Permission class that denies access to guest users.
    """
    
    def has_permission(self, request, view):
        return (
            request.user and
            request.user.is_authenticated and
            not request.user.is_guest
        )
