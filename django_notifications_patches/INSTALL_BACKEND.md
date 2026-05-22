# Professional notifications backend — install guide

Your current backend has **4 critical bugs** that explain why Flutter shows `"Someone liked delivery"` with no photo and no tap actions.

---

## Problems in your current code

| Issue | Your code | What Flutter needs |
|--------|-----------|-------------------|
| **WebSocket group mismatch** | `utils.py` sends to `user_notifications_{id}` | Consumer listens on `notifications_{id}` → **live push never arrives** |
| **No `data` field** | Model has no JSONField | `agent_id`, `offer_id`, `agent_name`, `avatar_url`, `action` |
| **Serializer omits `data`** | Only id, title, body… | `GET /api/notifications/me/` must return `data` |
| **Create view ignores `data`** | POST only saves title/body | Rich payload lost |
| **React view** | Only creates Interaction | Must call `notify_client_agent_liked_offer()` |

Also fix the typo in `urls.py`: `notificat\nions/` → `notifications/`.

---

## Step 1 — Copy patched files

From this repo folder `django_notifications_patches/notifications/` into your Django project `notifications/`:

- `models.py`
- `serializers.py`
- `views.py`
- `utils.py` (**replace** your file — fixes group name)
- `payloads.py` (**new**)
- `consumers.py` (JWT + correct group — optional if yours already matches)
- `urls.py` (add `notifications/me/<id>/read/`)

From `django_interactions_patches/notify_helpers.py` → `interactions/notify_helpers.py`

---

## Step 2 — Migrate

```bash
python manage.py makemigrations notifications
python manage.py migrate notifications
```

If you already have migration `0003`, ensure it adds:

```python
migrations.AddField(
    model_name="notification",
    name="data",
    field=models.JSONField(blank=True, default=dict),
),
```

---

## Step 3 — Hook react / accept / reject (interactions app)

In your **react** view, after saving the interaction:

```python
from interactions.notify_helpers import notify_client_agent_liked_offer

try:
    notify_client_agent_liked_offer(
        interaction=interaction,
        agent_user=request.user,
        request=request,
    )
except Exception:
    import logging
    logging.getLogger(__name__).exception("notify_client_agent_liked_offer failed")
```

In **accept** view:

```python
from interactions.notify_helpers import notify_agent_client_accepted

notify_agent_client_accepted(
    interaction=interaction,
    client_user=request.user,
    request=request,
)
```

In **reject** view:

```python
from interactions.notify_helpers import notify_agent_client_rejected

notify_agent_client_rejected(
    interaction=interaction,
    client_user=request.user,
    request=request,
)
```

---

## Step 4 — User profile photo

`payloads.resolve_user_avatar_url()` looks for photo on:

- `user.photo`, `user.avatar`
- `user.agent_profile.photo`, `user.client_profile.photo`

If your field is different (e.g. `Agent.photo`), add one line in `payloads.py`:

```python
value = getattr(user, "your_field", None)
```

Photos must be absolute URLs or paths Django can build with `request.build_absolute_uri()`.

---

## Step 5 — Security

Change `NotificationCreateAPIView` from `AllowAny` to `IsAuthenticated` (included in patched `views.py`).

Only your react/accept/reject views or admins should create notifications for other users.

---

## Step 6 — Restart ASGI

```bash
daphne -b 0.0.0.0 -p 8000 config.asgi:application
```

`runserver` alone may not run Channels WebSockets correctly.

---

## Example API response (what Flutter receives)

```json
{
  "id": 5,
  "title": "Molka Bakri is interested in your offer",
  "body": "Molka Bakri liked your offer \"delivery\".",
  "type": "PROPOSAL_STATUS",
  "isRead": false,
  "created_at": "2026-05-15T19:50:01.914693Z",
  "user": 3,
  "data": {
    "action": "agent_liked_offer",
    "offer_id": 14,
    "offer_title": "delivery",
    "agent_id": 10,
    "agent_name": "Molka Bakri",
    "agent_email": "bokrimolka2@gmail.com",
    "avatar_url": "http://127.0.0.1:8000/media/agents/photo.jpg",
    "interaction_id": 22,
    "proposed_price": "700.00",
    "message": "I am interested in this offer."
  }
}
```

Flutter already reads `data.agent_name`, `data.avatar_url`, and opens accept/reject on tap.

---

## Postman test (manual create)

```http
POST http://127.0.0.1:8000/api/notifications/
Authorization: Bearer <token>
Content-Type: application/json

{
  "user": <CLIENT_USER_ID>,
  "title": "Molka Bakri is interested in your offer",
  "body": "Molka Bakri liked your offer \"delivery\".",
  "type": "PROPOSAL_STATUS",
  "data": {
    "action": "agent_liked_offer",
    "offer_id": 14,
    "offer_title": "delivery",
    "agent_id": 10,
    "agent_name": "Molka Bakri",
    "agent_email": "bokrimolka2@gmail.com",
    "avatar_url": "http://127.0.0.1:8000/media/...",
    "interaction_id": 22
  }
}
```

Then as **client**: `GET /api/notifications/me/`
