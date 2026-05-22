# Example: add at the END of your OfferReactAPIView.post() after interaction is saved.
# Adjust import path to where you copied notify_helpers.py.

from rest_framework import status
from rest_framework.response import Response


def react_view_post_tail_example(request, interaction, serializer_data):
    """
    Call this right before: return Response(serializer_data, status=status.HTTP_201_CREATED)
    """
    try:
        from interactions.notify_helpers import notify_client_agent_liked_offer

        notify_client_agent_liked_offer(
            interaction=interaction,
            agent_user=request.user,
        )
    except Exception as exc:
        import logging

        logging.getLogger(__name__).exception(
            "notify_client_agent_liked_offer failed: %s", exc
        )

    return Response(serializer_data, status=status.HTTP_201_CREATED)
