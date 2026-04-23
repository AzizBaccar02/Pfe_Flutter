import '../models/client_offer_model.dart';
import '../models/interested_agent_model.dart';

class MockClientData {
  static bool isProfileCompleted = true;

  static String clientName = 'Aziz Baccar';
  static String clientEmail = 'azizbaccar@gmail.com';
  static String clientPhone = '+216 12 345 678';
  static String clientCity = 'Tunis';

  static List<ClientOfferModel> offers = [
    ClientOfferModel(
      id: 1,
      title: 'Need a plumber for kitchen leak',
      description:
          'There is a water leak under the kitchen sink. I need someone available today.',
      budget: 120,
      category: 'Plumbing',
      city: 'Tunis',
      address: 'Rue Habib Bourguiba',
      postalCode: '1000',
      status: OfferStatus.open,
      images: [
        'assets/images/Offer1.jpg',
        'assets/images/Offer2.jpg',
      ],
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      interestedAgentsCount: 4,
    ),
    ClientOfferModel(
      id: 2,
      title: 'Fix electrical issue in bedroom',
      description:
          'The bedroom light keeps turning off. Need an electrician to check wiring.',
      budget: 180,
      category: 'Electricity',
      city: 'Sousse',
      address: 'Avenue de la Corniche',
      postalCode: '4000',
      status: OfferStatus.open,
      images: [
        'assets/images/Offer3.jpg',
      ],
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      interestedAgentsCount: 2,
    ),
  ];

  static List<InterestedAgentModel> interestedAgents = [
    InterestedAgentModel(
      id: 1,
      name: 'Sami Ben Ali',
      jobTitle: 'Professional Plumber',
      city: 'Tunis',
      rating: 4.8,
      completedJobs: 34,
      imageUrl: 'assets/images/agent1.jpg',
      offerId: 1,
      offerTitle: 'Need a plumber for kitchen leak',
    ),
    InterestedAgentModel(
      id: 2,
      name: 'Youssef Trabelsi',
      jobTitle: 'Skilled Electrician',
      city: 'Sousse',
      rating: 4.7,
      completedJobs: 28,
      imageUrl: 'assets/images/agent2.jpg',
      offerId: 2,
      offerTitle: 'Fix electrical issue in bedroom',
    ),
  ];

  static int get totalOffers => offers.length;

  static int get openOffers =>
      offers.where((offer) => offer.status == OfferStatus.open).length;

  static int get closedOffers =>
      offers.where((offer) => offer.status == OfferStatus.closed).length;

  static int get totalInterestedAgents => interestedAgents.length;

  static void addOffer({
    required String title,
    required String description,
    required double budget,
    required String category,
    required String city,
    required String address,
    required String postalCode,
    List<String> images = const [],
  }) {
    final newOffer = ClientOfferModel(
      id: DateTime.now().millisecondsSinceEpoch,
      title: title,
      description: description,
      budget: budget,
      category: category,
      city: city,
      address: address,
      postalCode: postalCode,
      status: OfferStatus.open,
      images: images,
      createdAt: DateTime.now(),
      interestedAgentsCount: 0,
    );

    offers.insert(0, newOffer);
  }
}