#notifications/consumers.py

import json

from channels.db import database_sync_to_async
from channels.generic.websocket import AsyncWebsocketConsumer
from django.contrib.auth import get_user_model
from rest_framework_simplejwt.exceptions import InvalidToken, TokenError
from rest_framework_simplejwt.tokens import AccessToken

User = get_user_model()


class NotificationConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        self.user_id = self.scope["url_route"]["kwargs"].get("user_id")
        self.group_name = None

        if not self.user_id:
            await self.close()
            return

        user = await self._authenticate_user()

        if user is None:
            await self.close()
            return

        if str(user.id) != str(self.user_id):
            await self.close()
            return

        self.group_name = f"notifications_{user.id}"

        await self.channel_layer.group_add(self.group_name, self.channel_name)
        await self.accept()

        await self.send(
            text_data=json.dumps(
                {
                    "type": "connection_established",
                    "message": f"Connected to {self.group_name}",
                }
            )
        )

    async def disconnect(self, close_code):
        if self.group_name:
            await self.channel_layer.group_discard(
                self.group_name,
                self.channel_name,
            )

    async def send_notification(self, event):
        await self.send(
            text_data=json.dumps(
                {
                    "type": "new_notification",
                    "notification": event["notification"],
                }
            )
        )

    @database_sync_to_async
    def _authenticate_user(self):
        query_string = self.scope.get("query_string", b"").decode()
        token = None

        for part in query_string.split("&"):
            if part.startswith("token="):
                token = part.split("=", 1)[1]
                break

        if not token:
            return None

        try:
            validated = AccessToken(token)
            user_id = validated.get("user_id")
            return User.objects.filter(id=user_id, is_active=True).first()
        except (InvalidToken, TokenError, User.DoesNotExist):
            return None
