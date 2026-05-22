# Generated migration — copy into notifications/migrations/

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("notifications", "0002_initial"),
    ]

    operations = [
        migrations.AddField(
            model_name="notification",
            name="data",
            field=models.JSONField(blank=True, default=dict),
        ),
        migrations.AlterField(
            model_name="notification",
            name="type",
            field=models.CharField(
                choices=[
                    ("PROPOSAL_STATUS", "PROPOSAL_STATUS"),
                    ("NEW_MESSAGE", "NEW_MESSAGE"),
                    ("MATCH_CREATED", "MATCH_CREATED"),
                    ("AGENT_LIKED_OFFER", "AGENT_LIKED_OFFER"),
                    ("CLIENT_REJECTED", "CLIENT_REJECTED"),
                ],
                max_length=30,
            ),
        ),
    ]
