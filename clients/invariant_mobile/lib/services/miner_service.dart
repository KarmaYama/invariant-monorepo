import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:workmanager/workmanager.dart';
import '../api_client.dart';
import '../utils/time_helper.dart';

const String kHeartbeatTask = "invariant_heartbeat";

// This entry point runs on a separate isolate (Headless Flutter Engine)
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // 1. Initialize dependencies in the background isolate
    const storage = FlutterSecureStorage();
    final client = InvariantClient();
    
    // This works because we moved the logic to the 'native_keystore' plugin
    const platform = MethodChannel('com.invariant.protocol/keystore');

    try {
      debugPrint("⛏️ MINER: Waking up in BACKGROUND...");
      
      final identityId = await storage.read(key: 'identity_id');
      if (identityId == null) {
        debugPrint("⛏️ MINER: No Identity found. Sleeping.");
        return Future.value(false); // Task failed (no retry needed usually if no ID)
      }

      // 2. Generate Timestamp using Canonical Helper
      final timestamp = TimeHelper.canonicalUtcTimestamp();
      final payloadToSign = "$identityId|$timestamp";

      // 3. Call the Native Plugin to sign via TEE
      final signature = await platform.invokeMethod('signHeartbeat', {
        'payload': payloadToSign,
      });

      // 4. Send to Server
      final sigBytes = (signature as List<Object?>).map((e) => e as int).toList();
      final success = await client.heartbeat(identityId, sigBytes, timestamp);
      
      if (success) {
        debugPrint("✅ MINER: Heartbeat Accepted ($timestamp).");
      } else {
        debugPrint("❌ MINER: Server Rejected.");
      }

      // Return true if successful, false to retry
      return Future.value(success);

    } catch (e) {
      debugPrint("❌ MINER ERROR: $e");
      // Return false to let WorkManager retry later if it was a glitch
      return Future.value(false);
    }
  });
}

class MinerService {
  static void initialize() {
    Workmanager().initialize(
      callbackDispatcher,
      // ignore: deprecated_member_use
      isInDebugMode: false, // 🚀 PRODUCTION MODE: No generic notifications
    );
  }

  static void startMining() {
    // Android WorkManager guarantees execution, but timing is inexact to save battery.
    // 4 hours is a safe window for the 6-hour streak logic.
    Workmanager().registerPeriodicTask(
      kHeartbeatTask, 
      "mining_task",
      frequency: const Duration(hours: 4), 
      constraints: Constraints(
        networkType: NetworkType.connected, 
        requiresBatteryNotLow: true, // Be polite to the user's battery
      ),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      backoffPolicy: BackoffPolicy.linear,
      backoffPolicyDelay: const Duration(minutes: 10),
    );
  }
}