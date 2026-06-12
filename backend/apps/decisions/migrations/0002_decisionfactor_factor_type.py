from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('decisions', '0001_initial'),
    ]

    operations = [
        migrations.AddField(
            model_name='decisionfactor',
            name='factor_type',
            field=models.CharField(
                choices=[('pro', 'Pro'), ('con', 'Con')],
                default='pro',
                max_length=10,
            ),
        ),
    ]
