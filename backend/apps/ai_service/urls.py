"""
URL Configuration for AI Service App
"""

from django.urls import path
from . import views

app_name = 'ai_service'

urlpatterns = [
    # AI Status
    path('status/', views.AIStatusView.as_view(), name='ai-status'),
    
    # Decision Analysis
    path('analyze/<uuid:decision_id>/', views.AnalyzeDecisionView.as_view(), name='analyze-decision'),
    path('quick-analyze/', views.QuickAnalyzeView.as_view(), name='quick-analyze'),
    
    # AI Suggestions
    path('suggest-factors/<uuid:decision_id>/', views.SuggestFactorsView.as_view(), name='suggest-factors'),
    path('generate-pros-cons/<uuid:decision_id>/<uuid:option_id>/', views.GenerateProsConsView.as_view(), name='generate-pros-cons'),
    path('insights/<uuid:decision_id>/', views.GetInsightsView.as_view(), name='get-insights'),
]
