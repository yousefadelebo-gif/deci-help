"""
URL Configuration for Decisions App
"""

from django.urls import path
from . import views

app_name = 'decisions'

urlpatterns = [
    # Decisions
    path('', views.DecisionListCreateView.as_view(), name='decision-list-create'),
    path('<uuid:pk>/', views.DecisionDetailView.as_view(), name='decision-detail'),
    
    # Options
    path('<uuid:decision_id>/options/', views.DecisionOptionsView.as_view(), name='decision-options'),
    path('<uuid:decision_id>/options/<uuid:pk>/', views.DecisionOptionDetailView.as_view(), name='option-detail'),
    
    # Factors
    path('<uuid:decision_id>/factors/', views.DecisionFactorsView.as_view(), name='decision-factors'),
    path('<uuid:decision_id>/factors/<uuid:pk>/', views.DecisionFactorDetailView.as_view(), name='factor-detail'),
    
    # Ratings
    path('<uuid:decision_id>/ratings/', views.FactorRatingView.as_view(), name='factor-ratings'),
    
    # Choose option
    path('<uuid:decision_id>/choose/', views.ChooseOptionView.as_view(), name='choose-option'),
    
    # Journal
    path('<uuid:decision_id>/journal/', views.JournalEntryView.as_view(), name='journal-entry'),
    
    # Satisfaction
    path('<uuid:decision_id>/satisfaction/', views.DecisionSatisfactionView.as_view(), name='decision-satisfaction'),
    
    # Analytics
    path('analytics/', views.DecisionAnalyticsView.as_view(), name='decision-analytics'),
    path('recent/', views.RecentDecisionsView.as_view(), name='recent-decisions'),
]
