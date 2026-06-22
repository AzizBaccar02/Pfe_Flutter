import '../utils/media_url_resolver.dart';

/// Maps [OfferPublicSerializer] from `GET /api/offers/agent/offers/`.
class AgentPublicOfferModel {
  final int id;
  final String title;
  final String description;
  final double budget;
  final String categoryName;
  final String city;
  final String clientName;
  final List<String> imageUrls;
  final List<String> skills;
  final List<String> highlights;

  AgentPublicOfferModel({
    required this.id,
    required this.title,
    required this.description,
    required this.budget,
    required this.categoryName,
    required this.city,
    required this.clientName,
    required this.imageUrls,
    required this.skills,
    required this.highlights,
  });

  static AgentPublicOfferModel fromJson(Map<String, dynamic> json) {
    final urls = MediaUrlResolver.parseImageList(json['images']);

    final skillsRaw = json['skills'];
    final skills = <String>[];
    if (skillsRaw is List) {
      for (final s in skillsRaw) {
        final t = s.toString().trim();
        if (t.isNotEmpty) skills.add(t);
      }
    }

    final highlightsRaw = json['highlights'];
    final highlights = <String>[];
    if (highlightsRaw is List) {
      for (final h in highlightsRaw) {
        final t = h.toString().trim();
        if (t.isNotEmpty) highlights.add(t);
      }
    }

    final budgetVal = json['budget'];
    double budget = 0;
    if (budgetVal is num) {
      budget = budgetVal.toDouble();
    } else if (budgetVal != null) {
      budget = double.tryParse(budgetVal.toString()) ?? 0;
    }

    return AgentPublicOfferModel(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      title: (json['title'] ?? '').toString().trim(),
      description: (json['description'] ?? '').toString().trim(),
      budget: budget,
      categoryName: (json['category_name'] ?? '').toString().trim(),
      city: (json['city'] ?? '').toString().trim(),
      clientName: (json['clientName'] ?? '').toString().trim(),
      imageUrls: urls,
      skills: skills,
      highlights: highlights,
    );
  }

  String get budgetLabel {
    if (budget <= 0) return 'Budget not set';
    final whole = budget == budget.roundToDouble();
    final s = whole ? budget.round().toString() : budget.toStringAsFixed(2);
    return '$s DT';
  }
}
