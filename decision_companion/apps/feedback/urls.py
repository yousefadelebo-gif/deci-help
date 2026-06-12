"""
Feedback URL Configuration

Decision Companion - AI Decision Making System
"""

from django.urls import path
from .views import FeedbackCreateView, MyFeedbackListView

app_name = 'feedback'

urlpatterns = [
    path('feedback', FeedbackCreateView.as_view(), name='feedback-create'),
    path('feedback/my', MyFeedbackListView.as_view(), name='my-feedback'),
]
