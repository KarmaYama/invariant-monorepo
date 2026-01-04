/*
 * Copyright (c) 2026 Invariant Protocol.
 *
 * This source code is licensed under the Business Source License (BSL 1.1) 
 * found in the LICENSE.md file in the root directory of this source tree.
 * * You may NOT use this code for active blocking or enforcement without a commercial license.
 */
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

  /// Verifies the device hardware using the STATELESS endpoint.
  /// This checks the crypto but does NOT mint a new identity in the database.
  Future<Map<String, dynamic>?> verify(List<int> pk, List<List<int>> chain, String nonce) async {
    try {
      // Convert hex string nonce back to bytes
      List<int> nonceBytes = [];
      for (int i = 0; i < nonce.length; i += 2) {
        nonceBytes.add(int.parse(nonce.substring(i, i + 2), radix: 16));
      }

      final response = await http.post(
        Uri.parse('$baseUrl/verify'), // <--- POINTING TO STATELESS ENDPOINT
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

      // Status 200 = Verified (Stateless)
      // Status 201 = Created (Stateful/Genesis) - We expect 200 here now.
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}