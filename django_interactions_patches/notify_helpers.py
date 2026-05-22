# Copy into your Django project: interactions/notify_helpers.py

from __future__ import annotations

from typing import Any, Optional

from notifications.payloads import (
    build_agent_liked_offer_data,
    build_client_accepted_data,
    build_client_rejected_data,
    display_name,
)
from notifications.utils import create_and_send_notification


def _resolve_user(obj: Any):
    if obj is None:
        return None

    if hasattr(obj, "is_authenticated"):
        return obj

    for attr in ("user", "account", "customuser", "custom_user"):
        nested = getattr(obj, attr, None)
        if nested is not None and hasattr(nested, "is_authenticated"):
            return nested

    return None


def resolve_offer_client_user(offer) -> Optional[Any]:
    if offer is None:
        return None

    for attr in ("client", "owner", "created_by", "user"):
        candidate = getattr(offer, attr, None)
        user = _resolve_user(candidate)
        if user is not None:
            return user

    return _resolve_user(offer)


def resolve_interaction_agent_user(interaction) -> Optional[Any]:
    if interaction is None:
        return None

    for attr in ("agent", "agent_user", "user"):
        candidate = getattr(interaction, attr, None)
        user = _resolve_user(candidate)
        if user is not None:
            return user

    return None


def resolve_interaction_offer(interaction):
    for attr in ("offre", "offer"):
        offer = getattr(interaction, attr, None)
        if offer is not None:
            return offer
    return None


def notify_client_agent_liked_offer(*, interaction, agent_user, request=None) -> None:
    offer = resolve_interaction_offer(interaction)
    client_user = resolve_offer_client_user(offer)

    if client_user is None:
        raise ValueError(
            "Could not resolve offer owner user. "
            "Check Offre.client / Offre.user on your model."
        )

    agent_name = display_name(agent_user)
    offer_title = getattr(offer, "title", "") or ""
    data = build_agent_liked_offer_data(
        offer=offer,
        interaction=interaction,
        agent_user=agent_user,
        request=request,
    )

    create_and_send_notification(
        user=client_user,
        title=f"{agent_name} is interested in your offer",
        body=f'{agent_name} liked your offer "{offer_title}".',
        notification_type="PROPOSAL_STATUS",
        data=data,
        request=request,
    )


def notify_agent_client_accepted(*, interaction, client_user, request=None) -> None:
    offer = resolve_interaction_offer(interaction)
    agent_user = resolve_interaction_agent_user(interaction)

    if agent_user is None:
        raise ValueError("Could not resolve agent user on interaction.")

    client_name = display_name(client_user)
    offer_title = getattr(offer, "title", "") or ""
    data = build_client_accepted_data(
        offer=offer,
        interaction=interaction,
        client_user=client_user,
        request=request,
    )

    create_and_send_notification(
        user=agent_user,
        title=f"{client_name} accepted your interest",
        body=f'Your interest on "{offer_title}" was accepted.',
        notification_type="PROPOSAL_STATUS",
        data=data,
        request=request,
    )


def notify_agent_client_rejected(*, interaction, client_user, request=None) -> None:
    offer = resolve_interaction_offer(interaction)
    agent_user = resolve_interaction_agent_user(interaction)

    if agent_user is None:
        raise ValueError("Could not resolve agent user on interaction.")

    client_name = display_name(client_user)
    offer_title = getattr(offer, "title", "") or ""
    data = build_client_rejected_data(
        offer=offer,
        interaction=interaction,
        client_user=client_user,
        request=request,
    )

    create_and_send_notification(
        user=agent_user,
        title=f"{client_name} declined your interest",
        body=f'Your interest on "{offer_title}" was declined.',
        notification_type="PROPOSAL_STATUS",
        data=data,
        request=request,
    )
