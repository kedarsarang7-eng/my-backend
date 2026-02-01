// ============================================================================
// RESTAURANT NOTIFICATION SERVICE
// ============================================================================
// Handles push notifications for order updates

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../data/models/food_order_model.dart';

class RestaurantNotificationService {
  static final RestaurantNotificationService _instance =
      RestaurantNotificationService._internal();
  factory RestaurantNotificationService() => _instance;
  RestaurantNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isInitialized = false;
  bool _soundEnabled = true;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _isInitialized = true;
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap - navigate to relevant screen
    // payload format: "order:{orderId}" or "table:{tableId}"
  }

  /// Toggle sound alerts
  void setSoundEnabled(bool enabled) {
    _soundEnabled = enabled;
  }

  bool get isSoundEnabled => _soundEnabled;

  // ============================================================================
  // VENDOR NOTIFICATIONS
  // ============================================================================

  /// Notify vendor of new order (with bell sound)
  Future<void> notifyNewOrder(FoodOrder order) async {
    await _showNotification(
      id: order.id.hashCode,
      title: '🔔 New Order!',
      body:
          'Table ${order.tableNumber ?? 'Takeaway'} - ${order.items.length} items',
      channelId: 'new_orders',
      channelName: 'New Orders',
      sound: 'order_bell',
      importance: Importance.high,
    );

    // Play bell sound
    if (_soundEnabled) {
      await _playOrderBell();
    }
  }

  /// Notify vendor that customer requested bill
  Future<void> notifyBillRequested(String tableNumber, String orderId) async {
    await _showNotification(
      id: orderId.hashCode,
      title: '📄 Bill Requested',
      body: 'Table $tableNumber is ready to pay',
      channelId: 'bill_requests',
      channelName: 'Bill Requests',
      importance: Importance.high,
    );

    if (_soundEnabled) {
      await _playNotificationSound();
    }
  }

  /// Notify kitchen that order is taking too long
  Future<void> notifyOrderDelay(FoodOrder order, int minutesWaiting) async {
    await _showNotification(
      id: order.id.hashCode + 1000,
      title: '⚠️ Order Delayed',
      body:
          'Table ${order.tableNumber ?? 'Takeaway'} waiting $minutesWaiting min',
      channelId: 'order_delays',
      channelName: 'Order Delays',
      importance: Importance.high,
    );

    if (_soundEnabled) {
      await _playAlertSound();
    }
  }

  // ============================================================================
  // CUSTOMER NOTIFICATIONS
  // ============================================================================

  /// Notify customer that order is accepted
  Future<void> notifyOrderAccepted(String orderId, String? tableNumber) async {
    await _showNotification(
      id: orderId.hashCode,
      title: '✅ Order Accepted',
      body: 'Your order is being prepared',
      channelId: 'order_updates',
      channelName: 'Order Updates',
    );
  }

  /// Notify customer that order is ready
  Future<void> notifyOrderReady(String orderId, String? tableNumber) async {
    await _showNotification(
      id: orderId.hashCode,
      title: '🍽️ Order Ready!',
      body: 'Your delicious food is ready to serve',
      channelId: 'order_updates',
      channelName: 'Order Updates',
      importance: Importance.high,
    );

    if (_soundEnabled) {
      await _playNotificationSound();
    }
  }

  /// Notify customer that order is served
  Future<void> notifyOrderServed(String orderId) async {
    await _showNotification(
      id: orderId.hashCode,
      title: '🎉 Enjoy Your Meal!',
      body: 'Your order has been served. Bon appétit!',
      channelId: 'order_updates',
      channelName: 'Order Updates',
    );
  }

  // ============================================================================
  // SOUND EFFECTS
  // ============================================================================

  /// Play the new order bell sound
  Future<void> _playOrderBell() async {
    try {
      // Using a system sound as fallback - in production, use custom asset
      await _audioPlayer.play(AssetSource('sounds/order_bell.mp3'));
    } catch (e) {
      // Fallback to system notification sound
      await _playSystemSound();
    }
  }

  /// Play a generic notification sound
  Future<void> _playNotificationSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/notification.mp3'));
    } catch (e) {
      await _playSystemSound();
    }
  }

  /// Play alert sound for delays
  Future<void> _playAlertSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/alert.mp3'));
    } catch (e) {
      await _playSystemSound();
    }
  }

  /// Play system default sound
  Future<void> _playSystemSound() async {
    // Use a tone as fallback
    try {
      await _audioPlayer.play(
        UrlSource('https://www.soundjay.com/button/beep-07.wav'),
      );
    } catch (_) {
      // Silent fallback
    }
  }

  /// Play the order bell manually (for testing or manual trigger)
  Future<void> playOrderBell() async {
    if (_soundEnabled) {
      await _playOrderBell();
    }
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  Future<void> _showNotification({
    required int id,
    required String title,
    required String body,
    required String channelId,
    required String channelName,
    String? sound,
    Importance importance = Importance.defaultImportance,
    String? payload,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      importance: importance,
      priority: importance == Importance.high
          ? Priority.high
          : Priority.defaultPriority,
      playSound: sound != null,
      enableVibration: true,
      ticker: title,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      id,
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  /// Dispose resources
  void dispose() {
    _audioPlayer.dispose();
  }
}
