"""
Views for AI Service App
"""

import logging

from rest_framework import status, permissions
from rest_framework.response import Response
from rest_framework.views import APIView
from django.shortcuts import get_object_or_404
from django.utils import timezone

from apps.decisions.models import Decision, DecisionOption
from apps.decisions.serializers import DecisionDetailSerializer
from .service import ai_service

logger = logging.getLogger(__name__)


class AIStatusView(APIView):
    """Check if AI service is available"""
    
    permission_classes = [permissions.IsAuthenticated]
    
    def get(self, request):
        return Response({
            'available': ai_service.is_available(),
            'model': ai_service.model if ai_service.is_available() else None
        })


class AnalyzeDecisionView(APIView):
    """Analyze a decision and get AI recommendation"""
    
    permission_classes = [permissions.IsAuthenticated]
    throttle_scope = 'ai'
    
    def post(self, request, decision_id):
        decision = get_object_or_404(Decision.objects.prefetch_related('options', 'decision_factors__ratings'), id=decision_id, user=request.user)
        logger.info("AI analyze start decision_id=%s user_id=%s", decision_id, request.user.id)
        logger.debug("AI analyze decision state options=%s factors=%s", decision.options.count(), decision.decision_factors.count())

        if decision.options.count() == 0:
            return Response({'success': False, 'error': 'Decision has no options.'}, status=status.HTTP_400_BAD_REQUEST)
        if decision.decision_factors.count() == 0:
            return Response({'success': False, 'error': 'Decision has no factors.'}, status=status.HTTP_400_BAD_REQUEST)
        
        # Build decision data for AI
        decision_data = {
            'title': decision.title,
            'description': decision.description,
            'category': decision.category,
            'options': [],
            'factors': [],
            'ratings': []
        }
        
        options_list = list(decision.options.all().order_by('order'))
        option_index_map = {str(option.id): idx for idx, option in enumerate(options_list)}

        # Add options
        for option in options_list:
            decision_data['options'].append({
                'name': option.name,
                'description': option.description,
                'pros': option.pros,
                'cons': option.cons
            })
        
        # Add factors
        raw_weights = [max(float(factor.weight), 0.0) for factor in decision.decision_factors.all()]
        total_weight = sum(raw_weights)
        normalized_weights = [
            (weight / total_weight) if total_weight > 0 else (1.0 / len(raw_weights) if raw_weights else 0.0)
            for weight in raw_weights
        ]

        for factor in decision.decision_factors.all():
            factor_type = factor.factor_type
            factor_index = len(decision_data['factors'])
            decision_data['factors'].append({
                'name': factor.name,
                'weight': factor.weight,
                'normalized_weight': normalized_weights[factor_index] if factor_index < len(normalized_weights) else 0.0,
                'type': factor_type,
            })
        
        # Add ratings
        missing_pairs = []
        for factor in decision.decision_factors.all():
            seen_option_ids = set()
            for rating in factor.ratings.all():
                option_index = option_index_map.get(str(rating.option_id), 0)
                seen_option_ids.add(str(rating.option_id))
                decision_data['ratings'].append({
                    'factor_name': factor.name,
                    'option_index': option_index,
                    'score': rating.score
                })
            for option in options_list:
                if str(option.id) not in seen_option_ids:
                    missing_pairs.append({
                        'factor_id': str(factor.id),
                        'factor_name': factor.name,
                        'option_id': str(option.id),
                        'option_name': option.name,
                    })

        if missing_pairs:
            logger.warning("AI analyze blocked: missing ratings decision_id=%s missing=%s", decision_id, len(missing_pairs))
            return Response(
                {
                    'success': False,
                    'error': 'Missing ratings for one or more factor/option pairs.',
                    'missing_ratings': missing_pairs,
                },
                status=status.HTTP_400_BAD_REQUEST,
            )
        
        # Get AI analysis
        result = ai_service.analyze_decision(decision_data)
        
        if result['success']:
            # Update decision with AI results
            recommended_idx = result.get('recommendation', 0)
            
            if 0 <= recommended_idx < len(options_list):
                decision.ai_recommendation = options_list[recommended_idx]
            
            decision.ai_confidence = result.get('confidence', 0.5)
            decision.ai_explanation = result.get('summary') or result.get('explanation', '')
            decision.ai_insights = {
                'summary': result.get('summary') or result.get('explanation', ''),
                'drivers': result.get('drivers', []),
                'risks': result.get('risks', []),
                'questions': result.get('questions', []),
                'insights': result.get('insights', []),
                'considerations': result.get('considerations', []),
                'potential_risks': result.get('potential_risks', []),
                'option_scores': result.get('option_scores', []),
            }
            decision.analyzed_at = timezone.now()
            decision.status = 'completed'
            decision.save()
            
            # Update option AI scores
            for score_data in result.get('option_scores', []):
                idx = score_data.get('index', 0)
                if 0 <= idx < len(options_list):
                    options_list[idx].ai_score = score_data.get('score', 0)
                    options_list[idx].save()
            
            factor_breakdown = []
            factors_list = list(decision.decision_factors.all())
            ratings_by_key = {}
            for factor in factors_list:
                for rating in factor.ratings.all():
                    ratings_by_key[(str(factor.id), str(rating.option_id))] = float(rating.score)

            option_score_map = {}
            for item in result.get('option_scores', []):
                try:
                    idx_key = int(item.get('index', -1))
                    option_score_map[idx_key] = float(item.get('score', 0))
                except (TypeError, ValueError):
                    continue

            for idx, option in enumerate(options_list):
                fallback_score = option_score_map.get(idx, 0.0)
                weighted_total = 0.0
                per_factor = []
                for f_idx, factor in enumerate(factors_list):
                    n_weight = normalized_weights[f_idx] if f_idx < len(normalized_weights) else 0.0
                    raw_score = ratings_by_key.get((str(factor.id), str(option.id)), 0.0)
                    normalized_score = max(0.0, min(1.0, raw_score / 10.0))
                    contribution = normalized_score * n_weight
                    weighted_total += contribution
                    per_factor.append({
                        'factor_id': str(factor.id),
                        'factor_name': factor.name,
                        'type': decision_data['factors'][f_idx]['type'] if f_idx < len(decision_data['factors']) else 'pro',
                        'normalized_weight': n_weight,
                        'raw_score': raw_score,
                        'normalized_score': normalized_score,
                        'contribution': contribution,
                    })
                factor_breakdown.append({
                    'option_id': str(option.id),
                    'option_name': option.name,
                    'weighted_score': weighted_total if weighted_total > 0 else fallback_score,
                    'factors': per_factor,
                })

            score_rows = sorted(
                [
                    {
                        'option_id': row['option_id'],
                        'option_name': row['option_name'],
                        'score': round(float(row['weighted_score']), 4),
                        'percentage': round(float(row['weighted_score']) * 100, 2),
                    }
                    for row in factor_breakdown
                ],
                key=lambda x: x['score'],
                reverse=True,
            )
            weights = [
                {
                    'factor_id': str(f.id),
                    'factor_name': f.name,
                    'type': decision_data['factors'][i]['type'] if i < len(decision_data['factors']) else 'pro',
                    'weight': float(f.weight),
                    'normalized_weight': normalized_weights[i] if i < len(normalized_weights) else 0.0,
                }
                for i, f in enumerate(factors_list)
            ]
            winner = score_rows[0] if score_rows else None
            logger.info("AI analyze completed decision_id=%s winner=%s score=%s", decision_id, winner['option_name'] if winner else None, winner['score'] if winner else None)

            return Response({
                'success': True,
                'analysis': result,
                'summary': result.get('summary') or result.get('explanation', ''),
                'drivers': result.get('drivers', []),
                'risks': result.get('risks', []),
                'questions': result.get('questions', []),
                'option_scores': result.get('option_scores', []),
                'scores': score_rows,
                'percentages': [{'option_id': item['option_id'], 'option_name': item['option_name'], 'percentage': item['percentage']} for item in score_rows],
                'weights': weights,
                'winner': winner,
                'recommendation': {
                    'option_index': recommended_idx if 0 <= recommended_idx < len(options_list) else 0,
                    'option_id': str(options_list[recommended_idx].id) if 0 <= recommended_idx < len(options_list) else None,
                    'option_name': options_list[recommended_idx].name if 0 <= recommended_idx < len(options_list) else None,
                },
                'factor_breakdown': factor_breakdown,
                'decision': DecisionDetailSerializer(decision).data
            })
        else:
            return Response({
                'success': False,
                'error': result.get('error', 'Analysis failed')
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class SuggestFactorsView(APIView):
    """Get AI-suggested factors for a decision"""
    
    permission_classes = [permissions.IsAuthenticated]
    throttle_scope = 'ai'
    
    def post(self, request, decision_id):
        decision = get_object_or_404(Decision, id=decision_id, user=request.user)
        
        decision_data = {
            'title': decision.title,
            'description': decision.description,
            'category': decision.category,
            'options': [{'name': o.name} for o in decision.options.all()]
        }
        
        result = ai_service.suggest_factors(decision_data)
        
        return Response(result)


class GenerateProsConsView(APIView):
    """Generate pros and cons for a decision option"""
    
    permission_classes = [permissions.IsAuthenticated]
    throttle_scope = 'ai'
    
    def post(self, request, decision_id, option_id):
        decision = get_object_or_404(Decision, id=decision_id, user=request.user)
        option = get_object_or_404(DecisionOption, id=option_id, decision=decision)
        
        result = ai_service.generate_pros_cons(
            option_name=option.name,
            decision_context=f"{decision.title}: {decision.description}"
        )
        
        if result['success']:
            # Update option with generated pros/cons
            if result['pros']:
                option.pros = list(set(option.pros + result['pros']))
            if result['cons']:
                option.cons = list(set(option.cons + result['cons']))
            option.save()
        
        return Response(result)


class GetInsightsView(APIView):
    """Get AI insights for a decision"""
    
    permission_classes = [permissions.IsAuthenticated]
    throttle_scope = 'ai'
    
    def get(self, request, decision_id):
        decision = get_object_or_404(Decision, id=decision_id, user=request.user)
        
        decision_data = {
            'title': decision.title,
            'description': decision.description,
            'options': [
                {
                    'name': o.name,
                    'description': o.description,
                    'pros': o.pros,
                    'cons': o.cons
                } for o in decision.options.all()
            ]
        }
        
        result = ai_service.get_decision_insights(decision_data)
        
        return Response(result)


class QuickAnalyzeView(APIView):
    """Quick analysis without saving - for preview"""
    
    permission_classes = [permissions.IsAuthenticated]
    throttle_scope = 'ai'
    
    def post(self, request):
        """
        Quick analyze decision data without persisting
        
        Request body for suggest_options:
        {
            "title": "Decision title",
            "request_type": "suggest_options"
        }
        
        Request body for suggest_factors:
        {
            "title": "Decision title",
            "options": ["Option 1", "Option 2"],
            "request_type": "suggest_factors"
        }
        
        Request body for analysis:
        {
            "title": "Decision title",
            "description": "Description",
            "category": "career",
            "options": [{"name": "Option 1", "pros": [], "cons": []}]
        }
        """
        decision_data = request.data
        request_type = decision_data.get('request_type', 'analyze')
        
        # Handle option suggestions
        if request_type == 'suggest_options':
            title = decision_data.get('title', '')
            if not title:
                return Response({
                    'error': 'Title is required for option suggestions'
                }, status=status.HTTP_400_BAD_REQUEST)
            
            description = decision_data.get('description', '')
            result = ai_service.suggest_options(title, description)
            return Response(result)
        
        # Handle factor suggestions
        if request_type == 'suggest_factors':
            title = decision_data.get('title', '')
            options = decision_data.get('options', [])
            
            if not title:
                return Response({
                    'error': 'Title is required for factor suggestions'
                }, status=status.HTTP_400_BAD_REQUEST)
            
            # Build decision data for factor suggestion
            factor_data = {
                'title': title,
                'description': decision_data.get('description', ''),
                'category': decision_data.get('category', 'General'),
                'options': [{'name': o} if isinstance(o, str) else o for o in options]
            }
            
            result = ai_service.suggest_factors(factor_data)
            return Response(result)

        if request_type == 'generate_ratings':
            title = decision_data.get('title', '')
            options = decision_data.get('options', [])
            factors = decision_data.get('factors', [])

            if not title or not options or not factors:
                return Response({
                    'success': False,
                    'error': 'Title, options, and factors are required for rating generation'
                }, status=status.HTTP_400_BAD_REQUEST)

            result = ai_service.generate_factor_ratings({
                'title': title,
                'description': decision_data.get('description', ''),
                'options': options,
                'factors': factors,
            })
            return Response(result, status=status.HTTP_200_OK if result.get('success') else status.HTTP_400_BAD_REQUEST)
        
        # Handle full analysis
        if not decision_data.get('title') or not decision_data.get('options'):
            return Response({
                'error': 'Title and options are required'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        result = ai_service.analyze_decision(decision_data)
        
        return Response(result)
