// clients/invariant_mobile/lib/services/miner_service.dart
import 'dart:io';
// LINTER FIX: Removed unused 'dart:ui'
import 'package:flutter/material.dart'; // REQUIRED for WidgetsFlutterBinding
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
// LINTER FIX: Removed unnecessary 'flutter/foundation.dart' (covered by material)
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// LINTER FIX: Removed unused 'shared_preferences'
import '../api_client.dart';
import '../utils/time_helper.dart';
import 'notification_manager.dart';

// Unique IDs for our Alarms
const int kAlarmIdMining = 777;
const int kAlarmIdSafetyNet = 888; // The "Wake Up" Nudge

// The native bridge channel (must match Kotlin)
const platform = MethodChannel('com.invariant.protocol/keystore');

class MinerService {
  
  /// Call this on App Startup (main.dart) to unleash the Hydra.
  static Future<void> initialize() async {
    if (!Platform.isAndroid) return;

    await AndroidAlarmManager.initialize();
    
    // HEAL THE ZOMBIES: 
    // If the app is opened, force a re-schedule. This fixes "Force Stop" states.
    await scheduleMiningCycle();
  }

  /// The "Set It and Forget It" Scheduler
  static Future<void> scheduleMiningCycle() async {
    debugPrint("🔩 MINER: Scheduling Hydra...");

    // 1. Schedule the Mining Task (Every 4 hours)
    // We use 'periodic' with wakeup:true to punch through Doze.
    // 'exact: false' is KEY. It tells Android "Run this when you can," 
    // which prevents the OS from killing us for being annoying.
    await AndroidAlarmManager.periodic(
      const Duration(hours: 4),
      kAlarmIdMining,
      _miningCallback,
      wakeup: true, // Forces CPU wake
      rescheduleOnReboot: true, // Survives restart
      exact: false, // "Windowed" execution (Higher reliability)
    );

    // 2. Schedule the "Safety Net" (23 Hours from now)
    // If _miningCallback runs successfully, it pushes this forward.
    // If it fails for a whole day, this alarm fires a notification to the user.
    await AndroidAlarmManager.oneShot(
      const Duration(hours: 23),
      kAlarmIdSafetyNet,
      _safetyNetCallback,
      wakeup: true,
      exact: true, // Must be exact to warn user before streak dies
      rescheduleOnReboot: true,
    );
  }

  /// THE HEADLESS WORKER
  /// This runs in a separate Isolate when the Alarm fires.
  @pragma('vm:entry-point')
  static Future<void> _miningCallback() async {
    // Ensure Flutter engine is initialized in this background isolate
    WidgetsFlutterBinding.ensureInitialized();
    debugPrint("⛏️ MINER: Waking up from Doze...");
    
    // 1. Safety Check: Direct Boot / User Lock
    // If the user hasn't unlocked their phone after reboot, SecureStorage crashes.
    try {
      const storage = FlutterSecureStorage();
      final id = await storage.read(key: 'identity_id');
      
      if (id == null) {
        debugPrint("⚠️ MINER: No Identity found (Locked?). Aborting.");
        return;
      }

      // 2. The Cryptographic Handshake
      final timestamp = TimeHelper.canonicalUtcTimestamp();
      final payload = "$id|$timestamp";
      
      // Native Bridge call to StrongBox
      // We invoke the platform channel from the background isolate.
      final signature = await platform.invokeMethod('signHeartbeat', {'payload': payload});
      final sigBytes = (signature as List<Object?>).map((e) => e as int).toList();

      // 3. Upload to Rust Backend
      final success = await InvariantClient().heartbeat(id, sigBytes, timestamp);

      if (success) {
        debugPrint("✅ MINER: Success. Extending Safety Net.");
        
        // PUSH THE SAFETY NET BACK 23 HOURS
        // This effectively cancels the "Warning" notification because we are safe.
        await AndroidAlarmManager.oneShot(
          const Duration(hours: 23),
          kAlarmIdSafetyNet,
          _safetyNetCallback,
          wakeup: true,
          exact: true, 
          rescheduleOnReboot: true,
        );
      } else {
        debugPrint("❌ MINER: Upload failed. Safety Net remains active.");
      }

    } catch (e) {
      debugPrint("💥 MINER CRITICAL: $e");
      // We do NOT cancel the Safety Net. 
      // If this keeps failing, the Safety Net alarm will eventually fire 
      // and notify the user to open the app.
    }
  }

  /// THE SAFETY NET (The "Fail-Safe")
  /// This only runs if the miner has failed for 23 straight hours.
  @pragma('vm:entry-point')
  static Future<void> _safetyNetCallback() async {
    WidgetsFlutterBinding.ensureInitialized();
    final notifs = NotificationManager();
    await notifs.initialize();
    await notifs.showSafetyNetWarning();
  }
}