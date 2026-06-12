"""
Feedback Models

Decision Companion - AI Decision Making System
"""

import uuid
from django.db import models
from django.conf import settings
from django.core.validators import MinValueValidator, MaxValueValidator


class Feedback(models.Model):
    """
    User feedback model.
    
    Allows users to submit feedback with ratings (1-5)
    about the application or specific features.
    """
    
    class FeedbackType(models.TextChoices):
        GENERAL = 'GENERAL', 'General Feedback'
        BUG = 'BUG', 'Bug Report'
        FEATURE = 'FEATURE', 'Feature Request'
        AI_QUALITY = 'AI_QUALITY', 'AI Quality'
        UI_UX = 'UI_UX', 'User Experience'
        OTHER = 'OTHER', 'Other'
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='feedbacks'
    )
    feedback_type = models.CharField(
        max_length=20,
        choices=FeedbackType.choices,
        default=FeedbackType.GENERAL
    )
    rating = models.IntegerField(
        validators=[MinValueValidator(1), MaxValueValidator(5)]
    )
    title = models.CharField(max_length=255)
    message = models.TextField()
    decision = models.ForeignKey(
        'decisions.Decision',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='feedbacks'
    )
    is_resolved = models.BooleanField(default=False)
    admin_response = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'feedbacks'
        verbose_name = 'Feedback'
        verbose_name_plural = 'Feedbacks'
        ordering = ['-created_at']
    
    def __str__(self):
        return f"{self.feedback_type} - {self.title} ({self.rating}/5)"
