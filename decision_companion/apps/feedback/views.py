"""
Feedback Views

Decision Companion - AI Decision Making System
"""

from rest_framework import status, generics
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from rest_framework.views import APIView
from .models import Feedback
from .serializers import FeedbackSerializer, FeedbackCreateSerializer
from apps.core.utils import log_activity
from apps.core.models import ActivityLog


class FeedbackCreateView(APIView):
    """
    POST /api/v1/feedback
    Submit new feedback.
    """
    permission_classes = [IsAuthenticated]
    
    def post(self, request):
        serializer = FeedbackCreateSerializer(data=request.data)
        
        if serializer.is_valid():
            feedback = serializer.save(user=request.user)
            
            # Log activity
            log_activity(
                request.user,
                ActivityLog.ActionType.SUBMIT_FEEDBACK,
                f"Submitted feedback: {feedback.title}",
                request,
                {'feedback_id': str(feedback.id), 'rating': feedback.rating}
            )
            
            return Response({
                'success': True,
                'message': 'Feedback submitted successfully',
                'data': FeedbackSerializer(feedback).data
            }, status=status.HTTP_201_CREATED)
        
        return Response({
            'success': False,
            'error': {
                'code': 'VALIDATION_ERROR',
                'message': 'Failed to submit feedback',
                'details': serializer.errors
            }
        }, status=status.HTTP_400_BAD_REQUEST)


class MyFeedbackListView(generics.ListAPIView):
    """
    GET /api/v1/feedback/my
    List current user's feedback submissions.
    """
    serializer_class = FeedbackSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        return Feedback.objects.filter(user=self.request.user)
    
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
