# Copy into interactions/views.py and register in urls.py:
#
#   path(
#       "reactions/<int:reaction_id>/respond/",
#       ReactionRespondAPIView.as_view(),
#       name="reaction-respond",
#   ),
#
# Flutter calls: POST /api/interactions/reactions/{reactionId}/respond/
# Body: { "accept": true }  → match + notify agent
#       { "accept": false } → reject + notify agent

from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

# Adjust imports:
from .models import Interaction  # noqa: F401
from .serializers import InteractionSerializer  # noqa: F401


def _get_interaction_or_404(pk):
    try:
        return Interaction.objects.select_related("offre", "agent").get(pk=pk)
    except Interaction.DoesNotExist:
        return None


def _resolve_offer_client_user(offer):
    if offer is None:
        return None
    for attr in ("client", "owner", "created_by", "user"):
        candidate = getattr(offer, attr, None)
        if candidate is None:
            continue
        if hasattr(candidate, "is_authenticated"):
            return candidate
        nested = getattr(candidate, "user", None)
        if nested is not None and hasattr(nested, "is_authenticated"):
            return nested
    return None


def _assert_client_owns_offer(request, interaction):
    offer = getattr(interaction, "offre", None) or getattr(interaction, "offer", None)
    client_user = _resolve_offer_client_user(offer)
    if client_user is None or client_user != request.user:
        return Response({"detail": "Forbidden"}, status=status.HTTP_403_FORBIDDEN)
    return None


class ReactionRespondAPIView(APIView):
    """Client swipe right/left on Interested tab."""

    permission_classes = [IsAuthenticated]

    def post(self, request, reaction_id, *args, **kwargs):
        interaction = _get_interaction_or_404(reaction_id)
        if interaction is None:
            return Response({"detail": "Not found"}, status=status.HTTP_404_NOT_FOUND)

        forbidden = _assert_client_owns_offer(request, interaction)
        if forbidden is not None:
            return forbidden

        accept = request.data.get("accept")
        if accept is None:
            return Response(
                {"detail": 'Field "accept" (true/false) is required.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        new_status = "ACCEPTED" if bool(accept) else "REJECTED"
        interaction.status = new_status
        interaction.save(update_fields=["status"])

        try:
            if new_status == "ACCEPTED":
                from interactions.notify_helpers import notify_agent_client_accepted

                notify_agent_client_accepted(
                    interaction=interaction,
                    client_user=request.user,
                    request=request,
                )
            else:
                from interactions.notify_helpers import notify_agent_client_rejected

                notify_agent_client_rejected(
                    interaction=interaction,
                    client_user=request.user,
                    request=request,
                )
        except Exception:
            import logging

            logging.getLogger(__name__).exception(
                "notify on reaction respond failed"
            )

        payload = InteractionSerializer(interaction).data
        return Response(
            {"reaction": payload, "status": new_status},
            status=status.HTTP_200_OK,
        )
