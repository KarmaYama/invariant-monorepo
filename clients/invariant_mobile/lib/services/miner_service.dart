// clients/invariant_mobile/lib/services/miner_service.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:workmanager/workmanager.dart';
import '../api_client.dart';
import '../utils/time_helper.dart';
import '../utils/genesis_logic.dart'; 
import 'notification_manager.dart'; 

const String kHeartbeatTask = "invariant_heartbeat";

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    final notifs = NotificationManager();
    await notifs.initialize();

    const storage = FlutterSecureStorage();
    final client = InvariantClient();
    const platform = MethodChannel('com.invariant.protocol/keystore');

    try {
      debugPrint("⛏️ MINER: Waking up...");
      
      final identityId = await storage.read(key: 'identity_id');
      if (identityId == null) return Future.value(false);

      final timestamp = TimeHelper.canonicalUtcTimestamp();
      final payloadToSign = "$identityId|$timestamp";

      final signature = await platform.invokeMethod('signHeartbeat', {
        'payload': payloadToSign,
      });

      final sigBytes = (signature as List<Object?>).map((e) => e as int).toList();
      final success = await client.heartbeat(identityId, sigBytes, timestamp);
      
      if (success) {
        debugPrint("✅ MINER: Success.");

        // 1. REAPER: Reset the Dead Man's Switch to +5 hours
        await notifs.scheduleReaperWarning();

        // 2. DAILY BRIEF: Check status and notify if milestone reached
        try {
          final status = await client.getIdentityStatus(identityId);
          if (status != null) {
            final streak = int.tryParse((status['streak'] ?? '0').toString()) ?? 0;
            
            // UPDATED LOGIC: 
            // Notify on the VERY FIRST success (streak=1) so they know it works.
            // Then notify every 24h (streak % 6 == 0).
            if (streak == 1 || (streak > 0 && streak % GenesisLogic.cyclesPerDay == 0)) {
              
              // Mock total nodes if API doesn't return it yet
              int totalNodes = 20; 
              
              await notifs.showMissionBrief(streak, totalNodes);
            }
          }
        } catch (e) {
          debugPrint("Miner Status Check Failed: $e");
        }

      } else {
        debugPrint("❌ MINER: Failed.");
      }

      return Future.value(success);

    } catch (e) {
      debugPrint("❌ MINER ERROR: $e");
      return Future.value(false);
    }
  });
}

class MinerService {
  static void initialize() {
    Workmanager().initialize(
      callbackDispatcher,
      // ignore: deprecated_member_use
      isInDebugMode: false, 
    );
  }

  static void startMining() {
    Workmanager().registerPeriodicTask(
      kHeartbeatTask, 
      "mining_task",
      frequency: const Duration(hours: 4), 
      constraints: Constraints(
        networkType: NetworkType.connected, 
        requiresBatteryNotLow: true,
      ),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      backoffPolicy: BackoffPolicy.linear,
      backoffPolicyDelay: const Duration(minutes: 10),
    );
  }
}