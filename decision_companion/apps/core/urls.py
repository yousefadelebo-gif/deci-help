"""
Core URL Configuration

Decision Companion - AI Decision Making System
"""

from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView
from .views import (
    RegisterView, LoginView, GuestLoginView, CurrentUserView, LogoutView,
    UserProfileView, UserStatsView, UserSettingsView, ChangePasswordView
)

app_name = 'core'

urlpatterns = [
    # Authentication endpoints
    path('auth/register', RegisterView.as_view(), name='register'),
    path('auth/login', LoginView.as_view(), name='login'),
    path('auth/guest', GuestLoginView.as_view(), name='guest-login'),
    path('auth/me', CurrentUserView.as_view(), name='current-user'),
    path('auth/logout', LogoutView.as_view(), name='logout'),
    path('auth/token/refresh', TokenRefreshView.as_view(), name='token-refresh'),
    
    # User profile endpoints
    path('users/me', UserProfileView.as_view(), name='user-profile'),
    path('users/me/stats', UserStatsView.as_view(), name='user-stats'),
    path('users/me/settings', UserSettingsView.as_view(), name='user-settings'),
    path('users/me/change-password', ChangePasswordView.as_view(), name='change-password'),
]
