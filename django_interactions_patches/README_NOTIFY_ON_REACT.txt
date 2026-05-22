Add this to your Django interaction "react" view AFTER the interaction is saved.
Replace model paths with your actual Offre / Interaction models.

from notifications.utils import create_and_send_notification

# Example inside react view after interaction = Interaction.objects.create(...)
client_user = interaction.offre.client  # or interaction.offre.user
agent_name = request.user.get_full_name() or request.user.username

create_and_send_notification(
    user=client_user,
    title=f"{agent_name} is interested in your offer",
    body=f'{agent_name} reacted to "{interaction.offre.title}".',
    notification_type="PROPOSAL_STATUS",
    data={
        "action": "agent_liked_offer",
        "offer_id": interaction.offre_id,
        "agent_id": request.user.id,
        "agent_name": agent_name,
        "offer_title": interaction.offre.title,
        "interaction_id": interaction.id,
    },
)

Without this hook, Postman react works but the client never receives a notification.

--- Client accept (notify agent) ---

create_and_send_notification(
    user=interaction.agent,  # agent user account
    title=f"{client_name} accepted your interest",
    body=f'Your interest on "{interaction.offre.title}" was accepted.',
    notification_type="PROPOSAL_STATUS",
    data={
        "action": "client_accepted",
        "offer_id": interaction.offre_id,
        "client_id": request.user.id,
        "client_name": client_name,
        "offer_title": interaction.offre.title,
        "interaction_id": interaction.id,
    },
)

--- Client reject (notify agent) ---

create_and_send_notification(
    user=interaction.agent,
    title=f"{client_name} declined your interest",
    body=f'Your interest on "{interaction.offre.title}" was declined.',
    notification_type="PROPOSAL_STATUS",
    data={
        "action": "client_rejected",
        "offer_id": interaction.offre_id,
        "client_id": request.user.id,
        "client_name": client_name,
        "offer_title": interaction.offre.title,
        "interaction_id": interaction.id,
    },
)
