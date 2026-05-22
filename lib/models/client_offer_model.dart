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

  ClientOfferModel copyWith({
    int? interestedAgentsCount,
  }) {
    return ClientOfferModel(
      id: id,
      title: title,
      description: description,
      budget: budget,
      category: category,
      city: city,
      address: address,
      postalCode: postalCode,
      status: status,
      images: images,
      createdAt: createdAt,
      interestedAgentsCount:
          interestedAgentsCount ?? this.interestedAgentsCount,
    );
  }
}