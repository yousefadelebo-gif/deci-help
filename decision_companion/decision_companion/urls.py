"""
URL configuration for decision_companion project.

Decision Companion - AI Decision Making System
API versioning: /api/v1/
"""

from django.contrib import admin
from django.urls import path, include

urlpatterns = [
    # Django Admin
    path('admin/', admin.site.urls),
    
    # API v1 endpoints
    path('api/v1/', include('apps.core.urls')),
    path('api/v1/', include('apps.decisions.urls')),
    path('api/v1/', include('apps.feedback.urls')),
    path('api/v1/', include('apps.admin_panel.urls')),
]
