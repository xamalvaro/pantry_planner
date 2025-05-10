import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:pantry_pal/expiry/expiry_model.dart';
import 'package:pantry_pal/expiry/expiry_service.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  final ExpiryService _expiryService = ExpiryService();

  Future<void> initialize() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
        print('Notification tapped: ${response.payload}');
      },
    );

    // Schedule daily check
    _scheduleDailyCheck();
  }

  void _scheduleDailyCheck() async {
    // Check for expiring items every morning at 9 AM
    await _notifications.periodicallyShow(
      0,
      'PantryPal',
      'Checking for expiring items...',
      RepeatInterval.daily,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'expiry_check',
          'Expiry Check',
          channelDescription: 'Daily check for expiring items',
          importance: Importance.low,
          priority: Priority.low,
        ),
      ),
    );

    // Actually check items
    _checkExpiringItems();
  }

  Future<void> _checkExpiringItems() async {
    final expiredItems = await _expiryService.getExpiredItems();
    final expiringItems = await _expiryService.getExpiringItems(withinDays: 3);

    // Remove already notified items
    final itemsToNotify = expiringItems.where((item) => !item.isNotified).toList();

    if (expiredItems.isNotEmpty) {
      await _showNotification(
        'Items Expired!',
        '${expiredItems.length} item(s) have expired. Check your pantry!',
        importance: Importance.high,
      );
    }

    if (itemsToNotify.isNotEmpty) {
      await _showNotification(
        'Items Expiring Soon',
        '${itemsToNotify.length} item(s) are expiring within 3 days!',
        importance: Importance.defaultImportance,
      );

      // Mark items as notified
      for (final item in itemsToNotify) {
        await _expiryService.updateItem(item.copyWith(isNotified: true));
      }
    }
  }

  Future<void> _showNotification(
      String title,
      String body, {
        Importance importance = Importance.defaultImportance,
      }) async {
    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'expiry_alerts',
          'Expiry Alerts',
          channelDescription: 'Notifications for expiring items',
          importance: importance,
          priority: Priority.high,
        ),
      ),
    );
  }
}