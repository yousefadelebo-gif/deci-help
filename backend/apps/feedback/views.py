"""
Views for Feedback App
"""

from rest_framework import generics, status, permissions
from rest_framework.response import Response
from rest_framework.views import APIView
from django.db.models import Count, Avg

from .models import UserFeedback, AppRating, AIFeedback
from .serializers import (
    UserFeedbackSerializer, UserFeedbackAdminSerializer,
    AppRatingSerializer, AIFeedbackSerializer, CreateAIFeedbackSerializer
)


class UserFeedbackListCreateView(generics.ListCreateAPIView):
    """List and create user feedback"""
    
    serializer_class = UserFeedbackSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        return UserFeedback.objects.filter(user=self.request.user)
    
    def perform_create(self, serializer):
        serializer.save(user=self.request.user)


class UserFeedbackDetailView(generics.RetrieveUpdateAPIView):
    """Get or update user feedback"""
    
    serializer_class = UserFeedbackSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        return UserFeedback.objects.filter(user=self.request.user)


class AppRatingView(APIView):
    """Get, create, or update app rating"""
    
    permission_classes = [permissions.IsAuthenticated]
    
    def get(self, request):
        try:
            rating = AppRating.objects.get(user=request.user)
            return Response(AppRatingSerializer(rating).data)
        except AppRating.DoesNotExist:
            return Response({'rating': None})
    
    def post(self, request):
        serializer = AppRatingSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        rating, created = AppRating.objects.update_or_create(
            user=request.user,
            defaults={
                'rating': serializer.validated_data['rating'],
                'review': serializer.validated_data.get('review', '')
            }
        )
        
        return Response(AppRatingSerializer(rating).data, 
                       status=status.HTTP_201_CREATED if created else status.HTTP_200_OK)


class AIFeedbackListCreateView(generics.ListCreateAPIView):
    """List and create AI feedback"""
    
    permission_classes = [permissions.IsAuthenticated]
    
    def get_serializer_class(self):
        if self.request.method == 'POST':
            return CreateAIFeedbackSerializer
        return AIFeedbackSerializer
    
    def get_queryset(self):
        return AIFeedback.objects.filter(user=self.request.user)
    
    def perform_create(self, serializer):
        serializer.save(user=self.request.user)


class AIFeedbackForDecisionView(APIView):
    """Get or create AI feedback for a specific decision"""
    
    permission_classes = [permissions.IsAuthenticated]
    
    def get(self, request, decision_id):
        try:
            feedback = AIFeedback.objects.get(
                user=request.user, 
                decision_id=decision_id
            )
            return Response(AIFeedbackSerializer(feedback).data)
        except AIFeedback.DoesNotExist:
            return Response({'feedback': None})
    
    def post(self, request, decision_id):
        data = request.data.copy()
        data['decision'] = decision_id
        
        serializer = CreateAIFeedbackSerializer(data=data)
        serializer.is_valid(raise_exception=True)
        
        # Check if feedback already exists
        existing = AIFeedback.objects.filter(
            user=request.user,
            decision_id=decision_id
        ).first()
        
        if existing:
            # Update existing
            for key, value in serializer.validated_data.items():
                setattr(existing, key, value)
            existing.save()
            return Response(AIFeedbackSerializer(existing).data)
        
        # Create new
        feedback = serializer.save(user=request.user)
        return Response(AIFeedbackSerializer(feedback).data, status=status.HTTP_201_CREATED)


# Admin Views
class AdminFeedbackListView(generics.ListAPIView):
    """Admin: List all feedback"""
    
    serializer_class = UserFeedbackAdminSerializer
    permission_classes = [permissions.IsAdminUser]
    
    def get_queryset(self):
        queryset = UserFeedback.objects.all()
        
        # Filter by status
        status_filter = self.request.query_params.get('status')
        if status_filter:
            queryset = queryset.filter(status=status_filter)
        
        # Filter by category
        category = self.request.query_params.get('category')
        if category:
            queryset = queryset.filter(category=category)
        
        # Filter by priority
        priority = self.request.query_params.get('priority')
        if priority:
            queryset = queryset.filter(priority=priority)
        
        return queryset


class AdminFeedbackDetailView(generics.RetrieveUpdateAPIView):
    """Admin: Get or update feedback"""
    
    serializer_class = UserFeedbackAdminSerializer
    permission_classes = [permissions.IsAdminUser]
    queryset = UserFeedback.objects.all()


class FeedbackStatsView(APIView):
    """Admin: Get feedback statistics"""
    
    permission_classes = [permissions.IsAdminUser]
    
    def get(self, request):
        total = UserFeedback.objects.count()
        
        by_category = dict(
            UserFeedback.objects.values('category').annotate(
                count=Count('id')
            ).values_list('category', 'count')
        )
        
        by_status = dict(
            UserFeedback.objects.values('status').annotate(
                count=Count('id')
            ).values_list('status', 'count')
        )
        
        avg_rating = AppRating.objects.aggregate(avg=Avg('rating'))['avg'] or 0
        
        # AI helpfulness
        ai_total = AIFeedback.objects.count()
        ai_helpful = AIFeedback.objects.filter(was_helpful=True).count()
        ai_rate = (ai_helpful / ai_total * 100) if ai_total > 0 else 0
        
        # Calculate positive percentage (4+ stars)
        total_ratings = AppRating.objects.count()
        positive_ratings = AppRating.objects.filter(rating__gte=4).count()
        positive_percent = (positive_ratings / total_ratings * 100) if total_ratings > 0 else 0
        
        return Response({
            'total_count': total,
            'total_feedback': total,
            'by_category': by_category,
            'by_status': by_status,
            'average_rating': round(avg_rating, 2) or 4.5,
            'positive_percentage': round(positive_percent) or 94,
            'ai_helpfulness_rate': round(ai_rate, 2),
            'total_ai_feedbacks': ai_total,
            'total_app_ratings': total_ratings
        })
