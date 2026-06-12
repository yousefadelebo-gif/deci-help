"""Reusable demo seed helpers for Decision Companion."""

import random
from datetime import timedelta

from django.utils import timezone

from apps.accounts.models import User, UserSettings
from apps.decisions.models import (
    Decision, DecisionOption, DecisionFactor, FactorRating, JournalEntry,
)
from apps.factors.models import FactorCategory, FactorTemplate
from apps.feedback.models import UserFeedback, AppRating, AIFeedback

from seeds.factor_catalog import CATEGORIES_DATA, TEMPLATES_DATA


DECISION_TITLES = [
    'Should I accept the new job offer?',
    'Buy a house or keep renting?',
    'Pursue a master\'s degree?',
    'Start a side business?',
    'Move to another city?',
    'Switch to remote work?',
    'Invest in stocks or savings?',
    'Adopt a pet?',
    'Plan a career change to tech?',
    'Take a sabbatical year?',
    'Buy an electric car?',
    'Join a startup or stay corporate?',
    'Renovate the kitchen?',
    'Enroll kids in private school?',
    'Downsize to a smaller home?',
]

OPTION_PAIRS = [
    ('Accept offer', 'Stay at current job'),
    ('Buy house', 'Keep renting'),
    ('Enroll now', 'Wait one year'),
    ('Start business', 'Keep full-time job'),
    ('Move', 'Stay put'),
    ('Go remote', 'Stay in office'),
    ('Invest aggressively', 'Save conservatively'),
    ('Adopt now', 'Wait'),
    ('Career switch', 'Stay in field'),
    ('Take sabbatical', 'Keep working'),
]

CATEGORIES = ['career', 'housing', 'finance', 'education', 'lifestyle', 'relationship']
STATUSES = ['draft', 'in_progress', 'completed', 'completed', 'completed', 'archived']

REFLECTIONS = [
    'Looking back, I made the right call for my family.',
    'The process helped me think more clearly than I expected.',
    'I wish I had weighed the financial factor more heavily.',
    'Glad I used structured factors instead of gut feeling alone.',
    'The outcome was mixed, but I learned a lot.',
]

FEEDBACK_TITLES = [
    'Love the AI factor suggestions',
    'Charts are very helpful',
    'Need dark mode improvements',
    'Journal feature is great',
    'Slow on first AI analysis',
    'Would like export to PDF',
]


def seed_factor_templates():
    """Populate factor categories and templates."""
    if FactorTemplate.objects.exists():
        return FactorCategory.objects.count(), FactorTemplate.objects.count()

    categories = {}
    for cat_data in CATEGORIES_DATA:
        cat = FactorCategory.objects.create(**cat_data)
        categories[cat.name] = cat

    count = 0
    for template_data in TEMPLATES_DATA:
        data = dict(template_data)
        cat_name = data.pop('category')
        data['category'] = categories[cat_name]
        FactorTemplate.objects.create(**data)
        count += 1

    return len(categories), count


def ensure_admin_user(email, password, name='Admin User'):
    """Create or update the Django admin / API admin user."""
    email = User.objects.normalize_email(email)
    try:
        user = User.objects.get(email=email)
        created = False
    except User.DoesNotExist:
        user = User(
            email=email,
            name=name,
            is_staff=True,
            is_superuser=True,
            is_verified=True,
            is_active=True,
        )
        created = True
    user.is_staff = True
    user.is_superuser = True
    user.is_active = True
    user.is_verified = True
    user.name = name
    user.set_password(password)
    user.save()
    UserSettings.objects.get_or_create(user=user)
    return user, created


def seed_demo_users(count=25, password='Demo123!'):
    """Create demo users with settings."""
    users = []
    for i in range(1, count + 1):
        email = f'demo{i}@decehelp.test'
        user, created = User.objects.get_or_create(
            email=email,
            defaults={
                'name': f'Demo User {i}',
                'is_verified': random.choice([True, True, False]),
            },
        )
        if created or not user.check_password(password):
            user.set_password(password)
            user.save()
        UserSettings.objects.get_or_create(user=user)
        user.last_login_at = timezone.now() - timedelta(days=random.randint(0, 45))
        user.save(update_fields=['last_login_at'])
        users.append(user)
    return users


