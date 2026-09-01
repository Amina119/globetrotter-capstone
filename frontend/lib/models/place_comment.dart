class PlaceComment {
  final String id;
  final String placeId;
  final String? parentId;
  final String email;
  final String name;
  final String text;
  final String createdAt;

  PlaceComment({
    required this.id,
    required this.placeId,
    this.parentId,
    required this.email,
    required this.name,
    required this.text,
    required this.createdAt,
  });

  factory PlaceComment.fromJson(Map<String, dynamic> json) {
    return PlaceComment(
      id: json['id']?.toString() ?? '',
      placeId: json['place_id']?.toString() ?? '',
      parentId: json['parent_id']?.toString(),
      email: json['email']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}
