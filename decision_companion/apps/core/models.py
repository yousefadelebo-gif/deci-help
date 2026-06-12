"""
Core Models - User and UserSettings

Decision Companion - AI Decision Making System
"""

import uuid
from django.contrib.auth.models import AbstractBaseUser, BaseUserManager, PermissionsMixin
from django.db import models
from django.utils import timezone


class UserManager(BaseUserManager):
    """Custom user manager for User model."""
    
    def create_user(self, email, password=None, **extra_fields):
        """Create and return a regular user."""
        if not email:
            raise ValueError('Users must have an email address')
        
        email = self.normalize_email(email)
        user = self.model(email=email, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user
    
    def create_superuser(self, email, password=None, **extra_fields):
        """Create and return a superuser."""
        extra_fields.setdefault('is_staff', True)
        extra_fields.setdefault('is_superuser', True)
        extra_fields.setdefault('role', User.Role.ADMIN)
        
        if extra_fields.get('is_staff') is not True:
            raise ValueError('Superuser must have is_staff=True.')
        if extra_fields.get('is_superuser') is not True:
            raise ValueError('Superuser must have is_superuser=True.')
        
        return self.create_user(email, password, **extra_fields)
    
    def create_guest_user(self):
        """Create and return a guest user."""
        guest_email = f"guest_{uuid.uuid4().hex[:8]}@guest.local"
        user = self.model(
            email=guest_email,
            name=f"Guest User",
            is_guest=True,
            role=User.Role.USER
        )
        user.set_unusable_password()
        user.save(using=self._db)
        return user


class User(AbstractBaseUser, PermissionsMixin):
    """
    Custom User model for Decision Companion.
    
    Attributes:
        id: UUID primary key
        email: Unique email address (used as username)
        name: User's display name
        role: USER or ADMIN
        is_guest: Whether this is a guest account
        is_active: Whether the user account is active
        is_staff: Whether user can access admin site
        created_at: Account creation timestamp
        updated_at: Last update timestamp
    """
    
    class Role(models.TextChoices):
        USER = 'USER', 'User'
        ADMIN = 'ADMIN', 'Admin'
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    email = models.EmailField(unique=True, max_length=255)
    name = models.CharField(max_length=255, blank=True)
    role = models.CharField(max_length=10, choices=Role.choices, default=Role.USER)
    is_guest = models.BooleanField(default=False)
    is_active = models.BooleanField(default=True)
    is_staff = models.BooleanField(default=False)
    created_at = models.DateTimeField(default=timezone.now)
    updated_at = models.DateTimeField(auto_now=True)
    
    objects = UserManager()
    
    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['name']
    
    class Meta:
        db_table = 'users'
        verbose_name = 'User'
        verbose_name_plural = 'Users'
        ordering = ['-created_at']
    
    def __str__(self):
        return f"{self.name} ({self.email})"
    
    @property
    def is_admin(self):
        """Check if user has admin role."""
        return self.role == self.Role.ADMIN


class UserSettings(models.Model):
    """
    User application settings.
    
    Stores user preferences like theme, notifications, and language.
    """
    
    class Theme(models.TextChoices):
        LIGHT = 'light', 'Light'
        DARK = 'dark', 'Dark'
        SYSTEM = 'system', 'System'
    
    class Language(models.TextChoices):
        EN = 'en', 'English'
        ES = 'es', 'Spanish'
        FR = 'fr', 'French'
        DE = 'de', 'German'
        AR = 'ar', 'Arabic'
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.OneToOneField(
        User,
        on_delete=models.CASCADE,
        related_name='settings'
    )
    theme = models.CharField(max_length=10, choices=Theme.choices, default=Theme.SYSTEM)
    notifications_enabled = models.BooleanField(default=True)
    email_notifications = models.BooleanField(default=True)
    push_notifications = models.BooleanField(default=True)
    language = models.CharField(max_length=5, choices=Language.choices, default=Language.EN)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'user_settings'
        verbose_name = 'User Settings'
        verbose_name_plural = 'User Settings'
    
    def __str__(self):
        return f"Settings for {self.user.email}"


class ActivityLog(models.Model):
    """
    Activity log for tracking user actions.
    
    Used for admin analytics and debugging.
    """
    
    class ActionType(models.TextChoices):
        LOGIN = 'LOGIN', 'Login'
        LOGOUT = 'LOGOUT', 'Logout'
        REGISTER = 'REGISTER', 'Register'
        CREATE_DECISION = 'CREATE_DECISION', 'Create Decision'
        UPDATE_DECISION = 'UPDATE_DECISION', 'Update Decision'
        DELETE_DECISION = 'DELETE_DECISION', 'Delete Decision'
        AI_ANALYZE = 'AI_ANALYZE', 'AI Analysis'
        AI_SUGGESTIONS = 'AI_SUGGESTIONS', 'AI Suggestions'
        SUBMIT_FEEDBACK = 'SUBMIT_FEEDBACK', 'Submit Feedback'
        UPDATE_PROFILE = 'UPDATE_PROFILE', 'Update Profile'
        UPDATE_SETTINGS = 'UPDATE_SETTINGS', 'Update Settings'
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='activity_logs'
    )
    action = models.CharField(max_length=50, choices=ActionType.choices)
    description = models.TextField(blank=True)
    ip_address = models.GenericIPAddressField(null=True, blank=True)
    user_agent = models.TextField(blank=True)
    metadata = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        db_table = 'activity_logs'
        verbose_name = 'Activity Log'
        verbose_name_plural = 'Activity Logs'
        ordering = ['-created_at']
    
    def __str__(self):
        return f"{self.action} by {self.user} at {self.created_at}"
