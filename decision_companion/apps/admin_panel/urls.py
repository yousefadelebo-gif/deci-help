"""
Admin Panel URL Configuration

Decision Companion - AI Decision Making System
"""

from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    AdminUserListView, AdminUserDetailView,
    UsageAnalyticsView, FeedbackAnalyticsView,
    AdminFactorTemplateViewSet, AdminAIParameterListView,
    AdminAIParameterDetailView, AdminLogsView
)

app_name = 'admin_panel'

router = DefaultRouter(trailing_slash=False)
router.register('admin/factor-templates', AdminFactorTemplateViewSet, basename='admin-factor-template')

urlpatterns = [
    # User management
    path('admin/users', AdminUserListView.as_view(), name='admin-user-list'),
    path('admin/users/<uuid:user_id>', AdminUserDetailView.as_view(), name='admin-user-detail'),
    
    # Analytics
    path('admin/analytics/usage', UsageAnalyticsView.as_view(), name='admin-usage-analytics'),
    path('admin/analytics/feedback', FeedbackAnalyticsView.as_view(), name='admin-feedback-analytics'),
    
    # AI Parameters
    path('admin/ai-parameters', AdminAIParameterListView.as_view(), name='admin-ai-parameters'),
    path('admin/ai-parameters/<str:key>', AdminAIParameterDetailView.as_view(), name='admin-ai-parameter-detail'),
    
    # Activity Logs
    path('admin/logs', AdminLogsView.as_view(), name='admin-logs'),
    
    # Router URLs
    path('', include(router.urls)),
]
