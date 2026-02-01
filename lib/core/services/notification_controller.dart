import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Unified Controller for all Notification Logic (Push + Local).
/// Replaces: PushService, NotificationService, FirebaseMessagingService.
class NotificationController {
  final FirebaseMessaging _fm = FirebaseMessaging.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  NotificationController();

  /// Initialize permissions and listeners
  Future<void> init() async {
    try {
      // 1. Request Permissions
      final settings = await _fm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      developer.log('FCM Permission: ${settings.authorizationStatus}',
          name: 'NotificationController');

      // 2. Init Local Notifications (Native only)
      if (!kIsWeb) {
        const androidInit =
            AndroidInitializationSettings('@mipmap/ic_launcher');
        const iosInit = DarwinInitializationSettings();
        await _local.initialize(
          const InitializationSettings(android: androidInit, iOS: iosInit),
          onDidReceiveNotificationResponse: (response) {
            developer.log('Local Notification Clicked: ${response.payload}',
                name: 'NotificationController');
            // Handle navigation here if needed
          },
        );
      }

      // 3. Foreground Listener
      FirebaseMessaging.onMessage.listen((message) {
        developer.log('Foreground Message: ${message.messageId}',
            name: 'NotificationController');
        final notification = message.notification;
        if (notification != null) {
          showLocal(
            title: notification.title ?? 'Notification',
            body: notification.body ?? '',
          );
        }
      });

      // 4. Background Open Listener
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        developer.log('Message Opened App: ${message.messageId}',
            name: 'NotificationController');
        // Navigate to specific screen if needed
      });
    } catch (e) {
      developer.log('Init Error: $e', name: 'NotificationController');
    }
  }

  /// Get FCM Token and optionally sync to User Profile
  Future<String?> getToken({String? uid}) async {
    try {
      final token = await _fm.getToken();
      if (token != null) {
        developer.log('FCM Token: $token', name: 'NotificationController');
        if (uid != null) {
          await _saveTokenToFirestore(uid, token);
        }
      }
      return token;
    } catch (e) {
      developer.log('Get Token Error: $e', name: 'NotificationController');
      return null;
    }
  }

  /// Manually show a local notification
  Future<void> showLocal({required String title, required String body}) async {
    if (kIsWeb) return;
    try {
      const android = AndroidNotificationDetails(
        'dukanx_channel_01',
        'DukanX Alerts',
        channelDescription: 'General Notifications',
        importance: Importance.max,
        priority: Priority.high,
      );
      const ios = DarwinNotificationDetails();
      const detail = NotificationDetails(android: android, iOS: ios);

      // using hashCode of title as ID to allow multiple distinct notifications, or 0 for single slot
      await _local.show(DateTime.now().millisecond, title, body, detail);
    } catch (e) {
      developer.log('Show Local Error: $e', name: 'NotificationController');
    }
  }

  /// Topic Management
  Future<void> subscribeToTopic(String topic) => _fm.subscribeToTopic(topic);
  Future<void> unsubscribeFromTopic(String topic) =>
      _fm.unsubscribeFromTopic(topic);

  /// Helper: Save token to Firestore
  Future<void> _saveTokenToFirestore(String uid, String token) async {
    try {
      await _db.collection('users').doc(uid).set(
        {'fcmToken': token, 'tokenUpdatedAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );
    } catch (e) {
      developer.log('Save Token Error: $e', name: 'NotificationController');
    }
  }

  /// Schedule a specific reminder (Example usage)
  Future<void> schedulePaymentReminder(
      String customerName, double amount) async {
    await showLocal(
        title: 'Payment Reminder',
        body:
            'Review pending dues for $customerName: ₹${amount.toStringAsFixed(0)}');
  }
}
