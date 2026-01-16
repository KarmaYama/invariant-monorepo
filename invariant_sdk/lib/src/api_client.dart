/*
 * Copyright (c) 2026 Invariant Protocol.
 *
 * This source code is licensed under the Business Source License (BSL 1.1) 
 * found in the LICENSE.md file in the root directory of this source tree.
 * * You may NOT use this code for active blocking or enforcement without a commercial license.
 */
// invariant_sdk/lib/src/api_client.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  final String apiKey;
  final String baseUrl;

  ApiClient({required this.apiKey, String? baseUrl}) 
      : baseUrl = baseUrl ?? "http://16.171.151.222:3000"; 

  /// Requests a fresh nonce for hardware attestation
  Future<String?> getChallenge() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/genesis/challenge'),
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

  /// Submits the hardware attestation chain to the Rust engine for verification.
  Future<Map<String, dynamic>?> verify(List<int> pk, List<List<int>> chain, String nonce) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/verify'), 
        headers: {
          'Content-Type': 'application/json',
          'X-Invariant-Key': apiKey
        },
        body: jsonEncode({
          'public_key': pk,
          'attestation_chain': chain,
          'nonce': _hexToBytes(nonce), 
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  List<int> _hexToBytes(String hex) {
    List<int> bytes = [];
    for (int i = 0; i < hex.length; i += 2) {
      bytes.add(int.parse(hex.substring(i, i + 2), radix: 16));
    }
    return bytes;
  }
}