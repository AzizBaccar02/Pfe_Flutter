# Agent public profile (photo, city, phone) for clients

Flutter loads agent details from (in order):

1. **Interaction JSON** — nested `agent` object on `GET /api/interactions/{id}/` or list endpoints
2. **Public profile API** — one of the URLs below
3. **Notification `data`** — `avatar_url`, `agent_name`, `agent_email`

## Required backend shape

### Option A — nested agent on interaction (recommended)

```json
{
  "id": 22,
  "offre": 14,
  "agent": {
    "id": 10,
    "user": 5,
    "firstName": "Molka",
    "lastName": "Bokri",
    "email": "bokrimolka2@gmail.com",
    "photo": "/media/agents/photo.jpg",
    "phone": "+216...",
    "city": "Tunis",
    "bio": "...",
    "skills": "...",
    "hourlyRate": 25
  },
  "status": "PENDING",
  "react": true
}
```

### Option B — public profile endpoint

Add a read-only view, e.g.:

- `GET /api/users/agents/{user_id}/`
- or `GET /api/users/agent/profile/{user_id}/`

Response (any of these field names work):

```json
{
  "first_name": "Molka",
  "last_name": "Bokri",
  "photo": "/media/...",
  "phone": "...",
  "city": "Tunis",
  "hourlyRate": 25,
  "bio": "...",
  "skills": "..."
}
```

Use **`user.id`** (CustomUser), not only AgentProfile.pk, in notification `data.agent_id` if they differ.

### Notifications

Ensure react creates notification with rich `data` (see `notifications/payloads.py`):

- `avatar_url` — absolute or `/media/...` URL
- `agent_name`, `agent_email`, `interaction_id`, `offer_id`

Copy `django_notifications_patches` and `notify_helpers.py` into your Django project and call `notify_client_agent_liked_offer()` from the react view.
