// clients/invariant_mobile/lib/services/notification_manager.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:ui';
import '../utils/genesis_logic.dart';

class NotificationManager {
  static final NotificationManager _instance = NotificationManager._internal();
  factory NotificationManager() => _instance;
  NotificationManager._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  // CHANNELS
  static const String _channelIdHigh = 'invariant_critical';
  static const String _channelIdLow = 'invariant_updates';
  static const String _channelIdNudge = 'invariant_maintenance'; // NEW

  // ID MAP
  static const int _idReaper = 666;
  static const int _idSafetyNet = 777; // NEW: The "Wake Up" nudge
  static const int _idPromotion = 888; // NEW: Rank up
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
    // 1. CRITICAL (Reaper)
    const AndroidNotificationChannel highChannel = AndroidNotificationChannel(
      _channelIdHigh, 'Critical Alerts',
      description: 'Notifications when identity revocation is imminent.',
      importance: Importance.max, playSound: true, enableVibration: true,
      ledColor: Color(0xFFFF0000), enableLights: true,
    );

    // 2. MAINTENANCE (Safety Net)
    const AndroidNotificationChannel nudgeChannel = AndroidNotificationChannel(
      _channelIdNudge, 'Signal Maintenance',
      description: 'Alerts when background synchronization is delayed.',
      importance: Importance.high, playSound: true, enableVibration: true,
    );

    // 3. UPDATES (Promotions/Daily)
    const AndroidNotificationChannel lowChannel = AndroidNotificationChannel(
      _channelIdLow, 'Mission Updates',
      description: 'Rank upgrades and daily summaries.',
      importance: Importance.defaultImportance,
    );

    var androidPlatform = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlatform != null) {
      await androidPlatform.createNotificationChannel(highChannel);
      await androidPlatform.createNotificationChannel(nudgeChannel);
      await androidPlatform.createNotificationChannel(lowChannel);
    }
  }

  // --- LOGIC ---

  /// THE SAFETY NET (Smart Nudge)
  /// Schedules a "Please Open App" notification for 3h 50m from now.
  /// If the miner runs successfully before then, this gets cancelled/overwritten.
  Future<void> scheduleSafetyNet() async {
    await _notifications.cancel(_idSafetyNet); // Clear previous

    // Schedule for just before the 4-hour window closes
    final scheduledDate = tz.TZDateTime.now(tz.local).add(const Duration(minutes: 230)); // 3h 50m

    await _notifications.zonedSchedule(
      _idSafetyNet,
      '⚠️ SIGNAL DEGRADING',
      'Background sync failed. Tap to manually verify and save your streak.',
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelIdNudge, 'Signal Maintenance',
          importance: Importance.high,
          priority: Priority.high,
          color: Color(0xFF00FFC2), // Cyan for "Fix It"
          visibility: NotificationVisibility.public,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// THE PROMOTION (Dopamine)
  /// Fires immediately when a user hits a new tier (Day 3, 7, 10, 14)
  Future<void> showPromotion(String newTier) async {
    await _notifications.show(
      _idPromotion,
      '🎖️ PROMOTION: $newTier',
      'You have reached a new security clearance level. The network acknowledges your consistency.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelIdLow, 'Mission Updates',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          color: Color(0xFF00FFC2),
        ),
      ),
    );
  }

  /// THE DAILY BRIEF
  Future<void> showMissionBrief(int streak, int totalNetworkNodes) async {
    String body = GenesisLogic.getDailyBriefBody(streak, totalNetworkNodes);
    await _notifications.show(
      _idDaily, 'Genesis Update', body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelIdLow, 'Mission Updates',
          importance: Importance.low, priority: Priority.low,
        ),
      ),
    );
  }

  /// THE REAPER (Final Warning - 5 Hours)
  Future<void> scheduleReaperWarning() async {
    await _notifications.cancel(_idReaper);
    final scheduledDate = tz.TZDateTime.now(tz.local).add(const Duration(hours: 5));

    await _notifications.zonedSchedule(
      _idReaper, '🚨 IDENTITY AT RISK',
      'You have missed a cycle. Revocation imminent.',
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelIdHigh, 'Critical Alerts',
          importance: Importance.max, priority: Priority.high,
          fullScreenIntent: true,
          color: Color(0xFFFF0000),
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }
}