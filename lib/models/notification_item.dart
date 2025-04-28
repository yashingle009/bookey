class NotificationItem {
  final String id;
  final String title;
  final String message;
  final DateTime time;
  final String? imageUrl;
  final bool isRead;
  final NotificationType type;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    this.imageUrl,
    this.isRead = false,
    this.type = NotificationType.info,
  });
}

enum NotificationType {
  info,
  success,
  warning,
  error,
}
