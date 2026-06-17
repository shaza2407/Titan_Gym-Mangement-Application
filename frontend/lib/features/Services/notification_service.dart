import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import '../shared/api_constants.dart';
import 'package:flutter/foundation.dart'; 

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class NotificationService {
  // static final _messaging = FirebaseMessaging.instance;
  static FirebaseMessaging get _messaging => FirebaseMessaging.instance;
  static final _localNotifications = FlutterLocalNotificationsPlugin();

  static const _channelId = 'gym_invites';
  static const _channelName = 'Gym Invitations';
  static const _channelDesc = 'Gym invitation notifications';

  static Future<void> init() async {
    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await _localNotifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (NotificationResponse response) {},
    );

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification != null) {
        _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              _channelId,
              _channelName,
              channelDescription: _channelDesc,
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
        );
      }
    });
  }


static Future<void> saveToken(int userId, String authToken) async {
  if (kIsWeb || Platform.isLinux) return;

  final token = await _messaging.getToken();
  if (token == null) return;

  await http.post(
    Uri.parse('${ApiConstants.baseUrl}/notifications/fcm-token?user_id=$userId&token=$token'),
    headers: {'Authorization': 'Bearer $authToken'},
  );
}
}