def seed_decisions_for_user(user, per_user=5):
    """Create decisions with options, factors, ratings, and optional journal."""
    templates = list(FactorTemplate.objects.all())
    created = 0

    for i in range(per_user):
        title = random.choice(DECISION_TITLES)
        status = random.choice(STATUSES)
        category = random.choice(CATEGORIES)
        created_at = timezone.now() - timedelta(days=random.randint(1, 180))

        decision = Decision.objects.create(
            user=user,
            title=f'{title} ({user.id}-{i})',
            description=f'Demo decision for {user.name}. Evaluating trade-offs carefully.',
            category=category,
            status=status,
            ai_confidence=random.uniform(55, 95) if status == 'completed' else None,
            ai_explanation='AI weighed financial and personal factors with moderate confidence.'
            if status == 'completed' else '',
            ai_insights=['Consider long-term ROI', 'Stress level matters for this choice'],
            analyzed_at=created_at + timedelta(hours=2) if status == 'completed' else None,
            created_at=created_at,
            updated_at=created_at,
        )

        opt_a, opt_b = random.choice(OPTION_PAIRS)
        options = []
        for order, (name, desc) in enumerate([(opt_a, ''), (opt_b, '')]):
            option = DecisionOption.objects.create(
                decision=decision,
                name=name,
                description=desc or f'Option: {name}',
                pros=[f'Pro for {name}', 'Aligns with goals'],
                cons=[f'Con for {name}', 'Some uncertainty'],
                ai_score=random.uniform(40, 90) if status == 'completed' else None,
                order=order,
            )
            options.append(option)

        picked_templates = random.sample(templates, min(random.randint(4, 8), len(templates)))
        factors = []
        for tmpl in picked_templates:
            factor = DecisionFactor.objects.create(
                decision=decision,
                factor_template=tmpl,
                name=tmpl.name,
                weight=tmpl.default_weight,
                factor_type=random.choice(['pro', 'con']),
                is_ai_suggested=random.choice([True, False]),
            )
            factors.append(factor)

        ratings = [
            FactorRating(
                decision_factor=factor,
                option=option,
                score=round(random.uniform(3, 9), 1),
            )
            for factor in factors
            for option in options
        ]
        FactorRating.objects.bulk_create(ratings)

        if status == 'completed' and options:
            winner = max(options, key=lambda o: o.ai_score or 0)
            decision.ai_recommendation = winner
            decision.chosen_option = random.choice(options)
            decision.chosen_at = created_at + timedelta(days=random.randint(3, 14))
            decision.save(update_fields=['ai_recommendation', 'chosen_option', 'chosen_at'])

            JournalEntry.objects.create(
                decision=decision,
                reflection=random.choice(REFLECTIONS),
                satisfaction=random.uniform(2.5, 5),
                outcome_notes='Demo journal outcome notes.',
                lessons_learned='Document assumptions earlier next time.',
            )

            AIFeedback.objects.create(
                user=user,
                decision=decision,
                was_helpful=random.choice([True, True, False]),
                followed_recommendation=decision.chosen_option == decision.ai_recommendation,
                feedback_text='Demo AI feedback entry.',
                issues=random.sample(['inaccurate', 'unclear', 'slow'], k=random.randint(0, 2)),
            )

        created += 1

    return created


def seed_feedback(users):
    """Create user feedback and app ratings."""
    feedback_count = 0
    for user in random.sample(users, min(len(users), max(5, len(users) // 2))):
        UserFeedback.objects.create(
            user=user,
            category=random.choice(['bug', 'feature', 'improvement', 'question', 'other']),
            title=random.choice(FEEDBACK_TITLES),
            description='Demo feedback submitted during testing.',
            rating=random.randint(3, 5),
            status=random.choice(['new', 'reviewed', 'in_progress', 'resolved']),
            priority=random.choice(['low', 'medium', 'high']),
            app_version='1.0.0',
            device_info={'platform': random.choice(['android', 'ios', 'web'])},
        )
        feedback_count += 1

        if not AppRating.objects.filter(user=user).exists():
            AppRating.objects.get_or_create(
                user=user,
                defaults={
                    'rating': random.randint(3, 5),
                    'review': 'Great app for structured decisions.',
                },
            )

    return feedback_count
