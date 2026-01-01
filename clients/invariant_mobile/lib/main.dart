import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Add this
import 'theme_manager.dart';
import 'screens/boot_loader.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
    // This 'watches' for theme changes
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