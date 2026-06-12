"""
Views for Decisions App
"""

import logging

from rest_framework import generics, status, permissions
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.views import APIView
from django.shortcuts import get_object_or_404
from django.utils import timezone
from django.db.models import Count, Avg, Prefetch

from .models import Decision, DecisionOption, DecisionFactor, FactorRating, JournalEntry
from .serializers import (
    DecisionListSerializer, DecisionDetailSerializer, CreateDecisionSerializer,
    UpdateDecisionSerializer, DecisionOptionSerializer, DecisionFactorSerializer,
    FactorRatingSerializer, JournalEntrySerializer, ChooseOptionSerializer
)

logger = logging.getLogger(__name__)


class DecisionListCreateView(generics.ListCreateAPIView):
    """List all decisions or create a new decision"""
    
    permission_classes = [permissions.IsAuthenticated]
    
    def get_serializer_class(self):
        if self.request.method == 'POST':
            return CreateDecisionSerializer
        return DecisionListSerializer

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        decision = serializer.save()
        decision = Decision.objects.prefetch_related(
            'options',
            'decision_factors',
        ).get(pk=decision.pk)
        return Response(
            DecisionDetailSerializer(decision).data,
            status=status.HTTP_201_CREATED,
        )
    
    def get_queryset(self):
        queryset = Decision.objects.filter(user=self.request.user)
        queryset = queryset.select_related('chosen_option', 'ai_recommendation').prefetch_related(
            Prefetch('options'),
            Prefetch('decision_factors'),
            Prefetch('journal_entry'),
        )
        
        # Filter by status
        status_filter = self.request.query_params.get('status')
        if status_filter:
            queryset = queryset.filter(status=status_filter)
        
        # Filter by category
        category = self.request.query_params.get('category')
        if category:
            queryset = queryset.filter(category=category)
        
        # Search
        search = self.request.query_params.get('search')
        if search:
            queryset = queryset.filter(title__icontains=search)
        
        return queryset.order_by('-created_at')


class DecisionDetailView(generics.RetrieveUpdateDestroyAPIView):
    """Retrieve, update, or delete a decision"""
    
    permission_classes = [permissions.IsAuthenticated]
    
    def get_serializer_class(self):
        if self.request.method in ['PUT', 'PATCH']:
            return UpdateDecisionSerializer
        return DecisionDetailSerializer
    
    def get_queryset(self):
        return Decision.objects.filter(user=self.request.user)


class DecisionOptionsView(generics.ListCreateAPIView):
    """List or create options for a decision"""
    
    serializer_class = DecisionOptionSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        decision_id = self.kwargs.get('decision_id')
        decision = get_object_or_404(Decision, id=decision_id, user=self.request.user)
        return decision.options.all().order_by('order')
    
    def perform_create(self, serializer):
        decision_id = self.kwargs.get('decision_id')
        decision = get_object_or_404(Decision, id=decision_id, user=self.request.user)
        order = decision.options.count()
        serializer.save(decision=decision, order=order)


class DecisionOptionDetailView(generics.RetrieveUpdateDestroyAPIView):
    """Retrieve, update, or delete a decision option"""
    
    serializer_class = DecisionOptionSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        decision_id = self.kwargs.get('decision_id')
        decision = get_object_or_404(Decision, id=decision_id, user=self.request.user)
        return decision.options.all()


class DecisionFactorsView(generics.ListCreateAPIView):
    """List or create factors for a decision"""
    
    serializer_class = DecisionFactorSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        decision_id = self.kwargs.get('decision_id')
        decision = get_object_or_404(Decision, id=decision_id, user=self.request.user)
        return decision.decision_factors.all()
    
    def perform_create(self, serializer):
        decision_id = self.kwargs.get('decision_id')
        decision = get_object_or_404(Decision, id=decision_id, user=self.request.user)
        serializer.save(decision=decision)


class DecisionFactorDetailView(generics.RetrieveUpdateDestroyAPIView):
    """Retrieve, update, or delete a decision factor"""
    
    serializer_class = DecisionFactorSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        decision_id = self.kwargs.get('decision_id')
        decision = get_object_or_404(Decision, id=decision_id, user=self.request.user)
        return decision.decision_factors.all()


class FactorRatingView(APIView):
    """Create or update factor ratings"""
    
    permission_classes = [permissions.IsAuthenticated]
    
    def post(self, request, decision_id):
        """Create or update multiple factor ratings"""
        decision = get_object_or_404(Decision, id=decision_id, user=request.user)
        ratings_data = request.data.get('ratings', [])
        expected_ratings = decision.options.count() * decision.decision_factors.count()
        logger.info(
            "rating persistence decision_id=%s options=%s factors=%s received_ratings=%s expected_ratings=%s",
            decision_id,
            decision.options.count(),
            decision.decision_factors.count(),
            len(ratings_data),
            expected_ratings,
        )
        
        created_ratings = []
        for rating_data in ratings_data:
            factor_id = rating_data.get('factor_id')
            option_id = rating_data.get('option_id')
            score = rating_data.get('score')
            notes = rating_data.get('notes', '')
            
            factor = get_object_or_404(DecisionFactor, id=factor_id, decision=decision)
            option = get_object_or_404(DecisionOption, id=option_id, decision=decision)
            
            rating, created = FactorRating.objects.update_or_create(
                decision_factor=factor,
                option=option,
                defaults={'score': score, 'notes': notes}
            )
            created_ratings.append(FactorRatingSerializer(rating).data)
        
        return Response({'ratings': created_ratings}, status=status.HTTP_200_OK)


