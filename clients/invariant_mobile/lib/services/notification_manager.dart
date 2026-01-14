// clients/invariant_mobile/lib/services/notification_manager.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
// LINTER FIX: Removed unused 'package:timezone/timezone.dart'
import 'dart:ui';
import '../utils/genesis_logic.dart';

class NotificationManager {
  static final NotificationManager _instance = NotificationManager._internal();
  factory NotificationManager() => _instance;
  NotificationManager._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  static const String _channelIdHigh = 'invariant_critical';
  static const String _channelIdLow = 'invariant_updates';
  static const String _channelIdNudge = 'invariant_maintenance';

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
    // 1. CRITICAL
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

    // 3. UPDATES
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

  /// THE SAFETY NET WARNING
  /// Triggered by AlarmManager if no heartbeat sent in 23 hours.
  Future<void> showSafetyNetWarning() async {
    await _notifications.show(
      999,
      '⚠️ ANCHOR DISCONNECTED',
      'Background sync failed. Tap to verify and save your streak.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelIdNudge, 'Signal Maintenance',
          importance: Importance.high,
          priority: Priority.high,
          color: Color(0xFF00FFC2),
          fullScreenIntent: true, // Wake up the screen!
        ),
      ),
      payload: 'safety_net',
    );
  }

  Future<void> showPromotion(String newTier) async {
    await _notifications.show(
      888, '🎖️ PROMOTION: $newTier',
      'You have reached a new security clearance level.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelIdLow, 'Mission Updates',
          importance: Importance.defaultImportance,
          color: Color(0xFF00FFC2),
        ),
      ),
    );
  }

  Future<void> showMissionBrief(int streak, int totalNetworkNodes) async {
    String body = GenesisLogic.getDailyBriefBody(streak, totalNetworkNodes);
    await _notifications.show(
      101, 'Genesis Update', body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelIdLow, 'Mission Updates',
          importance: Importance.low, priority: Priority.low,
        ),
      ),
    );
  }
}