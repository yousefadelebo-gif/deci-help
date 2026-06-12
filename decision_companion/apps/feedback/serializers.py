"""
Feedback Serializers

Decision Companion - AI Decision Making System
"""

from rest_framework import serializers
from .models import Feedback


class FeedbackSerializer(serializers.ModelSerializer):
    """Serializer for Feedback model."""
    
    user_email = serializers.CharField(source='user.email', read_only=True)
    user_name = serializers.CharField(source='user.name', read_only=True)
    decision_title = serializers.CharField(
        source='decision.title',
        read_only=True,
        allow_null=True
    )
    
    class Meta:
        model = Feedback
        fields = [
            'id', 'user', 'user_email', 'user_name', 'feedback_type',
            'rating', 'title', 'message', 'decision', 'decision_title',
            'is_resolved', 'admin_response', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'user', 'is_resolved', 'admin_response', 'created_at', 'updated_at']


class FeedbackCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating feedback."""
    
    class Meta:
        model = Feedback
        fields = ['feedback_type', 'rating', 'title', 'message', 'decision']
    
    def validate_rating(self, value):
        if not 1 <= value <= 5:
            raise serializers.ValidationError("Rating must be between 1 and 5.")
        return value


class FeedbackAdminSerializer(serializers.ModelSerializer):
    """Serializer for admin to update feedback."""
    
    class Meta:
        model = Feedback
        fields = ['is_resolved', 'admin_response']
