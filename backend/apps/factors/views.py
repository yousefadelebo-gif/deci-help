"""
Views for Factors App
"""

from rest_framework import generics, status, permissions
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.views import APIView
from django.db.models import F

from .models import FactorCategory, FactorTemplate, UserFactorTemplate
from .serializers import (
    FactorCategorySerializer, FactorCategoryListSerializer,
    FactorTemplateSerializer, UserFactorTemplateSerializer
)


class FactorCategoryListView(generics.ListAPIView):
    """List all factor categories"""
    
    serializer_class = FactorCategoryListSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        return FactorCategory.objects.filter(is_active=True).order_by('order')


class FactorCategoryDetailView(generics.RetrieveAPIView):
    """Get category with all its templates"""
    
    serializer_class = FactorCategorySerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        return FactorCategory.objects.filter(is_active=True)


class FactorTemplateListView(generics.ListAPIView):
    """List all factor templates"""
    
    serializer_class = FactorTemplateSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        queryset = FactorTemplate.objects.filter(is_active=True)
        
        # Filter by category
        category_id = self.request.query_params.get('category')
        if category_id:
            queryset = queryset.filter(category_id=category_id)
        
        # Search
        search = self.request.query_params.get('search')
        if search:
            queryset = queryset.filter(name__icontains=search)
        
        return queryset


class FactorTemplateDetailView(generics.RetrieveAPIView):
    """Get a single factor template"""
    
    serializer_class = FactorTemplateSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        return FactorTemplate.objects.filter(is_active=True)


class SuggestedFactorsView(APIView):
    """Get AI-suggested factors for a decision category"""
    
    permission_classes = [permissions.IsAuthenticated]
    
    def get(self, request):
        decision_category = request.query_params.get('category', '')
        
        # Get factors that are suggested for this category
        suggested = FactorTemplate.objects.filter(
            is_active=True,
            ai_suggested_for__contains=[decision_category]
        ).order_by('-usage_count')[:10]
        
        # Also get popular factors
        popular = FactorTemplate.objects.filter(
            is_active=True
        ).order_by('-usage_count')[:10]
        
        return Response({
            'suggested': FactorTemplateSerializer(suggested, many=True).data,
            'popular': FactorTemplateSerializer(popular, many=True).data
        })


class UserFactorTemplateListView(generics.ListCreateAPIView):
    """List and create user's custom factor templates"""
    
    serializer_class = UserFactorTemplateSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        return UserFactorTemplate.objects.filter(user=self.request.user)
    
    def perform_create(self, serializer):
        serializer.save(user=self.request.user)


class UserFactorTemplateDetailView(generics.RetrieveUpdateDestroyAPIView):
    """Get, update, or delete a user's custom factor template"""
    
    serializer_class = UserFactorTemplateSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        return UserFactorTemplate.objects.filter(user=self.request.user)


class IncrementFactorUsageView(APIView):
    """Increment usage count when a factor is used"""
    
    permission_classes = [permissions.IsAuthenticated]
    
    def post(self, request, pk):
        try:
            factor = FactorTemplate.objects.get(pk=pk, is_active=True)
            factor.usage_count = F('usage_count') + 1
            factor.save()
            factor.refresh_from_db()
            return Response({'usage_count': factor.usage_count})
        except FactorTemplate.DoesNotExist:
            # Try user factor
            try:
                user_factor = UserFactorTemplate.objects.get(pk=pk, user=request.user)
                user_factor.usage_count = F('usage_count') + 1
                user_factor.save()
                user_factor.refresh_from_db()
                return Response({'usage_count': user_factor.usage_count})
            except UserFactorTemplate.DoesNotExist:
                return Response({'error': 'Factor not found'}, status=status.HTTP_404_NOT_FOUND)


class PopularFactorsView(generics.ListAPIView):
    """Get most popular factors"""
    
    serializer_class = FactorTemplateSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        return FactorTemplate.objects.filter(
            is_active=True
        ).order_by('-usage_count')[:20]
