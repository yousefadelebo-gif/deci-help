"""
Seed Data for Factor Categories and Templates
Run this after migrations: python manage.py shell < seeds/seed_factors.py
"""

from apps.factors.models import FactorCategory, FactorTemplate

# Clear existing data
FactorTemplate.objects.all().delete()
FactorCategory.objects.all().delete()

# Create Categories
categories_data = [
    {
        'name': 'Financial',
        'description': 'Money and cost-related factors',
        'icon': 'attach_money',
        'color': '#4CAF50',
        'order': 1,
    },
    {
        'name': 'Time',
        'description': 'Time and schedule-related factors',
        'icon': 'schedule',
        'color': '#2196F3',
        'order': 2,
    },
    {
        'name': 'Career',
        'description': 'Professional and career growth factors',
        'icon': 'work',
        'color': '#9C27B0',
        'order': 3,
    },
    {
        'name': 'Personal',
        'description': 'Personal well-being and lifestyle factors',
        'icon': 'person',
        'color': '#FF9800',
        'order': 4,
    },
    {
        'name': 'Relationships',
        'description': 'Family, friends, and social factors',
        'icon': 'people',
        'color': '#E91E63',
        'order': 5,
    },
    {
        'name': 'Risk',
        'description': 'Risk and security factors',
        'icon': 'security',
        'color': '#F44336',
        'order': 6,
    },
    {
        'name': 'Health',
        'description': 'Physical and mental health factors',
        'icon': 'favorite',
        'color': '#00BCD4',
        'order': 7,
    },
    {
        'name': 'Values',
        'description': 'Personal values and ethics',
        'icon': 'star',
        'color': '#FFC107',
        'order': 8,
    },
]

categories = {}
for cat_data in categories_data:
    cat = FactorCategory.objects.create(**cat_data)
    categories[cat.name] = cat
    print(f"Created category: {cat.name}")

