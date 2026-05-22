enum OfferStatus {
  open,
  closed,
  archived,
}

class ClientOfferModel {
  final int id;
  final String title;
  final String description;
  final double budget;
  final String category;
  final String city;
  final String address;
  final String postalCode;
  final OfferStatus status;
  final List<String> images;
  final DateTime createdAt;
  final int interestedAgentsCount;

  const ClientOfferModel({
    required this.id,
    required this.title,
    required this.description,
    required this.budget,
    required this.category,
    required this.city,
    required this.address,
    required this.postalCode,
    required this.status,
    required this.images,
    required this.createdAt,
    required this.interestedAgentsCount,
  });

  factory ClientOfferModel.fromJson(Map<String, dynamic> json) {
    return ClientOfferModel(
      id: _parseInt(json['id']) ?? 0,
      title: _parseString(json['title']),
      description: _parseString(json['description']),
      budget: _parseDouble(json['budget']),
      category: _parseString(
        json['category_name'] ?? json['categoryName'] ?? json['category'],
      ),
      city: _parseString(json['city'] ?? json['city_value']),
      address: _parseString(json['address'] ?? json['address_value']),
      postalCode: _parseString(
        json['postalCode'] ?? json['postal_code_value'],
      ),
      status: offerStatusFromApi(json['status']),
      images: _parseImages(json['images']),
      createdAt: _parseDateTime(json['createdAt']),
      interestedAgentsCount: _parseInt(json['interestedAgentsCount']) ?? 0,
    );
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'title': title.trim(),
      'description': description.trim(),
      'budget': budget,
      'categoryName': category.trim(),
      'city': city.trim(),
      'address': address.trim(),
      'postalCode': postalCode.trim(),
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'title': title.trim(),
      'description': description.trim(),
      'budget': budget,
      'categoryName': category.trim(),
      'city': city.trim(),
      'address': address.trim(),
      'postalCode': postalCode.trim(),
      'status': offerStatusToApi(status),
    };
  }

  ClientOfferModel copyWith({
    int? id,
    String? title,
    String? description,
    double? budget,
    String? category,
    String? city,
    String? address,
    String? postalCode,
    OfferStatus? status,
    List<String>? images,
    DateTime? createdAt,
    int? interestedAgentsCount,
  }) {
    return ClientOfferModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      budget: budget ?? this.budget,
      category: category ?? this.category,
      city: city ?? this.city,
      address: address ?? this.address,
      postalCode: postalCode ?? this.postalCode,
      status: status ?? this.status,
      images: images ?? this.images,
      createdAt: createdAt ?? this.createdAt,
      interestedAgentsCount:
          interestedAgentsCount ?? this.interestedAgentsCount,
    );
  }

  static String _parseString(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value.toString());
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();

    final parsed = DateTime.tryParse(value.toString());
    return parsed ?? DateTime.now();
  }

  static List<String> _parseImages(dynamic value) {
    if (value == null || value is! List) return [];

    return value
        .map((item) {
          if (item is String) return item;

          if (item is Map<String, dynamic>) {
            return item['url']?.toString() ?? '';
          }

          return '';
        })
        .where((url) => url.trim().isNotEmpty)
        .toList();
  }
}

OfferStatus offerStatusFromApi(dynamic value) {
  final normalized = value.toString().trim().toUpperCase();

  switch (normalized) {
    case 'CLOSED':
      return OfferStatus.closed;
    case 'ARCHIVED':
      return OfferStatus.archived;
    case 'OPEN':
    default:
      return OfferStatus.open;
  }
}

String offerStatusToApi(OfferStatus status) {
  switch (status) {
    case OfferStatus.open:
      return 'OPEN';
    case OfferStatus.closed:
      return 'CLOSED';
    case OfferStatus.archived:
      return 'ARCHIVED';
  }
}