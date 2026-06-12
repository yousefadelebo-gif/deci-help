"""
Core Views - Authentication and User Management

Decision Companion - AI Decision Making System
"""

from rest_framework import status, viewsets, generics
from rest_framework.decorators import api_view, permission_classes, action
from rest_framework.response import Response
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.views import APIView
from django.db.models import Avg
from .models import User, UserSettings, ActivityLog
from .serializers import (
    UserSerializer, UserDetailSerializer, RegisterSerializer,
    LoginSerializer, TokenSerializer, LogoutSerializer,
    UserSettingsSerializer, UserProfileUpdateSerializer,
    ChangePasswordSerializer, UserStatsSerializer
)
from .permissions import IsAdmin, IsOwnerOrAdmin
from .utils import log_activity


# ============================================================================
# Authentication Views
# ============================================================================

class RegisterView(APIView):
    """
    Register a new user.
    
    POST /api/v1/auth/register
    """
    permission_classes = [AllowAny]
    
    def post(self, request):
        serializer = RegisterSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.save()
            
            # Log activity
            log_activity(user, ActivityLog.ActionType.REGISTER, request=request)
            
            # Generate tokens
            tokens = TokenSerializer.get_tokens_for_user(user)
            
            return Response({
                'success': True,
                'message': 'Registration successful',
                'data': tokens
            }, status=status.HTTP_201_CREATED)
        
        return Response({
            'success': False,
            'error': {
                'code': 'VALIDATION_ERROR',
                'message': 'Registration failed',
                'details': serializer.errors
            }
        }, status=status.HTTP_400_BAD_REQUEST)


class LoginView(APIView):
    """
    Login user and return JWT tokens.
    
    POST /api/v1/auth/login
    """
    permission_classes = [AllowAny]
    
    def post(self, request):
        serializer = LoginSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.validated_data['user']
            
            # Log activity
            log_activity(user, ActivityLog.ActionType.LOGIN, request=request)
            
            # Generate tokens
            tokens = TokenSerializer.get_tokens_for_user(user)
            
            return Response({
                'success': True,
                'message': 'Login successful',
                'data': tokens
            }, status=status.HTTP_200_OK)
        
        return Response({
            'success': False,
            'error': {
                'code': 'AUTHENTICATION_ERROR',
                'message': 'Login failed',
                'details': serializer.errors
            }
        }, status=status.HTTP_401_UNAUTHORIZED)


class GuestLoginView(APIView):
    """
    Create and login as a guest user.
    
    POST /api/v1/auth/guest
    """
    permission_classes = [AllowAny]
    
    def post(self, request):
        # Create guest user
        user = User.objects.create_guest_user()
        
        # Create default settings
        UserSettings.objects.create(user=user)
        
        # Log activity
        log_activity(user, ActivityLog.ActionType.LOGIN, 'Guest login', request)
        
        # Generate tokens
        tokens = TokenSerializer.get_tokens_for_user(user)
        
        return Response({
            'success': True,
            'message': 'Guest login successful',
            'data': tokens
        }, status=status.HTTP_200_OK)


class CurrentUserView(APIView):
    """
    Get current authenticated user.
    
    GET /api/v1/auth/me
    """
    permission_classes = [IsAuthenticated]
    
    def get(self, request):
        serializer = UserDetailSerializer(request.user)
        return Response({
            'success': True,
            'data': serializer.data
        }, status=status.HTTP_200_OK)


class LogoutView(APIView):
    """
    Logout user by blacklisting refresh token.
    
    POST /api/v1/auth/logout
    """
    permission_classes = [IsAuthenticated]
    
    def post(self, request):
        serializer = LogoutSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            
            # Log activity
            log_activity(request.user, ActivityLog.ActionType.LOGOUT, request=request)
            
            return Response({
                'success': True,
                'message': 'Logout successful'
            }, status=status.HTTP_200_OK)
        
        return Response({
            'success': False,
            'error': {
                'code': 'LOGOUT_ERROR',
                'message': 'Logout failed',
                'details': serializer.errors
            }
        }, status=status.HTTP_400_BAD_REQUEST)


# ============================================================================
# User Profile Views
# ============================================================================

