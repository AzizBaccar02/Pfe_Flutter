import '../../../../models/recommended_offer_model.dart';
import '../../../../utils/tunisia_location_utils.dart';

enum OfferSortMode {
  locationThenNlp,
  bestSkills,
  nearest,
}

class OfferSearchFilters {
  final String query;
  final int? locationTier;
  final String? category;
  final OfferSortMode sortMode;

  const OfferSearchFilters({
    this.query = '',
    this.locationTier,
    this.category,
    this.sortMode = OfferSortMode.locationThenNlp,
  });

  OfferSearchFilters copyWith({
    String? query,
    int? locationTier,
    bool clearLocationTier = false,
    String? category,
    bool clearCategory = false,
    OfferSortMode? sortMode,
  }) {
    return OfferSearchFilters(
      query: query ?? this.query,
      locationTier:
          clearLocationTier ? null : (locationTier ?? this.locationTier),
      category: clearCategory ? null : (category ?? this.category),
      sortMode: sortMode ?? this.sortMode,
    );
  }

  bool get hasActiveFilters =>
      query.trim().isNotEmpty ||
      locationTier != null ||
      (category != null && category!.isNotEmpty);

  int get activeFilterCount {
    var count = 0;
    if (locationTier != null) count++;
    if (category != null && category!.isNotEmpty) count++;
    if (sortMode != OfferSortMode.locationThenNlp) count++;
    return count;
  }
}

bool offerMatchesQuery(RecommendedOfferModel offer, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return true;

  final haystack = [
    offer.title,
    offer.description,
    offer.category,
    offer.city,
    offer.locationLabel,
    offer.clientUsername,
  ].join(' ').toLowerCase();

  final terms = q.split(RegExp(r'\s+')).where((t) => t.length >= 2).toList();
  if (terms.isEmpty) return true;

  bool termMatches(String term) {
    if (haystack.contains(term)) return true;
    if (term.endsWith('s') && term.length > 3) {
      return haystack.contains(term.substring(0, term.length - 1));
    }
    return false;
  }

  return terms.any(termMatches);
}

List<RecommendedOfferModel> applyOfferSearchAndFilters({
  required List<RecommendedOfferModel> offers,
  required OfferSearchFilters filters,
  required String agentCityKey,
  List<String> agentSkillTokens = const [],
}) {
  var result = offers.where((offer) {
    if (!offerMatchesQuery(offer, filters.query)) return false;
    if (filters.locationTier != null &&
        offer.locationTier != filters.locationTier) {
      return false;
    }
    if (filters.category != null &&
        filters.category!.isNotEmpty &&
        offer.category.toLowerCase() != filters.category!.toLowerCase()) {
      return false;
    }
    return true;
  }).toList();

  switch (filters.sortMode) {
    case OfferSortMode.locationThenNlp:
      result = sortRecommendedOffersByLocationAndNlp(
        offers: result,
        agentCityKey: agentCityKey,
        agentCityDisplay: '',
        agentSkillTokens: agentSkillTokens,
      );
      break;
    case OfferSortMode.bestSkills:
      result.sort((a, b) {
        final relA = agentSkillTokens.isEmpty
            ? a.semanticScore
            : a.relevanceForAgent(agentSkillTokens);
        final relB = agentSkillTokens.isEmpty
            ? b.semanticScore
            : b.relevanceForAgent(agentSkillTokens);
        return relB.compareTo(relA);
      });
      break;
    case OfferSortMode.nearest:
      result.sort((a, b) {
        final dA = TunisiaLocationUtils.distanceKm(
              agentCityKey,
              a.offerCityKey,
            ) ??
            99999;
        final dB = TunisiaLocationUtils.distanceKm(
              agentCityKey,
              b.offerCityKey,
            ) ??
            99999;
        return dA.compareTo(dB);
      });
      break;
  }

  return result;
}

List<String> collectOfferCategories(List<RecommendedOfferModel> offers) {
  final categories = <String>{};
  for (final offer in offers) {
    final cat = offer.category.trim();
    if (cat.isNotEmpty) categories.add(cat);
  }
  final list = categories.toList()..sort();
  return list;
}
