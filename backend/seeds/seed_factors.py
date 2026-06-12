"""
Seed factor categories and templates.
Run: python manage.py seed_demo_data
Or:  python manage.py shell -c "from seeds.demo_data import seed_factor_templates; seed_factor_templates()"
"""

from seeds.demo_data import seed_factor_templates

if __name__ == '__main__':
    cats, tmpls = seed_factor_templates()
    print(f'Created {cats} categories and {tmpls} templates')
