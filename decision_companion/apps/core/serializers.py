"""
Core Serializers - User, Authentication, Settings

Decision Companion - AI Decision Making System
"""

from rest_framework import serializers
from rest_framework_simplejwt.tokens import RefreshToken
from django.contrib.auth import authenticate
from django.contrib.auth.password_validation import validate_password
from .models import User, UserSettings, ActivityLog


class UserSerializer(serializers.ModelSerializer):
    """Serializer for User model."""
    
    class Meta:
        model = User
        fields = ['id', 'email', 'name', 'role', 'is_guest', 'created_at', 'updated_at']
        read_only_fields = ['id', 'role', 'is_guest', 'created_at', 'updated_at']


class UserDetailSerializer(serializers.ModelSerializer):
    """Detailed serializer for User with settings."""
    
    settings = serializers.SerializerMethodField()
    
    class Meta:
        model = User
        fields = ['id', 'email', 'name', 'role', 'is_guest', 'created_at', 'updated_at', 'settings']
        read_only_fields = ['id', 'email', 'role', 'is_guest', 'created_at', 'updated_at']
    
    def get_settings(self, obj):
        """Get user settings if they exist."""
        try:
            return UserSettingsSerializer(obj.settings).data
        except UserSettings.DoesNotExist:
            return None


class RegisterSerializer(serializers.Serializer):
    """Serializer for user registration."""
    
    email = serializers.EmailField(required=True)
    password = serializers.CharField(write_only=True, required=True, validators=[validate_password])
    password_confirm = serializers.CharField(write_only=True, required=True)
    name = serializers.CharField(required=True, max_length=255)
    
    def validate_email(self, value):
        """Check if email already exists."""
        if User.objects.filter(email=value.lower()).exists():
            raise serializers.ValidationError("A user with this email already exists.")
        return value.lower()
    
    def validate(self, attrs):
        """Validate password confirmation."""
        if attrs['password'] != attrs['password_confirm']:
            raise serializers.ValidationError({"password_confirm": "Passwords don't match."})
        return attrs
    
    def create(self, validated_data):
        """Create new user."""
        validated_data.pop('password_confirm')
        user = User.objects.create_user(
            email=validated_data['email'],
            password=validated_data['password'],
            name=validated_data['name']
        )
        # Create default settings for user
        UserSettings.objects.create(user=user)
        return user


class LoginSerializer(serializers.Serializer):
    """Serializer for user login."""
    
    email = serializers.EmailField(required=True)
    password = serializers.CharField(write_only=True, required=True)
    
    def validate(self, attrs):
        """Authenticate user."""
        email = attrs.get('email', '').lower()
        password = attrs.get('password', '')
        
        user = authenticate(username=email, password=password)
        
        if not user:
            raise serializers.ValidationError("Invalid email or password.")
        
        if not user.is_active:
            raise serializers.ValidationError("User account is disabled.")
        
        attrs['user'] = user
        return attrs


class TokenSerializer(serializers.Serializer):
    """Serializer for JWT token response."""
    
    access_token = serializers.CharField()
    refresh_token = serializers.CharField()
    user = UserSerializer()
    
    @staticmethod
    def get_tokens_for_user(user):
        """Generate JWT tokens for user."""
        refresh = RefreshToken.for_user(user)
        return {
            'access_token': str(refresh.access_token),
            'refresh_token': str(refresh),
            'user': UserSerializer(user).data
        }


class LogoutSerializer(serializers.Serializer):
    """Serializer for logout - blacklist refresh token."""
    
    refresh_token = serializers.CharField(required=True)
    
    def validate(self, attrs):
        """Validate and blacklist the refresh token."""
        self.token = attrs['refresh_token']
        return attrs
    
    def save(self, **kwargs):
        """Blacklist the refresh token."""
        try:
            token = RefreshToken(self.token)
            token.blacklist()
        except Exception as e:
            raise serializers.ValidationError(str(e))


class UserSettingsSerializer(serializers.ModelSerializer):
    """Serializer for UserSettings model."""
    
    class Meta:
        model = UserSettings
        fields = [
            'id', 'theme', 'notifications_enabled', 'email_notifications',
            'push_notifications', 'language', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']


class UserProfileUpdateSerializer(serializers.ModelSerializer):
    """Serializer for updating user profile."""
    
    class Meta:
        model = User
        fields = ['name']


class ChangePasswordSerializer(serializers.Serializer):
    """Serializer for changing password."""
    
    old_password = serializers.CharField(required=True)
    new_password = serializers.CharField(required=True, validators=[validate_password])
    new_password_confirm = serializers.CharField(required=True)
    
    def validate_old_password(self, value):
        """Validate old password is correct."""
        user = self.context['request'].user
        if not user.check_password(value):
            raise serializers.ValidationError("Old password is incorrect.")
        return value
    
    def validate(self, attrs):
        """Validate new password confirmation."""
        if attrs['new_password'] != attrs['new_password_confirm']:
            raise serializers.ValidationError({"new_password_confirm": "New passwords don't match."})
        return attrs


class UserStatsSerializer(serializers.Serializer):
    """Serializer for user statistics."""
    
    total_decisions = serializers.IntegerField()
    analyzed_decisions = serializers.IntegerField()
    archived_decisions = serializers.IntegerField()
    draft_decisions = serializers.IntegerField()
    average_satisfaction = serializers.FloatField(allow_null=True)
    total_feedback_submitted = serializers.IntegerField()
    member_since = serializers.DateTimeField()


class ActivityLogSerializer(serializers.ModelSerializer):
    """Serializer for ActivityLog model."""
    
    user_email = serializers.CharField(source='user.email', read_only=True, allow_null=True)
    user_name = serializers.CharField(source='user.name', read_only=True, allow_null=True)
    
    class Meta:
        model = ActivityLog
        fields = [
            'id', 'user', 'user_email', 'user_name', 'action',
            'description', 'ip_address', 'user_agent', 'metadata', 'created_at'
        ]
        read_only_fields = ['id', 'created_at']
