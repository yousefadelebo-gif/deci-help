"""
Models for Factors App - Factor Templates and Categories
"""

import uuid
from django.db import models


class FactorCategory(models.Model):
    """Category for grouping factor templates"""
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=100)
    description = models.TextField(blank=True)
    icon = models.CharField(max_length=50, blank=True)  # Icon name
    color = models.CharField(max_length=20, blank=True)  # Hex color
    order = models.IntegerField(default=0)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'factor_categories'
        verbose_name_plural = 'Factor Categories'
        ordering = ['order', 'name']
    
    def __str__(self):
        return self.name


class FactorTemplate(models.Model):
    """Predefined factor templates for decision making"""
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    category = models.ForeignKey(
        FactorCategory, 
        on_delete=models.CASCADE, 
        related_name='templates'
    )
    name = models.CharField(max_length=100)
    description = models.TextField(blank=True)
    icon = models.CharField(max_length=50, blank=True)
    default_weight = models.FloatField(default=0.5)  # 0.0 to 1.0
    
    # AI suggestions
    ai_suggested_for = models.JSONField(
        default=list, 
        blank=True,
        help_text='List of decision categories this factor is suggested for'
    )
    
    # Usage tracking
    usage_count = models.IntegerField(default=0)
    
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'factor_templates'
        ordering = ['-usage_count', 'name']
    
    def __str__(self):
        return f"{self.name} ({self.category.name})"


class UserFactorTemplate(models.Model):
    """Custom factor templates created by users"""
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(
        'accounts.User',
        on_delete=models.CASCADE,
        related_name='custom_factors'
    )
    category = models.ForeignKey(
        FactorCategory,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='user_templates'
    )
    name = models.CharField(max_length=100)
    description = models.TextField(blank=True)
    default_weight = models.FloatField(default=0.5)
    usage_count = models.IntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        db_table = 'user_factor_templates'
        ordering = ['-usage_count', 'name']
    
    def __str__(self):
        return f"{self.name} (Custom - {self.user.email})"
