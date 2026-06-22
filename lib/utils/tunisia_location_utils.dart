import 'dart:math' as math;

/// Client-side Tunisia city normalization and geographic proximity (mirrors backend tiers).
abstract final class TunisiaLocationUtils {
  static const List<String> _cities = [
    'ben arous',
    'la marsa',
    'la goulette',
    'la soukra',
    'tataouine',
    'kairouan',
    'monastir',
    'mahdia',
    'medenine',
    'zaghouan',
    'jendouba',
    'bizerte',
    'manouba',
    'nabeul',
    'siliana',
    'gabes',
    'sfax',
    'beja',
    'ariana',
    'gafsa',
    'kebili',
    'sousse',
    'tozeur',
    'tunis',
    'kef',
  ];

  static const Map<String, String> _aliases = {
    'la soukra': 'ariana',
    'soukra': 'ariana',
    'cite el ghazala': 'ariana',
    'raoued': 'ariana',
    'mnihla': 'ariana',
    'la marsa': 'tunis',
    'la goulette': 'tunis',
    'carthage': 'tunis',
  };

  /// Neighboring governorates (graph hop). Used for tier-2 "Near you".
  static const Map<String, List<String>> _nearby = {
    'tunis': ['ariana', 'ben arous', 'manouba', 'la marsa', 'la goulette', 'bizerte', 'zaghouan'],
    'ariana': ['tunis', 'manouba', 'ben arous', 'la soukra', 'zaghouan'],
    'la soukra': ['ariana', 'tunis', 'ben arous', 'manouba'],
    'ben arous': ['tunis', 'ariana', 'manouba', 'sousse'],
    'manouba': ['tunis', 'ariana', 'ben arous', 'beja'],
    'bizerte': ['tunis', 'beja', 'jendouba', 'nabeul'],
    'nabeul': ['bizerte', 'zaghouan', 'sousse'],
    'zaghouan': ['tunis', 'ariana', 'nabeul', 'kairouan'],
    'beja': ['bizerte', 'jendouba', 'kef', 'manouba'],
    'jendouba': ['beja', 'kef', 'siliana'],
    'kef': ['beja', 'jendouba', 'siliana', 'kairouan'],
    'siliana': ['kef', 'jendouba', 'kairouan'],
    'sousse': ['monastir', 'mahdia', 'kairouan', 'ben arous', 'nabeul', 'sfax'],
    'monastir': ['sousse', 'mahdia', 'kairouan'],
    'mahdia': ['monastir', 'sousse', 'sfax', 'kairouan'],
    'kairouan': ['sousse', 'monastir', 'mahdia', 'sfax', 'gafsa', 'zaghouan', 'kef'],
    'sfax': ['mahdia', 'gabes', 'sousse', 'monastir', 'kairouan', 'gafsa'],
    'gabes': ['sfax', 'medenine', 'gafsa', 'tozeur'],
    'medenine': ['gabes', 'tataouine', 'kebili'],
    'tataouine': ['medenine', 'gabes', 'kebili'],
    'gafsa': ['sfax', 'gabes', 'tozeur', 'kairouan', 'kebili'],
    'tozeur': ['gafsa', 'gabes', 'kebili'],
    'kebili': ['gafsa', 'tozeur', 'medenine', 'tataouine'],
  };

  /// Approximate governorate centers (lat, lon) for distance sorting.
  static const Map<String, (double lat, double lon)> _coordinates = {
    'tunis': (36.8065, 10.1815),
    'ariana': (36.8625, 10.1956),
    'ben arous': (36.7531, 10.2189),
    'manouba': (36.8101, 10.0972),
    'bizerte': (37.2744, 9.8739),
    'beja': (36.7256, 9.1817),
    'jendouba': (36.5011, 8.7802),
    'kef': (36.1822, 8.7147),
    'siliana': (36.0849, 9.3708),
    'zaghouan': (36.4029, 10.1429),
    'nabeul': (36.4561, 10.7376),
    'sousse': (35.8256, 10.6411),
    'monastir': (35.7643, 10.8113),
    'mahdia': (35.5047, 11.0622),
    'kairouan': (35.6781, 10.0963),
    'sfax': (34.7406, 10.7603),
    'gabes': (33.8815, 10.0982),
    'medenine': (33.3549, 10.5055),
    'tataouine': (32.9297, 10.4518),
    'gafsa': (34.4250, 8.7842),
    'tozeur': (33.9197, 8.1335),
    'kebili': (33.7044, 8.9694),
  };

  static String normalizeCityKey(String? city, [String? address]) {
    final combined = _clean('${city ?? ''} ${address ?? ''}');
    if (combined.isEmpty) return '';

    final sorted = List<String>.from(_cities)
      ..sort((a, b) => b.length.compareTo(a.length));

    for (final cityName in sorted) {
      if (combined.contains(cityName)) {
        return _aliases[cityName] ?? cityName;
      }
    }
    return '';
  }

