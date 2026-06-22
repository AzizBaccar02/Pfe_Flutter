# Agent ratings API (Django backend)

The Flutter app calls these endpoints so **clients can rate agents after a service is completed** (offer closed + accepted agent).

## Endpoints

| Method | Path | Role | Purpose |
|--------|------|------|---------|
| `POST` | `/api/ratings/` | Client | Submit 1–5 stars + optional comment |
| `GET` | `/api/ratings/pending/` | Client | Closed offers with accepted agent, not yet rated |
| `GET` | `/api/ratings/status/?offer_id=&agent_id=` | Client | `{ "hasRated": true/false }` |

### POST body

```json
{
  "offer_id": 12,
  "agent_id": 7,
  "reaction_id": 33,
  "chat_id": 5,
  "stars": 5,
  "comment": "Professional and on time."
}
```

### POST response (201)

```json
{
  "rating": {
    "id": 1,
    "offer_id": 12,
    "agent_id": 7,
    "stars": 5,
    "comment": "Professional and on time.",
    "created_at": "2026-05-24T12:00:00Z"
  },
  "agent_average_rating": 4.8,
  "agent_rating_count": 12
}
```

## Business rules

1. Only users with role **CLIENT** may create ratings.
2. Offer must be **closed** (or chat closed via `/api/chats/{id}/close/`).
3. There must be an **ACCEPTED** interaction between that client, offer, and agent.
4. **One rating per** `(client, offer, agent)` — return `400` on duplicate.
5. Update agent aggregates: `rating` (average), `completed_jobs` / `rating_count` on interested-agents and public profile payloads.

## Include in existing list APIs

Add to `GET /api/interactions/client/interested-agents/`:

```json
{
  "id": 7,
  "rating": 4.8,
  "completedJobs": 12,
  "hasRated": false
}
```

## Files in this folder

- `ratings_models_example.py` — model sketch
- `ratings_views_example.py` — DRF-style view sketch
- `urls_example.py` — URL wiring

Copy into your Django project and adjust app names / imports.

## Agent notification (where the agent sees the rating)

When a client submits a rating, the **agent** should receive an in-app notification:

| Field | Value |
|-------|--------|
| `type` | `AGENT_RATED` (or use `data.action`) |
| `data.action` | `agent_received_rating` |
| `data.stars` | `1`–`5` |
| `data.client_name` | Client display name |
| `data.offer_title` | Offer title |
| `data.comment` | Optional feedback |

Example title: `Molka Bokri rated you 5★`

**Flutter:** Agent opens the **bell icon → Notifications** (same inbox as match alerts). Tap the row to see stars, offer, and comment.

See `notify_agent_rating.py` for a Django helper to create the notification after `POST /api/ratings/`.

## Flutter without backend

If endpoints return **404**, the app still saves ratings **locally on the client's phone** so you can demo the UI. **The agent app on another device will still show "No ratings yet"** until you implement these endpoints and update the agent profile (`rating`, `ratingCount` on `GET /api/users/agent/profile/me/`).

Quick check (server running):

```http
GET http://127.0.0.1:8000/api/ratings/status/
```

- **404** → not wired; copy `ratings_views_example.py` + `urls_example.py` into your Django project.
- **401/200** → route exists; implement `POST /api/ratings/` and call `notify_agent_rating.py` after save.

**Agent notifications require the backend** to create the notification row.
