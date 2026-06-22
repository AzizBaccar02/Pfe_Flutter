import '../utils/skills_match_utils.dart';
import '../utils/tunisia_location_utils.dart';

/// AI-ranked offer from `GET /api/ai-recommendations/offers/`.
class RecommendedOfferModel {
  final int id;
  final String title;
  final String description;
  final double budget;
  final String status;
  final String category;
  final String city;
  final String address;
  final String postalCode;
  final int clientId;
  final String clientUsername;
  final double clientRating;
  final String clientCity;
  final DateTime? createdAt;

  final double matchScore;
  final double skillsScore;
  final double semanticScore;
  final double keywordSkillsScore;
  final int locationBoost;
  final int locationTier;
  final String locationLabel;
  final int budgetBoost;
  final int clientRatingBoost;
  final String matchLevel;
  final List<String> aiReasons;

  const RecommendedOfferModel({
    required this.id,
    required this.title,
    required this.description,
    required this.budget,
    required this.status,
    required this.category,
    required this.city,
    required this.address,
    required this.postalCode,
    required this.clientId,
    required this.clientUsername,
    required this.clientRating,
    required this.clientCity,
    required this.createdAt,
    required this.matchScore,
    required this.skillsScore,
    required this.semanticScore,
    required this.keywordSkillsScore,
    required this.locationBoost,
    required this.locationTier,
    required this.locationLabel,
    required this.budgetBoost,
    required this.clientRatingBoost,
    required this.matchLevel,
    required this.aiReasons,
  });

  static const int tierSameCity = 3;
  static const int tierNearby = 2;
  static const int tierOther = 1;
  static const int tierUnknown = 0;

  factory RecommendedOfferModel.fromJson(Map<String, dynamic> json) {
    final reasonsRaw = json['aiReasons'];
    final reasons = <String>[];
    if (reasonsRaw is List) {
      for (final reason in reasonsRaw) {
        final text = reason.toString().trim();
        if (text.isNotEmpty) reasons.add(text);
      }
    }

    return RecommendedOfferModel(
      id: _asInt(json['id']),
      title: (json['title'] ?? '').toString().trim(),
      description: (json['description'] ?? '').toString().trim(),
      budget: _asDouble(json['budget']),
      status: (json['status'] ?? '').toString().trim(),
      category: (json['category'] ?? '').toString().trim(),
      city: (json['city'] ?? '').toString().trim(),
      address: (json['address'] ?? '').toString().trim(),
      postalCode: (json['postalCode'] ?? '').toString().trim(),
      clientId: _asInt(json['clientId']),
      clientUsername: (json['clientUsername'] ?? '').toString().trim(),
      clientRating: _asDouble(json['clientRating']),
      clientCity: (json['clientCity'] ?? '').toString().trim(),
      createdAt: _parseDate(json['createdAt']),
      matchScore: _asDouble(json['matchScore']),
      skillsScore: _asDouble(json['skillsScore'] ?? json['semanticScore']),
      semanticScore: _asDouble(json['semanticScore']),
      keywordSkillsScore: _asDouble(json['keywordSkillsScore']),
      locationBoost: _asInt(json['locationBoost']),
      locationTier: _asInt(json['locationTier']),
      locationLabel: (json['locationLabel'] ?? '').toString().trim(),
      budgetBoost: _asInt(json['budgetBoost']),
      clientRatingBoost: _asInt(json['clientRatingBoost']),
      matchLevel: (json['matchLevel'] ?? '').toString().trim(),
      aiReasons: reasons,
    );
  }

  String get budgetLabel {
    if (budget <= 0) return 'Budget not set';
    final whole = budget == budget.roundToDouble();
    final value = whole ? budget.round().toString() : budget.toStringAsFixed(0);
    return '$value DT';
  }

  String get matchScoreLabel => '${matchScore.round()}% match';

  /// True when the backend ran sentence-embedding (NLP) scoring.
  bool get hasNlpScore => semanticScore > 0.01;

  String get skillsMatchLabel => hasNlpScore
      ? '${semanticScore.round()}% skill fit'
      : '${skillsScore.round()}% skills';

  String get subtitle {
    final location = displayCity.isNotEmpty ? displayCity : 'Location TBD';
    final cat = category.isNotEmpty ? category : 'General';
    return '$location · $cat';
  }

  String get displayCity {
    if (city.isNotEmpty) return city;
    if (clientCity.isNotEmpty) return clientCity;
    return '';
  }

  bool get isSameCity => locationTier == tierSameCity;

  bool get isNearby => locationTier == tierNearby;

  String get offerCityKey =>
      TunisiaLocationUtils.normalizeCityKey(city, address);

