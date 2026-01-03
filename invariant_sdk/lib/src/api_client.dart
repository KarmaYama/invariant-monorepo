// lib/src/api_client.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  final String apiKey;
  final String baseUrl;

  ApiClient({required this.apiKey, String? baseUrl}) 
      : baseUrl = baseUrl ?? "http://16.171.151.222:3000"; // Default to Prod

  Future<String?> getChallenge() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/genesis/challenge'),
        // In real B2B, you'd pass the API key here
        headers: {'X-Invariant-Key': apiKey},
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['nonce'];
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> verify(List<int> pk, List<List<int>> chain, String nonce) async {
    try {
      // Convert hex string nonce back to bytes if needed by your specific backend logic, 
      // but here we just pass it through as the backend expects.
      List<int> nonceBytes = [];
      for (int i = 0; i < nonce.length; i += 2) {
        nonceBytes.add(int.parse(nonce.substring(i, i + 2), radix: 16));
      }

      final response = await http.post(
        Uri.parse('$baseUrl/genesis'), // Reusing the genesis endpoint for verification
        headers: {
          'Content-Type': 'application/json',
          'X-Invariant-Key': apiKey
        },
        body: jsonEncode({
          'public_key': pk,
          'attestation_chain': chain,
          'nonce': nonceBytes, 
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}