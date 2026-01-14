// clients/invariant_mobile/lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'theme_manager.dart';
import 'screens/boot_loader.dart';
import 'services/push_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Firebase Core
  try {
    await Firebase.initializeApp();
    // Register Background Handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint("⚠️ Firebase Init Failed: $e");
  }

  // 2. Try to get ID for Push Init (Best Effort)
  const storage = FlutterSecureStorage();
  String? id = await storage.read(key: 'identity_id');
  
  if (id != null) {
    await PushService.initialize(id);
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeController(),
      child: const InvariantApp(),
    ),
  );
}

class InvariantApp extends StatelessWidget {
  const InvariantApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = context.watch<ThemeController>();

    return MaterialApp(
      title: 'Invariant Protocol',
      debugShowCheckedModeBanner: false,
      themeMode: themeController.mode,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF5F5F7),
        primaryColor: const Color(0xFF00FFC2),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF050505),
        primaryColor: const Color(0xFF00FFC2),
        useMaterial3: true,
      ),
      home: const BootLoader(),
    );
  }
}