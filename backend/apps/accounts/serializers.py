"""
Serializers for Accounts App
"""

from rest_framework import serializers
from django.contrib.auth import get_user_model
from django.contrib.auth.password_validation import validate_password
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer

User = get_user_model()


class UserSerializer(serializers.ModelSerializer):
    """User serializer for profile data"""
    
    class Meta:
        model = User
        fields = [
            'id', 'email', 'name', 'avatar', 'theme', 'language',
            'notifications_enabled', 'email_notifications',
            'is_verified', 'created_at', 'last_login_at'
        ]
        read_only_fields = ['id', 'email', 'is_verified', 'created_at', 'last_login_at']


class RegisterSerializer(serializers.ModelSerializer):
    """Serializer for user registration"""
    
    password = serializers.CharField(write_only=True, validators=[validate_password])
    password_confirm = serializers.CharField(write_only=True)
    
    class Meta:
        model = User
        fields = ['email', 'name', 'password', 'password_confirm']
    
    def validate(self, attrs):
        if attrs['password'] != attrs['password_confirm']:
            raise serializers.ValidationError({"password": "Passwords don't match."})
        return attrs
    
    def create(self, validated_data):
        validated_data.pop('password_confirm')
        user = User.objects.create_user(**validated_data)
        return user


class LoginSerializer(TokenObtainPairSerializer):
    """Custom login serializer with user data"""
    
    def validate(self, attrs):
        data = super().validate(attrs)
        
        # Add user data to response
        data['user'] = UserSerializer(self.user).data
        
        return data


class ChangePasswordSerializer(serializers.Serializer):
    """Serializer for password change"""
    
    old_password = serializers.CharField(required=True)
    new_password = serializers.CharField(required=True, validators=[validate_password])
    
    def validate_old_password(self, value):
        user = self.context['request'].user
        if not user.check_password(value):
            raise serializers.ValidationError("Old password is incorrect.")
        return value


class UpdateProfileSerializer(serializers.ModelSerializer):
    """Serializer for updating user profile"""
    
    class Meta:
        model = User
        fields = ['name', 'avatar', 'theme', 'language', 'notifications_enabled', 'email_notifications']


class UserSettingsSerializer(serializers.ModelSerializer):
    """Serializer for user settings"""
    
    class Meta:
        from .models import UserSettings
        model = UserSettings
        fields = ['default_reminder_days', 'use_ai_suggestions', 'ai_confidence_threshold', 'share_anonymous_data']
