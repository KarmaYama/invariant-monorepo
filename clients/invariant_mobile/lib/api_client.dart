import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class InvariantClient {
  // ⚠️ CONFIGURATION: Real Production IP
  static const String baseUrl = 'http://16.171.151.222:3000'; 

  // Timeout to prevent "Stuck" UI
  static const Duration kRequestTimeout = Duration(seconds: 10);

  /// Step 1: Get the Challenge (Nonce) from the Server
  Future<String?> getGenesisChallenge() async {
    final url = Uri.parse('$baseUrl/genesis/challenge');
    try {
      final response = await http.get(url).timeout(kRequestTimeout);
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return body['nonce'];
      }
      return null;
    } catch (e) {
      debugPrint('❌ Challenge Fetch Error: $e');
      return null;
    }
  }

  /// Step 2: Submit the Hardware-Attested Key + Nonce
  Future<String?> genesis(List<int> publicKey, List<List<int>> attestationChain, String nonce) async {
    final url = Uri.parse('$baseUrl/genesis');
    
    try {
      List<int> nonceBytes = [];
      for (int i = 0; i < nonce.length; i += 2) {
        nonceBytes.add(int.parse(nonce.substring(i, i + 2), radix: 16));
      }

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'public_key': publicKey,
          'attestation_chain': attestationChain,
          'nonce': nonceBytes,
        }),
      ).timeout(kRequestTimeout);

      if (response.statusCode == 201) {
        debugPrint('✅ Genesis Successful');
        final body = jsonDecode(response.body);
        return body['id'] as String;
      } else {
        debugPrint('❌ Genesis Failed: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Connection Error: $e');
      return null;
    }
  }

  /// Claim a human-readable handle for the Genesis Cohort
  Future<bool> claimUsername(String uuid, String username) async {
    final url = Uri.parse('$baseUrl/identity/claim_username');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'identity_id': uuid,
          'username': username,
        }),
      ).timeout(kRequestTimeout);

      if (response.statusCode == 200) return true;
      
      debugPrint("Username Claim Failed: ${response.statusCode} ${response.body}");
      return false;
    } catch (e) {
      debugPrint("Username Net Error: $e");
      return false;
    }
  }

  /// Checks if the Identity still exists on the server.
  Future<bool> checkSession(String uuid) async {
    final url = Uri.parse('$baseUrl/identity/$uuid');
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      
      // If 404, the server explicitly says "I don't know you". 
      // This is the ONLY case we return false (which triggers a wipe).
      if (response.statusCode == 404) return false;
      
      // 200 OK or any other server error -> Assume valid (Fail Open)
      return true;
    } catch (e) {
      // Offline / Timeout -> Assume valid so user can see their card
      debugPrint("Session Check Offline: $e");
      return true; 
    }
  }

  Future<Map<String, dynamic>?> getIdentityStatus(String uuid) async {
    final url = Uri.parse('$baseUrl/identity/$uuid');
    try {
      final response = await http.get(url).timeout(kRequestTimeout);
      if (response.statusCode == 200) return jsonDecode(response.body);
      return null;
    } catch (e) { 
      return null; 
    }
  }

  /// Sends a signed heartbeat to the server
  Future<bool> heartbeat(String uuid, List<int> signature, String timestamp) async {
    final url = Uri.parse('$baseUrl/heartbeat');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'identity_id': uuid,
          'device_signature': signature,
          'timestamp': timestamp,
        }),
      ).timeout(kRequestTimeout);

      if (response.statusCode == 200) return true;
      
      debugPrint("Server Rejected Heartbeat: ${response.statusCode} ${response.body}");
      return false;
    } catch (e) { 
      debugPrint("Heartbeat Net Error: $e");
      return false; 
    }
  }

  /// Fetches the live Global Leaderboard
  Future<List<Map<String, dynamic>>> fetchLeaderboard() async {
    final url = Uri.parse('$baseUrl/leaderboard');
    try {
      final response = await http.get(url).timeout(kRequestTimeout);
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      debugPrint("Leaderboard Error: $e");
      return [];
    }
  }
}