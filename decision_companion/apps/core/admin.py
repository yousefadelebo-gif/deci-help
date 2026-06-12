"""
Core Admin Configuration

Decision Companion - AI Decision Making System
"""

from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from .models import User, UserSettings, ActivityLog


@admin.register(User)
class UserAdmin(BaseUserAdmin):
    """Admin configuration for User model."""
    
    list_display = ('email', 'name', 'role', 'is_guest', 'is_active', 'is_staff', 'created_at')
    list_filter = ('role', 'is_guest', 'is_active', 'is_staff', 'created_at')
    search_fields = ('email', 'name')
    ordering = ('-created_at',)
    readonly_fields = ('id', 'created_at', 'updated_at', 'last_login')
    
    fieldsets = (
        (None, {'fields': ('email', 'password')}),
        ('Personal Info', {'fields': ('name',)}),
        ('Permissions', {'fields': ('role', 'is_active', 'is_staff', 'is_superuser', 'is_guest')}),
        ('Group Permissions', {'fields': ('groups', 'user_permissions')}),
        ('Important Dates', {'fields': ('created_at', 'updated_at', 'last_login')}),
    )
    
    add_fieldsets = (
        (None, {
            'classes': ('wide',),
            'fields': ('email', 'name', 'password1', 'password2', 'role', 'is_active', 'is_staff'),
        }),
    )


@admin.register(UserSettings)
class UserSettingsAdmin(admin.ModelAdmin):
    """Admin configuration for UserSettings model."""
    
    list_display = ('user', 'theme', 'language', 'notifications_enabled', 'updated_at')
    list_filter = ('theme', 'language', 'notifications_enabled')
    search_fields = ('user__email', 'user__name')
    readonly_fields = ('id', 'created_at', 'updated_at')
    
    fieldsets = (
        ('User', {'fields': ('user',)}),
        ('Preferences', {'fields': ('theme', 'language')}),
        ('Notifications', {'fields': ('notifications_enabled', 'email_notifications', 'push_notifications')}),
        ('Timestamps', {'fields': ('created_at', 'updated_at')}),
    )


@admin.register(ActivityLog)
class ActivityLogAdmin(admin.ModelAdmin):
    """Admin configuration for ActivityLog model."""
    
    list_display = ('action', 'user', 'ip_address', 'created_at')
    list_filter = ('action', 'created_at')
    search_fields = ('user__email', 'description', 'ip_address')
    readonly_fields = ('id', 'created_at')
    ordering = ('-created_at',)
    
    fieldsets = (
        ('Activity', {'fields': ('user', 'action', 'description')}),
        ('Request Info', {'fields': ('ip_address', 'user_agent')}),
        ('Metadata', {'fields': ('metadata',)}),
        ('Timestamp', {'fields': ('created_at',)}),
    )
