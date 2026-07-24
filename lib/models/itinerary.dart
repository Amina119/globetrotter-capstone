class Itinerary {
  final String id;
  final String title;
  final List<String> destinations;
  final String startDate;
  final String endDate;
  final String notes;

  Itinerary({
    required this.id,
    required this.title,
    required this.destinations,
    required this.startDate,
    required this.endDate,
    required this.notes,
  });

  factory Itinerary.fromJson(Map<String, dynamic> json) {
    return Itinerary(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      destinations: (json['destinations'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
      notes: json['notes'] ?? '',
    );
  }
}
