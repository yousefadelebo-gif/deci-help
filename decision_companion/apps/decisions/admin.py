"""
Decision Admin Configuration

Decision Companion - AI Decision Making System
"""

from django.contrib import admin
from .models import (
    FactorTemplate, AIParameters, Decision, DecisionOption,
    Factor, FactorScore, Result
)


@admin.register(FactorTemplate)
class FactorTemplateAdmin(admin.ModelAdmin):
    """Admin configuration for FactorTemplate model."""
    
    list_display = ('key', 'name', 'default_category', 'default_weight', 'is_active', 'sort_order')
    list_filter = ('default_category', 'is_active')
    search_fields = ('key', 'name', 'description')
    ordering = ('sort_order', 'name')
    readonly_fields = ('id', 'created_at', 'updated_at')
    
    fieldsets = (
        ('Identification', {'fields': ('id', 'key', 'name', 'description')}),
        ('Defaults', {'fields': ('default_category', 'default_weight', 'icon')}),
        ('Settings', {'fields': ('is_active', 'sort_order')}),
        ('Timestamps', {'fields': ('created_at', 'updated_at')}),
    )


@admin.register(AIParameters)
class AIParametersAdmin(admin.ModelAdmin):
    """Admin configuration for AIParameters model."""
    
    list_display = ('key', 'value', 'value_type', 'is_active', 'updated_at')
    list_filter = ('value_type', 'is_active')
    search_fields = ('key', 'description')
    readonly_fields = ('id', 'created_at', 'updated_at')
    
    fieldsets = (
        ('Parameter', {'fields': ('id', 'key', 'value', 'value_type')}),
        ('Info', {'fields': ('description', 'is_active')}),
        ('Timestamps', {'fields': ('created_at', 'updated_at')}),
    )


class DecisionOptionInline(admin.TabularInline):
    """Inline admin for DecisionOption."""
    model = DecisionOption
    extra = 0
    readonly_fields = ('id', 'created_at')


class FactorInline(admin.TabularInline):
    """Inline admin for Factor."""
    model = Factor
    extra = 0
    readonly_fields = ('id', 'created_at')


@admin.register(Decision)
class DecisionAdmin(admin.ModelAdmin):
    """Admin configuration for Decision model."""
    
    list_display = ('title', 'user', 'status', 'confidence_level', 'satisfaction_rating', 'created_at')
    list_filter = ('status', 'created_at', 'analyzed_at')
    search_fields = ('title', 'description', 'user__email')
    readonly_fields = ('id', 'created_at', 'updated_at', 'analyzed_at')
    ordering = ('-created_at',)
    inlines = [DecisionOptionInline, FactorInline]
    
    fieldsets = (
        ('Decision', {'fields': ('id', 'user', 'title', 'description')}),
        ('Status', {'fields': ('status', 'chosen_option', 'confidence_level')}),
        ('Journal', {'fields': ('satisfaction_rating', 'reflection_notes')}),
        ('Timestamps', {'fields': ('created_at', 'updated_at', 'analyzed_at')}),
    )


@admin.register(DecisionOption)
class DecisionOptionAdmin(admin.ModelAdmin):
    """Admin configuration for DecisionOption model."""
    
    list_display = ('name', 'decision', 'sort_order', 'created_at')
    list_filter = ('created_at',)
    search_fields = ('name', 'description', 'decision__title')
    readonly_fields = ('id', 'created_at', 'updated_at')


class FactorScoreInline(admin.TabularInline):
    """Inline admin for FactorScore."""
    model = FactorScore
    extra = 0
    readonly_fields = ('id', 'created_at')


@admin.register(Factor)
class FactorAdmin(admin.ModelAdmin):
    """Admin configuration for Factor model."""
    
    list_display = ('name', 'decision', 'category', 'weight', 'is_from_template', 'created_at')
    list_filter = ('category', 'is_from_template', 'created_at')
    search_fields = ('name', 'description', 'decision__title')
    readonly_fields = ('id', 'created_at', 'updated_at')
    inlines = [FactorScoreInline]


@admin.register(FactorScore)
class FactorScoreAdmin(admin.ModelAdmin):
    """Admin configuration for FactorScore model."""
    
    list_display = ('factor', 'option', 'score', 'created_at')
    list_filter = ('score', 'created_at')
    search_fields = ('factor__name', 'option__name')
    readonly_fields = ('id', 'created_at', 'updated_at')


@admin.register(Result)
class ResultAdmin(admin.ModelAdmin):
    """Admin configuration for Result model."""
    
    list_display = ('decision', 'recommended_option', 'confidence_level', 'created_at')
    list_filter = ('confidence_level', 'created_at')
    search_fields = ('decision__title', 'explanation')
    readonly_fields = ('id', 'created_at', 'updated_at')
    
    fieldsets = (
        ('Result', {'fields': ('id', 'decision', 'recommended_option')}),
        ('Analysis', {'fields': ('confidence_level', 'explanation')}),
        ('Breakdown', {'fields': ('scoring_breakdown',)}),
        ('Timestamps', {'fields': ('created_at', 'updated_at')}),
    )
