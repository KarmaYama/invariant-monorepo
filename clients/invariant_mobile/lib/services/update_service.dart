import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class UpdateService {
  // ⚡ ARCHITECTURE FIX: Point to Netlify CDN, NOT the API Server.
  // The Rust server (Control Plane) handles logic.
  // The Website (Data Plane) handles static files (APK/JSON).
  static const String manifestUrl = "https://invariantprotocol.com/version.json"; 

  Future<void> checkForUpdate(BuildContext context) async {
    // 1. Platform Guard: Don't run APK logic on iOS/Web/Desktop
    if (!Platform.isAndroid) return;

    try {
      // 2. Get Local Version
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String currentVersion = packageInfo.version;

      // 3. Fetch Manifest from Netlify CDN
      final response = await http.get(Uri.parse(manifestUrl))
          .timeout(const Duration(seconds: 3));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // 4. Defensive Parsing: Ensure types are correct
        if (data is! Map) return;

        final latestVersion = data['latest_version'];
        final downloadUrl = data['download_url'];
        
        // If critical metadata is missing or wrong type, abort
        if (latestVersion is! String || downloadUrl is! String) return;

        bool isCritical = data['critical'] == true; // safely handles null

        // 5. Robust Comparison
        if (_isNewer(currentVersion, latestVersion)) {
          if (context.mounted) {
            _showUpdateDialog(context, downloadUrl, isCritical, latestVersion);
          }
        }
      }
    } catch (e) {
      debugPrint("⚠️ Update check skipped (CDN Unreachable): $e"); 
    }
  }

  /// PROD-GRADE COMPARATOR
  /// Handles "1.0" vs "1.0.1" and non-numeric suffixes safely.
  bool _isNewer(String current, String latest) {
    // Parse segments, defaulting to 0 if non-numeric (e.g. "beta")
    List<int> c = current.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    List<int> l = latest.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    // Normalize lengths (e.g. 1.0 becomes 1.0.0 if comparing to 1.0.0)
    int maxLen = (c.length > l.length) ? c.length : l.length;

    for (int i = 0; i < maxLen; i++) {
      int cv = i < c.length ? c[i] : 0;
      int lv = i < l.length ? l[i] : 0;

      if (lv > cv) return true;  // Newer found
      if (lv < cv) return false; // Older found
    }
    return false; // Exact match
  }

  void _showUpdateDialog(BuildContext context, String url, bool isCritical, String version) {
    showDialog(
      context: context,
      barrierDismissible: !isCritical, 
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF111111),
        shape: RoundedRectangleBorder(
            side: const BorderSide(color: Color(0xFF00FFC2), width: 1),
            borderRadius: BorderRadius.circular(12)
        ),
        title: const Text("PROTOCOL UPDATE", 
            style: TextStyle(color: Color(0xFF00FFC2), fontFamily: 'SpaceGrotesk', fontWeight: FontWeight.bold)),
        content: Text(
            "New security patch v$version is available.\n\n"
            "${isCritical ? 'CRITICAL: Required to maintain Node status.' : 'Recommended for network stability.'}",
            style: const TextStyle(color: Colors.white70)
        ),
        actions: [
          if (!isCritical)
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("LATER", style: TextStyle(color: Colors.white38)),
            ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF00FFC2)),
            onPressed: () {
              launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
            },
            child: const Text("INSTALL", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}