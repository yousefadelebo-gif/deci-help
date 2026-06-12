"""
Admin Configuration for Factors App
"""

from django.contrib import admin
from .models import FactorCategory, FactorTemplate, UserFactorTemplate


class FactorTemplateInline(admin.TabularInline):
    model = FactorTemplate
    extra = 0


@admin.register(FactorCategory)
class FactorCategoryAdmin(admin.ModelAdmin):
    list_display = ['name', 'order', 'is_active', 'created_at']
    list_filter = ['is_active']
    search_fields = ['name', 'description']
    ordering = ['order']
    inlines = [FactorTemplateInline]


@admin.register(FactorTemplate)
class FactorTemplateAdmin(admin.ModelAdmin):
    list_display = ['name', 'category', 'default_weight', 'usage_count', 'is_active']
    list_filter = ['category', 'is_active']
    search_fields = ['name', 'description']
    ordering = ['-usage_count']


@admin.register(UserFactorTemplate)
class UserFactorTemplateAdmin(admin.ModelAdmin):
    list_display = ['name', 'user', 'category', 'usage_count', 'created_at']
    list_filter = ['category']
    search_fields = ['name', 'user__email']
