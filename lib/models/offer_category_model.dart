class OfferCategoryModel {
  final int id;
  final String name;

  const OfferCategoryModel({
    required this.id,
    required this.name,
  });

  factory OfferCategoryModel.fromJson(Map<String, dynamic> json) {
    return OfferCategoryModel(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      name: json['name']?.toString().trim() ?? '',
    );
  }
}
