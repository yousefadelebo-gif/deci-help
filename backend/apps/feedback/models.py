"""
Models for Feedback App
"""

import uuid
from django.db import models


class UserFeedback(models.Model):
    """User feedback and suggestions"""
    
    CATEGORY_CHOICES = [
        ('bug', 'Bug Report'),
        ('feature', 'Feature Request'),
        ('improvement', 'Improvement'),
        ('question', 'Question'),
        ('other', 'Other'),
    ]
    
    STATUS_CHOICES = [
        ('new', 'New'),
        ('reviewed', 'Reviewed'),
        ('in_progress', 'In Progress'),
        ('resolved', 'Resolved'),
        ('closed', 'Closed'),
    ]
    
    PRIORITY_CHOICES = [
        ('low', 'Low'),
        ('medium', 'Medium'),
        ('high', 'High'),
        ('critical', 'Critical'),
    ]
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(
        'accounts.User',
        on_delete=models.CASCADE,
        related_name='feedbacks'
    )
    
    # Feedback content
    category = models.CharField(max_length=20, choices=CATEGORY_CHOICES, default='other')
    title = models.CharField(max_length=200)
    description = models.TextField()
    
    # Optional screenshot or attachment reference
    attachment_url = models.URLField(blank=True)
    
    # Rating
    rating = models.IntegerField(null=True, blank=True)  # 1-5 stars
    
    # Admin fields
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='new')
    priority = models.CharField(max_length=20, choices=PRIORITY_CHOICES, default='medium')
    admin_notes = models.TextField(blank=True)
    resolved_at = models.DateTimeField(null=True, blank=True)
    
    # Metadata
    app_version = models.CharField(max_length=20, blank=True)
    device_info = models.JSONField(default=dict, blank=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'user_feedback'
        ordering = ['-created_at']
    
    def __str__(self):
        return f"{self.title} ({self.category}) - {self.user.email}"


class AppRating(models.Model):
    """App rating and review"""
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.OneToOneField(
        'accounts.User',
        on_delete=models.CASCADE,
        related_name='app_rating'
    )
    rating = models.IntegerField()  # 1-5 stars
    review = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'app_ratings'
    
    def __str__(self):
        return f"{self.user.email} - {self.rating} stars"


class AIFeedback(models.Model):
    """Feedback on AI recommendations"""
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(
        'accounts.User',
        on_delete=models.CASCADE,
        related_name='ai_feedbacks'
    )
    decision = models.ForeignKey(
        'decisions.Decision',
        on_delete=models.CASCADE,
        related_name='ai_feedbacks'
    )
    
    # Was the AI recommendation helpful?
    was_helpful = models.BooleanField()
    followed_recommendation = models.BooleanField(null=True, blank=True)
    
    # Detailed feedback
    feedback_text = models.TextField(blank=True)
    
    # What they didn't like
    issues = models.JSONField(default=list, blank=True)  # e.g., ['inaccurate', 'irrelevant', 'unclear']
    
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        db_table = 'ai_feedback'
        ordering = ['-created_at']
    
    def __str__(self):
        helpful = "Helpful" if self.was_helpful else "Not Helpful"
        return f"AI Feedback: {helpful} - {self.decision.title}"
