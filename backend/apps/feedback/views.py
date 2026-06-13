"""
Views for Feedback App
"""

from rest_framework import generics, status, permissions
from rest_framework.response import Response
from rest_framework.views import APIView
from django.db.models import Count, Avg
from django.utils import timezone
from datetime import timedelta

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
        queryset = UserFeedback.objects.select_related('user').all()
        
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
        days = request.query_params.get('days')
        queryset = UserFeedback.objects.all()
        ratings_queryset = AppRating.objects.all()
        ai_queryset = AIFeedback.objects.all()
        if days:
            try:
                since = timezone.now() - timedelta(days=int(days))
                queryset = queryset.filter(created_at__gte=since)
                ratings_queryset = ratings_queryset.filter(created_at__gte=since)
                ai_queryset = ai_queryset.filter(created_at__gte=since)
            except (TypeError, ValueError):
                pass

        total = UserFeedback.objects.count()
        period_total = queryset.count()
        
        by_category = dict(
            queryset.values('category').annotate(
                count=Count('id')
            ).values_list('category', 'count')
        )
        
        by_status = dict(
            queryset.values('status').annotate(
                count=Count('id')
            ).values_list('status', 'count')
        )
        
        combined_rating_values = [
            *ratings_queryset.values_list('rating', flat=True),
            *queryset.exclude(rating__isnull=True).values_list('rating', flat=True),
        ]
        avg_rating = (
            sum(combined_rating_values) / len(combined_rating_values)
            if combined_rating_values else 0
        )
        
        # AI helpfulness
        ai_total = ai_queryset.count()
        ai_helpful = ai_queryset.filter(was_helpful=True).count()
        ai_rate = (ai_helpful / ai_total * 100) if ai_total > 0 else 0
        
        # Calculate positive percentage (4+ stars)
        total_ratings = len(combined_rating_values)
        positive_ratings = len([rating for rating in combined_rating_values if rating >= 4])
        positive_percent = (positive_ratings / total_ratings * 100) if total_ratings > 0 else 0

        rating_distribution = []
        for stars in range(5, 0, -1):
            count = len([rating for rating in combined_rating_values if int(rating) == stars])
            rating_distribution.append({
                'stars': stars,
                'count': count,
                'percentage': round((count / total_ratings) if total_ratings else 0, 4),
            })

        trends = []
        for i in range(3, -1, -1):
            end = timezone.now() - timedelta(days=i * 7)
            start = end - timedelta(days=7)
            feedback_ratings = list(
                UserFeedback.objects.filter(
                    created_at__gte=start,
                    created_at__lt=end,
                    rating__isnull=False,
                ).values_list('rating', flat=True)
            )
            app_ratings = list(
                AppRating.objects.filter(
                    created_at__gte=start,
                    created_at__lt=end,
                ).values_list('rating', flat=True)
            )
            values = feedback_ratings + app_ratings
            trends.append({
                'label': f'W{4 - i}',
                'average_rating': round((sum(values) / len(values)) if values else 0, 2),
                'count': len(values),
            })

        category_summary = []
        category_labels = dict(UserFeedback.CATEGORY_CHOICES)
        for category, count in by_category.items():
            category_qs = queryset.filter(category=category)
            category_ratings = list(
                category_qs.exclude(rating__isnull=True).values_list('rating', flat=True)
            )
            category_summary.append({
                'category': category,
                'label': category_labels.get(category, category or 'Other'),
                'count': count,
                'average_rating': round(
                    (sum(category_ratings) / len(category_ratings))
                    if category_ratings else 0,
                    2,
                ),
            })

        recent_feedback = UserFeedbackAdminSerializer(
            queryset.select_related('user').order_by('-created_at')[:10],
            many=True,
        ).data
        
        return Response({
            'total_count': total,
            'total_feedback': total,
            'period_feedback': period_total,
            'by_category': by_category,
            'by_status': by_status,
            'average_rating': round(avg_rating, 2),
            'positive_percentage': round(positive_percent),
            'ai_helpfulness_rate': round(ai_rate, 2),
            'total_ai_feedbacks': ai_total,
            'total_app_ratings': total_ratings,
            'rating_distribution': rating_distribution,
            'trends': trends,
            'category_summary': category_summary,
            'recent_feedback': recent_feedback,
        })
