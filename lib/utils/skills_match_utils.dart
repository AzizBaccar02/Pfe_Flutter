/// Fast keyword skills overlap (mirrors backend skills_matching).
abstract final class SkillsMatchUtils {
  /// Maps agent skill phrases to offer categories / keywords (e.g. pets → Pet Care).
  static const Map<String, List<String>> _categoryAliases = {
    'pet care': [
      'pet',
      'pets',
      'caring pets',
      'pet care',
      'pet grooming',
      'grooming',
      'animal care',
      'dog',
      'dogs',
      'cat',
      'cats',
    ],
    'maintenance': ['maintenance', 'repair', 'hvac', 'air conditioning', 'ac'],
    'web development': ['web', 'website', 'design', 'development', 'frontend'],
  };

  static List<String> parseSkillTokens(String? skills, [String? bio]) {
    final raw = '${skills ?? ''} ${bio ?? ''}'.toLowerCase();
    final parts = raw.split(RegExp(r'[,;/|\n]+'));
    final seen = <String>{};
    final tokens = <String>[];

    for (final part in parts) {
      final token = part.trim().replaceAll(RegExp(r'\s+'), ' ');
      if (token.length < 2) continue;
      if (seen.add(token)) tokens.add(token);
    }

    return tokens;
  }

  static String offerCorpus({
    required String title,
    required String description,
    required String category,
  }) {
    return '${title.toLowerCase()} ${description.toLowerCase()} ${category.toLowerCase()}';
  }

  static double keywordScore(
    List<String> agentTokens,
    String corpus, {
    String category = '',
  }) {
    if (agentTokens.isEmpty) return 0;

    final categoryLower = category.toLowerCase().trim();
    var matched = 0;

    for (final token in agentTokens) {
      if (corpus.contains(token)) {
        matched++;
        continue;
      }
      if (categoryLower.isNotEmpty &&
          (token == categoryLower ||
              categoryLower.contains(token) ||
              token.contains(categoryLower))) {
        matched++;
        continue;
      }
      for (final word in token.split(' ')) {
        if (word.length >= 3 && corpus.contains(word)) {
          matched++;
          break;
        }
      }
    }

    if (matched == 0) return 0;

    var score = (matched / agentTokens.length) * 100;
    if (categoryLower.isNotEmpty &&
        agentTokens.any(
          (t) =>
              t == categoryLower ||
              categoryLower.contains(t) ||
              t.contains(categoryLower),
        )) {
      score = score < 85 ? 85 : score;
    }
    if (matched >= 2) score = (score + 10).clamp(0, 100);
    return score;
  }

  /// Whether agent skills align with an offer category via aliases (e.g. "caring pets" → Pet Care).
  static bool matchesCategory(List<String> agentTokens, String category) {
    final categoryLower = category.toLowerCase().trim();
    if (categoryLower.isEmpty || agentTokens.isEmpty) return false;

    for (final token in agentTokens) {
      final t = token.toLowerCase().trim();
      if (t.isEmpty) continue;
      if (categoryLower.contains(t) || t.contains(categoryLower)) return true;
    }

    for (final entry in _categoryAliases.entries) {
      final canonical = entry.key;
      if (!categoryLower.contains(canonical) && !canonical.contains(categoryLower)) {
        continue;
      }
      for (final alias in entry.value) {
        if (agentTokens.any((token) {
          final t = token.toLowerCase();
          return t.contains(alias) || alias.contains(t);
        })) {
          return true;
        }
      }
    }

    for (final entry in _categoryAliases.entries) {
      for (final alias in entry.value) {
        if (!agentTokens.any((t) => t.toLowerCase().contains(alias))) continue;
        if (categoryLower.contains(entry.key) ||
            entry.key.contains(categoryLower) ||
            categoryLower.contains(alias)) {
          return true;
        }
      }
    }

    return false;
  }

  /// 0–100 relevance for ranking/filtering (NLP + keywords + category aliases).
  static double relevanceScore(
    List<String> agentTokens, {
    required String title,
    required String description,
    required String category,
    double semanticScore = 0,
    double keywordSkillsScore = 0,
  }) {
    final keyword = keywordScore(
      agentTokens,
      offerCorpus(title: title, description: description, category: category),
      category: category,
    );

    var score = semanticScore;
    if (keywordSkillsScore > score) score = keywordSkillsScore;
    if (keyword > score) score = keyword;

    if (matchesCategory(agentTokens, category)) {
      score = score < 72 ? 72 : score;
    }

    return score.clamp(0, 100);
  }
}
