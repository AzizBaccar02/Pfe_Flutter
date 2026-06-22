# User online / offline (Django)

The Flutter app marks presence when:

1. **Login** — `PresenceService.activate()` (REST + `ws/chats/inbox/` connect)
2. **Logout** — `PresenceService.deactivate()` (REST + inbox socket disconnect)
3. **Heartbeat** — `POST .../online/` every 30s while the session is active

## Recommended backend

### Option A — Inbox WebSocket (preferred)

In `UserChatsConsumer.connect()` set `user.is_online = True` and broadcast:

```python
{"type": "presence_update", "user_id": <id>, "is_online": true}
```

In `disconnect()` set offline and broadcast `is_online: false`.

### Option B — REST endpoints

Wire any of these (Flutter tries them in order):

| Online | Offline |
|--------|---------|
| `POST /api/users/me/online/` | `POST /api/users/me/offline/` |
| `POST /api/users/presence/online/` | `POST /api/users/presence/offline/` |
| `POST /api/chats/presence/online/` | `POST /api/chats/presence/offline/` |

Return `200`/`204`. Use JWT auth like other `/api/` routes.

### Chat list API

Include `is_online` / `isOnline` on `client`, `agent`, and `other_user` in `GET /api/chats/list/` so the green dot renders before the first WebSocket event.
