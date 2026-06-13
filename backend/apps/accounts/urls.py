"""
URL Routes for Accounts App
"""

from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView

from .views import (
    RegisterView, LoginView, LogoutView, ProfileView,
    ChangePasswordView, UserSettingsView, DeleteAccountView,
    AdminStatsView, AdminUsersListView, AdminUserAnalyticsView
)

urlpatterns = [
    # Authentication
    path('register/', RegisterView.as_view(), name='register'),
    path('login/', LoginView.as_view(), name='login'),
    path('logout/', LogoutView.as_view(), name='logout'),
    path('token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    
    # Profile
    path('profile/', ProfileView.as_view(), name='profile'),
    path('change-password/', ChangePasswordView.as_view(), name='change_password'),
    path('settings/', UserSettingsView.as_view(), name='user_settings'),
    path('delete-account/', DeleteAccountView.as_view(), name='delete_account'),
    
    # Admin
    path('admin/stats/', AdminStatsView.as_view(), name='admin_stats'),
    path('admin/user-analytics/', AdminUserAnalyticsView.as_view(), name='admin_user_analytics'),
    path('admin/users/', AdminUsersListView.as_view(), name='admin_users'),
]
