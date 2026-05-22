# notifications/payloads.py — build rich `data` for Flutter (name, photo, ids).

from __future__ import annotations

from typing import Any, Dict, Optional


def display_name(user) -> str:
    if user is None:
        return "User"

    full = ""
    if hasattr(user, "get_full_name"):
        full = (user.get_full_name() or "").strip()

    if full:
        return full

    username = getattr(user, "username", "") or ""
    if username.strip():
        return username.strip()

    email = getattr(user, "email", "") or ""
    if "@" in email:
        local = email.split("@", 1)[0]
        return local.replace(".", " ").replace("_", " ").title()

    return "User"


def resolve_media_url(request, value: Optional[str]) -> str:
    if not value:
        return ""

    text = str(value).strip()
    if not text:
        return ""

    if text.startswith("http://") or text.startswith("https://"):
        return text

    if request is not None:
        return request.build_absolute_uri(text)

    return text


def resolve_user_avatar_url(user, request=None) -> str:
    """Try common profile photo fields on CustomUser / Agent / Client."""
    if user is None:
        return ""

    candidates = []

    for attr in ("photo", "avatar", "image", "profile_picture", "profilePhoto"):
        value = getattr(user, attr, None)
        if value:
            candidates.append(value)

    for profile_attr in ("agent_profile", "agent", "client_profile", "client"):
        profile = getattr(user, profile_attr, None)
        if profile is None:
            continue

        for attr in ("photo", "avatar", "image", "profile_picture"):
            value = getattr(profile, attr, None)
            if value:
                candidates.append(value)

    for value in candidates:
        if hasattr(value, "url"):
            return resolve_media_url(request, value.url)
        return resolve_media_url(request, str(value))

    return ""


def build_agent_liked_offer_data(
    *,
    offer,
    interaction,
    agent_user,
    request=None,
) -> Dict[str, Any]:
    offer_id = getattr(offer, "id", None)
    offer_title = getattr(offer, "title", "") or ""
    agent_name = display_name(agent_user)
    agent_id = getattr(agent_user, "id", None)

    return {
        "action": "agent_liked_offer",
        "offer_id": offer_id,
        "offer_title": offer_title,
        "agent_id": agent_id,
        "agent_name": agent_name,
        "agent_email": getattr(agent_user, "email", "") or "",
        "avatar_url": resolve_user_avatar_url(agent_user, request),
        "interaction_id": getattr(interaction, "id", None),
        "proposed_price": _interaction_price(interaction),
        "message": getattr(interaction, "message", "") or "",
    }


def build_client_accepted_data(
    *,
    offer,
    interaction,
    client_user,
    request=None,
) -> Dict[str, Any]:
    client_name = display_name(client_user)

    return {
        "action": "client_accepted",
        "offer_id": getattr(offer, "id", None),
        "offer_title": getattr(offer, "title", "") or "",
        "client_id": getattr(client_user, "id", None),
        "client_name": client_name,
        "avatar_url": resolve_user_avatar_url(client_user, request),
        "interaction_id": getattr(interaction, "id", None),
    }


def build_client_rejected_data(
    *,
    offer,
    interaction,
    client_user,
    request=None,
) -> Dict[str, Any]:
    client_name = display_name(client_user)

    return {
        "action": "client_rejected",
        "offer_id": getattr(offer, "id", None),
        "offer_title": getattr(offer, "title", "") or "",
        "client_id": getattr(client_user, "id", None),
        "client_name": client_name,
        "avatar_url": resolve_user_avatar_url(client_user, request),
        "interaction_id": getattr(interaction, "id", None),
    }


def _interaction_price(interaction) -> Optional[str]:
    for attr in ("proposedPrice", "proposed_price", "price"):
        value = getattr(interaction, attr, None)
        if value is not None:
            return str(value)
    return None
