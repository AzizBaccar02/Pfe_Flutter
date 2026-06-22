import 'chat_conversation_summary_model.dart';
import 'offer_interaction_model.dart';

/// Result of resolving whether an agent-interest notification is still actionable.
class InterestResolution {
  final OfferInteractionModel? reaction;
  final ChatConversationSummaryModel? chat;
  final bool inferredAcceptedFromChat;

  const InterestResolution({
    this.reaction,
    this.chat,
    this.inferredAcceptedFromChat = false,
  });

  bool get isAccepted =>
      (reaction != null && _isAccepted(reaction!.status)) || chat != null;

  bool get isRejected =>
      reaction != null && _isRejected(reaction!.status);

  bool get isPending => !isAccepted && !isRejected;

  static bool _isAccepted(String? status) =>
      status?.trim().toUpperCase() == 'ACCEPTED';

  static bool _isRejected(String? status) =>
      status?.trim().toUpperCase() == 'REJECTED';
}
