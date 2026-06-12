from unittest.mock import patch

from rest_framework import status
from rest_framework.test import APITestCase

from apps.accounts.models import User
from apps.decisions.models import Decision, DecisionOption, DecisionFactor, FactorRating


class AIEndpointTests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            email='aiuser@example.com',
            password='StrongPass123!',
            name='AI User',
        )
        login = self.client.post(
            '/api/v1/auth/login/',
            {'email': 'aiuser@example.com', 'password': 'StrongPass123!'},
            format='json',
        )
        self.assertEqual(login.status_code, status.HTTP_200_OK)
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {login.data['access']}")

        self.decision = Decision.objects.create(user=self.user, title='Choose a job')
        self.option_a = DecisionOption.objects.create(decision=self.decision, name='Offer A', order=0)
        self.option_b = DecisionOption.objects.create(decision=self.decision, name='Offer B', order=1)
        self.factor = DecisionFactor.objects.create(decision=self.decision, name='Cost', weight=0.7)
        FactorRating.objects.create(decision_factor=self.factor, option=self.option_a, score=8)
        FactorRating.objects.create(decision_factor=self.factor, option=self.option_b, score=6)

    @patch('apps.ai_service.views.ai_service.generate_analysis_narrative')
    def test_analyze_endpoint_returns_success_and_updates_status(self, mock_narrative):
        mock_narrative.return_value = {
            'success': True,
            'recommendation': 0,
            'confidence': 0.8,
            'explanation': 'A is better',
            'insights': [],
            'considerations': [],
            'potential_risks': [],
            'option_scores': [{'index': 0, 'score': 0.8}, {'index': 1, 'score': 0.6}],
        }

        response = self.client.post(f'/api/v1/ai/analyze/{self.decision.id}/', {}, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.decision.refresh_from_db()
        self.assertEqual(self.decision.status, 'completed')

    def test_throttled_scope_is_defined_on_quick_analyze(self):
        from .views import QuickAnalyzeView

        self.assertEqual(getattr(QuickAnalyzeView, 'throttle_scope', None), 'ai')

    @patch('apps.ai_service.views.ai_service.suggest_options')
    def test_quick_analyze_suggest_options(self, mock_suggest_options):
        mock_suggest_options.return_value = {
            'success': True,
            'suggested_options': ['A', 'B', 'C'],
        }
        response = self.client.post(
            '/api/v1/ai/quick-analyze/',
            {'title': 'Choose laptop', 'request_type': 'suggest_options'},
            format='json',
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertTrue(response.data['success'])
        self.assertEqual(response.data['suggested_options'], ['A', 'B', 'C'])

    @patch('apps.ai_service.views.ai_service.suggest_factors')
    def test_quick_analyze_suggest_factors_returns_type_and_default_weight(self, mock_suggest_factors):
        mock_suggest_factors.return_value = {
            'success': True,
            'factors': [
                {
                    'name': 'Cost',
                    'description': 'Budget impact',
                    'type': 'con',
                    'default_weight': 0.8,
                    'suggested_weight': 0.8,
                }
            ],
        }
        response = self.client.post(
            '/api/v1/ai/quick-analyze/',
            {
                'title': 'Choose laptop',
                'request_type': 'suggest_factors',
                'options': ['A', 'B'],
            },
            format='json',
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['factors'][0]['type'], 'con')
        self.assertIn('default_weight', response.data['factors'][0])

    @patch('apps.ai_service.views.ai_service.generate_factor_ratings')
    def test_quick_analyze_generate_ratings(self, mock_generate_ratings):
        mock_generate_ratings.return_value = {
            'success': True,
            'ratings': [
                {'option_index': 0, 'factor_index': 0, 'score': 8},
                {'option_index': 1, 'factor_index': 0, 'score': 6},
            ],
        }
        response = self.client.post(
            '/api/v1/ai/quick-analyze/',
            {
                'title': 'Choose laptop',
                'request_type': 'generate_ratings',
                'options': [{'name': 'A'}, {'name': 'B'}],
                'factors': [{'name': 'Cost', 'type': 'con', 'weight': 0.8}],
            },
            format='json',
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertTrue(response.data['success'])
        self.assertEqual(len(response.data['ratings']), 2)

    @patch('apps.ai_service.views.ai_service.generate_analysis_narrative')
    def test_analyze_includes_documented_analysis_fields(self, mock_narrative):
        mock_narrative.return_value = {
            'success': True,
            'recommendation': 0,
            'confidence': 0.8,
            'summary': 'Pick A',
            'drivers': ['price'],
            'risks': ['supply'],
            'questions': ['delivery date?'],
            'option_scores': [{'index': 0, 'score': 0.8}],
        }
        response = self.client.post(f'/api/v1/ai/analyze/{self.decision.id}/', {}, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('summary', response.data)
        self.assertIn('drivers', response.data)
        self.assertIn('risks', response.data)
        self.assertIn('questions', response.data)
        self.assertIn('recommendation', response.data)
        self.assertIn('factor_breakdown', response.data)
        self.assertIn('scores', response.data)
        self.assertIn('percentages', response.data)
        self.assertIn('weights', response.data)
        self.assertIn('winner', response.data)

    @patch('apps.ai_service.views.ai_service.generate_ratings_and_analysis')
    def test_analyze_generates_ratings_when_missing(self, mock_combined):
        mock_combined.return_value = {
            'success': True,
            'recommendation': 0,
            'confidence': 0.7,
            'explanation': 'Option A wins',
            'insights': [],
            'considerations': [],
            'potential_risks': [],
            'ratings': [
                {'option_index': 0, 'factor_index': 0, 'score': 8},
                {'option_index': 1, 'factor_index': 0, 'score': 6},
            ],
        }
        decision = Decision.objects.create(user=self.user, title='No ratings decision')
        DecisionOption.objects.create(decision=decision, name='Option A', order=0)
        DecisionOption.objects.create(decision=decision, name='Option B', order=1)
        DecisionFactor.objects.create(decision=decision, name='Speed', weight=0.5)
        response = self.client.post(f'/api/v1/ai/analyze/{decision.id}/', {}, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertTrue(response.data['success'])
        self.assertEqual(FactorRating.objects.filter(decision_factor__decision=decision).count(), 2)
