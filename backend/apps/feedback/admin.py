"""
Admin Configuration for Feedback App
"""

from django.contrib import admin
from .models import UserFeedback, AppRating, AIFeedback


@admin.register(UserFeedback)
class UserFeedbackAdmin(admin.ModelAdmin):
    list_display = ['title', 'user', 'category', 'status', 'priority', 'created_at']
    list_filter = ['category', 'status', 'priority', 'created_at']
    search_fields = ['title', 'description', 'user__email']
    readonly_fields = ['id', 'created_at', 'updated_at']
    
    fieldsets = (
        ('Feedback Info', {
            'fields': ('id', 'user', 'category', 'title', 'description', 'rating')
        }),
        ('Status', {
            'fields': ('status', 'priority', 'admin_notes', 'resolved_at')
        }),
        ('Metadata', {
            'fields': ('attachment_url', 'app_version', 'device_info', 'created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )


@admin.register(AppRating)
class AppRatingAdmin(admin.ModelAdmin):
    list_display = ['user', 'rating', 'created_at']
    list_filter = ['rating', 'created_at']
    search_fields = ['user__email', 'review']


@admin.register(AIFeedback)
class AIFeedbackAdmin(admin.ModelAdmin):
    list_display = ['decision', 'user', 'was_helpful', 'followed_recommendation', 'created_at']
    list_filter = ['was_helpful', 'followed_recommendation', 'created_at']
    search_fields = ['decision__title', 'user__email', 'feedback_text']