  double relevanceForAgent(List<String> agentSkillTokens) =>
      SkillsMatchUtils.relevanceScore(
        agentSkillTokens,
        title: title,
        description: description,
        category: category,
        semanticScore: semanticScore,
        keywordSkillsScore: keywordSkillsScore,
      );

  RecommendedOfferModel copyWith({
    String? locationLabel,
    int? locationTier,
  }) {
    return RecommendedOfferModel(
      id: id,
      title: title,
      description: description,
      budget: budget,
      status: status,
      category: category,
      city: city,
      address: address,
      postalCode: postalCode,
      clientId: clientId,
      clientUsername: clientUsername,
      clientRating: clientRating,
      clientCity: clientCity,
      createdAt: createdAt,
      matchScore: matchScore,
      skillsScore: skillsScore,
      semanticScore: semanticScore,
      keywordSkillsScore: keywordSkillsScore,
      locationBoost: locationBoost,
      locationTier: locationTier ?? this.locationTier,
      locationLabel: locationLabel ?? this.locationLabel,
      budgetBoost: budgetBoost,
      clientRatingBoost: clientRatingBoost,
      matchLevel: matchLevel,
      aiReasons: aiReasons,
    );
  }

  RecommendedOfferModel withProximityContext({
    required String agentCityKey,
    required String agentCityDisplay,
  }) {
    final tier = agentCityKey.isEmpty
        ? locationTier
        : TunisiaLocationUtils.locationTier(
            agentCityKey: agentCityKey,
            offerCityKey: offerCityKey,
          );

    return copyWith(
      locationTier: tier,
      locationLabel: TunisiaLocationUtils.buildProximityLabel(
        agentCityDisplay: agentCityDisplay,
        agentCityKey: agentCityKey,
        offerCityDisplay: displayCity,
        offerCityKey: offerCityKey,
        locationTier: tier,
      ),
    );
  }

  static int _asInt(dynamic value) => int.tryParse(value?.toString() ?? '') ?? 0;

  static double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}

class AiRecommendationsResult {
  final String agentCity;
  final String sortBy;
  final List<RecommendedOfferModel> offers;

  const AiRecommendationsResult({
    required this.agentCity,
    required this.sortBy,
    required this.offers,
  });
}

class RecommendedOfferSection {
  final int locationTier;
  final String title;
  final String subtitle;
  final List<RecommendedOfferModel> offers;

  const RecommendedOfferSection({
    required this.locationTier,
    required this.title,
    required this.subtitle,
    required this.offers,
  });
}

/// Location first (tier → distance band), then NLP semantic score, then combined match %.
int compareRecommendedOffersByLocationAndNlp(
  RecommendedOfferModel a,
  RecommendedOfferModel b, {
  required String agentCityKey,
}) {
  if (a.locationTier != b.locationTier) {
    return b.locationTier.compareTo(a.locationTier);
  }

  // Within the same area: skills (NLP) before fine distance differences.
  final nlpCompare = b.semanticScore.compareTo(a.semanticScore);
  if (nlpCompare != 0) return nlpCompare;

  if (agentCityKey.isNotEmpty) {
    final distCompare = TunisiaLocationUtils.compareDistanceBands(
      TunisiaLocationUtils.distanceKm(agentCityKey, a.offerCityKey),
      TunisiaLocationUtils.distanceKm(agentCityKey, b.offerCityKey),
    );
    if (distCompare != 0) return distCompare;
  }

  // Backend combined score (location boosts + NLP + keywords).
  final matchCompare = b.matchScore.compareTo(a.matchScore);
  if (matchCompare != 0) return matchCompare;

  final keywordCompare = b.keywordSkillsScore.compareTo(a.keywordSkillsScore);
  if (keywordCompare != 0) return keywordCompare;

  return b.skillsScore.compareTo(a.skillsScore);
}

/// Sorts AI recommendations: nearest areas first, then NLP fit within each band.
List<RecommendedOfferModel> sortRecommendedOffersByLocationAndNlp({
  required List<RecommendedOfferModel> offers,
  required String agentCityKey,
  required String agentCityDisplay,
  List<String> agentSkillTokens = const [],
}) {
  var working = List<RecommendedOfferModel>.from(offers);

  if (agentSkillTokens.isNotEmpty) {
    working = _demoteWeakSkillMatches(working, agentSkillTokens);
  }

  working.sort(
    (a, b) => compareRecommendedOffersByLocationAndNlp(
      a,
      b,
      agentCityKey: agentCityKey,
    ),
  );

  return working
      .map(
        (offer) => offer.withProximityContext(
          agentCityKey: agentCityKey,
          agentCityDisplay: agentCityDisplay,
        ),
      )
      .toList();
}

