# Why Postman "react" does not show a notification

`POST /api/interactions/offers/14/react/` only saves an **Interaction** row.
The Flutter app reads **`GET /api/notifications/me/`** — a separate table.

If your Django react view does not call `create_and_send_notification()`, the client will always see an empty inbox.

---

## Step 1 — Confirm (as the **client**, Aziz)

1. In Postman, **login as the client** who owns offer 14 (not the agent).
2. Copy the client **access** JWT.
3. Request:

```
GET http://127.0.0.1:8000/api/notifications/me/
Authorization: Bearer <CLIENT_ACCESS_TOKEN>
```

4. Also check unread count:

```
GET http://127.0.0.1:8000/api/notifications/me/unread-count/
Authorization: Bearer <CLIENT_ACCESS_TOKEN>
```

**If the list is `[]` and `unread_count` is `0`** → no notification was created in the database. Flutter is working; the backend hook is missing.

---

## Step 2 — Quick test (create one notification manually)

Use any authenticated token:

```
POST http://127.0.0.1:8000/api/notifications/
Authorization: Bearer <TOKEN>
Content-Type: application/json

{
  "user": <CLIENT_USER_ID>,
  "title": "Agent is interested in your offer",
  "body": "Someone liked delivery",
  "type": "PROPOSAL_STATUS",
  "data": {
    "action": "agent_liked_offer",
    "offer_id": 14,
    "agent_id": 18,
    "agent_name": "Agent",
    "offer_title": "delivery",
    "interaction_id": 21
  }
}
```

Replace `<CLIENT_USER_ID>` with Aziz's **CustomUser** id (from login JSON, not agent profile id).

Then repeat Step 1 and open Notifications in the app (pull to refresh).

---

## Step 3 — Permanent fix (react view)

Copy `notify_helpers.py` into your Django project and after saving the interaction:

```python
from interactions.notify_helpers import notify_client_agent_liked_offer

try:
    notify_client_agent_liked_offer(
        interaction=interaction,
        agent_user=request.user,
    )
except Exception:
    import logging
    logging.getLogger(__name__).exception("Failed to notify offer owner")
```

Apply patches from `django_notifications_patches/notifications/` (especially `data` JSONField + `utils.py` group name `notifications_{user.id}`).

Restart Django **ASGI** server (Daphne/Uvicorn) for WebSocket push.

---

## Common mistakes

| Mistake | Result |
|--------|--------|
| React with **agent** token, check notifications while logged in as **agent** | Wrong inbox — notification goes to **offer owner** |
| `user` in POST notification is agent id `18` instead of client user id | Notification created for wrong account |
| Patches not migrated (`data` field missing) | 500 on create |
| Only restarted `runserver` without Channels | DB row exists but no live badge until refresh |
