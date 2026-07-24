import '../models/local_place.dart';

/// The sectors that make up the Nkolmbong quarter of Yaoundé.
const nkolmbongSectors = [
  'Premiere Maison',
  'Derriere Chefferie',
  'San Francisco',
  'Dubai City',
  'Terminus',
  'Chefferie Haussa',
];

/// Sample restaurant listings around Nkolmbong, Yaoundé, shown on the home
/// dashboard until the backend exposes a real restaurants endpoint.
const sampleRestaurants = [
  LocalPlace(name: 'Chez Maman Cathy', category: 'Cameroonian home cooking', rating: 4.6, priceTier: '1 500 FCFA'),
  LocalPlace(name: 'Restaurant Le Ndolé Palace', category: 'Ndolé & local specialties', rating: 4.5, priceTier: '4 000 FCFA'),
  LocalPlace(name: 'La Terrasse Nkolmbong', category: 'Grills & drinks', rating: 4.3, priceTier: '4 500 FCFA'),
  LocalPlace(name: 'Le Poivre Vert', category: 'Franco-Cameroonian fine dining', rating: 4.7, priceTier: '12 000 FCFA'),
  LocalPlace(name: 'Chez Wou', category: 'Chinese-Cameroonian fusion', rating: 4.2, priceTier: '5 000 FCFA'),
  LocalPlace(name: "La Fourchette d'Or", category: 'Seafood & local dishes', rating: 4.4, priceTier: '5 500 FCFA'),
];

/// Sample hotel listings in Nkolmbong, Yaoundé, one per sector, shown on the
/// home dashboard and destinations page until the backend exposes a real
/// hotels endpoint. Prices are per night.
const sampleHotels = [
  LocalPlace(name: 'Résidence Nkol Eton', category: 'Boutique hotel', rating: 4.5, priceTier: '25 000 FCFA', sector: 'Premiere Maison'),
  LocalPlace(name: 'Hôtel Panorama Yaoundé', category: 'City-view rooms', rating: 4.3, priceTier: '22 000 FCFA', sector: 'Derriere Chefferie'),
  LocalPlace(name: 'La Falaise Suites', category: 'Business hotel', rating: 4.6, priceTier: '45 000 FCFA', sector: 'San Francisco'),
  LocalPlace(name: 'Auberge du Mont', category: 'Cozy guesthouse', rating: 4.2, priceTier: '12 000 FCFA', sector: 'Dubai City'),
  LocalPlace(name: 'Villa Nkolmbong', category: 'Family-run lodge', rating: 4.4, priceTier: '20 000 FCFA', sector: 'Terminus'),
  LocalPlace(name: 'Hôtel Étoile du Centre', category: 'Central location', rating: 4.1, priceTier: '10 000 FCFA', sector: 'Chefferie Haussa'),
];

/// Sample points of interest ("areas to visit") in each Nkolmbong sector,
/// shown alongside hotels on the sector detail page.
const sampleAttractions = [
  LocalPlace(name: 'Marché Premiere Maison', category: 'Local market', rating: 4.4, priceTier: 'Free', sector: 'Premiere Maison'),
  LocalPlace(name: "Place de l'Indépendance", category: 'Public square', rating: 4.2, priceTier: 'Free', sector: 'Premiere Maison'),
  LocalPlace(name: 'Chefferie de Nkolmbong', category: 'Traditional palace', rating: 4.7, priceTier: 'Free', sector: 'Derriere Chefferie'),
  LocalPlace(name: 'Terrain Derriere Chefferie', category: 'Football field & hangout', rating: 4.1, priceTier: 'Free', sector: 'Derriere Chefferie'),
  LocalPlace(name: 'Carrefour San Francisco', category: 'Popular nightlife junction', rating: 4.3, priceTier: '2 000 FCFA', sector: 'San Francisco'),
  LocalPlace(name: 'Bar Terrasse San Francisco', category: 'Rooftop bar', rating: 4.2, priceTier: '5 000 FCFA', sector: 'San Francisco'),
  LocalPlace(name: 'Dubai City Shopping Center', category: 'Shopping & boutiques', rating: 4.3, priceTier: '3 000 FCFA', sector: 'Dubai City'),
  LocalPlace(name: 'Espace Vert Dubai City', category: 'Park & green space', rating: 4.0, priceTier: 'Free', sector: 'Dubai City'),
  LocalPlace(name: 'Gare Routière Terminus', category: 'Bus station & transit hub', rating: 3.9, priceTier: 'Free', sector: 'Terminus'),
  LocalPlace(name: 'Marché Terminus', category: 'Food & produce market', rating: 4.3, priceTier: 'Free', sector: 'Terminus'),
  LocalPlace(name: 'Mosquée Chefferie Haussa', category: 'Historic mosque', rating: 4.6, priceTier: 'Free', sector: 'Chefferie Haussa'),
  LocalPlace(name: 'Marché Haussa', category: 'Textiles & spices market', rating: 4.4, priceTier: 'Free', sector: 'Chefferie Haussa'),
];
