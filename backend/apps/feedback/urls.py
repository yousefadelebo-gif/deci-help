"""
URL Configuration for Feedback App
"""

from django.urls import path
from . import views

app_name = 'feedback'

urlpatterns = [
    # User feedback
    path('', views.UserFeedbackListCreateView.as_view(), name='feedback-list-create'),
    path('<uuid:pk>/', views.UserFeedbackDetailView.as_view(), name='feedback-detail'),
    
    # App rating
    path('rating/', views.AppRatingView.as_view(), name='app-rating'),
    
    # AI feedback
    path('ai/', views.AIFeedbackListCreateView.as_view(), name='ai-feedback-list'),
    path('ai/decision/<uuid:decision_id>/', views.AIFeedbackForDecisionView.as_view(), name='ai-feedback-decision'),
    
    # Admin endpoints
    path('admin/list/', views.AdminFeedbackListView.as_view(), name='admin-feedback-list'),
    path('admin/<uuid:pk>/', views.AdminFeedbackDetailView.as_view(), name='admin-feedback-detail'),
    path('admin/stats/', views.FeedbackStatsView.as_view(), name='feedback-stats'),
]
