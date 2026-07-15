class AiNewsReminder {
  const AiNewsReminder({
    required this.itemId,
    required this.title,
    required this.source,
    required this.publishedAt,
    required this.createdAt,
    this.readAt,
  });

  final String itemId;
  final String title;
  final String source;
  final DateTime publishedAt;
  final DateTime createdAt;
  final DateTime? readAt;

  bool get isRead => readAt != null;
}
