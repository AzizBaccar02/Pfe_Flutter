# Copy into your Django interactions app (e.g. interactions/views.py + urls.py)
#
# Registers endpoints Flutter already calls:
#   POST /api/interactions/<id>/accept/
#   POST /api/interactions/<id>/reject/
#   PATCH /api/interactions/<id>/  { "status": "ACCEPTED" | "REJECTED" }

from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

# Adjust these imports to your project:
from .models import Interaction  # noqa: F401 — your model name
from .serializers import InteractionSerializer  # noqa: F401


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


def _get_interaction_or_404(pk):
    try:
        return Interaction.objects.select_related("offre", "agent").get(pk=pk)
    except Interaction.DoesNotExist:
        return None


def _assert_client_owns_offer(request, interaction):
    offer = getattr(interaction, "offre", None) or getattr(interaction, "offer", None)
    client_user = _resolve_offer_client_user(offer)
    if client_user is None or client_user != request.user:
        return Response({"detail": "Forbidden"}, status=status.HTTP_403_FORBIDDEN)
    return None


def _set_status(interaction, new_status: str):
    interaction.status = new_status
    interaction.save(update_fields=["status"])
    return interaction


class InteractionAcceptAPIView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, interaction_id, *args, **kwargs):
        interaction = _get_interaction_or_404(interaction_id)
        if interaction is None:
            return Response({"detail": "Not found"}, status=status.HTTP_404_NOT_FOUND)

        forbidden = _assert_client_owns_offer(request, interaction)
        if forbidden is not None:
            return forbidden

        interaction = _set_status(interaction, "ACCEPTED")

        try:
            from interactions.notify_helpers import notify_agent_client_accepted

            notify_agent_client_accepted(
                interaction=interaction,
                client_user=request.user,
                request=request,
            )
        except Exception:
            import logging

            logging.getLogger(__name__).exception("notify_agent_client_accepted failed")

        return Response(
            InteractionSerializer(interaction).data,
            status=status.HTTP_200_OK,
        )


class InteractionRejectAPIView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, interaction_id, *args, **kwargs):
        interaction = _get_interaction_or_404(interaction_id)
        if interaction is None:
            return Response({"detail": "Not found"}, status=status.HTTP_404_NOT_FOUND)

        forbidden = _assert_client_owns_offer(request, interaction)
        if forbidden is not None:
            return forbidden

        interaction = _set_status(interaction, "REJECTED")

        try:
            from interactions.notify_helpers import notify_agent_client_rejected

            notify_agent_client_rejected(
                interaction=interaction,
                client_user=request.user,
                request=request,
            )
        except Exception:
            import logging

            logging.getLogger(__name__).exception("notify_agent_client_rejected failed")

        return Response(
            InteractionSerializer(interaction).data,
            status=status.HTTP_200_OK,
        )


class InteractionDetailAPIView(APIView):
    """PATCH status — fallback used by Flutter."""

    permission_classes = [IsAuthenticated]

    def patch(self, request, interaction_id, *args, **kwargs):
        interaction = _get_interaction_or_404(interaction_id)
        if interaction is None:
            return Response({"detail": "Not found"}, status=status.HTTP_404_NOT_FOUND)

        forbidden = _assert_client_owns_offer(request, interaction)
        if forbidden is not None:
            return forbidden

        raw_status = (
            request.data.get("status")
            or ("ACCEPTED" if request.data.get("accept") is True else None)
            or ("REJECTED" if request.data.get("accept") is False else None)
        )

        if not raw_status:
            return Response(
                {"detail": "status or accept is required"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        normalized = str(raw_status).strip().upper()
        if normalized in ("ACCEPT", "ACCEPTED", "APPROVED"):
            normalized = "ACCEPTED"
        elif normalized in ("REJECT", "REJECTED", "DECLINED", "DECLINE"):
            normalized = "REJECTED"
        else:
            return Response(
                {"detail": f"Invalid status: {raw_status}"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        interaction = _set_status(interaction, normalized)

        try:
            if normalized == "ACCEPTED":
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

            logging.getLogger(__name__).exception("notify on patch failed")

        return Response(
            InteractionSerializer(interaction).data,
            status=status.HTTP_200_OK,
        )


# urls.py — add under your api/interactions/ include:
#
# path("interactions/<int:interaction_id>/accept/", InteractionAcceptAPIView.as_view()),
# path("interactions/<int:interaction_id>/reject/", InteractionRejectAPIView.as_view()),
# path("interactions/<int:interaction_id>/", InteractionDetailAPIView.as_view()),
