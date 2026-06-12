"""
Admin Panel Views - Admin-specific API endpoints

Decision Companion - AI Decision Making System
"""

from rest_framework import status, generics, viewsets
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from rest_framework.views import APIView
from django.db.models import Avg, Count
from django.utils import timezone
from datetime import timedelta
from django.shortcuts import get_object_or_404

from apps.core.models import User, ActivityLog
from apps.core.permissions import IsAdmin
from apps.decisions.models import Decision, FactorTemplate, AIParameters
from apps.feedback.models import Feedback
from apps.feedback.serializers import FeedbackSerializer
from .serializers import (
    AdminUserSerializer, AdminUserDetailSerializer,
    UsageAnalyticsSerializer, FeedbackAnalyticsSerializer,
    AdminFactorTemplateSerializer, AdminAIParametersSerializer,
    AdminActivityLogSerializer
)


# ============================================================================
# Admin User Management Views
# ============================================================================

class AdminUserListView(generics.ListAPIView):
    """
    GET /api/v1/admin/users
    List all users (admin only).
    """
    serializer_class = AdminUserSerializer
    permission_classes = [IsAuthenticated, IsAdmin]
    
    def get_queryset(self):
        queryset = User.objects.all()
        
        # Filter by role
        role = self.request.query_params.get('role')
        if role:
            queryset = queryset.filter(role=role.upper())
        
        # Filter by is_guest
        is_guest = self.request.query_params.get('is_guest')
        if is_guest is not None:
            queryset = queryset.filter(is_guest=is_guest.lower() == 'true')
        
        # Filter by is_active
        is_active = self.request.query_params.get('is_active')
        if is_active is not None:
            queryset = queryset.filter(is_active=is_active.lower() == 'true')
        
        return queryset
    
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


class AdminUserDetailView(APIView):
    """
    GET /api/v1/admin/users/{id}
    Get user details (admin only).
    """
    permission_classes = [IsAuthenticated, IsAdmin]
    
    def get(self, request, user_id):
        user = get_object_or_404(User, id=user_id)
        serializer = AdminUserDetailSerializer(user)
        return Response({
            'success': True,
            'data': serializer.data
        })


# ============================================================================
# Analytics Views
# ============================================================================

class UsageAnalyticsView(APIView):
    """
    GET /api/v1/admin/analytics/usage
    Get usage analytics (admin only).
    """
    permission_classes = [IsAuthenticated, IsAdmin]
    
    def get(self, request):
        now = timezone.now()
        week_ago = now - timedelta(days=7)
        month_ago = now - timedelta(days=30)
        
        # User stats
        total_users = User.objects.count()
        active_users = User.objects.filter(is_active=True).count()
        guest_users = User.objects.filter(is_guest=True).count()
        
        # Decision stats
        decisions = Decision.objects.all()
        total_decisions = decisions.count()
        decisions_by_status = dict(decisions.values('status').annotate(
            count=Count('id')
        ).values_list('status', 'count'))
        
        # AI analysis stats
        total_analyses = decisions.filter(status='ANALYZED').count()
        average_confidence = decisions.filter(
            confidence_level__isnull=False
        ).aggregate(avg=Avg('confidence_level'))['avg']
        
        # Time-based stats
        decisions_this_week = decisions.filter(created_at__gte=week_ago).count()
        decisions_this_month = decisions.filter(created_at__gte=month_ago).count()
        
        # Most active users
        most_active = User.objects.annotate(
            decision_count=Count('decisions')
        ).order_by('-decision_count')[:5]
        
        most_active_users = [
            {
                'id': str(u.id),
                'email': u.email,
                'name': u.name,
                'decision_count': u.decision_count
            }
            for u in most_active
        ]
        
        data = {
            'total_users': total_users,
            'active_users': active_users,
            'guest_users': guest_users,
            'total_decisions': total_decisions,
            'decisions_by_status': decisions_by_status,
            'total_analyses': total_analyses,
            'average_confidence': round(average_confidence, 2) if average_confidence else None,
            'decisions_this_week': decisions_this_week,
            'decisions_this_month': decisions_this_month,
            'most_active_users': most_active_users
        }
        
        serializer = UsageAnalyticsSerializer(data)
        return Response({
            'success': True,
            'data': serializer.data
        })


class FeedbackAnalyticsView(APIView):
    """
    GET /api/v1/admin/analytics/feedback
    Get feedback analytics (admin only).
    """
    permission_classes = [IsAuthenticated, IsAdmin]
    
    def get(self, request):
        feedbacks = Feedback.objects.all()
        
        # Basic stats
        total_feedback = feedbacks.count()
        resolved_feedback = feedbacks.filter(is_resolved=True).count()
        pending_feedback = feedbacks.filter(is_resolved=False).count()
        
        # Rating stats
        average_rating = feedbacks.aggregate(avg=Avg('rating'))['avg']
        
        # Feedback by type
        feedback_by_type = dict(feedbacks.values('feedback_type').annotate(
            count=Count('id')
        ).values_list('feedback_type', 'count'))
        
        # Rating distribution
        rating_distribution = {}
        for i in range(1, 6):
            rating_distribution[str(i)] = feedbacks.filter(rating=i).count()
        
        # Recent feedback
        recent = feedbacks.order_by('-created_at')[:10]
        recent_feedback = FeedbackSerializer(recent, many=True).data
        
        data = {
            'total_feedback': total_feedback,
            'resolved_feedback': resolved_feedback,
            'pending_feedback': pending_feedback,
            'average_rating': round(average_rating, 2) if average_rating else None,
            'feedback_by_type': feedback_by_type,
            'rating_distribution': rating_distribution,
            'recent_feedback': recent_feedback
        }
        
        serializer = FeedbackAnalyticsSerializer(data)
        return Response({
            'success': True,
            'data': serializer.data
        })


