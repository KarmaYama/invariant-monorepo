// clients/invariant_mobile/lib/services/push_service.dart
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../api_client.dart';

// Background handler
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("🌙 Wake Up Received: ${message.data}");
}

class PushService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  static Future<void> initialize(String identityId) async {
    // 1. Request Permission
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // 2. Sync Token
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        debugPrint("🔥 FCM Token: $token");
        await InvariantClient().updatePushToken(identityId, token);
      }
    }
  }
}