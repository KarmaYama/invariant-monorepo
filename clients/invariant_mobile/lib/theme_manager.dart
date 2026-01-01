import 'package:flutter/material.dart';

class ThemeController extends ChangeNotifier {
  ThemeMode mode = ThemeMode.dark;

  bool get isDark => mode == ThemeMode.dark;

  void toggle() {
    mode = mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }
}