class UserProfileView(APIView):
    """
    Get and update current user profile.
    
    GET /api/v1/users/me
    PUT /api/v1/users/me
    """
    permission_classes = [IsAuthenticated]
    
    def get(self, request):
        serializer = UserDetailSerializer(request.user)
        return Response({
            'success': True,
            'data': serializer.data
        }, status=status.HTTP_200_OK)
    
    def put(self, request):
        serializer = UserProfileUpdateSerializer(
            request.user,
            data=request.data,
            partial=True
        )
        if serializer.is_valid():
            serializer.save()
            
            # Log activity
            log_activity(
                request.user,
                ActivityLog.ActionType.UPDATE_PROFILE,
                request=request
            )
            
            return Response({
                'success': True,
                'message': 'Profile updated successfully',
                'data': UserDetailSerializer(request.user).data
            }, status=status.HTTP_200_OK)
        
        return Response({
            'success': False,
            'error': {
                'code': 'VALIDATION_ERROR',
                'message': 'Profile update failed',
                'details': serializer.errors
            }
        }, status=status.HTTP_400_BAD_REQUEST)


class UserStatsView(APIView):
    """
    Get current user statistics.
    
    GET /api/v1/users/me/stats
    """
    permission_classes = [IsAuthenticated]
    
    def get(self, request):
        user = request.user
        
        # Import here to avoid circular imports
        from apps.decisions.models import Decision
        from apps.feedback.models import Feedback
        
        decisions = Decision.objects.filter(user=user)
        
        stats = {
            'total_decisions': decisions.count(),
            'analyzed_decisions': decisions.filter(status='ANALYZED').count(),
            'archived_decisions': decisions.filter(status='ARCHIVED').count(),
            'draft_decisions': decisions.filter(status='DRAFT').count(),
            'average_satisfaction': decisions.filter(
                satisfaction_rating__isnull=False
            ).aggregate(avg=Avg('satisfaction_rating'))['avg'],
            'total_feedback_submitted': Feedback.objects.filter(user=user).count(),
            'member_since': user.created_at
        }
        
        serializer = UserStatsSerializer(stats)
        
        return Response({
            'success': True,
            'data': serializer.data
        }, status=status.HTTP_200_OK)


class UserSettingsView(APIView):
    """
    Get and update user settings.
    
    GET /api/v1/users/me/settings
    PUT /api/v1/users/me/settings
    """
    permission_classes = [IsAuthenticated]
    
    def get(self, request):
        settings, created = UserSettings.objects.get_or_create(user=request.user)
        serializer = UserSettingsSerializer(settings)
        return Response({
            'success': True,
            'data': serializer.data
        }, status=status.HTTP_200_OK)
    
    def put(self, request):
        settings, created = UserSettings.objects.get_or_create(user=request.user)
        serializer = UserSettingsSerializer(settings, data=request.data, partial=True)
        
        if serializer.is_valid():
            serializer.save()
            
            # Log activity
            log_activity(
                request.user,
                ActivityLog.ActionType.UPDATE_SETTINGS,
                request=request
            )
            
            return Response({
                'success': True,
                'message': 'Settings updated successfully',
                'data': serializer.data
            }, status=status.HTTP_200_OK)
        
        return Response({
            'success': False,
            'error': {
                'code': 'VALIDATION_ERROR',
                'message': 'Settings update failed',
                'details': serializer.errors
            }
        }, status=status.HTTP_400_BAD_REQUEST)


class ChangePasswordView(APIView):
    """
    Change user password.
    
    POST /api/v1/users/me/change-password
    """
    permission_classes = [IsAuthenticated]
    
    def post(self, request):
        serializer = ChangePasswordSerializer(
            data=request.data,
            context={'request': request}
        )
        
        if serializer.is_valid():
            request.user.set_password(serializer.validated_data['new_password'])
            request.user.save()
            
            return Response({
                'success': True,
                'message': 'Password changed successfully'
            }, status=status.HTTP_200_OK)
        
        return Response({
            'success': False,
            'error': {
                'code': 'VALIDATION_ERROR',
                'message': 'Password change failed',
                'details': serializer.errors
            }
        }, status=status.HTTP_400_BAD_REQUEST)
