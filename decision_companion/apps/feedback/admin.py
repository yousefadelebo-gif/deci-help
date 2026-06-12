"""
Feedback Admin Configuration

Decision Companion - AI Decision Making System
"""

from django.contrib import admin
from .models import Feedback


@admin.register(Feedback)
class FeedbackAdmin(admin.ModelAdmin):
    """Admin configuration for Feedback model."""
    
    list_display = ('title', 'user', 'feedback_type', 'rating', 'is_resolved', 'created_at')
    list_filter = ('feedback_type', 'rating', 'is_resolved', 'created_at')
    search_fields = ('title', 'message', 'user__email')
    readonly_fields = ('id', 'created_at', 'updated_at')
    ordering = ('-created_at',)
    
    fieldsets = (
        ('Feedback', {'fields': ('id', 'user', 'feedback_type', 'decision')}),
        ('Content', {'fields': ('title', 'message', 'rating')}),
        ('Admin', {'fields': ('is_resolved', 'admin_response')}),
        ('Timestamps', {'fields': ('created_at', 'updated_at')}),
    )
    
    actions = ['mark_resolved', 'mark_unresolved']
    
    def mark_resolved(self, request, queryset):
        queryset.update(is_resolved=True)
    mark_resolved.short_description = "Mark selected feedback as resolved"
    
    def mark_unresolved(self, request, queryset):
        queryset.update(is_resolved=False)
    mark_unresolved.short_description = "Mark selected feedback as unresolved"