class ChooseOptionView(APIView):
    """Choose an option for a decision"""
    
    permission_classes = [permissions.IsAuthenticated]
    
    def post(self, request, decision_id):
        serializer = ChooseOptionSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        decision = get_object_or_404(Decision, id=decision_id, user=request.user)
        option = get_object_or_404(DecisionOption, id=serializer.validated_data['option_id'], decision=decision)
        
        decision.chosen_option = option
        decision.chosen_at = timezone.now()
        decision.status = 'completed'
        decision.save()
        
        return Response({
            'message': 'Option selected successfully',
            'decision': DecisionDetailSerializer(decision).data
        })


class JournalEntryView(generics.RetrieveUpdateAPIView, generics.CreateAPIView):
    """Get, create, or update journal entry for a decision"""
    
    serializer_class = JournalEntrySerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_object(self):
        decision_id = self.kwargs.get('decision_id')
        decision = get_object_or_404(Decision, id=decision_id, user=self.request.user)
        return get_object_or_404(JournalEntry, decision=decision)
    
    def perform_create(self, serializer):
        decision_id = self.kwargs.get('decision_id')
        decision = get_object_or_404(Decision, id=decision_id, user=self.request.user)
        serializer.save(decision=decision)
    
    def create(self, request, *args, **kwargs):
        decision_id = self.kwargs.get('decision_id')
        decision = get_object_or_404(Decision, id=decision_id, user=self.request.user)
        
        # Check if journal entry already exists
        if hasattr(decision, 'journal_entry'):
            return Response({'error': 'Journal entry already exists'}, status=status.HTTP_400_BAD_REQUEST)
        
        return super().create(request, *args, **kwargs)


class DecisionSatisfactionView(APIView):
    """Save satisfaction rating and feedback for a decision"""
    
    permission_classes = [permissions.IsAuthenticated]
    
    def post(self, request, decision_id):
        decision = get_object_or_404(Decision, id=decision_id, user=request.user)
        
        satisfaction = request.data.get('satisfaction')  # 1-5 rating
        comment = request.data.get('comment', '')
        
        if satisfaction is None:
            return Response(
                {'error': 'satisfaction field is required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            satisfaction = float(satisfaction)
            if satisfaction < 1 or satisfaction > 5:
                raise ValueError
        except (ValueError, TypeError):
            return Response(
                {'error': 'satisfaction must be a number between 1 and 5'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Create or update journal entry with satisfaction
        journal_entry, created = JournalEntry.objects.update_or_create(
            decision=decision,
            defaults={
                'satisfaction': satisfaction,
                'reflection': comment if comment else '',
            }
        )
        
        # Update decision status to completed if still in progress
        if decision.status in ('draft', 'in_progress', 'analyzing'):
            decision.status = 'completed'
            decision.save(update_fields=['status'])
        
        return Response({
            'message': 'Satisfaction saved successfully',
            'satisfaction': satisfaction,
            'journal_entry': JournalEntrySerializer(journal_entry).data,
            'decision_id': str(decision.id),
        }, status=status.HTTP_200_OK)


class DecisionAnalyticsView(APIView):
    """Get analytics for user's decisions"""
    
    permission_classes = [permissions.IsAuthenticated]
    
    def get(self, request):
        decisions = Decision.objects.filter(user=request.user)
        
        total = decisions.count()
        by_status = decisions.values('status').annotate(count=Count('id'))
        by_category = decisions.values('category').annotate(count=Count('id'))
        
        # Average confidence from AI analysis
        analyzed_decisions = decisions.exclude(ai_confidence__isnull=True)
        avg_confidence = analyzed_decisions.aggregate(avg=Avg('ai_confidence'))['avg'] or 0
        # ai_confidence is stored as 0-1 decimal, convert to percentage
        if avg_confidence > 0 and avg_confidence <= 1:
            avg_confidence = avg_confidence * 100
        
        # Satisfaction stats from journal entries
        journal_entries = JournalEntry.objects.filter(
            decision__user=request.user,
            satisfaction__isnull=False
        )
        avg_satisfaction = journal_entries.aggregate(avg=Avg('satisfaction'))['avg'] or 0.0
        
        # Pending count: decisions that are draft, in_progress, or analyzing
        pending_count = decisions.filter(
            status__in=['draft', 'in_progress', 'analyzing']
        ).count()
        
        # Completed count
        completed_count = decisions.filter(
            status='completed'
        ).count()
        
        return Response({
            'total_decisions': total,
            'average_confidence': round(avg_confidence, 1),
            'average_satisfaction': round(avg_satisfaction, 1),
            'pending_count': pending_count,
            'completed_decisions': completed_count,
            'by_status': {item['status']: item['count'] for item in by_status},
            'by_category': {item['category']: item['count'] for item in by_category if item['category']},
        })


class RecentDecisionsView(generics.ListAPIView):
    """Get recent decisions for dashboard"""
    
    serializer_class = DecisionListSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        return Decision.objects.filter(
            user=self.request.user
        ).order_by('-created_at')[:5]
