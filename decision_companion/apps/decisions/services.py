"""
AI Service - Business Logic for AI Analysis

Decision Companion - AI Decision Making System

This module contains placeholder AI logic for:
- Suggesting factors based on decision context
- Analyzing options and calculating weighted scores
- Generating recommendations with confidence levels
"""

from django.utils import timezone
from .models import (
    Decision, DecisionOption, Factor, FactorScore,
    Result, FactorTemplate, AIParameters
)


class AIService:
    """
    AI Service for decision analysis and suggestions.
    
    This is a placeholder implementation. In production,
    this would integrate with ML models or AI APIs.
    """
    
    # Default suggested factor templates
    DEFAULT_SUGGESTIONS = [
        {'key': 'COST', 'name': 'Cost', 'category': 'CON', 'weight': 7},
        {'key': 'QUALITY', 'name': 'Quality', 'category': 'PRO', 'weight': 8},
        {'key': 'TIME', 'name': 'Time Required', 'category': 'CON', 'weight': 6},
        {'key': 'RISK', 'name': 'Risk Level', 'category': 'CON', 'weight': 7},
        {'key': 'BENEFIT', 'name': 'Long-term Benefit', 'category': 'PRO', 'weight': 8},
        {'key': 'EFFORT', 'name': 'Effort Required', 'category': 'CON', 'weight': 5},
    ]
    
    def __init__(self, decision_id):
        """Initialize AI service with decision ID."""
        self.decision = Decision.objects.get(id=decision_id)
    
    def get_suggestions(self):
        """
        Get suggested factors for the decision.
        
        Returns a list of suggested factors based on:
        - Active factor templates
        - Decision title/description analysis (placeholder)
        - User history (placeholder)
        """
        suggestions = []
        
        # Get active factor templates
        templates = FactorTemplate.objects.filter(is_active=True)[:10]
        
        if templates.exists():
            for template in templates:
                # Check if factor already exists in decision
                existing = self.decision.factors.filter(
                    template_key=template.key
                ).exists()
                
                if not existing:
                    suggestions.append({
                        'key': template.key,
                        'name': template.name,
                        'description': template.description,
                        'category': template.default_category,
                        'weight': template.default_weight,
                        'icon': template.icon,
                        'from_template': True
                    })
        else:
            # Use default suggestions if no templates
            for suggestion in self.DEFAULT_SUGGESTIONS:
                existing = self.decision.factors.filter(
                    name__iexact=suggestion['name']
                ).exists()
                
                if not existing:
                    suggestions.append({
                        **suggestion,
                        'description': '',
                        'icon': '',
                        'from_template': False
                    })
        
        return {
            'suggested_factors': suggestions[:6],
            'decision_id': str(self.decision.id),
            'message': f"Found {len(suggestions)} suggested factors for your decision."
        }
    
    def analyze(self):
        """
        Analyze the decision and generate recommendations.
        
        Algorithm:
        1. For each option, calculate weighted score
        2. PRO factors add to score, CON factors subtract
        3. Normalize scores
        4. Calculate confidence based on score variance and data completeness
        5. Generate explanation
        """
        options = self.decision.options.all()
        factors = self.decision.factors.all()
        
        if not options.exists():
            raise ValueError("Decision must have at least one option to analyze.")
        
        if not factors.exists():
            raise ValueError("Decision must have at least one factor to analyze.")
        
        # Calculate scores for each option
        option_scores = []
        total_possible_weight = sum(f.weight for f in factors) * 10  # Max score per factor is 10
        
        for option in options:
            weighted_score = 0
            factor_breakdown = []
            
            for factor in factors:
                # Get score for this factor-option combination
                factor_score = FactorScore.objects.filter(
                    factor=factor,
                    option=option
                ).first()
                
                if factor_score:
                    score_value = factor_score.score
                else:
                    # Default score if not rated
                    score_value = 5
                
                # Calculate weighted contribution
                weighted_value = score_value * factor.weight
                
                # CON factors reduce the score
                if factor.category == 'CON':
                    weighted_score -= weighted_value
                else:
                    weighted_score += weighted_value
                
                factor_breakdown.append({
                    'factor_id': str(factor.id),
                    'name': factor.name,
                    'category': factor.category,
                    'score': score_value,
                    'weight': factor.weight,
                    'weighted': weighted_value if factor.category == 'PRO' else -weighted_value
                })
            
            option_scores.append({
                'option_id': str(option.id),
                'option_name': option.name,
                'raw_score': weighted_score,
                'factors': factor_breakdown
            })
        
        # Normalize scores to 0-100 range
        min_score = min(os['raw_score'] for os in option_scores)
        max_score = max(os['raw_score'] for os in option_scores)
        score_range = max_score - min_score if max_score != min_score else 1
        
        for os in option_scores:
            os['normalized_score'] = round(
                ((os['raw_score'] - min_score) / score_range) * 100,
                2
            )
        
        # Find best option
        best_option_data = max(option_scores, key=lambda x: x['normalized_score'])
        best_option = options.get(id=best_option_data['option_id'])
        
        # Calculate confidence level
        # Higher variance = lower confidence, more factors = higher confidence
        scores = [os['normalized_score'] for os in option_scores]
        avg_score = sum(scores) / len(scores)
        variance = sum((s - avg_score) ** 2 for s in scores) / len(scores)
        
        # Base confidence on variance and completeness
        score_confidence = min(100, variance * 2)  # Higher variance = more decisive
        completeness = self._calculate_completeness()
        
        confidence_level = round(
            (score_confidence * 0.6 + completeness * 0.4),
            1
        )
        confidence_level = max(30, min(95, confidence_level))  # Clamp between 30-95
        
        # Generate explanation
        explanation = self._generate_explanation(
            best_option_data,
            option_scores,
            confidence_level
        )
        
        # Build scoring breakdown
        scoring_breakdown = {
            'options': option_scores,
            'analysis_method': 'weighted_average',
            'metadata': {
                'total_factors': factors.count(),
                'total_options': options.count(),
                'pro_factors': factors.filter(category='PRO').count(),
                'con_factors': factors.filter(category='CON').count(),
                'analyzed_at': timezone.now().isoformat()
            }
        }
        
        # Save or update result
        result, created = Result.objects.update_or_create(
            decision=self.decision,
            defaults={
                'recommended_option': best_option,
                'confidence_level': confidence_level,
                'explanation': explanation,
                'scoring_breakdown': scoring_breakdown
            }
        )
        
        # Update decision
        self.decision.status = Decision.Status.ANALYZED
        self.decision.chosen_option = best_option
        self.decision.confidence_level = confidence_level
        self.decision.analyzed_at = timezone.now()
        self.decision.save()
        
        return {
            'decision_id': str(self.decision.id),
            'recommended_option': {
                'id': str(best_option.id),
                'name': best_option.name,
                'score': best_option_data['normalized_score']
            },
            'confidence_level': confidence_level,
            'explanation': explanation,
            'scoring_breakdown': scoring_breakdown
        }
    
    def _calculate_completeness(self):
        """Calculate data completeness percentage."""
        options = self.decision.options.all()
        factors = self.decision.factors.all()
        
        total_scores_needed = options.count() * factors.count()
        if total_scores_needed == 0:
            return 0
        
        actual_scores = FactorScore.objects.filter(
            factor__decision=self.decision
        ).count()
        
        return (actual_scores / total_scores_needed) * 100
    
    def _generate_explanation(self, best_option, all_scores, confidence):
        """Generate human-readable explanation for the recommendation."""
        option_name = best_option['option_name']
        score = best_option['normalized_score']
        
        # Find key contributing factors
        pros = sorted(
            [f for f in best_option['factors'] if f['weighted'] > 0],
            key=lambda x: x['weighted'],
            reverse=True
        )[:3]
        
        cons = sorted(
            [f for f in best_option['factors'] if f['weighted'] < 0],
            key=lambda x: x['weighted']
        )[:2]
        
        explanation = f"Based on the weighted analysis of all factors, "
        explanation += f"'{option_name}' is recommended with a score of {score:.1f}/100. "
        
        if pros:
            pro_names = ', '.join(f['name'] for f in pros)
            explanation += f"Key strengths include: {pro_names}. "
        
        if cons:
            con_names = ', '.join(f['name'] for f in cons)
            explanation += f"Consider these concerns: {con_names}. "
        
        if confidence >= 70:
            explanation += "This recommendation has high confidence based on clear score differentiation."
        elif confidence >= 50:
            explanation += "This recommendation has moderate confidence. Consider reviewing factor weights."
        else:
            explanation += "Confidence is lower due to similar scores. Additional factors may help."
        
        return explanation
