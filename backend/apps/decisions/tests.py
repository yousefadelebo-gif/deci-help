from rest_framework import status
from rest_framework.test import APITestCase

from apps.accounts.models import User
from .models import Decision


class DecisionLifecycleTests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            email='owner@example.com',
            password='StrongPass123!',
            name='Owner',
        )
        self.other = User.objects.create_user(
            email='other@example.com',
            password='StrongPass123!',
            name='Other',
        )
        self._authenticate(self.user.email)

    def _authenticate(self, email):
        response = self.client.post(
            '/api/v1/auth/login/',
            {'email': email, 'password': 'StrongPass123!'},
            format='json',
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {response.data['access']}")

    def test_decision_lifecycle_and_status_integrity(self):
        create = self.client.post('/api/v1/decisions/', {'title': 'Pick laptop'}, format='json')
        self.assertEqual(create.status_code, status.HTTP_201_CREATED)
        decision_id = create.data['id']

        option1 = self.client.post(f'/api/v1/decisions/{decision_id}/options/', {'name': 'A'}, format='json')
        option2 = self.client.post(f'/api/v1/decisions/{decision_id}/options/', {'name': 'B'}, format='json')
        self.assertEqual(option1.status_code, status.HTTP_201_CREATED)
        self.assertEqual(option2.status_code, status.HTTP_201_CREATED)

        choose = self.client.post(
            f'/api/v1/decisions/{decision_id}/choose/',
            {'option_id': option1.data['id']},
            format='json',
        )
        self.assertEqual(choose.status_code, status.HTTP_200_OK)
        self.assertEqual(choose.data['decision']['status'], 'completed')

    def test_cannot_set_chosen_option_from_another_decision(self):
        first = self.client.post('/api/v1/decisions/', {'title': 'First'}, format='json').data
        second = self.client.post('/api/v1/decisions/', {'title': 'Second'}, format='json').data
        option = self.client.post(f"/api/v1/decisions/{second['id']}/options/", {'name': 'OtherOption'}, format='json').data

        update = self.client.patch(
            f"/api/v1/decisions/{first['id']}/",
            {'chosen_option': option['id']},
            format='json',
        )
        self.assertEqual(update.status_code, status.HTTP_400_BAD_REQUEST)

    def test_user_cannot_access_another_users_decision(self):
        mine = self.client.post('/api/v1/decisions/', {'title': 'Mine'}, format='json').data
        self._authenticate(self.other.email)
        response = self.client.get(f"/api/v1/decisions/{mine['id']}/")
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)
