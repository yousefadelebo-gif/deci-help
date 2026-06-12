"""
Decision Serializers

Decision Companion - AI Decision Making System
"""

from rest_framework import serializers
from .models import (
    FactorTemplate, AIParameters, Decision, DecisionOption,
    Factor, FactorScore, Result
)


class FactorTemplateSerializer(serializers.ModelSerializer):
    """Serializer for FactorTemplate model."""
    
    class Meta:
        model = FactorTemplate
        fields = [
            'id', 'key', 'name', 'description', 'default_category',
            'default_weight', 'icon', 'is_active', 'sort_order',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']


class AIParametersSerializer(serializers.ModelSerializer):
    """Serializer for AIParameters model."""
    
    typed_value = serializers.SerializerMethodField()
    
    class Meta:
        model = AIParameters
        fields = [
            'id', 'key', 'value', 'value_type', 'typed_value',
            'description', 'is_active', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']
    
    def get_typed_value(self, obj):
        """Get the value converted to its type."""
        try:
            return obj.get_typed_value()
        except Exception:
            return obj.value


class FactorScoreSerializer(serializers.ModelSerializer):
    """Serializer for FactorScore model."""
    
    factor_name = serializers.CharField(source='factor.name', read_only=True)
    option_name = serializers.CharField(source='option.name', read_only=True)
    
    class Meta:
        model = FactorScore
        fields = [
            'id', 'factor', 'factor_name', 'option', 'option_name',
            'score', 'notes', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']


class FactorSerializer(serializers.ModelSerializer):
    """Serializer for Factor model."""
    
    scores = FactorScoreSerializer(many=True, read_only=True)
    
    class Meta:
        model = Factor
        fields = [
            'id', 'decision', 'name', 'description', 'category',
            'weight', 'is_from_template', 'template_key', 'sort_order',
            'scores', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'decision', 'is_from_template', 'template_key', 'created_at', 'updated_at']


class FactorCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating a Factor."""
    
    class Meta:
        model = Factor
        fields = ['name', 'description', 'category', 'weight', 'sort_order']
    
    def validate_weight(self, value):
        if not 1 <= value <= 10:
            raise serializers.ValidationError("Weight must be between 1 and 10.")
        return value


class FactorFromTemplateSerializer(serializers.Serializer):
    """Serializer for creating factor from template."""
    
    template_key = serializers.CharField()
    category = serializers.ChoiceField(choices=Factor.Category.choices, required=False)
    weight = serializers.IntegerField(min_value=1, max_value=10, required=False)
    
    def validate_template_key(self, value):
        if not FactorTemplate.objects.filter(key=value, is_active=True).exists():
            raise serializers.ValidationError(f"Factor template '{value}' not found or inactive.")
        return value


class DecisionOptionSerializer(serializers.ModelSerializer):
    """Serializer for DecisionOption model."""
    
    factor_scores = FactorScoreSerializer(many=True, read_only=True)
    total_score = serializers.SerializerMethodField()
    
    class Meta:
        model = DecisionOption
        fields = [
            'id', 'name', 'description', 'sort_order',
            'factor_scores', 'total_score', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']
    
    def get_total_score(self, obj):
        """Calculate total weighted score for this option."""
        scores = obj.factor_scores.all()
        if not scores:
            return None
        
        total = 0
        total_weight = 0
        for fs in scores:
            weight = fs.factor.weight
            # Adjust score based on category (CON factors subtract)
            if fs.factor.category == 'CON':
                total -= fs.score * weight
            else:
                total += fs.score * weight
            total_weight += weight
        
        if total_weight == 0:
            return 0
        
        return round(total / total_weight, 2)


class DecisionOptionCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating DecisionOption."""
    
    class Meta:
        model = DecisionOption
        fields = ['name', 'description', 'sort_order']


class ResultSerializer(serializers.ModelSerializer):
    """Serializer for Result model."""
    
    recommended_option_name = serializers.CharField(
        source='recommended_option.name',
        read_only=True,
        allow_null=True
    )
    
    class Meta:
        model = Result
        fields = [
            'id', 'decision', 'recommended_option', 'recommended_option_name',
            'confidence_level', 'explanation', 'scoring_breakdown',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'decision', 'created_at', 'updated_at']


class DecisionListSerializer(serializers.ModelSerializer):
    """Lightweight serializer for decision list."""
    
    options_count = serializers.SerializerMethodField()
    factors_count = serializers.SerializerMethodField()
    
    class Meta:
        model = Decision
        fields = [
            'id', 'title', 'description', 'status', 'confidence_level',
            'satisfaction_rating', 'options_count', 'factors_count',
            'created_at', 'updated_at', 'analyzed_at'
        ]
    
    def get_options_count(self, obj):
        return obj.options.count()
    
    def get_factors_count(self, obj):
        return obj.factors.count()


class DecisionSerializer(serializers.ModelSerializer):
    """Full serializer for Decision model."""
    
    options = DecisionOptionSerializer(many=True, read_only=True)
    factors = FactorSerializer(many=True, read_only=True)
    result = ResultSerializer(read_only=True)
    chosen_option_name = serializers.CharField(
        source='chosen_option.name',
        read_only=True,
        allow_null=True
    )
    
    class Meta:
        model = Decision
        fields = [
            'id', 'title', 'description', 'status', 'chosen_option',
            'chosen_option_name', 'confidence_level', 'satisfaction_rating',
            'reflection_notes', 'options', 'factors', 'result',
            'created_at', 'updated_at', 'analyzed_at'
        ]
        read_only_fields = [
            'id', 'status', 'chosen_option', 'confidence_level',
            'analyzed_at', 'created_at', 'updated_at'
        ]


class DecisionCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating a Decision."""
    
    options = DecisionOptionCreateSerializer(many=True, required=False)
    
    class Meta:
        model = Decision
        fields = ['title', 'description', 'options']
    
    def create(self, validated_data):
        options_data = validated_data.pop('options', [])
        decision = Decision.objects.create(**validated_data)
        
        for i, option_data in enumerate(options_data):
            option_data.setdefault('sort_order', i)
            DecisionOption.objects.create(decision=decision, **option_data)
        
        return decision


class DecisionUpdateSerializer(serializers.ModelSerializer):
    """Serializer for updating a Decision."""
    
    class Meta:
        model = Decision
        fields = ['title', 'description', 'status', 'satisfaction_rating', 'reflection_notes']
    
    def validate_status(self, value):
        instance = self.instance
        if instance and instance.status == 'ARCHIVED' and value != 'ARCHIVED':
            raise serializers.ValidationError("Cannot change status of archived decision.")
        return value


class JournalEntrySerializer(serializers.ModelSerializer):
    """Serializer for journal entries (analyzed decisions with ratings)."""
    
    chosen_option_name = serializers.CharField(
        source='chosen_option.name',
        read_only=True,
        allow_null=True
    )
    
    class Meta:
        model = Decision
        fields = [
            'id', 'title', 'description', 'status', 'chosen_option',
            'chosen_option_name', 'confidence_level', 'satisfaction_rating',
            'reflection_notes', 'created_at', 'analyzed_at'
        ]
        read_only_fields = [
            'id', 'title', 'description', 'status', 'chosen_option',
            'confidence_level', 'created_at', 'analyzed_at'
        ]


class JournalUpdateSerializer(serializers.Serializer):
    """Serializer for updating journal entry."""
    
    satisfaction_rating = serializers.IntegerField(min_value=1, max_value=5, required=False)
    reflection_notes = serializers.CharField(required=False, allow_blank=True)


class AISuggestionsResponseSerializer(serializers.Serializer):
    """Serializer for AI suggestions response."""
    
    suggested_factors = serializers.ListField(
        child=serializers.DictField()
    )
    decision_id = serializers.UUIDField()
    message = serializers.CharField()


class AIAnalyzeResponseSerializer(serializers.Serializer):
    """Serializer for AI analysis response."""
    
    decision_id = serializers.UUIDField()
    recommended_option = serializers.DictField()
    confidence_level = serializers.FloatField()
    explanation = serializers.CharField()
    scoring_breakdown = serializers.DictField()


class FactorScoreUpdateSerializer(serializers.Serializer):
    """Serializer for updating factor scores."""
    
    scores = serializers.ListField(
        child=serializers.DictField()
    )
    
    def validate_scores(self, value):
        for score_data in value:
            if 'option_id' not in score_data:
                raise serializers.ValidationError("Each score must have an option_id.")
            if 'score' not in score_data:
                raise serializers.ValidationError("Each score must have a score value.")
            if not 1 <= score_data['score'] <= 10:
                raise serializers.ValidationError("Score must be between 1 and 10.")
        return value
