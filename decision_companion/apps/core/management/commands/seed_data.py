"""
Management command to seed initial data.

Run with: python manage.py seed_data
"""

from django.core.management.base import BaseCommand
from apps.core.models import User, UserSettings
from apps.decisions.models import FactorTemplate, AIParameters


class Command(BaseCommand):
    help = 'Seed initial data for the Decision Companion application'
    
    def handle(self, *args, **options):
        self.stdout.write('Seeding initial data...')
        
        # Create admin user
        self.create_admin_user()
        
        # Create factor templates
        self.create_factor_templates()
        
        # Create AI parameters
        self.create_ai_parameters()
        
        self.stdout.write(self.style.SUCCESS('Successfully seeded initial data!'))
    
    def create_admin_user(self):
        """Create default admin user."""
        if not User.objects.filter(email='admin@example.com').exists():
            admin = User.objects.create_superuser(
                email='admin@example.com',
                password='admin123',
                name='Admin User'
            )
            UserSettings.objects.create(user=admin)
            self.stdout.write(f'  Created admin user: admin@example.com (password: admin123)')
        else:
            self.stdout.write('  Admin user already exists')
    
    def create_factor_templates(self):
        """Create default factor templates."""
        templates = [
            {
                'key': 'COST',
                'name': 'Cost',
                'description': 'Financial cost or price of the option',
                'default_category': 'CON',
                'default_weight': 7,
                'icon': 'money',
                'sort_order': 1
            },
            {
                'key': 'QUALITY',
                'name': 'Quality',
                'description': 'Overall quality and reliability',
                'default_category': 'PRO',
                'default_weight': 8,
                'icon': 'star',
                'sort_order': 2
            },
            {
                'key': 'TIME',
                'name': 'Time Required',
                'description': 'Time investment needed',
                'default_category': 'CON',
                'default_weight': 6,
                'icon': 'clock',
                'sort_order': 3
            },
            {
                'key': 'RISK',
                'name': 'Risk Level',
                'description': 'Potential risks or downsides',
                'default_category': 'CON',
                'default_weight': 7,
                'icon': 'warning',
                'sort_order': 4
            },
            {
                'key': 'BENEFIT',
                'name': 'Long-term Benefit',
                'description': 'Future value and long-term gains',
                'default_category': 'PRO',
                'default_weight': 8,
                'icon': 'trending_up',
                'sort_order': 5
            },
            {
                'key': 'EFFORT',
                'name': 'Effort Required',
                'description': 'Amount of effort or work needed',
                'default_category': 'CON',
                'default_weight': 5,
                'icon': 'fitness',
                'sort_order': 6
            },
            {
                'key': 'SATISFACTION',
                'name': 'Personal Satisfaction',
                'description': 'How satisfying or fulfilling the choice is',
                'default_category': 'PRO',
                'default_weight': 7,
                'icon': 'mood',
                'sort_order': 7
            },
            {
                'key': 'FLEXIBILITY',
                'name': 'Flexibility',
                'description': 'Ability to adapt or change later',
                'default_category': 'PRO',
                'default_weight': 6,
                'icon': 'sync',
                'sort_order': 8
            },
            {
                'key': 'CONVENIENCE',
                'name': 'Convenience',
                'description': 'Ease of use and accessibility',
                'default_category': 'PRO',
                'default_weight': 5,
                'icon': 'thumb_up',
                'sort_order': 9
            },
            {
                'key': 'REPUTATION',
                'name': 'Reputation',
                'description': 'Brand reputation and reviews',
                'default_category': 'PRO',
                'default_weight': 6,
                'icon': 'verified',
                'sort_order': 10
            }
        ]
        
        created_count = 0
        for template_data in templates:
            template, created = FactorTemplate.objects.get_or_create(
                key=template_data['key'],
                defaults=template_data
            )
            if created:
                created_count += 1
        
        self.stdout.write(f'  Created {created_count} factor templates')
    
    def create_ai_parameters(self):
        """Create default AI parameters."""
        parameters = [
            {
                'key': 'MIN_CONFIDENCE_THRESHOLD',
                'value': '30',
                'value_type': 'int',
                'description': 'Minimum confidence level for recommendations'
            },
            {
                'key': 'MAX_CONFIDENCE_THRESHOLD',
                'value': '95',
                'value_type': 'int',
                'description': 'Maximum confidence level cap'
            },
            {
                'key': 'WEIGHT_IMPORTANCE_FACTOR',
                'value': '1.5',
                'value_type': 'float',
                'description': 'Multiplier for weight importance in scoring'
            },
            {
                'key': 'ENABLE_AI_SUGGESTIONS',
                'value': 'true',
                'value_type': 'bool',
                'description': 'Enable AI factor suggestions feature'
            },
            {
                'key': 'DEFAULT_FACTOR_WEIGHT',
                'value': '5',
                'value_type': 'int',
                'description': 'Default weight for new factors'
            },
            {
                'key': 'ANALYSIS_VERSION',
                'value': '1.0',
                'value_type': 'string',
                'description': 'Current analysis algorithm version'
            }
        ]
        
        created_count = 0
        for param_data in parameters:
            param, created = AIParameters.objects.get_or_create(
                key=param_data['key'],
                defaults=param_data
            )
            if created:
                created_count += 1
        
        self.stdout.write(f'  Created {created_count} AI parameters')