  /// Greater Tunis: Tunis + Ariana + close suburbs count as the same work area.
  static const Set<String> _greaterTunis = {
    'tunis',
    'ariana',
    'ben arous',
    'la marsa',
    'la goulette',
    'manouba',
    'la soukra',
  };

  static bool _sameMetroArea(String agentCityKey, String offerCityKey) {
    if (agentCityKey.isEmpty || offerCityKey.isEmpty) return false;
    if (agentCityKey == offerCityKey) return true;
    if (_greaterTunis.contains(agentCityKey) &&
        _greaterTunis.contains(offerCityKey)) {
      return true;
    }
    return false;
  }

  static int locationTier({
    required String agentCityKey,
    required String offerCityKey,
  }) {
    if (agentCityKey.isEmpty || offerCityKey.isEmpty) return 0;
    if (_sameMetroArea(agentCityKey, offerCityKey)) return 3;
    if (_nearby[agentCityKey]?.contains(offerCityKey) ?? false) return 2;
    return 1;
  }

  /// City + address (e.g. city=Tunis, address=Ariana → ariana).
  static String normalizeAgentLocation({
    String? city,
    String? address,
  }) {
    final fromAddress = normalizeCityKey(null, address);
    if (fromAddress.isNotEmpty) return fromAddress;
    return normalizeCityKey(city);
  }

  /// Great-circle distance in km between two normalized city keys.
  static double? distanceKm(String cityKeyA, String cityKeyB) {
    if (cityKeyA.isEmpty || cityKeyB.isEmpty) return null;
    if (cityKeyA == cityKeyB) return 0;

    final a = _coordinates[cityKeyA];
    final b = _coordinates[cityKeyB];
    if (a == null || b == null) return null;

    const earthRadiusKm = 6371.0;
    final lat1 = a.$1 * math.pi / 180;
    final lat2 = b.$1 * math.pi / 180;
    final dLat = (b.$1 - a.$1) * math.pi / 180;
    final dLon = (b.$2 - a.$2) * math.pi / 180;

    final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
    return earthRadiusKm * c;
  }

  /// Groups distances so offers in the same band compete on NLP/skills, not 1 km gaps.
  static int distanceBandIndex(double? distanceKm, {double bandKm = 75}) {
    if (distanceKm == null) return 999;
    if (distanceKm <= 0) return 0;
    return (distanceKm / bandKm).floor();
  }

  static int compareDistanceBands(
    double? distanceA,
    double? distanceB, {
    double bandKm = 75,
  }) {
    final bandA = distanceBandIndex(distanceA, bandKm: bandKm);
    final bandB = distanceBandIndex(distanceB, bandKm: bandKm);
    if (bandA != bandB) return bandA.compareTo(bandB);
    if (distanceA == null && distanceB == null) return 0;
    if (distanceA == null) return 1;
    if (distanceB == null) return -1;
    return distanceA.compareTo(distanceB);
  }

  static int comparePublicOffersByLocation({
    required String agentCityKey,
    required String offerCityKeyA,
    required String offerCityKeyB,
    required double skillsA,
    required double skillsB,
    required int idA,
    required int idB,
  }) {
    final tierA = locationTier(
      agentCityKey: agentCityKey,
      offerCityKey: offerCityKeyA,
    );
    final tierB = locationTier(
      agentCityKey: agentCityKey,
      offerCityKey: offerCityKeyB,
    );
    if (tierA != tierB) return tierB.compareTo(tierA);

    final distCompare = compareDistanceBands(
      distanceKm(agentCityKey, offerCityKeyA),
      distanceKm(agentCityKey, offerCityKeyB),
    );
    if (distCompare != 0) return distCompare;

    if (skillsA != skillsB) return skillsB.compareTo(skillsA);
    return idB.compareTo(idA);
  }

  static int compareDistanceKeys(
    String agentCityKey,
    String offerCityKeyA,
    String offerCityKeyB,
  ) {
    final dA = distanceKm(agentCityKey, offerCityKeyA);
    final dB = distanceKm(agentCityKey, offerCityKeyB);
    if (dA == null && dB == null) return 0;
    if (dA == null) return 1;
    if (dB == null) return -1;
    return dA.compareTo(dB);
  }

  static String buildProximityLabel({
    required String agentCityDisplay,
    required String agentCityKey,
    required String offerCityDisplay,
    required String offerCityKey,
    required int locationTier,
  }) {
    final agentLabel =
        agentCityDisplay.trim().isNotEmpty ? agentCityDisplay.trim() : 'you';
    final offerLabel =
        offerCityDisplay.trim().isNotEmpty ? offerCityDisplay.trim() : 'Offer';

    if (locationTier == 3) {
      return '$offerLabel · your area';
    }
    if (locationTier == 2) {
      return '$offerLabel · near $agentLabel';
    }

    final km = distanceKm(agentCityKey, offerCityKey);
    if (km != null && km > 0) {
      return '$offerLabel · ~${km.round()} km from $agentLabel';
    }
    return '$offerLabel · farther from $agentLabel';
  }

  static String _clean(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r"['\-]"), ' ')
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
