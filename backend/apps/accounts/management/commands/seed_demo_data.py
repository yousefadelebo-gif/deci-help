"""
Seed demo data: admin user, factor templates, users, decisions, feedback.

Usage:
  python manage.py seed_demo_data
  python manage.py seed_demo_data --users 50 --decisions-per-user 8
  python manage.py seed_demo_data --flush
"""

from django.core.management.base import BaseCommand
from django.db import transaction

from apps.accounts.models import User
from apps.decisions.models import Decision, DecisionOption, DecisionFactor, FactorRating, JournalEntry
from apps.feedback.models import UserFeedback, AppRating, AIFeedback
from apps.factors.models import FactorCategory, FactorTemplate, UserFactorTemplate
from seeds.demo_data import (
    ensure_admin_user,
    seed_decisions_for_user,
    seed_demo_users,
    seed_factor_templates,
    seed_feedback,
)


class Command(BaseCommand):
    help = 'Seed database with admin account and rich demo data'

    def add_arguments(self, parser):
        parser.add_argument('--admin-email', default='admin@decehelp.com')
        parser.add_argument('--admin-password', default='Admin123!')
        parser.add_argument('--admin-name', default='Decehelp Admin')
        parser.add_argument('--users', type=int, default=25, help='Number of demo users')
        parser.add_argument('--decisions-per-user', type=int, default=5)
        parser.add_argument('--demo-password', default='Demo123!')
        parser.add_argument(
            '--flush',
            action='store_true',
            help='Delete demo users and seeded content (keeps admin)',
        )

    def handle(self, *args, **options):
        admin_email = options['admin_email']

        if options['flush']:
            with transaction.atomic():
                self._flush_demo_data(admin_email)
            self.stdout.write(self.style.WARNING('Demo data cleared.'))

        admin, admin_created = ensure_admin_user(
            admin_email,
            options['admin_password'],
            options['admin_name'],
        )
        action = 'Created' if admin_created else 'Updated'
        self.stdout.write(self.style.SUCCESS(f'{action} admin: {admin.email}'))

        cat_count, tmpl_count = seed_factor_templates()
        self.stdout.write(f'Factor categories: {cat_count}, templates: {tmpl_count}')

        users = seed_demo_users(options['users'], options['demo_password'])
        self.stdout.write(f'Demo users: {len(users)} (password: {options["demo_password"]})')

        total_decisions = 0
        for idx, user in enumerate(users, start=1):
            with transaction.atomic():
                total_decisions += seed_decisions_for_user(user, options['decisions_per_user'])
            if idx % 5 == 0 or idx == len(users):
                self.stdout.write(f'  ... seeded {idx}/{len(users)} users')
        self.stdout.write(f'Decisions created: {total_decisions}')

        feedback_count = seed_feedback(users)
        self.stdout.write(f'Feedback entries: {feedback_count}')

        self.stdout.write('')
        self.stdout.write(self.style.SUCCESS('Seed complete.'))
        self.stdout.write('Django admin:  http://127.0.0.1:8000/admin/')
        self.stdout.write('Swagger UI:    http://127.0.0.1:8000/swagger/')
        self.stdout.write(f'Admin login:   {admin_email} / {options["admin_password"]}')
        self.stdout.write('Swagger auth:  POST /api/v1/auth/login/ then Authorize with Bearer <access>')

    def _flush_demo_data(self, admin_email):
        demo_users = User.objects.exclude(email=admin_email).filter(email__endswith='@decehelp.test')
        Decision.objects.filter(user__in=demo_users).delete()
        UserFeedback.objects.filter(user__in=demo_users).delete()
        AppRating.objects.filter(user__in=demo_users).delete()
        AIFeedback.objects.filter(user__in=demo_users).delete()
        UserFactorTemplate.objects.filter(user__in=demo_users).delete()
        demo_users.delete()
