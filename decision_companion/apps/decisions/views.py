"""
Decision Views - API endpoints for decisions, factors, options, and AI

Decision Companion - AI Decision Making System
"""

from rest_framework import status, viewsets, generics
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.shortcuts import get_object_or_404
from .models import (
    Decision, DecisionOption, Factor, FactorScore,
    Result, FactorTemplate
)
from .serializers import (
    DecisionSerializer, DecisionListSerializer, DecisionCreateSerializer,
    DecisionUpdateSerializer, DecisionOptionSerializer, DecisionOptionCreateSerializer,
    FactorSerializer, FactorCreateSerializer, FactorFromTemplateSerializer,
    FactorScoreSerializer, FactorScoreUpdateSerializer, ResultSerializer,
    JournalEntrySerializer, JournalUpdateSerializer,
    FactorTemplateSerializer, AISuggestionsResponseSerializer, AIAnalyzeResponseSerializer
)
from .services import AIService
from apps.core.permissions import IsOwnerOrAdmin
from apps.core.utils import log_activity
from apps.core.models import ActivityLog


class DecisionViewSet(viewsets.ModelViewSet):
    """
    ViewSet for Decision CRUD operations.
    
    Endpoints:
    - GET /api/v1/decisions - List user's decisions
    - POST /api/v1/decisions - Create new decision
    - GET /api/v1/decisions/{id} - Get decision details
    - PUT /api/v1/decisions/{id} - Update decision
    - DELETE /api/v1/decisions/{id} - Delete decision
    """
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        """Filter decisions to only those owned by the user."""
        user = self.request.user
        queryset = Decision.objects.filter(user=user)
        
        # Filter by status if provided
        status_filter = self.request.query_params.get('status')
        if status_filter:
            queryset = queryset.filter(status=status_filter.upper())
        
        return queryset.select_related('chosen_option').prefetch_related('options', 'factors')
    
    def get_serializer_class(self):
        """Return appropriate serializer based on action."""
        if self.action == 'list':
            return DecisionListSerializer
        elif self.action == 'create':
            return DecisionCreateSerializer
        elif self.action in ['update', 'partial_update']:
            return DecisionUpdateSerializer
        return DecisionSerializer
    
    def perform_create(self, serializer):
        """Set user when creating decision."""
        decision = serializer.save(user=self.request.user)
        
        # Log activity
        log_activity(
            self.request.user,
            ActivityLog.ActionType.CREATE_DECISION,
            f"Created decision: {decision.title}",
            self.request,
            {'decision_id': str(decision.id)}
        )
    
    def perform_update(self, serializer):
        """Log update activity."""
        decision = serializer.save()
        
        log_activity(
            self.request.user,
            ActivityLog.ActionType.UPDATE_DECISION,
            f"Updated decision: {decision.title}",
            self.request,
            {'decision_id': str(decision.id)}
        )
    
    def perform_destroy(self, instance):
        """Log delete activity."""
        log_activity(
            self.request.user,
            ActivityLog.ActionType.DELETE_DECISION,
            f"Deleted decision: {instance.title}",
            self.request,
            {'decision_id': str(instance.id)}
        )
        instance.delete()
    
    def create(self, request, *args, **kwargs):
        """Create a new decision."""
        serializer = self.get_serializer(data=request.data)
        if serializer.is_valid():
            self.perform_create(serializer)
            decision = Decision.objects.get(id=serializer.instance.id)
            return Response({
                'success': True,
                'message': 'Decision created successfully',
                'data': DecisionSerializer(decision).data
            }, status=status.HTTP_201_CREATED)
        
        return Response({
            'success': False,
            'error': {
                'code': 'VALIDATION_ERROR',
                'message': 'Failed to create decision',
                'details': serializer.errors
            }
        }, status=status.HTTP_400_BAD_REQUEST)
    
    def list(self, request, *args, **kwargs):
        """List all user decisions."""
        queryset = self.filter_queryset(self.get_queryset())
        page = self.paginate_queryset(queryset)
        
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)
        
        serializer = self.get_serializer(queryset, many=True)
        return Response({
            'success': True,
            'data': serializer.data
        })
    
    def retrieve(self, request, *args, **kwargs):
        """Get decision details."""
        instance = self.get_object()
        serializer = DecisionSerializer(instance)
        return Response({
            'success': True,
            'data': serializer.data
        })
    
    def update(self, request, *args, **kwargs):
        """Update decision."""
        partial = kwargs.pop('partial', False)
        instance = self.get_object()
        serializer = self.get_serializer(instance, data=request.data, partial=partial)
        
        if serializer.is_valid():
            self.perform_update(serializer)
            return Response({
                'success': True,
                'message': 'Decision updated successfully',
                'data': DecisionSerializer(instance).data
            })
        
        return Response({
            'success': False,
            'error': {
                'code': 'VALIDATION_ERROR',
                'message': 'Failed to update decision',
                'details': serializer.errors
            }
        }, status=status.HTTP_400_BAD_REQUEST)
    
    def destroy(self, request, *args, **kwargs):
        """Delete decision."""
        instance = self.get_object()
        self.perform_destroy(instance)
        return Response({
            'success': True,
            'message': 'Decision deleted successfully'
        }, status=status.HTTP_200_OK)
    
    # =========================================
    # Nested Option Endpoints
    # =========================================
    
    @action(detail=True, methods=['get', 'post'], url_path='options')
    def options(self, request, pk=None):
        """
        GET /api/v1/decisions/{id}/options - List options
        POST /api/v1/decisions/{id}/options - Create option
        """
        decision = self.get_object()
        
        if request.method == 'GET':
            options = decision.options.all()
            serializer = DecisionOptionSerializer(options, many=True)
            return Response({
                'success': True,
                'data': serializer.data
            })
        
        elif request.method == 'POST':
            serializer = DecisionOptionCreateSerializer(data=request.data)
            if serializer.is_valid():
                option = DecisionOption.objects.create(
                    decision=decision,
                    **serializer.validated_data
                )
                return Response({
                    'success': True,
                    'message': 'Option created successfully',
                    'data': DecisionOptionSerializer(option).data
                }, status=status.HTTP_201_CREATED)
            
            return Response({
                'success': False,
                'error': {
                    'code': 'VALIDATION_ERROR',
                    'message': 'Failed to create option',
                    'details': serializer.errors
                }
            }, status=status.HTTP_400_BAD_REQUEST)
    
    @action(detail=True, methods=['put', 'delete'], url_path='options/(?P<option_id>[^/.]+)')
    def option_detail(self, request, pk=None, option_id=None):
        """
        PUT /api/v1/decisions/{id}/options/{optionId} - Update option
        DELETE /api/v1/decisions/{id}/options/{optionId} - Delete option
        """
        decision = self.get_object()
        option = get_object_or_404(DecisionOption, id=option_id, decision=decision)
        
        if request.method == 'PUT':
            serializer = DecisionOptionCreateSerializer(option, data=request.data, partial=True)
            if serializer.is_valid():
                serializer.save()
                return Response({
                    'success': True,
                    'message': 'Option updated successfully',
                    'data': DecisionOptionSerializer(option).data
                })
            
            return Response({
                'success': False,
                'error': {
                    'code': 'VALIDATION_ERROR',
                    'message': 'Failed to update option',
                    'details': serializer.errors
                }
            }, status=status.HTTP_400_BAD_REQUEST)
        
        elif request.method == 'DELETE':
            option.delete()
            return Response({
                'success': True,
                'message': 'Option deleted successfully'
            })
    
    # =========================================
    # Factor Endpoints
    # =========================================
    
    @action(detail=True, methods=['get', 'post'], url_path='factors')
    def factors(self, request, pk=None):
        """
        GET /api/v1/decisions/{id}/factors - List factors
        POST /api/v1/decisions/{id}/factors - Create factor
        """
        decision = self.get_object()
        
        if request.method == 'GET':
            factors = decision.factors.all()
            serializer = FactorSerializer(factors, many=True)
            return Response({
                'success': True,
                'data': serializer.data
            })
        
        elif request.method == 'POST':
            serializer = FactorCreateSerializer(data=request.data)
            if serializer.is_valid():
                factor = Factor.objects.create(
                    decision=decision,
                    **serializer.validated_data
                )
                return Response({
                    'success': True,
                    'message': 'Factor created successfully',
                    'data': FactorSerializer(factor).data
                }, status=status.HTTP_201_CREATED)
            
            return Response({
                'success': False,
                'error': {
                    'code': 'VALIDATION_ERROR',
                    'message': 'Failed to create factor',
                    'details': serializer.errors
                }
            }, status=status.HTTP_400_BAD_REQUEST)
    
    @action(detail=True, methods=['post'], url_path='factors/from-template')
    def factor_from_template(self, request, pk=None):
        """
        POST /api/v1/decisions/{id}/factors/from-template
        Create factor from predefined template.
        """
        decision = self.get_object()
        serializer = FactorFromTemplateSerializer(data=request.data)
        
        if serializer.is_valid():
            template_key = serializer.validated_data['template_key']
            template = FactorTemplate.objects.get(key=template_key)
            
            # Use provided values or defaults from template
            category = serializer.validated_data.get('category', template.default_category)
            weight = serializer.validated_data.get('weight', template.default_weight)
            
            # Check if factor already exists
            if decision.factors.filter(template_key=template_key).exists():
                return Response({
                    'success': False,
                    'error': {
                        'code': 'DUPLICATE_ERROR',
                        'message': f"Factor from template '{template_key}' already exists for this decision."
                    }
                }, status=status.HTTP_400_BAD_REQUEST)
            
            factor = Factor.objects.create(
                decision=decision,
                name=template.name,
                description=template.description,
                category=category,
                weight=weight,
                is_from_template=True,
                template_key=template_key
            )
            
            return Response({
                'success': True,
                'message': 'Factor created from template successfully',
                'data': FactorSerializer(factor).data
            }, status=status.HTTP_201_CREATED)
        
        return Response({
            'success': False,
            'error': {
                'code': 'VALIDATION_ERROR',
                'message': 'Failed to create factor from template',
                'details': serializer.errors
            }
        }, status=status.HTTP_400_BAD_REQUEST)
    
    @action(detail=True, methods=['put', 'delete'], url_path='factors/(?P<factor_id>[^/.]+)')
    def factor_detail(self, request, pk=None, factor_id=None):
        """
        PUT /api/v1/decisions/{id}/factors/{factorId} - Update factor
        DELETE /api/v1/decisions/{id}/factors/{factorId} - Delete factor
        """
        decision = self.get_object()
        factor = get_object_or_404(Factor, id=factor_id, decision=decision)
        
        if request.method == 'PUT':
            serializer = FactorCreateSerializer(factor, data=request.data, partial=True)
            if serializer.is_valid():
                serializer.save()
                return Response({
                    'success': True,
                    'message': 'Factor updated successfully',
                    'data': FactorSerializer(factor).data
                })
            
            return Response({
                'success': False,
                'error': {
                    'code': 'VALIDATION_ERROR',
                    'message': 'Failed to update factor',
                    'details': serializer.errors
                }
            }, status=status.HTTP_400_BAD_REQUEST)
        
        elif request.method == 'DELETE':
            factor.delete()
            return Response({
                'success': True,
                'message': 'Factor deleted successfully'
            })
    
    @action(detail=True, methods=['post'], url_path='factors/(?P<factor_id>[^/.]+)/scores')
    def factor_scores(self, request, pk=None, factor_id=None):
        """
        POST /api/v1/decisions/{id}/factors/{factorId}/scores
        Update scores for a factor across all options.
        """
        decision = self.get_object()
        factor = get_object_or_404(Factor, id=factor_id, decision=decision)
        
        serializer = FactorScoreUpdateSerializer(data=request.data)
        if serializer.is_valid():
            scores_data = serializer.validated_data['scores']
            
            for score_data in scores_data:
                option = get_object_or_404(
                    DecisionOption,
                    id=score_data['option_id'],
                    decision=decision
                )
                
                FactorScore.objects.update_or_create(
                    factor=factor,
                    option=option,
                    defaults={
                        'score': score_data['score'],
                        'notes': score_data.get('notes', '')
                    }
                )
            
            return Response({
                'success': True,
                'message': 'Scores updated successfully',
                'data': FactorSerializer(factor).data
            })
        
        return Response({
            'success': False,
            'error': {
                'code': 'VALIDATION_ERROR',
                'message': 'Failed to update scores',
                'details': serializer.errors
            }
        }, status=status.HTTP_400_BAD_REQUEST)
    
    # =========================================
    # AI Endpoints
    # =========================================
    
    @action(detail=True, methods=['post'], url_path='ai/suggestions')
    def ai_suggestions(self, request, pk=None):
        """
        POST /api/v1/decisions/{id}/ai/suggestions
        Get AI-suggested factors for the decision.
        """
        decision = self.get_object()
        
        try:
            ai_service = AIService(decision.id)
            suggestions = ai_service.get_suggestions()
            
            log_activity(
                request.user,
                ActivityLog.ActionType.AI_SUGGESTIONS,
                f"Got AI suggestions for: {decision.title}",
                request,
                {'decision_id': str(decision.id)}
            )
            
            return Response({
                'success': True,
                'data': suggestions
            })
        except Exception as e:
            return Response({
                'success': False,
                'error': {
                    'code': 'AI_ERROR',
                    'message': f"Failed to get suggestions: {str(e)}"
                }
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    
    @action(detail=True, methods=['post'], url_path='ai/analyze')
    def ai_analyze(self, request, pk=None):
        """
        POST /api/v1/decisions/{id}/ai/analyze
        Run AI analysis on the decision.
        """
        decision = self.get_object()
        
        try:
            ai_service = AIService(decision.id)
            result = ai_service.analyze()
            
            log_activity(
                request.user,
                ActivityLog.ActionType.AI_ANALYZE,
                f"Analyzed decision: {decision.title}",
                request,
                {'decision_id': str(decision.id), 'confidence': result['confidence_level']}
            )
            
            return Response({
                'success': True,
                'message': 'Analysis completed successfully',
                'data': result
            })
        except ValueError as e:
            return Response({
                'success': False,
                'error': {
                    'code': 'VALIDATION_ERROR',
                    'message': str(e)
                }
            }, status=status.HTTP_400_BAD_REQUEST)
        except Exception as e:
            return Response({
                'success': False,
                'error': {
                    'code': 'AI_ERROR',
                    'message': f"Analysis failed: {str(e)}"
                }
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    
    @action(detail=True, methods=['get'], url_path='result')
    def result(self, request, pk=None):
        """
        GET /api/v1/decisions/{id}/result
        Get the analysis result for a decision.
        """
        decision = self.get_object()
        
        try:
            result = decision.result
            serializer = ResultSerializer(result)
            return Response({
                'success': True,
                'data': serializer.data
            })
        except Result.DoesNotExist:
            return Response({
                'success': False,
                'error': {
                    'code': 'NOT_FOUND',
                    'message': 'No analysis result found. Run AI analysis first.'
                }
            }, status=status.HTTP_404_NOT_FOUND)
    
    # =========================================
    # Journal Endpoint
    # =========================================
    
    @action(detail=True, methods=['patch'], url_path='journal')
    def journal_update(self, request, pk=None):
        """
        PATCH /api/v1/decisions/{id}/journal
        Update journal entry (satisfaction rating and reflection notes).
        """
        decision = self.get_object()
        serializer = JournalUpdateSerializer(data=request.data)
        
        if serializer.is_valid():
            if 'satisfaction_rating' in serializer.validated_data:
                decision.satisfaction_rating = serializer.validated_data['satisfaction_rating']
            if 'reflection_notes' in serializer.validated_data:
                decision.reflection_notes = serializer.validated_data['reflection_notes']
            decision.save()
            
            return Response({
                'success': True,
                'message': 'Journal entry updated successfully',
                'data': JournalEntrySerializer(decision).data
            })
        
        return Response({
            'success': False,
            'error': {
                'code': 'VALIDATION_ERROR',
                'message': 'Failed to update journal entry',
                'details': serializer.errors
            }
        }, status=status.HTTP_400_BAD_REQUEST)


class JournalListView(generics.ListAPIView):
    """
    GET /api/v1/journal
    List analyzed decisions with journal information.
    """
    serializer_class = JournalEntrySerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        return Decision.objects.filter(
            user=self.request.user,
            status__in=['ANALYZED', 'ARCHIVED']
        ).select_related('chosen_option')
    
    def list(self, request, *args, **kwargs):
        queryset = self.filter_queryset(self.get_queryset())
        page = self.paginate_queryset(queryset)
        
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)
        
        serializer = self.get_serializer(queryset, many=True)
        return Response({
            'success': True,
            'data': serializer.data
        })


class FactorTemplateListView(generics.ListAPIView):
    """
    GET /api/v1/factor-templates
    List active factor templates (read-only for users).
    """
    serializer_class = FactorTemplateSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        return FactorTemplate.objects.filter(is_active=True)
    
    def list(self, request, *args, **kwargs):
        queryset = self.filter_queryset(self.get_queryset())
        serializer = self.get_serializer(queryset, many=True)
        return Response({
            'success': True,
            'data': serializer.data
        })
