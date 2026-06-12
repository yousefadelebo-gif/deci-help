"""
Decision URL Configuration

Decision Companion - AI Decision Making System
"""

from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import DecisionViewSet, JournalListView, FactorTemplateListView

app_name = 'decisions'

router = DefaultRouter(trailing_slash=False)
router.register('decisions', DecisionViewSet, basename='decision')

urlpatterns = [
    # Journal endpoint
    path('journal', JournalListView.as_view(), name='journal-list'),
    
    # Factor templates (read-only for users)
    path('factor-templates', FactorTemplateListView.as_view(), name='factor-template-list'),
    
    # Router URLs (decisions and nested routes)
    path('', include(router.urls)),
]
