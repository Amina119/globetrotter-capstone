import '../models/local_place.dart';

/// The sectors that make up the Nkolmbong quarter of Yaoundé.
const nkolmbongSectors = [
  'Premiere Maison',
  'San Francisco',
  'Terminus',
];

/// Sample hotel listings in Nkolmbong, Yaoundé, shown on the home dashboard
/// and destinations page until the backend exposes a real hotels endpoint.
/// Prices are per night.
const sampleHotels = [
  LocalPlace(
    name: 'Paulina Hotel',
    category: 'Boutique hotel',
    rating: 4.5,
    priceTier: '25 000 FCFA',
    sector: 'Premiere Maison',
    description: 'A comfortable boutique hotel in the heart of Premiere Maison, with warm service and easy access to the quarter\'s shops and market.',
    videoAsset: 'assets/places/premiere_maison/paulina_hotel.mp4',
    tags: ['city'],
  ),
];

/// Sample points of interest ("areas to visit") in each Nkolmbong sector,
/// shown alongside hotels on the sector detail page and on the home
/// dashboard. This is the full, real list of places for each sector — the
/// home dashboard's "Places to visit" and "Recommended for you" sections
/// are drawn from this same list, not separate placeholder data.
const sampleAttractions = [
  // --- Premiere Maison ------------------------------------------------
  LocalPlace(
    name: 'Institut Nourha Couture',
    category: 'Tailoring & couture',
    rating: 4.4,
    priceTier: '5 000 FCFA',
    sector: 'Premiere Maison',
    description: 'A couture and tailoring institute making custom outfits and teaching dressmaking to local apprentices.',
    videoAsset: 'assets/places/premiere_maison/institut_nourha_couture.mp4',
    tags: ['culture'],
  ),
  LocalPlace(
    name: 'BSA Event',
    category: 'Event planning & rentals',
    rating: 4.3,
    priceTier: '10 000 FCFA',
    sector: 'Premiere Maison',
    description: 'An event planning and rental service for weddings, ceremonies and celebrations in the quarter.',
    videoAsset: 'assets/places/premiere_maison/bsa_event.mp4',
    tags: ['romance'],
  ),
  LocalPlace(
    name: 'Honor Bilingual Complex',
    category: 'Bilingual school',
    rating: 4.5,
    priceTier: 'Free',
    sector: 'Premiere Maison',
    description: 'A well-regarded bilingual (French/English) school complex serving families in Premiere Maison.',
    videoAsset: 'assets/places/premiere_maison/honor_bilingual_complex.mp4',
    tags: ['culture'],
  ),
  LocalPlace(
    name: 'Regional Glacier',
    category: 'Ice cream & desserts',
    rating: 4.4,
    priceTier: '1 000 FCFA',
    sector: 'Premiere Maison',
    description: 'A cheerful ice cream and dessert spot, popular with families and a favorite stop on a hot afternoon.',
    videoAsset: 'assets/places/premiere_maison/regional_glacier.mp4',
    tags: ['food'],
  ),

  // --- San Francisco ----------------------------------------------------
  LocalPlace(
    name: 'Carrefour San Francisco',
    category: 'Popular junction & nightlife',
    rating: 4.3,
    priceTier: '2 000 FCFA',
    sector: 'San Francisco',
    description: 'The lively crossroads at the heart of San Francisco — street food stalls, drink spots and the buzz of the quarter after dark.',
    videoAsset: 'assets/places/san_francisco/carrefour.mp4',
    tags: ['city', 'food'],
  ),
  LocalPlace(
    name: 'Smef Café Boulangerie',
    category: 'Bakery & café',
    rating: 4.4,
    priceTier: '100 FCFA',
    sector: 'San Francisco',
    description: 'Fresh bread, pastries and coffee — a favorite morning stop for locals grabbing breakfast on the way out.',
    videoAsset: 'assets/places/san_francisco/smef_cafe_boulangerie.mp4',
    tags: ['food'],
  ),
  LocalPlace(
    name: 'Bill Pressing',
    category: 'Dry cleaning & laundry',
    rating: 4.2,
    priceTier: '1 000 FCFA',
    sector: 'San Francisco',
    description: 'A reliable neighborhood pressing shop for laundry and dry cleaning, priced per item.',
    videoAsset: 'assets/places/san_francisco/bill_pressing.jpeg',
  ),
  LocalPlace(
    name: 'Black and Brown Hair Salon',
    category: 'Hair & beauty salon',
    rating: 4.5,
    priceTier: '500 FCFA',
    sector: 'San Francisco',
    description: 'A popular salon for braids, cuts and styling, known for friendly service and steady queues on weekends.',
    videoAsset: 'assets/places/san_francisco/black_and_brown_hair_salon.mp4',
    tags: ['romance'],
  ),
  LocalPlace(
    name: 'Institut de Beauté Beauty with Grace',
    category: 'Beauty institute',
    rating: 4.5,
    priceTier: '1000 FCFA',
    sector: 'San Francisco',
    description: 'A beauty institute offering skincare, manicures and grooming treatments in a relaxed setting.',
    videoAsset: 'assets/places/san_francisco/beauty_with_grace.mp4',
    tags: ['romance'],
  ),
  LocalPlace(
    name: 'Princesse Hadidja Fashion',
    category: 'Fashion boutique',
    rating: 4.3,
    priceTier: '3000 FCFA',
    sector: 'San Francisco',
    description: 'A fashion boutique with ready-to-wear and made-to-order outfits for every occasion.',
    videoAsset: 'assets/places/san_francisco/princesse_hadidja_fashion.mp4',
    tags: ['romance'],
  ),

  // --- Terminus -----------------------------------------------------------
  LocalPlace(
    name: 'Carrefour Terminus Nkolmbong',
    category: 'Popular junction',
    rating: 4.2,
    priceTier: '500 FCFA',
    sector: 'Terminus',
    description: 'The busy crossroads at Terminus, lined with vendors and a steady flow of cars and bike men',
    videoAsset: 'assets/places/terminus/carrefour_terminus.mp4',
    tags: ['city'],
  ),
  LocalPlace(
    name: "Brigitte's Johari",
    category: 'Fashion & jewelry boutique',
    rating: 4.3,
    priceTier: '3 500 FCFA',
    sector: 'Terminus',
    description: 'A boutique known for jewelry and fashion pieces, a favorite stop for gifts and accessories.',
    videoAsset: 'assets/places/terminus/brigittes_johari.mp4',
    tags: ['romance'],
  ),
  LocalPlace(
    name: 'Mosquée Terminus',
    category: 'Neighborhood mosque',
    rating: 4.6,
    priceTier: 'Free',
    sector: 'Terminus',
    description: 'The neighborhood mosque serving the Terminus community, open for daily prayers — visitors are welcome to admire the architecture respectfully.',
    videoAsset: 'assets/places/terminus/mosquee_terminus.mp4',
    tags: ['culture'],
  ),
  LocalPlace(
    name: 'Auto École Leclerc',
    category: 'Driving school',
    rating: 4.1,
    priceTier: '15 000 FCFA',
    sector: 'Terminus',
    description: 'A driving school offering lessons and licensing preparation for new drivers.',
    videoAsset: 'assets/places/terminus/auto_ecole_leclerc.mp4',
  ),
];

/// All curated Nkolmbong places (hotels + areas to visit) in one list, for
/// the home dashboard's "Recommended for you" section.
List<LocalPlace> get allNkolmbongPlaces => [...sampleHotels, ...sampleAttractions];

/// Places matching at least one of [preferences] — the interest tags a user
/// chose when creating their account — ranked highest-rated first. Falls
/// back to every place (also rating-sorted) when there's no preference
/// match, so the section never comes up empty.
List<LocalPlace> recommendedPlaces(List<String> preferences) {
  final wanted = preferences.map((p) => p.toLowerCase()).toSet();
  final matches = allNkolmbongPlaces.where((p) => p.tags.any(wanted.contains)).toList();
  final pool = matches.isNotEmpty ? matches : allNkolmbongPlaces;
  return [...pool]..sort((a, b) => b.rating.compareTo(a.rating));
}
