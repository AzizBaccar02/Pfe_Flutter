# notifications/utils.py

from asgiref.sync import async_to_sync
from channels.layers import get_channel_layer

from .models import Notification
from .serializers import NotificationSerializer


def _group_name(user_id: int) -> str:
    # MUST match NotificationConsumer.group_name in consumers.py
    return f"notifications_{user_id}"


def create_and_send_notification(
    user,
    title,
    body,
    notification_type,
    data=None,
    *,
    request=None,
):
    """
    Create a notification, persist JSON `data`, and push to WebSocket.

    `data` should include action, ids, agent_name/client_name, avatar_url
    (see notifications/payloads.py and interactions/notify_helpers.py).
    """
    payload = data if isinstance(data, dict) else {}

    notification = Notification.objects.create(
        user=user,
        title=title,
        body=body,
        type=notification_type,
        data=payload,
    )

    serialized = NotificationSerializer(notification).data
    channel_layer = get_channel_layer()

    async_to_sync(channel_layer.group_send)(
        _group_name(user.id),
        {
            "type": "send_notification",
            "notification": serialized,
        },
    )

    return notification


def broadcast_notification(notification):
    """Re-send an existing row over the socket (e.g. after migration)."""
    serialized = NotificationSerializer(notification).data
    channel_layer = get_channel_layer()

    async_to_sync(channel_layer.group_send)(
        _group_name(notification.user_id),
        {
            "type": "send_notification",
            "notification": serialized,
        },
    )