# Create Factor Templates
templates_data = [
    # Financial
    {'category': 'Financial', 'name': 'Initial Cost', 'description': 'Upfront investment required', 'default_weight': 0.7, 'ai_suggested_for': ['career', 'purchase', 'education', 'business']},
    {'category': 'Financial', 'name': 'Long-term ROI', 'description': 'Expected return on investment over time', 'default_weight': 0.8, 'ai_suggested_for': ['career', 'investment', 'education', 'business']},
    {'category': 'Financial', 'name': 'Monthly Expenses', 'description': 'Ongoing monthly costs', 'default_weight': 0.6, 'ai_suggested_for': ['housing', 'lifestyle', 'purchase']},
    {'category': 'Financial', 'name': 'Income Potential', 'description': 'Potential to generate income', 'default_weight': 0.8, 'ai_suggested_for': ['career', 'business', 'education']},
    {'category': 'Financial', 'name': 'Financial Security', 'description': 'Impact on financial stability', 'default_weight': 0.9, 'ai_suggested_for': ['career', 'investment', 'major_decision']},
    
    # Time
    {'category': 'Time', 'name': 'Time Investment', 'description': 'Time required to complete or maintain', 'default_weight': 0.6, 'ai_suggested_for': ['career', 'education', 'project', 'hobby']},
    {'category': 'Time', 'name': 'Deadline Pressure', 'description': 'Urgency and time constraints', 'default_weight': 0.5, 'ai_suggested_for': ['career', 'project', 'decision']},
    {'category': 'Time', 'name': 'Work-Life Balance', 'description': 'Impact on personal time', 'default_weight': 0.8, 'ai_suggested_for': ['career', 'lifestyle', 'relationship']},
    {'category': 'Time', 'name': 'Flexibility', 'description': 'Freedom to adjust schedule', 'default_weight': 0.6, 'ai_suggested_for': ['career', 'lifestyle', 'housing']},
    
    # Career
    {'category': 'Career', 'name': 'Growth Opportunity', 'description': 'Potential for professional advancement', 'default_weight': 0.8, 'ai_suggested_for': ['career', 'education', 'business']},
    {'category': 'Career', 'name': 'Skill Development', 'description': 'Opportunities to learn new skills', 'default_weight': 0.7, 'ai_suggested_for': ['career', 'education', 'project']},
    {'category': 'Career', 'name': 'Job Security', 'description': 'Stability of the position', 'default_weight': 0.7, 'ai_suggested_for': ['career']},
    {'category': 'Career', 'name': 'Industry Alignment', 'description': 'Match with career goals', 'default_weight': 0.8, 'ai_suggested_for': ['career', 'education']},
    {'category': 'Career', 'name': 'Networking Value', 'description': 'Opportunities to build connections', 'default_weight': 0.5, 'ai_suggested_for': ['career', 'education', 'event']},
    
    # Personal
    {'category': 'Personal', 'name': 'Personal Satisfaction', 'description': 'Alignment with personal desires', 'default_weight': 0.8, 'ai_suggested_for': ['lifestyle', 'career', 'relationship', 'hobby']},
    {'category': 'Personal', 'name': 'Stress Level', 'description': 'Expected stress impact', 'default_weight': 0.7, 'ai_suggested_for': ['career', 'lifestyle', 'relationship', 'housing']},
    {'category': 'Personal', 'name': 'Comfort Zone', 'description': 'Familiarity and comfort with the choice', 'default_weight': 0.4, 'ai_suggested_for': ['career', 'lifestyle', 'relationship']},
    {'category': 'Personal', 'name': 'Passion Alignment', 'description': 'Match with personal passions', 'default_weight': 0.7, 'ai_suggested_for': ['career', 'hobby', 'education']},
    
    # Relationships
    {'category': 'Relationships', 'name': 'Family Impact', 'description': 'Effect on family members', 'default_weight': 0.9, 'ai_suggested_for': ['career', 'housing', 'lifestyle', 'relationship']},
    {'category': 'Relationships', 'name': 'Partner Agreement', 'description': 'Alignment with partner\'s wishes', 'default_weight': 0.8, 'ai_suggested_for': ['housing', 'lifestyle', 'career', 'relationship']},
    {'category': 'Relationships', 'name': 'Social Circle', 'description': 'Impact on friendships', 'default_weight': 0.5, 'ai_suggested_for': ['housing', 'lifestyle', 'career']},
    
    # Risk
    {'category': 'Risk', 'name': 'Risk Level', 'description': 'Overall risk involved', 'default_weight': 0.7, 'ai_suggested_for': ['investment', 'career', 'business', 'major_decision']},
    {'category': 'Risk', 'name': 'Reversibility', 'description': 'Ease of undoing the decision', 'default_weight': 0.6, 'ai_suggested_for': ['career', 'relationship', 'major_decision']},
    {'category': 'Risk', 'name': 'Worst Case Impact', 'description': 'Severity if things go wrong', 'default_weight': 0.8, 'ai_suggested_for': ['investment', 'career', 'business']},
    {'category': 'Risk', 'name': 'Success Probability', 'description': 'Likelihood of positive outcome', 'default_weight': 0.7, 'ai_suggested_for': ['business', 'career', 'project']},
    
    # Health
    {'category': 'Health', 'name': 'Physical Health Impact', 'description': 'Effect on physical well-being', 'default_weight': 0.9, 'ai_suggested_for': ['lifestyle', 'career', 'housing']},
    {'category': 'Health', 'name': 'Mental Health Impact', 'description': 'Effect on mental well-being', 'default_weight': 0.9, 'ai_suggested_for': ['career', 'lifestyle', 'relationship']},
    {'category': 'Health', 'name': 'Energy Level', 'description': 'Impact on daily energy', 'default_weight': 0.6, 'ai_suggested_for': ['lifestyle', 'career']},
    
    # Values
    {'category': 'Values', 'name': 'Ethical Alignment', 'description': 'Match with personal ethics', 'default_weight': 0.8, 'ai_suggested_for': ['career', 'business', 'major_decision']},
    {'category': 'Values', 'name': 'Environmental Impact', 'description': 'Effect on the environment', 'default_weight': 0.5, 'ai_suggested_for': ['purchase', 'lifestyle', 'business']},
    {'category': 'Values', 'name': 'Social Responsibility', 'description': 'Contribution to society', 'default_weight': 0.5, 'ai_suggested_for': ['career', 'business']},
    {'category': 'Values', 'name': 'Long-term Vision', 'description': 'Alignment with life goals', 'default_weight': 0.9, 'ai_suggested_for': ['career', 'education', 'relationship', 'major_decision']},
]

for template_data in templates_data:
    cat_name = template_data.pop('category')
    template_data['category'] = categories[cat_name]
    template = FactorTemplate.objects.create(**template_data)
    print(f"Created template: {template.name}")

print(f"\nCreated {len(categories)} categories and {len(templates_data)} templates")
