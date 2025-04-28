import 'package:flutter/foundation.dart';
import '../models/notification_item.dart';
import '../services/notification_service.dart';

class NotificationProvider with ChangeNotifier {
  final NotificationService _notificationService = NotificationService();
  List<NotificationItem> _notifications = [];
  bool _showNotificationOverlay = false;
  NotificationItem? _lastRemovedNotification;
  int? _lastRemovedIndex;

  NotificationProvider() {
    _notificationService.notificationsStream.listen((notifications) {
      _notifications = notifications;
      notifyListeners();
    });
  }

  List<NotificationItem> get notifications => _notifications;
  bool get showNotificationOverlay => _showNotificationOverlay;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  void toggleNotificationOverlay() {
    _showNotificationOverlay = !_showNotificationOverlay;
    notifyListeners();
  }

  void markAsRead(String notificationId) {
    _notificationService.markAsRead(notificationId);
  }

  void markAllAsRead() {
    _notificationService.markAllAsRead();
  }

  void clearNotifications() {
    _notificationService.clearNotifications();
  }

  // Remove a notification by ID
  void removeNotification(String notificationId) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      // Store the removed notification for potential undo
      _lastRemovedNotification = _notifications[index];
      _lastRemovedIndex = index;

      // Remove from the service
      _notificationService.removeNotification(notificationId);
    }
  }

  // Undo the last notification removal
  void undoRemoveNotification() {
    if (_lastRemovedNotification != null && _lastRemovedIndex != null) {
      // Add back to the service
      _notificationService.addNotification(
        _lastRemovedNotification!.title,
        _lastRemovedNotification!.message,
        _lastRemovedNotification!.type,
        imageUrl: _lastRemovedNotification!.imageUrl,
        isRead: _lastRemovedNotification!.isRead,
        time: _lastRemovedNotification!.time,
      );

      // Clear the stored notification
      _lastRemovedNotification = null;
      _lastRemovedIndex = null;
    }
  }

  @override
  void dispose() {
    _notificationService.dispose();
    super.dispose();
  }
}
