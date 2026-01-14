// clients/invariant_mobile/lib/services/push_service.dart
import 'dart:async';
import 'package:flutter/material.dart'; // REQUIRED for Color
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../api_client.dart';

// ⚠️ ENTRY POINT: Must be top-level (outside any class)
// This runs in a separate isolate when the app is terminated/backgrounded.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // 1. Initialize Firebase (Minimal)
  await Firebase.initializeApp();

  debugPrint("🌙 BACKGROUND WAKE-UP RECEIVED: ${message.data}");

  // 2. Handle Data-Only Payload
  // We manually trigger the notification because "data-only" messages
  // don't wake the screen automatically on Android.
  if (message.data['type'] == 'wake_up_call') {
    await PushService.showLocalNotification(
      title: "⚠️ ANCHOR DECAYING",
      body: "Your identity streak is at risk. Tap to verify now.",
      payload: "verify_now",
    );
  }
}

class PushService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize(String identityId) async {
    // 1. Setup Local Notifications (The Display Layer)
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const InitializationSettings initSettings =
        InitializationSettings(android: androidSettings);

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint("🔔 Notification Tapped: ${details.payload}");
        // Navigation logic creates a new route stack if app was closed
      },
    );

    // 2. Request Permissions (Android 13+ / iOS)
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('✅ Push Permission Granted');
      
      // 3. Get FCM Token & Sync to Server
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        debugPrint("🔥 FCM Token: $token");
        // UNCOMMENTED & FIXED:
        try {
           await InvariantClient().updatePushToken(identityId, token);
           debugPrint("🚀 Token synced to Invariant Node");
        } catch (e) {
           debugPrint("⚠️ Failed to sync token: $e");
        }
      }
    } else {
      debugPrint('❌ Push Permission Denied');
    }

    // 4. Foreground Listener (When app is open)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint("☀️ FOREGROUND MESSAGE: ${message.data}");
      if (message.data['type'] == 'wake_up_call') {
        showLocalNotification(
          title: "⚠️ ANCHOR DECAYING",
          body: "Your identity streak is at risk. Tap to verify.",
          payload: "verify_now",
        );
      }
    });
  }

  /// Manually triggers a high-priority notification from a data payload.
  /// This bridges the gap between "Silent Data Push" and "User Alert".
  static Future<void> showLocalNotification({
    required String title,
    required String body,
    required String payload,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'invariant_critical', // Must match channel ID in AndroidManifest
      'Critical Alerts',
      channelDescription: 'Wake-up calls for identity verification',
      importance: Importance.max,
      priority: Priority.high,
      color: Color(0xFF00FFC2), // Invariant Cyan
      fullScreenIntent: true, // Attempt to wake screen
      enableVibration: true,
      playSound: true,
    );

    const NotificationDetails details = NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      0, // ID (0 replaces previous, preventing spam pile-up)
      title,
      body,
      details,
      payload: payload,
    );
  }
}