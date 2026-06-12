"""
Decision Models

Decision Companion - AI Decision Making System

Models:
- FactorTemplate: Predefined factor templates (admin managed)
- AIParameters: AI configuration parameters
- Decision: Main decision entity
- DecisionOption: Options for each decision
- Factor: Factors (PRO/CON) for evaluating options
- FactorScore: Score for each factor per option
- Result: AI analysis result for decision
"""

import uuid
from django.db import models
from django.conf import settings
from django.core.validators import MinValueValidator, MaxValueValidator


class FactorTemplate(models.Model):
    """
    Predefined factor templates managed by admin.
    
    Users can create factors from these templates for quick setup.
    Examples: PRICE, QUALITY, TIME, RISK, etc.
    """
    
    class Category(models.TextChoices):
        PRO = 'PRO', 'Pro'
        CON = 'CON', 'Con'
        NEUTRAL = 'NEUTRAL', 'Neutral'
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    key = models.CharField(max_length=50, unique=True)  # e.g., 'PRICE', 'QUALITY'
    name = models.CharField(max_length=100)
    description = models.TextField(blank=True)
    default_category = models.CharField(
        max_length=10,
        choices=Category.choices,
        default=Category.NEUTRAL
    )
    default_weight = models.IntegerField(
        default=5,
        validators=[MinValueValidator(1), MaxValueValidator(10)]
    )
    icon = models.CharField(max_length=50, blank=True)  # Icon name/code
    is_active = models.BooleanField(default=True)
    sort_order = models.IntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'factor_templates'
        verbose_name = 'Factor Template'
        verbose_name_plural = 'Factor Templates'
        ordering = ['sort_order', 'name']
    
    def __str__(self):
        return f"{self.name} ({self.key})"


class AIParameters(models.Model):
    """
    AI configuration parameters.
    
    Admin-managed settings for AI analysis behavior.
    """
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    key = models.CharField(max_length=50, unique=True)
    value = models.TextField()
    value_type = models.CharField(max_length=20, default='string')  # string, int, float, bool, json
    description = models.TextField(blank=True)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'ai_parameters'
        verbose_name = 'AI Parameter'
        verbose_name_plural = 'AI Parameters'
    
    def __str__(self):
        return f"{self.key}: {self.value}"
    
    def get_typed_value(self):
        """Return value converted to its specified type."""
        if self.value_type == 'int':
            return int(self.value)
        elif self.value_type == 'float':
            return float(self.value)
        elif self.value_type == 'bool':
            return self.value.lower() in ('true', '1', 'yes')
        elif self.value_type == 'json':
            import json
            return json.loads(self.value)
        return self.value


class Decision(models.Model):
    """
    Main Decision model.
    
    Represents a decision that a user is trying to make,
    with options, factors, and AI analysis.
    """
    
    class Status(models.TextChoices):
        DRAFT = 'DRAFT', 'Draft'
        ANALYZED = 'ANALYZED', 'Analyzed'
        ARCHIVED = 'ARCHIVED', 'Archived'
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='decisions'
    )
    title = models.CharField(max_length=255)
    description = models.TextField(blank=True)
    status = models.CharField(
        max_length=10,
        choices=Status.choices,
        default=Status.DRAFT
    )
    chosen_option = models.ForeignKey(
        'DecisionOption',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='chosen_for_decisions'
    )
    confidence_level = models.FloatField(
        null=True,
        blank=True,
        validators=[MinValueValidator(0), MaxValueValidator(100)]
    )
    satisfaction_rating = models.IntegerField(
        null=True,
        blank=True,
        validators=[MinValueValidator(1), MaxValueValidator(5)]
    )
    reflection_notes = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    analyzed_at = models.DateTimeField(null=True, blank=True)
    
    class Meta:
        db_table = 'decisions'
        verbose_name = 'Decision'
        verbose_name_plural = 'Decisions'
        ordering = ['-created_at']
    
    def __str__(self):
        return f"{self.title} ({self.user.email})"


class DecisionOption(models.Model):
    """
    Option for a decision.
    
    Each decision can have multiple options to choose from.
    """
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    decision = models.ForeignKey(
        Decision,
        on_delete=models.CASCADE,
        related_name='options'
    )
    name = models.CharField(max_length=255)
    description = models.TextField(blank=True)
    sort_order = models.IntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'decision_options'
        verbose_name = 'Decision Option'
        verbose_name_plural = 'Decision Options'
        ordering = ['sort_order', 'created_at']
    
    def __str__(self):
        return f"{self.name} - {self.decision.title}"


class Factor(models.Model):
    """
    Factor for evaluating decision options.
    
    Can be PRO or CON, with a weight indicating importance.
    Can be created from template or custom.
    """
    
    class Category(models.TextChoices):
        PRO = 'PRO', 'Pro'
        CON = 'CON', 'Con'
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    decision = models.ForeignKey(
        Decision,
        on_delete=models.CASCADE,
        related_name='factors'
    )
    name = models.CharField(max_length=255)
    description = models.TextField(blank=True)
    category = models.CharField(max_length=5, choices=Category.choices)
    weight = models.IntegerField(
        default=5,
        validators=[MinValueValidator(1), MaxValueValidator(10)]
    )
    is_from_template = models.BooleanField(default=False)
    template_key = models.CharField(max_length=50, blank=True)
    sort_order = models.IntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'factors'
        verbose_name = 'Factor'
        verbose_name_plural = 'Factors'
        ordering = ['category', 'sort_order', 'created_at']
    
    def __str__(self):
        return f"{self.name} ({self.category}) - {self.decision.title}"


class FactorScore(models.Model):
    """
    Score for a factor applied to an option.
    
    Links a factor to an option with a score (1-10).
    """
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    factor = models.ForeignKey(
        Factor,
        on_delete=models.CASCADE,
        related_name='scores'
    )
    option = models.ForeignKey(
        DecisionOption,
        on_delete=models.CASCADE,
        related_name='factor_scores'
    )
    score = models.IntegerField(
        validators=[MinValueValidator(1), MaxValueValidator(10)]
    )
    notes = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'factor_scores'
        verbose_name = 'Factor Score'
        verbose_name_plural = 'Factor Scores'
        unique_together = ['factor', 'option']
    
    def __str__(self):
        return f"{self.factor.name} - {self.option.name}: {self.score}"


class Result(models.Model):
    """
    AI analysis result for a decision.
    
    Contains the recommended option, confidence level,
    explanation, and detailed scoring breakdown.
    """
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    decision = models.OneToOneField(
        Decision,
        on_delete=models.CASCADE,
        related_name='result'
    )
    recommended_option = models.ForeignKey(
        DecisionOption,
        on_delete=models.SET_NULL,
        null=True,
        related_name='recommended_in_results'
    )
    confidence_level = models.FloatField(
        validators=[MinValueValidator(0), MaxValueValidator(100)]
    )
    explanation = models.TextField()
    scoring_breakdown = models.JSONField(default=dict)
    # Structure: {
    #   "options": [
    #     {
    #       "option_id": "uuid",
    #       "option_name": "Option A",
    #       "total_score": 85.5,
    #       "weighted_score": 72.3,
    #       "factors": [
    #         {"factor_id": "uuid", "name": "Price", "score": 8, "weight": 7, "weighted": 56}
    #       ]
    #     }
    #   ],
    #   "analysis_method": "weighted_average",
    #   "metadata": {...}
    # }
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'results'
        verbose_name = 'Result'
        verbose_name_plural = 'Results'
    
    def __str__(self):
        return f"Result for {self.decision.title}"
