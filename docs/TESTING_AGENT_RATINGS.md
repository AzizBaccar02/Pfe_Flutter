# Testing: Client rates agent after service completed

## Prerequisites

1. Django API running (`http://127.0.0.1:8000` on web/desktop, `10.0.2.2:8000` on Android emulator).
2. **Client account** logged in on the app.
3. At least one offer where you **accepted an agent** (status `ACCEPTED`) and had a chat.

Optional: implement backend endpoints from `django_ratings_patches/` so ratings sync across devices. Without them, the app uses **local storage** for demo ratings.

---

## Test 1 — Rate after closing from chat

1. Log in as **client**.
2. Open **Chats** and open a conversation tied to an accepted agent.
3. Swipe the chat row (or use menu) → **Close offer** → confirm.
4. **Expected:** Snackbar “offer closed”, then a bottom sheet **“Rate your experience”** with agent name, 5 stars, optional comment.
5. Select **4 or 5 stars** → **Submit rating**.
6. **Expected:** Green snackbar with new average (e.g. `4.8 ★`).
7. Re-open the same chat list — the rating sheet should **not** appear again for that offer/agent.

---

## Test 2 — Rate after “Mark as closed” on offer

1. **My offers** → open an offer with an accepted agent.
2. Menu (⋮) → **Mark as closed**.
3. **Expected:** Rating sheet appears (same as Test 1).
4. On offer details, a green **“Service completed — Rate”** card should show until you submit a rating.

---

## Test 3 — Rate from offer details (later)

1. Close an offer without submitting a rating (**Not now**).
2. Open **Offer details** for that closed offer.
3. Tap **Rate** on the prompt card.
4. Submit a rating.
5. **Expected:** Card disappears after submit.

---

## Test 4 — Pending rating on app launch

1. Close an offer and dismiss the sheet with **Not now**.
2. Fully restart the app (hot restart is enough if `ClientMainScreen` loads).
3. **Expected:** Rating sheet opens once for the oldest pending rating (local queue).

---

## Test 5 — Trust display for other clients

1. After submitting, open **Interested agents** or **Offer details** for another offer with the same agent (if API returns updated `rating` / `completedJobs`).
2. With backend connected, averages should match Postman:

```http
GET /api/ratings/status/?offer_id=12&agent_id=7
Authorization: Bearer <client_token>
```

```http
POST /api/ratings/
Authorization: Bearer <client_token>
Content-Type: application/json

{
  "offer_id": 12,
  "agent_id": 7,
  "stars": 5,
  "comment": "Great job"
}
```

---

## Test 6 — Validation

| Action | Expected |
|--------|----------|
| Submit with 0 stars | Button disabled |
| Rate same offer twice | Second time: no prompt / API 400 |
| Close offer with no accepted agent | No rating sheet |
| Agent account closes offer | No rating sheet (client-only) |

---

## Test 7 — Agent receives rating notification

1. Client submits a rating (Tests 1–3) with Django API + notifications enabled.
2. Log in as the **agent** on another device or emulator.
3. Tap the **bell icon** (Notifications) in the agent app bar.
4. **Expected:** A row like **"Molka Bokri left you 5★ for Home Internet Installation."** with a gold star avatar.
5. Tap the notification → bottom sheet shows stars, offer title, and client comment.
6. **Without backend notification:** The agent will **not** see this until you implement `notify_agent_rating.py` on the server.

---

## Troubleshooting

| Issue | Check |
|-------|--------|
| No rating sheet after close | Agent must be **ACCEPTED** on that offer |
| Sheet shows wrong agent | `linkedAgentId` on chat or first ACCEPTED in interested-agents API |
| Rating not on other devices | Add Django endpoints from `django_ratings_patches/` |
| 404 on submit | Normal in demo mode — rating saved locally |

---

## Files (Flutter)

- `lib/services/agent_rating_service.dart` — API + local fallback
- `lib/screens/offers/client/widgets/rate_agent_sheet.dart` — UI
- `lib/utils/agent_rating_flow.dart` — when to show prompt
- `lib/screens/chats/chats_screen.dart` — after chat close
- `lib/screens/offers/client/offer_detail_screen.dart` — after mark closed + prompt card
