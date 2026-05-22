# Accept / Decline agent interest (fix HTTP 404)

Flutter calls these endpoints when the client taps **Accept agent** or **Decline**:

```
POST /api/interactions/<interaction_id>/accept/
POST /api/interactions/<interaction_id>/reject/
PATCH /api/interactions/<interaction_id>/   { "status": "ACCEPTED" | "REJECTED" }
```

If none of these exist in Django, the app shows **HTTP 404**.

## Quick fix

1. Copy `accept_reject_views.py` into your `interactions` app.
2. Wire URLs in `interactions/urls.py`:

```python
from .accept_reject_views import (
    InteractionAcceptAPIView,
    InteractionRejectAPIView,
    InteractionDetailAPIView,
)

urlpatterns = [
    # ... your existing react route ...
    path(
        "interactions/<int:interaction_id>/accept/",
        InteractionAcceptAPIView.as_view(),
    ),
    path(
        "interactions/<int:interaction_id>/reject/",
        InteractionRejectAPIView.as_view(),
    ),
    path(
        "interactions/<int:interaction_id>/",
        InteractionDetailAPIView.as_view(),
    ),
]
```

3. Adjust imports (`Interaction`, `InteractionSerializer`) to match your project.
4. Ensure `Interaction.status` accepts `ACCEPTED` and `REJECTED`.
5. Copy `notify_helpers.py` and call notifications from accept/reject (included in the views).
6. Restart Django: `python manage.py runserver` or daphne.

## Postman test (as client / offer owner)

```http
POST http://127.0.0.1:8000/api/interactions/22/accept/
Authorization: Bearer <client_token>
Content-Type: application/json

{}
```

Expected: `200` with interaction JSON and `status: "ACCEPTED"`.

```http
POST http://127.0.0.1:8000/api/interactions/22/reject/
Authorization: Bearer <client_token>
```

Expected: `200` with `status: "REJECTED"`.

## Notes

- Only the **offer owner (client)** should be allowed to accept/reject.
- `interaction_id` must be the real DB id (e.g. `22`), not the agent profile id.
- After accept, the agent should receive a notification (`notify_agent_client_accepted`).