# ============================================================================
# Factor Template Management Views
# ============================================================================

class AdminFactorTemplateViewSet(viewsets.ModelViewSet):
    """
    ViewSet for admin factor template management.
    
    Endpoints:
    - GET /api/v1/admin/factor-templates
    - POST /api/v1/admin/factor-templates
    - GET /api/v1/admin/factor-templates/{id}
    - PUT /api/v1/admin/factor-templates/{id}
    - DELETE /api/v1/admin/factor-templates/{id}
    """
    serializer_class = AdminFactorTemplateSerializer
    permission_classes = [IsAuthenticated, IsAdmin]
    queryset = FactorTemplate.objects.all()
    
    def list(self, request, *args, **kwargs):
        queryset = self.filter_queryset(self.get_queryset())
        serializer = self.get_serializer(queryset, many=True)
        return Response({
            'success': True,
            'data': serializer.data
        })
    
    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response({
                'success': True,
                'message': 'Factor template created successfully',
                'data': serializer.data
            }, status=status.HTTP_201_CREATED)
        
        return Response({
            'success': False,
            'error': {
                'code': 'VALIDATION_ERROR',
                'message': 'Failed to create factor template',
                'details': serializer.errors
            }
        }, status=status.HTTP_400_BAD_REQUEST)
    
    def retrieve(self, request, *args, **kwargs):
        instance = self.get_object()
        serializer = self.get_serializer(instance)
        return Response({
            'success': True,
            'data': serializer.data
        })
    
    def update(self, request, *args, **kwargs):
        partial = kwargs.pop('partial', False)
        instance = self.get_object()
        serializer = self.get_serializer(instance, data=request.data, partial=partial)
        
        if serializer.is_valid():
            serializer.save()
            return Response({
                'success': True,
                'message': 'Factor template updated successfully',
                'data': serializer.data
            })
        
        return Response({
            'success': False,
            'error': {
                'code': 'VALIDATION_ERROR',
                'message': 'Failed to update factor template',
                'details': serializer.errors
            }
        }, status=status.HTTP_400_BAD_REQUEST)
    
    def destroy(self, request, *args, **kwargs):
        instance = self.get_object()
        instance.delete()
        return Response({
            'success': True,
            'message': 'Factor template deleted successfully'
        })


# ============================================================================
# AI Parameters Management Views
# ============================================================================

class AdminAIParameterListView(generics.ListAPIView):
    """
    GET /api/v1/admin/ai-parameters
    List all AI parameters (admin only).
    """
    serializer_class = AdminAIParametersSerializer
    permission_classes = [IsAuthenticated, IsAdmin]
    queryset = AIParameters.objects.all()
    
    def list(self, request, *args, **kwargs):
        queryset = self.filter_queryset(self.get_queryset())
        serializer = self.get_serializer(queryset, many=True)
        return Response({
            'success': True,
            'data': serializer.data
        })


class AdminAIParameterDetailView(APIView):
    """
    GET /api/v1/admin/ai-parameters/{key}
    PATCH /api/v1/admin/ai-parameters/{key}
    Get or update AI parameter by key (admin only).
    """
    permission_classes = [IsAuthenticated, IsAdmin]
    
    def get(self, request, key):
        param = get_object_or_404(AIParameters, key=key)
        serializer = AdminAIParametersSerializer(param)
        return Response({
            'success': True,
            'data': serializer.data
        })
    
    def patch(self, request, key):
        param = get_object_or_404(AIParameters, key=key)
        serializer = AdminAIParametersSerializer(param, data=request.data, partial=True)
        
        if serializer.is_valid():
            serializer.save()
            return Response({
                'success': True,
                'message': 'AI parameter updated successfully',
                'data': serializer.data
            })
        
        return Response({
            'success': False,
            'error': {
                'code': 'VALIDATION_ERROR',
                'message': 'Failed to update AI parameter',
                'details': serializer.errors
            }
        }, status=status.HTTP_400_BAD_REQUEST)


# ============================================================================
# Activity Logs View
# ============================================================================

class AdminLogsView(generics.ListAPIView):
    """
    GET /api/v1/admin/logs
    List activity logs (admin only).
    """
    serializer_class = AdminActivityLogSerializer
    permission_classes = [IsAuthenticated, IsAdmin]
    
    def get_queryset(self):
        queryset = ActivityLog.objects.all()
        
        # Filter by action type
        action = self.request.query_params.get('action')
        if action:
            queryset = queryset.filter(action=action.upper())
        
        # Filter by user
        user_id = self.request.query_params.get('user_id')
        if user_id:
            queryset = queryset.filter(user_id=user_id)
        
        # Filter by date range
        date_from = self.request.query_params.get('date_from')
        if date_from:
            queryset = queryset.filter(created_at__gte=date_from)
        
        date_to = self.request.query_params.get('date_to')
        if date_to:
            queryset = queryset.filter(created_at__lte=date_to)
        
        return queryset.select_related('user')
    
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
