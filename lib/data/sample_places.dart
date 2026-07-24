import '../models/local_place.dart';

/// Sample restaurant listings around Nkolmong, Yaoundé, shown on the home
/// dashboard until the backend exposes a real restaurants endpoint.
const sampleRestaurants = [
  LocalPlace(name: 'Chez Maman Cathy', category: 'Cameroonian home cooking', rating: 4.6, priceTier: '\$'),
  LocalPlace(name: 'Restaurant Le Ndolé Palace', category: 'Ndolé & local specialties', rating: 4.5, priceTier: '\$\$'),
  LocalPlace(name: 'La Terrasse Nkolmong', category: 'Grills & drinks', rating: 4.3, priceTier: '\$\$'),
  LocalPlace(name: 'Le Poivre Vert', category: 'Franco-Cameroonian fine dining', rating: 4.7, priceTier: '\$\$\$'),
  LocalPlace(name: 'Chez Wou', category: 'Chinese-Cameroonian fusion', rating: 4.2, priceTier: '\$\$'),
  LocalPlace(name: "La Fourchette d'Or", category: 'Seafood & local dishes', rating: 4.4, priceTier: '\$\$'),
];

/// Sample hotel listings around Yaoundé, shown on the home dashboard until
/// the backend exposes a real hotels endpoint.
const sampleHotels = [
  LocalPlace(name: 'Résidence Nkol Eton', category: 'Boutique hotel', rating: 4.5, priceTier: '\$\$'),
  LocalPlace(name: 'Hôtel Panorama Yaoundé', category: 'City-view rooms', rating: 4.3, priceTier: '\$\$'),
  LocalPlace(name: 'La Falaise Suites', category: 'Business hotel', rating: 4.6, priceTier: '\$\$\$'),
  LocalPlace(name: 'Auberge du Mont', category: 'Cozy guesthouse', rating: 4.2, priceTier: '\$'),
  LocalPlace(name: 'Villa Nkolmong', category: 'Family-run lodge', rating: 4.4, priceTier: '\$\$'),
  LocalPlace(name: 'Hôtel Étoile du Centre', category: 'Central location', rating: 4.1, priceTier: '\$'),
];
