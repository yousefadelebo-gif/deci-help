"""
Serializers for Factors App
"""

from rest_framework import serializers
from .models import FactorCategory, FactorTemplate, UserFactorTemplate


class FactorTemplateSerializer(serializers.ModelSerializer):
    """Serializer for factor templates"""
    
    category_name = serializers.CharField(source='category.name', read_only=True)
    
    class Meta:
        model = FactorTemplate
        fields = [
            'id', 'name', 'description', 'icon', 'default_weight',
            'category', 'category_name', 'ai_suggested_for', 'usage_count'
        ]


class FactorCategorySerializer(serializers.ModelSerializer):
    """Serializer for factor categories"""
    
    templates = FactorTemplateSerializer(many=True, read_only=True)
    templates_count = serializers.SerializerMethodField()
    
    class Meta:
        model = FactorCategory
        fields = [
            'id', 'name', 'description', 'icon', 'color', 
            'order', 'templates_count', 'templates'
        ]
    
    def get_templates_count(self, obj):
        return obj.templates.filter(is_active=True).count()


class FactorCategoryListSerializer(serializers.ModelSerializer):
    """Lighter serializer for listing categories"""
    
    templates_count = serializers.SerializerMethodField()
    templates = serializers.SerializerMethodField()
    
    class Meta:
        model = FactorCategory
        fields = ['id', 'name', 'description', 'icon', 'color', 'order', 'templates_count', 'templates']
    
    def get_templates_count(self, obj):
        return obj.templates.filter(is_active=True).count()

    def get_templates(self, obj):
        templates = getattr(obj, 'active_templates', None)
        if templates is None:
            templates = obj.templates.filter(is_active=True)
        return FactorTemplateSerializer(templates, many=True).data


class UserFactorTemplateSerializer(serializers.ModelSerializer):
    """Serializer for user custom factor templates"""
    
    category_name = serializers.CharField(source='category.name', read_only=True)
    
    class Meta:
        model = UserFactorTemplate
        fields = [
            'id', 'name', 'description', 'default_weight',
            'category', 'category_name', 'usage_count', 'created_at'
        ]
        read_only_fields = ['id', 'usage_count', 'created_at']


class SuggestedFactorsSerializer(serializers.Serializer):
    """Serializer for getting suggested factors for a decision category"""
    
    decision_category = serializers.CharField()
