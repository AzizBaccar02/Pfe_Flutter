# Example — add to your interactions or reviews app

from django.conf import settings
from django.core.validators import MaxValueValidator, MinValueValidator
from django.db import models


class AgentRating(models.Model):
    client = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='agent_ratings_given',
    )
    agent = models.ForeignKey(
        'agents.AgentProfile',  # adjust to your agent model
        on_delete=models.CASCADE,
        related_name='ratings_received',
    )
    offer = models.ForeignKey(
        'offers.Offer',
        on_delete=models.CASCADE,
        related_name='agent_ratings',
    )
    reaction = models.ForeignKey(
        'interactions.OfferReaction',
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
    )
    chat = models.ForeignKey(
        'chats.Chat',
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
    )
    stars = models.PositiveSmallIntegerField(
        validators=[MinValueValidator(1), MaxValueValidator(5)],
    )
    comment = models.TextField(blank=True, default='')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        constraints = [
            models.UniqueConstraint(
                fields=['client', 'offer', 'agent'],
                name='uniq_client_offer_agent_rating',
            ),
        ]

    def __str__(self):
        return f'{self.stars}★ offer={self.offer_id} agent={self.agent_id}'
