"""
Serializers for Decisions App
"""

from rest_framework import serializers
from .models import Decision, DecisionOption, DecisionFactor, FactorRating, JournalEntry


class FactorRatingSerializer(serializers.ModelSerializer):
    """Serializer for factor ratings"""
    decision_factor_name = serializers.CharField(source='decision_factor.name', read_only=True)
    option_name = serializers.CharField(source='option.name', read_only=True)
    
    class Meta:
        model = FactorRating
        fields = [
            'id',
            'decision_factor',
            'decision_factor_name',
            'option',
            'option_name',
            'score',
            'notes',
        ]
        read_only_fields = ['id']


class DecisionOptionSerializer(serializers.ModelSerializer):
    """Serializer for decision options"""
    
    factor_ratings = FactorRatingSerializer(many=True, read_only=True)
    
    class Meta:
        model = DecisionOption
        fields = ['id', 'name', 'description', 'pros', 'cons', 'ai_score', 'order', 'factor_ratings', 'created_at']
        read_only_fields = ['id', 'ai_score', 'created_at']


class DecisionFactorSerializer(serializers.ModelSerializer):
    """Serializer for decision factors"""
    
    ratings = FactorRatingSerializer(many=True, read_only=True)
    
    class Meta:
        model = DecisionFactor
        fields = ['id', 'name', 'weight', 'factor_type', 'is_ai_suggested', 'factor_template', 'ratings', 'created_at']
        read_only_fields = ['id', 'created_at']


class JournalEntrySerializer(serializers.ModelSerializer):
    """Serializer for journal entries"""
    
    class Meta:
        model = JournalEntry
        fields = ['id', 'reflection', 'satisfaction', 'outcome_notes', 'lessons_learned', 'created_at', 'updated_at']
        read_only_fields = ['id', 'created_at', 'updated_at']


class DecisionListSerializer(serializers.ModelSerializer):
    """Serializer for listing decisions"""
    
    options_count = serializers.SerializerMethodField()
    factors_count = serializers.SerializerMethodField()
    satisfaction = serializers.SerializerMethodField()
    chosen_option = DecisionOptionSerializer(read_only=True)
    ai_recommendation = DecisionOptionSerializer(read_only=True)
    options = DecisionOptionSerializer(many=True, read_only=True)
    
    class Meta:
        model = Decision
        fields = [
            'id', 'title', 'description', 'category', 'status',
            'ai_confidence', 'ai_recommendation', 'chosen_option',
            'satisfaction', 'deadline', 'options_count', 'factors_count',
            'options', 'created_at', 'updated_at'
        ]
    
    def get_options_count(self, obj):
        return len(obj.options.all())
    
    def get_factors_count(self, obj):
        return len(obj.decision_factors.all())
    
    def get_satisfaction(self, obj):
        try:
            if obj.journal_entry:
                return obj.journal_entry.satisfaction
        except JournalEntry.DoesNotExist:
            pass
        return None


class DecisionDetailSerializer(serializers.ModelSerializer):
    """Detailed serializer for a single decision"""
    
    options = DecisionOptionSerializer(many=True, read_only=True)
    decision_factors = DecisionFactorSerializer(many=True, read_only=True)
    journal_entry = JournalEntrySerializer(read_only=True)
    ai_recommendation_data = DecisionOptionSerializer(source='ai_recommendation', read_only=True)
    chosen_option_data = DecisionOptionSerializer(source='chosen_option', read_only=True)
    
    class Meta:
        model = Decision
        fields = [
            'id', 'title', 'description', 'category', 'status',
            'options', 'decision_factors',
            'ai_recommendation', 'ai_recommendation_data', 'ai_confidence', 
            'ai_explanation', 'ai_insights', 'analyzed_at',
            'chosen_option', 'chosen_option_data', 'chosen_at',
            'deadline', 'reminder_enabled', 'journal_entry',
            'created_at', 'updated_at'
        ]
        read_only_fields = [
            'id', 'ai_recommendation', 'ai_confidence', 'ai_explanation',
            'ai_insights', 'analyzed_at', 'created_at', 'updated_at'
        ]


class CreateDecisionSerializer(serializers.ModelSerializer):
    """Serializer for creating a decision"""
    
    options = serializers.ListField(
        child=serializers.DictField(), 
        write_only=True, 
        required=False
    )
    factors = serializers.ListField(
        child=serializers.DictField(), 
        write_only=True, 
        required=False
    )
    
    class Meta:
        model = Decision
        fields = ['id', 'title', 'description', 'category', 'deadline', 'reminder_enabled', 'options', 'factors']
        read_only_fields = ['id']
    
    def create(self, validated_data):
        options_data = validated_data.pop('options', [])
        factors_data = validated_data.pop('factors', [])
        
        # Create decision
        decision = Decision.objects.create(
            user=self.context['request'].user,
            **validated_data
        )
        
        # Create options
        for i, option_data in enumerate(options_data):
            DecisionOption.objects.create(
                decision=decision,
                name=option_data.get('name', ''),
                description=option_data.get('description', ''),
                pros=option_data.get('pros', []),
                cons=option_data.get('cons', []),
                order=i
            )
        
        # Create factors
        for factor_data in factors_data:
            DecisionFactor.objects.create(
                decision=decision,
                name=factor_data.get('name', ''),
                weight=factor_data.get('weight', 0.5),
                factor_type=factor_data.get('factor_type', factor_data.get('type', 'pro')),
                factor_template_id=factor_data.get('factor_template_id')
            )
        
        return decision


class UpdateDecisionSerializer(serializers.ModelSerializer):
    """Serializer for updating a decision"""
    
    class Meta:
        model = Decision
        fields = ['title', 'description', 'category', 'status', 'deadline', 'reminder_enabled', 'chosen_option']

    def validate_chosen_option(self, value):
        if value is None:
            return value
        decision = self.instance
        if decision and value.decision_id != decision.id:
            raise serializers.ValidationError('Chosen option must belong to this decision.')
        return value


class ChooseOptionSerializer(serializers.Serializer):
    """Serializer for choosing a decision option"""
    
    option_id = serializers.UUIDField()
