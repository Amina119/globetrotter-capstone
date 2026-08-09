class Destination {
  final String id;
  final String name;
  final String town;
  final String quarter;
  final String sector;
  final List<String> tags;
  final int? avgCostPerDay;
  final num? matchScore;

  Destination({
    required this.id,
    required this.name,
    required this.town,
    required this.quarter,
    required this.sector,
    required this.tags,
    this.avgCostPerDay,
    this.matchScore,
  });

  factory Destination.fromJson(Map<String, dynamic> json) {
    return Destination(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      town: json['Town'] ?? '',
      quarter: json['quarter'] ?? '',
      sector: json['sector'] ?? '',
      tags: (json['tags'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      avgCostPerDay: json['avg_cost_per_day'] is int ? json['avg_cost_per_day'] : null,
      matchScore: json['match_score'] is num ? json['match_score'] as num : null,
    );
  }
}
