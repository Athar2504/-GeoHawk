import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'shopper_home.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);

    await _notificationsPlugin.initialize(initializationSettings);
  }

  static Future<void> showNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'vendor_status_channel',
      'Vendor Status',
      importance: Importance.high,
      priority: Priority.high,
      ongoing: true, // Keeps notification persistent
    );

    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);

    await _notificationsPlugin.show(
      0,
      'Hawker Online',
      'You are visible to your customers. Turn off to go offline.',
      platformChannelSpecifics,
    );
  }

  static Future<void> cancelNotification() async {
    await _notificationsPlugin.cancel(0);
  }
}
