# List pending interactions for an offer (Django)

Flutter calls several URLs; the recommended one is:

```
GET /api/interactions/offers/<offer_id>/interactions/
Authorization: Bearer <client_token>
```

Response `200` — JSON array or paginated `{ "results": [ ... ] }`.

Each item should match your react response shape:

```json
{
  "id": 22,
  "message": "I am interested in this offer.",
  "proposedPrice": "700.00",
  "status": "PENDING",
  "agent": 10,
  "agent_email": "agent@example.com",
  "agent_name": "Molka Bakri",
  "offre": 14,
  "offer_title": "delivery",
  "react": true
}
```

## Example DRF view (add to your interactions app)

```python
# interactions/views.py
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import Interaction  # adjust import
from .serializers import InteractionSerializer  # adjust import


class OfferInteractionsListAPIView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, offer_id, *args, **kwargs):
        qs = Interaction.objects.filter(
            offre_id=offer_id,
            status="PENDING",
        ).select_related("agent", "offre").order_by("-created_at")

        # Only the offer owner (client) should see these
        offer = qs.first().offre if qs.exists() else None
        if offer is not None:
            client_user = getattr(offer, "client", None)
            if hasattr(client_user, "user"):
                client_user = client_user.user
            if client_user is not None and client_user != request.user:
                return Response({"detail": "Forbidden"}, status=403)

        data = InteractionSerializer(qs, many=True).data
        return Response(data)
```

```python
# interactions/urls.py
path(
    "interactions/offers/<int:offer_id>/interactions/",
    OfferInteractionsListAPIView.as_view(),
    name="offer-interactions-list",
),
```

After adding this route, Flutter will stop logging failures for `/pending/` and load agents from `/interactions/`.
