"""
Views for Accounts App
"""

from rest_framework import generics, status, permissions
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView
from rest_framework_simplejwt.tokens import RefreshToken
from django.contrib.auth import get_user_model
from django.db.models import Q, Count

from .serializers import (
    UserSerializer, RegisterSerializer, LoginSerializer,
    ChangePasswordSerializer, UpdateProfileSerializer, UserSettingsSerializer
)
from .models import UserSettings

User = get_user_model()


class RegisterView(generics.CreateAPIView):
    """User registration endpoint"""
    
    queryset = User.objects.all()
    serializer_class = RegisterSerializer
    permission_classes = [permissions.AllowAny]
    
    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()
        
        # Create user settings
        UserSettings.objects.create(user=user)
        
        # Generate tokens
        refresh = RefreshToken.for_user(user)
        
        return Response({
            'message': 'Registration successful',
            'user': UserSerializer(user).data,
            'tokens': {
                'refresh': str(refresh),
                'access': str(refresh.access_token),
            }
        }, status=status.HTTP_201_CREATED)


class LoginView(TokenObtainPairView):
    """User login endpoint"""
    
    serializer_class = LoginSerializer
    permission_classes = [permissions.AllowAny]


class LogoutView(APIView):
    """User logout endpoint - blacklist refresh token"""
    
    def post(self, request):
        try:
            refresh_token = request.data.get('refresh')
            if not refresh_token:
                return Response({'error': 'refresh token is required'}, status=status.HTTP_400_BAD_REQUEST)
            token = RefreshToken(refresh_token)
            token.blacklist()
            return Response({'message': 'Logout successful'}, status=status.HTTP_200_OK)
        except Exception:
            return Response({'error': 'Invalid refresh token'}, status=status.HTTP_400_BAD_REQUEST)


class ProfileView(generics.RetrieveUpdateAPIView):
    """Get and update user profile"""
    
    serializer_class = UserSerializer
    
    def get_object(self):
        return self.request.user
    
    def get_serializer_class(self):
        if self.request.method in ['PUT', 'PATCH']:
            return UpdateProfileSerializer
        return UserSerializer


