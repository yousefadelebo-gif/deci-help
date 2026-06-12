"""
Admin Configuration for Decisions App
"""

from django.contrib import admin
from .models import Decision, DecisionOption, DecisionFactor, FactorRating, JournalEntry


class DecisionOptionInline(admin.TabularInline):
    model = DecisionOption
    extra = 0


class DecisionFactorInline(admin.TabularInline):
    model = DecisionFactor
    extra = 0


@admin.register(Decision)
class DecisionAdmin(admin.ModelAdmin):
    list_display = ['title', 'user', 'category', 'status', 'created_at', 'ai_confidence']
    list_filter = ['status', 'category', 'created_at']
    search_fields = ['title', 'description', 'user__email']
    readonly_fields = ['id', 'created_at', 'updated_at', 'analyzed_at', 'chosen_at']
    inlines = [DecisionOptionInline, DecisionFactorInline]
    
    fieldsets = (
        ('Basic Info', {
            'fields': ('id', 'user', 'title', 'description', 'category', 'status')
        }),
        ('AI Analysis', {
            'fields': ('ai_recommendation', 'ai_confidence', 'ai_explanation', 'ai_insights', 'analyzed_at'),
            'classes': ('collapse',)
        }),
        ('Decision', {
            'fields': ('chosen_option', 'chosen_at', 'deadline', 'reminder_enabled')
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )


@admin.register(DecisionOption)
class DecisionOptionAdmin(admin.ModelAdmin):
    list_display = ['name', 'decision', 'ai_score', 'order']
    list_filter = ['decision__status']
    search_fields = ['name', 'decision__title']


@admin.register(DecisionFactor)
class DecisionFactorAdmin(admin.ModelAdmin):
    list_display = ['name', 'decision', 'weight', 'is_ai_suggested']
    list_filter = ['is_ai_suggested']
    search_fields = ['name', 'decision__title']


@admin.register(FactorRating)
class FactorRatingAdmin(admin.ModelAdmin):
    list_display = ['decision_factor', 'option', 'score']
    list_filter = ['score']


@admin.register(JournalEntry)
class JournalEntryAdmin(admin.ModelAdmin):
    list_display = ['decision', 'satisfaction', 'created_at']
    list_filter = ['satisfaction', 'created_at']
    search_fields = ['decision__title', 'reflection']
