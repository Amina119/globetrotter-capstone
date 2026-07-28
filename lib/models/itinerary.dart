class Itinerary {
  final String id;
  final String email;
  final String title;
  final List<String> destinations;
  final String startDate;
  final String endDate;
  final String notes;
  final List<String> sharedWith;

  Itinerary({
    required this.id,
    required this.email,
    required this.title,
    required this.destinations,
    required this.startDate,
    required this.endDate,
    required this.notes,
    required this.sharedWith,
  });

  factory Itinerary.fromJson(Map<String, dynamic> json) {
    return Itinerary(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      title: json['title'] ?? '',
      destinations: (json['destinations'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
      notes: json['notes'] ?? '',
      sharedWith: (json['shared_with'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
    );
  }
}