class ChangePasswordView(generics.UpdateAPIView):
    """Change user password"""
    
    serializer_class = ChangePasswordSerializer
    
    def get_object(self):
        return self.request.user
    
    def update(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        user = self.get_object()
        user.set_password(serializer.validated_data['new_password'])
        user.save()
        
        return Response({'message': 'Password changed successfully'}, status=status.HTTP_200_OK)


class UserSettingsView(generics.RetrieveUpdateAPIView):
    """Get and update user settings"""
    
    serializer_class = UserSettingsSerializer
    
    def get_object(self):
        settings, created = UserSettings.objects.get_or_create(user=self.request.user)
        return settings


class DeleteAccountView(APIView):
    """Delete user account"""
    
    def delete(self, request):
        user = request.user
        user.delete()
        return Response({'message': 'Account deleted successfully'}, status=status.HTTP_200_OK)


class AdminStatsView(APIView):
    """Admin dashboard statistics endpoint"""
    
    permission_classes = [permissions.IsAdminUser]
    
    def get(self, request):
        from django.utils import timezone
        from datetime import timedelta
        from django.db.models import Count, Avg
        from django.db.models.functions import TruncDate
        from apps.decisions.models import Decision
        from apps.feedback.models import AppRating
        
        today = timezone.now().date()
        week_ago = today - timedelta(days=7)
        month_ago = today - timedelta(days=30)
        
        # User stats - use created_at instead of date_joined
        total_users = User.objects.count()
        users_today = User.objects.filter(last_login_at__date=today).count()
        new_users_this_month = User.objects.filter(created_at__date__gte=month_ago).count()
        new_users_last_month = User.objects.filter(
            created_at__date__gte=month_ago - timedelta(days=30),
            created_at__date__lt=month_ago
        ).count()
        
        # Calculate user growth percentage
        if new_users_last_month > 0:
            user_growth = ((new_users_this_month - new_users_last_month) / new_users_last_month) * 100
        else:
            user_growth = 100 if new_users_this_month > 0 else 0
        
        # Decision stats
        total_decisions = Decision.objects.count()
        decisions_this_month = Decision.objects.filter(created_at__date__gte=month_ago).count()
        decisions_last_month = Decision.objects.filter(
            created_at__date__gte=month_ago - timedelta(days=30),
            created_at__date__lt=month_ago
        ).count()
        
        # Calculate decision growth percentage
        if decisions_last_month > 0:
            decision_growth = ((decisions_this_month - decisions_last_month) / decisions_last_month) * 100
        else:
            decision_growth = 100 if decisions_this_month > 0 else 0
        
        # Weekly activity (last 7 days)
        weekly_activity = []
        for i in range(6, -1, -1):
            day = today - timedelta(days=i)
            day_name = day.strftime('%a')
            count = Decision.objects.filter(created_at__date=day).count()
            weekly_activity.append({
                'day': day_name,
                'count': count,
            })
        
        # Decision categories distribution
        categories = Decision.objects.values('category').annotate(
            count=Count('id')
        ).order_by('-count')[:4]
        
        category_map = {
            'career': 'Career',
            'education': 'Education', 
            'finance': 'Finance',
            'lifestyle': 'Lifestyle',
            'health': 'Health',
            'relationship': 'Relationship',
        }
        
        total_categorized = sum(c['count'] for c in categories)
        decision_categories = []
        for cat in categories:
            cat_name = category_map.get(cat['category'], cat['category'] or 'Other')
            percentage = round((cat['count'] / total_categorized * 100) if total_categorized > 0 else 0)
            decision_categories.append({
                'name': cat_name,
                'count': cat['count'],
                'percentage': percentage,
            })
        
        # Rating stats
        avg_rating = AppRating.objects.aggregate(avg=Avg('rating'))['avg'] or 4.5
        
        # Recent users (last 10) - use created_at and name instead of date_joined and first_name/last_name
        recent_users = User.objects.order_by('-created_at')[:10].values(
            'id', 'email', 'name', 'created_at', 'last_login_at'
        )
        
        recent_users_list = []
        for u in recent_users:
            user_decisions = Decision.objects.filter(user_id=u['id']).count()
            recent_users_list.append({
                'id': str(u['id']),
                'email': u['email'],
                'name': u['name'] or u['email'].split('@')[0],
                'decisions': user_decisions,
                'joined': u['created_at'].isoformat() if u['created_at'] else None,
                'last_login': u['last_login_at'].isoformat() if u['last_login_at'] else None,
            })
        
        return Response({
            'total_users': total_users,
            'active_today': users_today,
            'user_growth': round(user_growth, 1),
            'total_decisions': total_decisions,
            'decision_growth': round(decision_growth, 1),
            'avg_rating': round(avg_rating, 1),
            'weekly_activity': weekly_activity,
            'decision_categories': decision_categories,
            'recent_users': recent_users_list,
        })


class AdminUsersListView(APIView):
    """Admin endpoint to get all users with full details"""
    
    permission_classes = [permissions.IsAdminUser]
    
    def get(self, request):
        from django.utils import timezone
        from datetime import timedelta
        
        # Get query parameters
        search = request.query_params.get('search', '')
        status_filter = request.query_params.get('status', 'all')
        
        # Get all users with decision counts in one query
        users_qs = User.objects.all().annotate(decision_count=Count('decisions')).order_by('-created_at')
        
        # Apply search filter
        if search:
            users_qs = users_qs.filter(
                Q(email__icontains=search) | 
                Q(name__icontains=search)
            )
        
        # Apply status filter
        if status_filter == 'active':
            users_qs = users_qs.filter(is_active=True)
        elif status_filter == 'inactive':
            # Inactive = not logged in for 30+ days
            threshold = timezone.now() - timedelta(days=30)
            users_qs = users_qs.filter(
                Q(last_login_at__lt=threshold) | 
                Q(last_login_at__isnull=True)
            )
        elif status_filter == 'suspended':
            users_qs = users_qs.filter(is_active=False)
        
        users_list = []
        now = timezone.now()
        
        for user in users_qs:
            # Calculate last active
            if user.last_login_at:
                delta = now - user.last_login_at
                if delta.days == 0:
                    if delta.seconds < 3600:
                        last_active = f"{delta.seconds // 60} minutes ago"
                    else:
                        last_active = f"{delta.seconds // 3600} hours ago"
                elif delta.days == 1:
                    last_active = "1 day ago"
                elif delta.days < 7:
                    last_active = f"{delta.days} days ago"
                elif delta.days < 30:
                    last_active = f"{delta.days // 7} weeks ago"
                else:
                    last_active = f"{delta.days // 30} months ago"
            else:
                last_active = "Never"
            
            # Determine status
            if not user.is_active:
                user_status = "Suspended"
            elif user.last_login_at and (now - user.last_login_at).days < 30:
                user_status = "Active"
            else:
                user_status = "Inactive"
            
            users_list.append({
                'id': str(user.id),
                'name': user.name or user.email.split('@')[0],
                'email': user.email,
                'avatar': (user.name[0].upper() if user.name else user.email[0].upper()),
                'status': user_status,
                'decisions': user.decision_count,
                'join_date': user.created_at.strftime('%b %d, %Y') if user.created_at else None,
                'last_active': last_active,
                'is_staff': user.is_staff,
                'is_verified': user.is_verified,
            })
        
        # Count stats
        total = len(users_list)
        active_count = len([u for u in users_list if u['status'] == 'Active'])
        inactive_count = len([u for u in users_list if u['status'] == 'Inactive'])
        suspended_count = len([u for u in users_list if u['status'] == 'Suspended'])
        
        return Response({
            'users': users_list,
            'stats': {
                'total': total,
                'active': active_count,
                'inactive': inactive_count,
                'suspended': suspended_count,
            }
        })
