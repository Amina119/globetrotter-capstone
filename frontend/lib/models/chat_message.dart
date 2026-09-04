class ChatMessage {
  final String id;
  final String? parentId;
  final String email;
  final String name;
  final String text;
  final String createdAt;
  final String? mediaUrl;
  final String? mediaType; // "image" | "audio" | "video" | null

  ChatMessage({
    required this.id,
    this.parentId,
    required this.email,
    required this.name,
    required this.text,
    required this.createdAt,
    this.mediaUrl,
    this.mediaType,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id']?.toString() ?? '',
      parentId: json['parent_id']?.toString(),
      email: json['email']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
      mediaUrl: json['media_url']?.toString(),
      mediaType: json['media_type']?.toString(),
    );
  }
}
