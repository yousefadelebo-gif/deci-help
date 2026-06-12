"""
Admin Panel Serializers

Decision Companion - AI Decision Making System
"""

from rest_framework import serializers
from apps.core.models import User, ActivityLog
from apps.decisions.models import FactorTemplate, AIParameters
from apps.feedback.models import Feedback


class AdminUserSerializer(serializers.ModelSerializer):
    """Serializer for admin user management."""
    
    decisions_count = serializers.SerializerMethodField()
    
    class Meta:
        model = User
        fields = [
            'id', 'email', 'name', 'role', 'is_guest', 'is_active',
            'is_staff', 'decisions_count', 'created_at', 'updated_at', 'last_login'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at', 'last_login']
    
    def get_decisions_count(self, obj):
        return obj.decisions.count()


class AdminUserDetailSerializer(serializers.ModelSerializer):
    """Detailed serializer for admin user view."""
    
    decisions_count = serializers.SerializerMethodField()
    feedback_count = serializers.SerializerMethodField()
    settings = serializers.SerializerMethodField()
    
    class Meta:
        model = User
        fields = [
            'id', 'email', 'name', 'role', 'is_guest', 'is_active',
            'is_staff', 'decisions_count', 'feedback_count', 'settings',
            'created_at', 'updated_at', 'last_login'
        ]
    
    def get_decisions_count(self, obj):
        return obj.decisions.count()
    
    def get_feedback_count(self, obj):
        return obj.feedbacks.count()
    
    def get_settings(self, obj):
        from apps.core.serializers import UserSettingsSerializer
        try:
            return UserSettingsSerializer(obj.settings).data
        except:
            return None


class UsageAnalyticsSerializer(serializers.Serializer):
    """Serializer for usage analytics."""
    
    total_users = serializers.IntegerField()
    active_users = serializers.IntegerField()
    guest_users = serializers.IntegerField()
    total_decisions = serializers.IntegerField()
    decisions_by_status = serializers.DictField()
    total_analyses = serializers.IntegerField()
    average_confidence = serializers.FloatField(allow_null=True)
    decisions_this_week = serializers.IntegerField()
    decisions_this_month = serializers.IntegerField()
    most_active_users = serializers.ListField()


class FeedbackAnalyticsSerializer(serializers.Serializer):
    """Serializer for feedback analytics."""
    
    total_feedback = serializers.IntegerField()
    resolved_feedback = serializers.IntegerField()
    pending_feedback = serializers.IntegerField()
    average_rating = serializers.FloatField(allow_null=True)
    feedback_by_type = serializers.DictField()
    rating_distribution = serializers.DictField()
    recent_feedback = serializers.ListField()


class AdminFactorTemplateSerializer(serializers.ModelSerializer):
    """Serializer for admin factor template management."""
    
    class Meta:
        model = FactorTemplate
        fields = [
            'id', 'key', 'name', 'description', 'default_category',
            'default_weight', 'icon', 'is_active', 'sort_order',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']
    
    def validate_key(self, value):
        """Ensure key is uppercase and unique."""
        value = value.upper()
        instance = self.instance
        if FactorTemplate.objects.filter(key=value).exclude(
            id=instance.id if instance else None
        ).exists():
            raise serializers.ValidationError(f"Factor template with key '{value}' already exists.")
        return value


class AdminAIParametersSerializer(serializers.ModelSerializer):
    """Serializer for admin AI parameters management."""
    
    typed_value = serializers.SerializerMethodField()
    
    class Meta:
        model = AIParameters
        fields = [
            'id', 'key', 'value', 'value_type', 'typed_value',
            'description', 'is_active', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'key', 'created_at', 'updated_at']
    
    def get_typed_value(self, obj):
        try:
            return obj.get_typed_value()
        except:
            return obj.value


class AdminActivityLogSerializer(serializers.ModelSerializer):
    """Serializer for admin activity logs."""
    
    user_email = serializers.CharField(source='user.email', read_only=True, allow_null=True)
    user_name = serializers.CharField(source='user.name', read_only=True, allow_null=True)
    
    class Meta:
        model = ActivityLog
        fields = [
            'id', 'user', 'user_email', 'user_name', 'action',
            'description', 'ip_address', 'user_agent', 'metadata', 'created_at'
        ]
