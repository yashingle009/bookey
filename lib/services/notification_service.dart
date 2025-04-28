import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_item.dart';
import 'firestore_service.dart';

class NotificationService {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<NotificationItem> _notifications = [];
  final StreamController<List<NotificationItem>> _notificationsController =
      StreamController<List<NotificationItem>>.broadcast();

  Stream<List<NotificationItem>> get notificationsStream => _notificationsController.stream;
  List<NotificationItem> get notifications => List.unmodifiable(_notifications);

  // Sample notification messages for different events
  final Map<String, List<String>> _notificationTemplates = {
    'new_book': [
      'A new book "%title%" has been added to our collection!',
      'Check out the latest addition: "%title%" by %author%',
      'New arrival: "%title%" is now available',
    ],
    'price_drop': [
      'Price drop alert! "%title%" is now %discount%% off',
      'Special offer: Get "%title%" at a reduced price',
      'Limited time offer: "%title%" price has been reduced',
    ],
    'book_recommendation': [
      'Based on your interests, you might like "%title%"',
      'Recommended for you: "%title%" by %author%',
      'Readers who liked your books also enjoyed "%title%"',
    ],
    'order_status': [
      'Your order #%orderId% has been %status%',
      'Order update: Your purchase of "%title%" has been %status%',
      'Good news! Your order #%orderId% is on its way',
    ],
  };

  NotificationService() {
    // Initialize with some sample notifications
    _loadNotifications();

    // Listen for real-time updates from Firestore
    _setupFirestoreListener();

    // Simulate periodic notifications for demo purposes
    _setupPeriodicNotifications();
  }

  void _loadNotifications() {
    // Add initial notifications
    _addNotification(
      'Welcome to Bookey!',
      'Discover and buy books from your local community',
      NotificationType.info,
    );
  }

  void _setupFirestoreListener() {
    // Listen for new books being added
    _firestoreService.getAllBooks().listen((snapshot) {
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final createdAt = data['createdAt'] as Timestamp?;

        // Only notify for recently added books (last 24 hours)
        if (createdAt != null) {
          final now = DateTime.now();
          final bookAddedTime = createdAt.toDate();

          if (now.difference(bookAddedTime).inHours < 24) {
            _generateBookNotification(data);
          }
        }
      }
    });
  }

  void _setupPeriodicNotifications() {
    // Simulate periodic notifications for demo purposes
    Timer.periodic(const Duration(minutes: 5), (timer) {
      _generateRandomNotification();
    });
  }

  void _generateBookNotification(Map<String, dynamic> bookData) {
    final title = bookData['title'] ?? 'New Book';
    final author = bookData['author'] ?? 'Unknown Author';

    final templates = _notificationTemplates['new_book']!;
    final template = templates[Random().nextInt(templates.length)];

    final message = template
        .replaceAll('%title%', title)
        .replaceAll('%author%', author);

    _addNotification(
      'New Book Available',
      message,
      NotificationType.info,
      imageUrl: bookData['imageUrl'],
    );
  }

  void _generateRandomNotification() {
    final random = Random();
    final types = ['price_drop', 'book_recommendation', 'order_status'];
    final selectedType = types[random.nextInt(types.length)];

    // Sample book data
    final sampleBooks = [
      {'title': 'The Silent Patient', 'author': 'Alex Michaelides'},
      {'title': 'Atomic Habits', 'author': 'James Clear'},
      {'title': 'Dune', 'author': 'Frank Herbert'},
      {'title': 'The Alchemist', 'author': 'Paulo Coelho'},
    ];

    final book = sampleBooks[random.nextInt(sampleBooks.length)];
    final templates = _notificationTemplates[selectedType]!;
    final template = templates[random.nextInt(templates.length)];

    String message = template
        .replaceAll('%title%', book['title']!)
        .replaceAll('%author%', book['author']!);

    if (selectedType == 'price_drop') {
      final discount = (random.nextInt(4) + 1) * 5; // 5%, 10%, 15%, or 20%
      message = message.replaceAll('%discount%', discount.toString());

      _addNotification(
        'Price Drop Alert',
        message,
        NotificationType.warning,
      );
    } else if (selectedType == 'book_recommendation') {
      _addNotification(
        'Recommended for You',
        message,
        NotificationType.info,
      );
    } else if (selectedType == 'order_status') {
      final orderId = 'ORD-${10000 + random.nextInt(90000)}';
      final statuses = ['confirmed', 'shipped', 'delivered'];
      final status = statuses[random.nextInt(statuses.length)];

      message = message
          .replaceAll('%orderId%', orderId)
          .replaceAll('%status%', status);

      _addNotification(
        'Order Update',
        message,
        NotificationType.success,
      );
    }
  }

  void _addNotification(String title, String message, NotificationType type, {String? imageUrl}) {
    addNotification(title, message, type, imageUrl: imageUrl);
  }

  // Public method to add a notification
  void addNotification(String title, String message, NotificationType type, {
    String? imageUrl,
    bool isRead = false,
    DateTime? time,
  }) {
    final notification = NotificationItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      time: time ?? DateTime.now(),
      imageUrl: imageUrl,
      type: type,
      isRead: isRead,
    );

    _notifications.insert(0, notification);

    // Limit to 20 notifications
    if (_notifications.length > 20) {
      _notifications.removeLast();
    }

    // Notify listeners
    _notificationsController.add(List.unmodifiable(_notifications));
  }

  // Remove a notification by ID
  void removeNotification(String notificationId) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications.removeAt(index);
      _notificationsController.add(List.unmodifiable(_notifications));
    }
  }

  void markAsRead(String notificationId) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      final notification = _notifications[index];
      _notifications[index] = NotificationItem(
        id: notification.id,
        title: notification.title,
        message: notification.message,
        time: notification.time,
        imageUrl: notification.imageUrl,
        type: notification.type,
        isRead: true,
      );

      _notificationsController.add(List.unmodifiable(_notifications));
    }
  }

  void markAllAsRead() {
    for (var i = 0; i < _notifications.length; i++) {
      final notification = _notifications[i];
      _notifications[i] = NotificationItem(
        id: notification.id,
        title: notification.title,
        message: notification.message,
        time: notification.time,
        imageUrl: notification.imageUrl,
        type: notification.type,
        isRead: true,
      );
    }

    _notificationsController.add(List.unmodifiable(_notifications));
  }

  void clearNotifications() {
    _notifications.clear();
    _notificationsController.add(List.unmodifiable(_notifications));
  }

  void dispose() {
    _notificationsController.close();
  }
}
