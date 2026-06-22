# Example: create an in-app notification for the agent when a client submits a rating.
# Wire this from SubmitAgentRatingView after saving AgentRating.

from __future__ import annotations

# from notifications.models import Notification
# from notifications.utils import push_notification_to_user


def build_agent_rating_notification_data(
    *,
    offer_id: int,
    agent_id: int,
    client_id: int,
    client_name: str,
    client_photo: str,
    offer_title: str,
    stars: int,
    comment: str,
) -> dict:
    return {
        'action': 'agent_received_rating',
        'offer_id': offer_id,
        'offerId': offer_id,
        'agent_id': agent_id,
        'agentId': agent_id,
        'client_id': client_id,
        'clientId': client_id,
        'client_name': client_name,
        'clientName': client_name,
        'client_photo': client_photo,
        'offer_title': offer_title,
        'offerTitle': offer_title,
        'stars': stars,
        'rating_stars': stars,
        'comment': comment,
        'rating_comment': comment,
    }


def notify_agent_rating(
    *,
    agent_user,
    client_user,
    offer,
    stars: int,
    comment: str = '',
) -> None:
    """
    Creates a Notification row for the agent and pushes via your existing
    NotificationRealtimeHub / WebSocket consumer.
    """
    client_name = getattr(client_user, 'get_full_name', lambda: '')() or str(
        client_user
    )
    # client_photo = resolve avatar from client profile

    title = f'{client_name} rated you {stars}★'
    body = comment.strip() or f'Thanks for completing "{offer.title}".'

    data = build_agent_rating_notification_data(
        offer_id=offer.id,
        agent_id=offer.agent_id,  # adjust field names
        client_id=client_user.id,
        client_name=client_name,
        client_photo='',
        offer_title=getattr(offer, 'title', ''),
        stars=stars,
        comment=comment,
    )

    # notification = Notification.objects.create(
    #     user=agent_user,
    #     type='AGENT_RATED',
    #     title=title,
    #     body=body,
    #     data=data,
    # )
    # push_notification_to_user(agent_user.id, notification)
