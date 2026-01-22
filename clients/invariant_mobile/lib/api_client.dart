// clients/invariant_mobile/lib/api_client.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class InvariantClient {
  // ⚠️ CONFIGURATION: Real Production IP
  static const String baseUrl = 'http://16.171.151.222:3000'; 

  static const Duration kRequestTimeout = Duration(seconds: 15);

  /// [Genesis] Step 1: Get the Challenge (Nonce)
  Future<String?> getGenesisChallenge() async {
    return _fetchNonce('$baseUrl/genesis/challenge');
  }

  /// [Daily Tap] Step 1: Get the Challenge (Nonce) for Heartbeat
  Future<String?> getHeartbeatChallenge() async {
    return _fetchNonce('$baseUrl/heartbeat/challenge');
  }

  Future<String?> _fetchNonce(String endpoint) async {
    try {
      final response = await http.get(Uri.parse(endpoint)).timeout(kRequestTimeout);
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return body['nonce'];
      }
      return null;
    } catch (e) {
      debugPrint('❌ Nonce Fetch Error: $e');
      return null;
    }
  }

  /// [Genesis] Step 2: Submit Identity
  Future<String?> genesis(List<int> publicKey, List<List<int>> attestationChain, String nonce) async {
    final url = Uri.parse('$baseUrl/genesis');
    
    try {
      List<int> nonceBytes = hexToBytes(nonce);

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

  /// [Daily Tap] Step 2: Submit Signed Heartbeat
  Future<bool> heartbeat(String uuid, List<int> signature, String nonce, String timestamp) async {
    final url = Uri.parse('$baseUrl/heartbeat');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'identity_id': uuid,
          'device_signature': signature,
          'nonce': hexToBytes(nonce), // Must send nonce bytes
          'timestamp': timestamp,
        }),
      ).timeout(kRequestTimeout);

      if (response.statusCode == 200) return true;
      
      // 429 = Already tapped today (Success state for UI)
      if (response.statusCode == 429) {
        debugPrint("⏳ Daily Limit Reached");
        return true; 
      }
      
      debugPrint("Server Rejected Tap: ${response.statusCode} ${response.body}");
      return false;
    } catch (e) { 
      debugPrint("Heartbeat Net Error: $e");
      return false; 
    }
  }

  Future<bool> claimUsername(String uuid, String username) async {
    final url = Uri.parse('$baseUrl/identity/claim_username');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'identity_id': uuid, 'username': username}),
      ).timeout(kRequestTimeout);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> checkSession(String uuid) async {
    final url = Uri.parse('$baseUrl/identity/$uuid');
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      if (response.statusCode == 404) return false; // Explicitly revoked/missing
      return true; // Fail open
    } catch (e) {
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
      return [];
    }
  }

  Future<void> updatePushToken(String uuid, String token) async {
    final url = Uri.parse('$baseUrl/identity/push_token');
    try {
      await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'identity_id': uuid, 'fcm_token': token}),
      ).timeout(kRequestTimeout);
    } catch (e) {
      debugPrint("❌ Token Sync Net Error: $e");
    }
  }

  static List<int> hexToBytes(String hex) {
    List<int> bytes = [];
    for (int i = 0; i < hex.length; i += 2) {
      bytes.add(int.parse(hex.substring(i, i + 2), radix: 16));
    }
    return bytes;
  }
}