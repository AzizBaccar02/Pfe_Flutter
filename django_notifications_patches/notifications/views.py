# Copy into your Django project: notifications/views.py

from asgiref.sync import async_to_sync
from channels.layers import get_channel_layer
from rest_framework import status
from rest_framework.generics import ListAPIView, RetrieveAPIView
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from users.models import CustomUser

from .models import Notification
from .serializers import NotificationSerializer
from .utils import _group_name, create_and_send_notification


class NotificationCreateAPIView(APIView):
    """
    Create a notification for a user.

    Prefer calling create_and_send_notification() from server code (react view).
    Requires authentication — do not use AllowAny in production.
    """

    permission_classes = [IsAuthenticated]

    def post(self, request, *args, **kwargs):
        title = request.data.get("title")
        body = request.data.get("body")
        notification_type = request.data.get("type")
        user_id = request.data.get("user")
        payload_data = request.data.get("data") or {}

        if not all([title, body, notification_type, user_id]):
            return Response(
                {"error": "title, body, type, and user are required"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            user = CustomUser.objects.get(id=user_id)
        except CustomUser.DoesNotExist:
            return Response(
                {"error": "User not found"},
                status=status.HTTP_404_NOT_FOUND,
            )

        notification = create_and_send_notification(
            user=user,
            title=title,
            body=body,
            notification_type=notification_type,
            data=payload_data if isinstance(payload_data, dict) else {},
            request=request,
        )

        return Response(
            NotificationSerializer(notification).data,
            status=status.HTTP_201_CREATED,
        )


class MyNotificationsAPIView(ListAPIView):
    permission_classes = [IsAuthenticated]
    serializer_class = NotificationSerializer

    def get_queryset(self):
        return Notification.objects.filter(user=self.request.user).order_by(
            "-created_at"
        )


class MyNotificationDetailAPIView(RetrieveAPIView):
    permission_classes = [IsAuthenticated]
    serializer_class = NotificationSerializer
    lookup_field = "id"

    def get_queryset(self):
        return Notification.objects.filter(user=self.request.user)


class MarkNotificationAsReadAPIView(APIView):
    permission_classes = [IsAuthenticated]

    def patch(self, request, id, *args, **kwargs):
        updated = Notification.objects.filter(
            user=request.user,
            id=id,
            isRead=False,
        ).update(isRead=True)

        if updated == 0:
            exists = Notification.objects.filter(
                user=request.user,
                id=id,
            ).exists()

            if not exists:
                return Response(
                    {"error": "Notification not found"},
                    status=status.HTTP_404_NOT_FOUND,
                )

        unread_count = Notification.objects.filter(
            user=request.user,
            isRead=False,
        ).count()

        return Response(
            {
                "message": "Notification marked as read",
                "notification_id": id,
                "unread_count": unread_count,
            },
            status=status.HTTP_200_OK,
        )


class MarkAllNotificationsAsReadAPIView(APIView):
    permission_classes = [IsAuthenticated]

    def patch(self, request, *args, **kwargs):
        updated_count = Notification.objects.filter(
            user=request.user,
            isRead=False,
        ).update(isRead=True)

        return Response(
            {
                "message": "All notifications marked as read",
                "updated_count": updated_count,
                "unread_count": 0,
            },
            status=status.HTTP_200_OK,
        )


class UnreadNotificationsCountAPIView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, *args, **kwargs):
        unread_count = Notification.objects.filter(
            user=request.user,
            isRead=False,
        ).count()

        return Response(
            {
                "user_id": request.user.id,
                "unread_count": unread_count,
            },
            status=status.HTTP_200_OK,
        )


def send_notification(title, body, notification_type, user_id, data=None):
    """Legacy helper — prefer create_and_send_notification()."""
    try:
        user = CustomUser.objects.get(id=user_id)
    except CustomUser.DoesNotExist:
        return {"error": "User not found"}

    notification = create_and_send_notification(
        user=user,
        title=title,
        body=body,
        notification_type=notification_type,
        data=data or {},
    )

    return NotificationSerializer(notification).data
