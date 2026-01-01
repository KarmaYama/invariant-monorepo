import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/foundation.dart';
import 'dart:ui';
import '../utils/genesis_logic.dart';

class NotificationManager {
  static final NotificationManager _instance = NotificationManager._internal();
  factory NotificationManager() => _instance;
  NotificationManager._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  static const String _channelIdHigh = 'invariant_high_alert';
  static const String _channelIdLow = 'invariant_mission_brief';
  static const int _idReaper = 666;
  static const int _idDaily = 101;

  Future<void> initialize() async {
    tz.initializeTimeZones();
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings settings =
        InitializationSettings(android: androidSettings);
    await _notifications.initialize(settings);
    await _createNotificationChannels();
  }

  Future<void> _createNotificationChannels() async {
    // 1. REAPER CHANNEL (Max Importance, Red LED)
    const AndroidNotificationChannel highChannel = AndroidNotificationChannel(
      _channelIdHigh,
      'Critical Alerts',
      description: 'Notifications when node stability is at risk.',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      ledColor: Color(0xFFFF0000),
      enableLights: true,
    );

    // 2. BRIEF CHANNEL (Low Importance, Silent)
    const AndroidNotificationChannel lowChannel = AndroidNotificationChannel(
      _channelIdLow,
      'Mission Briefs',
      description: 'Daily status updates.',
      importance: Importance.low,
      playSound: false,
      enableVibration: false,
    );

    var androidPlatform = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlatform?.createNotificationChannel(highChannel);
    await androidPlatform?.createNotificationChannel(lowChannel);
  }

  /// THE REAPER WARNING
  /// "If your server doesn't see a heartbeat for 5 hours... send a high-priority push"
  Future<void> scheduleReaperWarning() async {
    await _notifications.cancel(_idReaper); 

    // Schedule: +5 Hours from now
    final scheduledDate = tz.TZDateTime.now(tz.local).add(const Duration(hours: 5));

    await _notifications.zonedSchedule(
      _idReaper,
      '🚨 IDENTITY AT RISK', // Exact copy from plan
      'Your node has missed a cycle. Open Invariant immediately to prevent revocation.',
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelIdHigh,
          'Critical Alerts',
          importance: Importance.max,
          priority: Priority.high,
          color: Color(0xFFFF0000),
          fullScreenIntent: true, // Wake up screen
          visibility: NotificationVisibility.public,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
    debugPrint("💀 Reaper Warning Armed: +5 Hours");
  }

  /// THE DAILY BRIEF
  /// "Every morning, send a summary"
  Future<void> showMissionBrief(int streak, int totalNetworkNodes) async {
    String title = "Genesis Update";
    String body = GenesisLogic.getDailyBriefBody(streak, totalNetworkNodes);

    await _notifications.show(
      _idDaily,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelIdLow,
          'Mission Briefs',
          importance: Importance.low,
          priority: Priority.low,
          showWhen: true,
        ),
      ),
    );
  }

  Future<void> cancelReaper() async {
    await _notifications.cancel(_idReaper);
  }
}