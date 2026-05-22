class InterestedAgentModel {
  final int id; // agent id
  final int reactionId;

  final String name;
  final String jobTitle;
  final String city;
  final double rating;
  final int completedJobs;
  final String imageUrl;

  final int offerId;
  final String offerTitle;

  final String message;
  final String proposedPrice;
  final String status;
  final DateTime? createdAt;

  const InterestedAgentModel({
    required this.id,
    this.reactionId = 0,
    required this.name,
    required this.jobTitle,
    required this.city,
    required this.rating,
    required this.completedJobs,
    required this.imageUrl,
    required this.offerId,
    required this.offerTitle,
    this.message = '',
    this.proposedPrice = '',
    this.status = 'PENDING',
    this.createdAt,
  });

  factory InterestedAgentModel.fromJson(Map<String, dynamic> json) {
    return InterestedAgentModel(
      id: _parseInt(json['id']) ?? 0,
      reactionId: _parseInt(json['reactionId']) ?? 0,
      name: _parseString(json['name']),
      jobTitle: _parseString(json['jobTitle']),
      city: _parseString(json['city']),
      rating: _parseDouble(json['rating']),
      completedJobs: _parseInt(json['completedJobs']) ?? 0,
      imageUrl: _parseString(json['imageUrl']),
      offerId: _parseInt(json['offerId']) ?? 0,
      offerTitle: _parseString(json['offerTitle']),
      message: _parseString(json['message']),
      proposedPrice: _parseString(json['proposedPrice']),
      status: _parseString(json['status']).isEmpty
          ? 'PENDING'
          : _parseString(json['status']),
      createdAt: _parseDateTime(json['createdAt']),
    );
  }

  InterestedAgentModel copyWith({
    int? id,
    int? reactionId,
    String? name,
    String? jobTitle,
    String? city,
    double? rating,
    int? completedJobs,
    String? imageUrl,
    int? offerId,
    String? offerTitle,
    String? message,
    String? proposedPrice,
    String? status,
    DateTime? createdAt,
  }) {
    return InterestedAgentModel(
      id: id ?? this.id,
      reactionId: reactionId ?? this.reactionId,
      name: name ?? this.name,
      jobTitle: jobTitle ?? this.jobTitle,
      city: city ?? this.city,
      rating: rating ?? this.rating,
      completedJobs: completedJobs ?? this.completedJobs,
      imageUrl: imageUrl ?? this.imageUrl,
      offerId: offerId ?? this.offerId,
      offerTitle: offerTitle ?? this.offerTitle,
      message: message ?? this.message,
      proposedPrice: proposedPrice ?? this.proposedPrice,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
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

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}