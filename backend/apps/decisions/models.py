"""
Decision Models for Decision Companion
"""

from django.db import models
from django.conf import settings
import uuid


class Decision(models.Model):
    """Main Decision Model"""
    
    STATUS_CHOICES = [
        ('draft', 'Draft'),
        ('in_progress', 'In Progress'),
        ('analyzing', 'Analyzing'),
        ('completed', 'Completed'),
        ('archived', 'Archived'),
    ]
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='decisions')
    
    title = models.CharField(max_length=255)
    description = models.TextField(blank=True)
    category = models.CharField(max_length=100, blank=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='draft')
    
    # AI Analysis Results
    ai_recommendation = models.ForeignKey(
        'DecisionOption', on_delete=models.SET_NULL, 
        null=True, blank=True, related_name='recommended_for'
    )
    ai_confidence = models.FloatField(null=True, blank=True)  # 0-100
    ai_explanation = models.TextField(blank=True)
    ai_insights = models.JSONField(default=list, blank=True)
    analyzed_at = models.DateTimeField(null=True, blank=True)
    
    # User's Final Choice
    chosen_option = models.ForeignKey(
        'DecisionOption', on_delete=models.SET_NULL,
        null=True, blank=True, related_name='chosen_for'
    )
    chosen_at = models.DateTimeField(null=True, blank=True)
    
    # Settings
    deadline = models.DateTimeField(null=True, blank=True)
    reminder_enabled = models.BooleanField(default=False)
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'decisions'
        ordering = ['-created_at']
    
    def __str__(self):
        return f"{self.title} ({self.user.email})"


class DecisionOption(models.Model):
    """Options for a Decision"""
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    decision = models.ForeignKey(Decision, on_delete=models.CASCADE, related_name='options')
    
    name = models.CharField(max_length=255)
    description = models.TextField(blank=True)
    pros = models.JSONField(default=list, blank=True)  # List of strings
    cons = models.JSONField(default=list, blank=True)  # List of strings
    
    # AI Score
    ai_score = models.FloatField(null=True, blank=True)  # 0-100
    
    order = models.PositiveIntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        db_table = 'decision_options'
        ordering = ['order', 'created_at']
    
    def __str__(self):
        return f"{self.name} - {self.decision.title}"


class DecisionFactor(models.Model):
    """Factors considered for a Decision"""

    FACTOR_TYPE_CHOICES = [
        ('pro', 'Pro'),
        ('con', 'Con'),
    ]
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    decision = models.ForeignKey(Decision, on_delete=models.CASCADE, related_name='decision_factors')
    factor_template = models.ForeignKey(
        'factors.FactorTemplate', on_delete=models.SET_NULL, 
        null=True, blank=True
    )
    
    name = models.CharField(max_length=255)
    weight = models.FloatField(default=0.5)  # 0-1
    factor_type = models.CharField(max_length=10, choices=FACTOR_TYPE_CHOICES, default='pro')
    is_ai_suggested = models.BooleanField(default=False)
    
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        db_table = 'decision_factors'
        ordering = ['-weight', 'name']
    
    def __str__(self):
        return f"{self.name} ({self.weight})"


class FactorRating(models.Model):
    """Rating of an option for a specific factor"""
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    decision_factor = models.ForeignKey(DecisionFactor, on_delete=models.CASCADE, related_name='ratings')
    option = models.ForeignKey(DecisionOption, on_delete=models.CASCADE, related_name='factor_ratings')
    
    score = models.FloatField()  # 0-10
    notes = models.TextField(blank=True)
    
    class Meta:
        db_table = 'factor_ratings'
        unique_together = ['decision_factor', 'option']
    
    def __str__(self):
        return f"{self.option.name} - {self.decision_factor.name}: {self.score}"


class JournalEntry(models.Model):
    """Journal entry for reflecting on past decisions"""
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    decision = models.OneToOneField(Decision, on_delete=models.CASCADE, related_name='journal_entry')
    
    reflection = models.TextField(blank=True)
    satisfaction = models.FloatField(null=True, blank=True)  # 1-5
    outcome_notes = models.TextField(blank=True)
    lessons_learned = models.TextField(blank=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'journal_entries'
        ordering = ['-created_at']
    
    def __str__(self):
        return f"Journal: {self.decision.title}"