/// Hides poor skill fits in the same city when much better matches exist (e.g. pet care).
List<RecommendedOfferModel> _demoteWeakSkillMatches(
  List<RecommendedOfferModel> offers,
  List<String> agentSkillTokens,
) {
  final scored = offers
      .map((o) => MapEntry(o, o.relevanceForAgent(agentSkillTokens)))
      .toList();

  final bestRelevance = scored.fold<double>(
    0,
    (max, e) => e.value > max ? e.value : max,
  );

  if (bestRelevance < 50) return offers;

  final strong = <RecommendedOfferModel>[];
  final weak = <RecommendedOfferModel>[];

  for (final entry in scored) {
    final isWeakLocal =
        entry.key.locationTier == RecommendedOfferModel.tierSameCity &&
            entry.value < 35;
    if (isWeakLocal) {
      weak.add(entry.key);
    } else {
      strong.add(entry.key);
    }
  }

  if (weak.isEmpty) return offers;
  return [...strong, ...weak];
}

List<RecommendedOfferSection> groupRecommendedOffersWithSkillsHighlight({
  required List<RecommendedOfferModel> offers,
  required String agentCityKey,
  List<String> agentSkillTokens = const [],
}) {
  if (agentSkillTokens.isEmpty) {
    return groupRecommendedOffersByLocation(
      offers,
      agentCityKey: agentCityKey,
    );
  }

  final ranked = offers.map((o) {
    return MapEntry(o, o.relevanceForAgent(agentSkillTokens));
  }).toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  final topSkills = ranked
      .where((e) => e.value >= 50)
      .take(5)
      .map((e) => e.key)
      .toList();

  final sections = <RecommendedOfferSection>[];

  if (topSkills.isNotEmpty) {
    sections.add(
      RecommendedOfferSection(
        locationTier: 4,
        title: 'Best for your skills',
        subtitle: 'Tailored to your skills and preferences',
        offers: topSkills,
      ),
    );
  }

  final restIds = topSkills.map((o) => o.id).toSet();
  final rest = offers.where((o) => !restIds.contains(o.id)).toList();

  sections.addAll(
    groupRecommendedOffersByLocation(
      rest,
      agentCityKey: agentCityKey,
    ),
  );

  return sections;
}

List<RecommendedOfferSection> groupRecommendedOffersByLocation(
  List<RecommendedOfferModel> offers, {
  required String agentCityKey,
}) {
  final sameCity = <RecommendedOfferModel>[];
  final nearby = <RecommendedOfferModel>[];
  final other = <RecommendedOfferModel>[];
  final unknown = <RecommendedOfferModel>[];

  for (final offer in offers) {
    switch (offer.locationTier) {
      case RecommendedOfferModel.tierSameCity:
        sameCity.add(offer);
        break;
      case RecommendedOfferModel.tierNearby:
        nearby.add(offer);
        break;
      case RecommendedOfferModel.tierOther:
        other.add(offer);
        break;
      default:
        unknown.add(offer);
    }
  }

  void sortBucket(List<RecommendedOfferModel> bucket) {
    if (agentCityKey.isEmpty || bucket.length < 2) return;
    bucket.sort(
      (a, b) => compareRecommendedOffersByLocationAndNlp(
        a,
        b,
        agentCityKey: agentCityKey,
      ),
    );
  }

  sortBucket(sameCity);
  sortBucket(nearby);
  sortBucket(other);

  final sections = <RecommendedOfferSection>[];

  void addSection({
    required int tier,
    required String title,
    required String subtitle,
    required List<RecommendedOfferModel> items,
  }) {
    if (items.isEmpty) return;
    sections.add(
      RecommendedOfferSection(
        locationTier: tier,
        title: title,
        subtitle: subtitle,
        offers: items,
      ),
    );
  }

  addSection(
    tier: RecommendedOfferModel.tierSameCity,
    title: 'In your city',
    subtitle: 'Offers in your city matched to your skills',
    items: sameCity,
  );
  addSection(
    tier: RecommendedOfferModel.tierNearby,
    title: 'Near you',
    subtitle: 'Nearby offers matched to your skills',
    items: nearby,
  );
  addSection(
    tier: RecommendedOfferModel.tierOther,
    title: 'Other locations',
    subtitle: 'Other offers matched to your skills',
    items: other,
  );
  addSection(
    tier: RecommendedOfferModel.tierUnknown,
    title: 'Location pending',
    subtitle: 'Matched to your skills — location not specified yet',
    items: unknown,
  );

  return sections;
}
