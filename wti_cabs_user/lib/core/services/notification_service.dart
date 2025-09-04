import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin notificationsPlugin = FlutterLocalNotificationsPlugin();
  String? pendingNavigationPayload;

  Future<void> initialize() async {
    await _initLocalNotifications();
    await _initFirebaseMessaging();
  }

  Future<void> _initLocalNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();

    const initializationSettings = InitializationSettings(
      android: android,
      iOS: ios,
    );

    await notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (response) {
        _handlePayload(response.payload);
      },
    );
  }

  Future<void> _initFirebaseMessaging() async {
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    // Foreground notification
    FirebaseMessaging.onMessage.listen((message) {
      _showLocalNotification(message);
    });

    // App open from background notification tap
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handlePayload(message.data['ordered_data']);
    });

    // Terminated state notification handling
    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      pendingNavigationPayload = initialMessage.data['ordered_data'];
      // _navigateToBooking(pendingNavigationPayload ?? '');
    }
  }

  void _showLocalNotification(RemoteMessage message) {
    final payload = message.data['ordered_data'] ?? "";

    notificationsPlugin.show(
      message.hashCode,
      message.notification?.title ?? "New Booking",
      message.notification?.body ?? "",
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'high_importance_channel_v2',
          'High Importance Notifications',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          // sound: RawResourceAndroidNotificationSound('notification'),
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          // sound: 'notification.caf', // uncomment if you add custom iOS sound
        ),
      ),
      payload: payload,
    );
  }

  void _handlePayload(String? payload) {
    if (payload == null || payload.isEmpty) return;

    // Always store payload to be processed later after router is ready
    pendingNavigationPayload = payload;
  }

  void checkPendingNavigation() {
    if (pendingNavigationPayload != null) {
      // _navigateToBooking(pendingNavigationPayload!);
      pendingNavigationPayload = null;
    }
  }

  // void _navigateToBooking(String payload) {
  //   final data = _parsePayload(payload);
  //   AppPages.router.push(AppRoutes.confirmBooking, extra: data);
  // }

  Map<String, String> _parsePayload(String payload) {
    final map = <String, String>{};
    final lines = payload.split('\n');
    for (var line in lines) {
      final parts = line.split(':');
      if (parts.length >= 2) {
        map[parts[0].trim()] = parts.sublist(1).join(':').trim();
      }
    }
    return map;
  }
}
