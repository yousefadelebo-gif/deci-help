"""
Serializers for Feedback App
"""

from rest_framework import serializers
from .models import UserFeedback, AppRating, AIFeedback


class UserFeedbackSerializer(serializers.ModelSerializer):
    """Serializer for user feedback"""
    
    class Meta:
        model = UserFeedback
        fields = [
            'id', 'category', 'title', 'description', 'attachment_url',
            'rating', 'status', 'app_version', 'device_info',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'status', 'created_at', 'updated_at']


class UserFeedbackAdminSerializer(serializers.ModelSerializer):
    """Admin serializer for user feedback"""
    
    user_email = serializers.CharField(source='user.email', read_only=True)
    
    class Meta:
        model = UserFeedback
        fields = [
            'id', 'user', 'user_email', 'category', 'title', 'description',
            'attachment_url', 'rating', 'status', 'priority', 'admin_notes',
            'resolved_at', 'app_version', 'device_info',
            'created_at', 'updated_at'
        ]


class AppRatingSerializer(serializers.ModelSerializer):
    """Serializer for app rating"""
    
    class Meta:
        model = AppRating
        fields = ['id', 'rating', 'review', 'created_at', 'updated_at']
        read_only_fields = ['id', 'created_at', 'updated_at']


class AIFeedbackSerializer(serializers.ModelSerializer):
    """Serializer for AI feedback"""
    
    decision_title = serializers.CharField(source='decision.title', read_only=True)
    
    class Meta:
        model = AIFeedback
        fields = [
            'id', 'decision', 'decision_title', 'was_helpful',
            'followed_recommendation', 'feedback_text', 'issues', 'created_at'
        ]
        read_only_fields = ['id', 'created_at']


class CreateAIFeedbackSerializer(serializers.ModelSerializer):
    """Serializer for creating AI feedback"""
    
    class Meta:
        model = AIFeedback
        fields = ['decision', 'was_helpful', 'followed_recommendation', 'feedback_text', 'issues']


class FeedbackStatsSerializer(serializers.Serializer):
    """Serializer for feedback statistics"""
    
    total_feedback = serializers.IntegerField()
    by_category = serializers.DictField()
    by_status = serializers.DictField()
    average_rating = serializers.FloatField()
    ai_helpfulness_rate = serializers.FloatField()
