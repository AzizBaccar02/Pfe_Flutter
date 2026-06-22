# urlpatterns fragment

from django.urls import path

# from .ratings_views_example import (
#     PendingRatingsView,
#     RatingStatusView,
#     SubmitAgentRatingView,
# )

urlpatterns = [
    path('api/ratings/', SubmitAgentRatingView.as_view()),
    path('api/ratings/me/', AgentMyRatingSummaryView.as_view()),
    path('api/ratings/pending/', PendingRatingsView.as_view()),
    path('api/ratings/status/', RatingStatusView.as_view()),
]
