class InterestedAgentModel {
  final int id;
  final String name;
  final String jobTitle;
  final String city;
  final double rating;
  final int completedJobs;
  final String imageUrl;
  final int offerId;
  final String offerTitle;

  const InterestedAgentModel({
    required this.id,
    required this.name,
    required this.jobTitle,
    required this.city,
    required this.rating,
    required this.completedJobs,
    required this.imageUrl,
    required this.offerId,
    required this.offerTitle,
  });
}