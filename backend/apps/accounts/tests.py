from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase

from .models import User


class AuthAndAdminSecurityTests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            email='user@example.com',
            password='StrongPass123!',
            name='Regular User',
        )
        self.admin = User.objects.create_user(
            email='admin@example.com',
            password='StrongPass123!',
            name='Admin User',
            is_staff=True,
        )

    def _login(self, email, password):
        response = self.client.post('/api/v1/auth/login/', {'email': email, 'password': password}, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        return response.data['access'], response.data['refresh']

    def test_logout_blacklists_refresh_token(self):
        access, refresh = self._login('user@example.com', 'StrongPass123!')
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {access}')

        logout = self.client.post('/api/v1/auth/logout/', {'refresh': refresh}, format='json')
        self.assertEqual(logout.status_code, status.HTTP_200_OK)

        refresh_attempt = self.client.post('/api/v1/auth/token/refresh/', {'refresh': refresh}, format='json')
        self.assertIn(refresh_attempt.status_code, [status.HTTP_400_BAD_REQUEST, status.HTTP_401_UNAUTHORIZED])

    def test_admin_endpoints_require_admin_user(self):
        user_access, _ = self._login('user@example.com', 'StrongPass123!')
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {user_access}')
        self.assertEqual(self.client.get('/api/v1/auth/admin/stats/').status_code, status.HTTP_403_FORBIDDEN)
        self.assertEqual(self.client.get('/api/v1/auth/admin/users/').status_code, status.HTTP_403_FORBIDDEN)

        admin_access, _ = self._login('admin@example.com', 'StrongPass123!')
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {admin_access}')
        self.assertEqual(self.client.get('/api/v1/auth/admin/stats/').status_code, status.HTTP_200_OK)
        self.assertEqual(self.client.get('/api/v1/auth/admin/users/').status_code, status.HTTP_200_OK)
