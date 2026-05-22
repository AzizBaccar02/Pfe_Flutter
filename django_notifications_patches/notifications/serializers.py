#notifications/serializers.py

from rest_framework import serializers

from .models import Notification


class NotificationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Notification
        fields = [
            "id",
            "title",
            "body",
            "created_at",
            "isRead",
            "type",
            "data",
            "user",
        ]
        read_only_fields = ["id", "created_at", "isRead", "user"]
