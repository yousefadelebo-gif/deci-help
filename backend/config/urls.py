"""
URL Configuration for Decision Companion Backend
"""

from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static
from rest_framework import permissions
from drf_yasg.views import get_schema_view
from drf_yasg import openapi

# API Documentation
schema_view = get_schema_view(
    openapi.Info(
        title="Decision Companion API",
        default_version='v1',
        description="AI-Powered Decision Making API",
        terms_of_service="https://www.decisioncompanion.com/terms/",
        contact=openapi.Contact(email="support@decisioncompanion.com"),
        license=openapi.License(name="MIT License"),
    ),
    public=True,
    permission_classes=[permissions.AllowAny],
)

urlpatterns = [
    # Admin
    path('admin/', admin.site.urls),
    
    # API Documentation
    path('swagger/', schema_view.with_ui('swagger', cache_timeout=0), name='schema-swagger-ui'),
    path('redoc/', schema_view.with_ui('redoc', cache_timeout=0), name='schema-redoc'),
    
    # API Endpoints
    path('api/v1/auth/', include('apps.accounts.urls')),
    path('api/v1/decisions/', include('apps.decisions.urls')),
    path('api/v1/factors/', include('apps.factors.urls')),
    path('api/v1/feedback/', include('apps.feedback.urls')),
    path('api/v1/ai/', include('apps.ai_service.urls')),
]

# Serve media files in development
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
