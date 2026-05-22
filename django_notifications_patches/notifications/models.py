# notifications/models.py

from django.db import models


class NotificationType(models.TextChoices):
    PROPOSAL_STATUS = "PROPOSAL_STATUS", "PROPOSAL_STATUS"
    NEW_MESSAGE = "NEW_MESSAGE", "NEW_MESSAGE"
    MATCH_CREATED = "MATCH_CREATED", "MATCH_CREATED"
    AGENT_LIKED_OFFER = "AGENT_LIKED_OFFER", "AGENT_LIKED_OFFER"
    CLIENT_REJECTED = "CLIENT_REJECTED", "CLIENT_REJECTED"


class Notification(models.Model):
    title = models.CharField(max_length=200)
    body = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)
    isRead = models.BooleanField(default=False)
    type = models.CharField(max_length=30, choices=NotificationType.choices)
    data = models.JSONField(default=dict, blank=True)
    user = models.ForeignKey(
        "users.CustomUser",
        on_delete=models.CASCADE,
        related_name="notifications",
    )

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.title} → user {self.user_id}"
