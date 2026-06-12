"""
URL Configuration for Factors App
"""

from django.urls import path
from . import views

app_name = 'factors'

urlpatterns = [
    # Categories
    path('categories/', views.FactorCategoryListView.as_view(), name='category-list'),
    path('categories/<uuid:pk>/', views.FactorCategoryDetailView.as_view(), name='category-detail'),
    
    # Templates
    path('templates/', views.FactorTemplateListView.as_view(), name='template-list'),
    path('templates/<uuid:pk>/', views.FactorTemplateDetailView.as_view(), name='template-detail'),
    path('templates/<uuid:pk>/use/', views.IncrementFactorUsageView.as_view(), name='template-use'),
    
    # Suggestions
    path('suggested/', views.SuggestedFactorsView.as_view(), name='suggested-factors'),
    path('popular/', views.PopularFactorsView.as_view(), name='popular-factors'),
    
    # User custom factors
    path('custom/', views.UserFactorTemplateListView.as_view(), name='user-factors'),
    path('custom/<uuid:pk>/', views.UserFactorTemplateDetailView.as_view(), name='user-factor-detail'),
]
