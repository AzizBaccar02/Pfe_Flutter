# Example DRF views — adapt imports and permission classes to your project.

from django.db.models import Avg, Count
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

# from .models import AgentRating, OfferReaction, Offer
# from .permissions import IsClient


class RatingStatusView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        offer_id = int(request.query_params.get('offer_id', 0))
        agent_id = int(request.query_params.get('agent_id', 0))
        has_rated = AgentRating.objects.filter(
            client=request.user,
            offer_id=offer_id,
            agent_id=agent_id,
        ).exists()
        return Response({'hasRated': has_rated, 'has_rated': has_rated})


class PendingRatingsView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        # Pseudocode: closed offers + accepted reaction + no AgentRating row
        pending = []  # build list of dicts matching Flutter PendingAgentRating
        return Response(pending)


class AgentMyRatingSummaryView(APIView):
    """GET /api/ratings/me/ — logged-in agent's average + count."""

    permission_classes = [IsAuthenticated]

    def get(self, request):
        # agent_profile = request.user.agent_profile
        # return Response({
        #     'agent_average_rating': agent_profile.rating,
        #     'agent_rating_count': agent_profile.rating_count,
        # })
        return Response(
            {
                'agent_average_rating': 0,
                'agent_rating_count': 0,
            }
        )


class SubmitAgentRatingView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        offer_id = request.data.get('offer_id') or request.data.get('offerId')
        agent_id = request.data.get('agent_id') or request.data.get('agentId')
        stars = int(request.data.get('stars') or 0)
        comment = (request.data.get('comment') or '').strip()

        if stars < 1 or stars > 5:
            return Response(
                {'detail': 'stars must be between 1 and 5'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Validate: offer closed, reaction ACCEPTED, request.user is client owner
        # rating, created = AgentRating.objects.get_or_create(...)
        # agg = AgentRating.objects.filter(agent_id=agent_id).aggregate(
        #     avg=Avg('stars'), count=Count('id'),
        # )

        # Notify the agent (in-app + WebSocket) — see notify_agent_rating.py
        # notify_agent_rating(
        #     agent_user=agent.user,
        #     client_user=request.user,
        #     offer=offer,
        #     stars=stars,
        #     comment=comment,
        # )

        return Response(
            {
                'rating': {
                    'id': 1,
                    'offer_id': offer_id,
                    'agent_id': agent_id,
                    'stars': stars,
                    'comment': comment,
                },
                'agent_average_rating': 4.8,
                'agent_rating_count': 3,
            },
            status=status.HTTP_201_CREATED,
        )
