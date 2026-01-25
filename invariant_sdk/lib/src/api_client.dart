// invariant_sdk/lib/src/api_client.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  final String apiKey;
  final String baseUrl;
  
  // ⚡ FAIL-OPEN REQUIREMENT: Strict timeout
  static const Duration kNetworkTimeout = Duration(seconds: 4);

  ApiClient({required this.apiKey, String? baseUrl}) 
      : baseUrl = baseUrl ?? "http://16.171.151.222:3000"; 

  /// Requests a fresh nonce for hardware attestation.
  Future<String?> getChallenge() async {
    try {
      // 1. Headers: Authorization standard
      final headers = {
        'Authorization': 'Bearer $apiKey',
      };

      final response = await http.get(
        Uri.parse('$baseUrl/genesis/challenge'),
        headers: headers,
      ).timeout(kNetworkTimeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body)['nonce'];
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Submits the hardware attestation chain.
  Future<Map<String, dynamic>?> verify(Map<String, dynamic> payload) async {
    try {
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      };

      final response = await http.post(
        Uri.parse('$baseUrl/verify'), 
        headers: headers,
        body: jsonEncode(payload),
      ).timeout(kNetworkTimeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Utility: Converts Hex String to List<int> (Byte Array)
  /// Crucial for interoperability with Rust's Vec<u8> serde deserialization.
  List<int> hexToBytes(String hex) {
    List<int> bytes = [];
    for (int i = 0; i < hex.length; i += 2) {
      bytes.add(int.parse(hex.substring(i, i + 2), radix: 16));
    }
    return bytes;
  }
}