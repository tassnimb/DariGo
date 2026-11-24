
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
class MessagerieService {
static String get baseUrl {
  if (defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:8000';
  }

  return 'http://127.0.0.1:8000';
}

  // Récupérer le token JWT
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access');
  }

  // Récupérer la liste des conversations
  static Future<List<dynamic>> getConversations() async {
    final token = await getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Utilisateur non connecté');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/api/messagerie/conversations/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data is List) return data;

      if (data is Map && data['results'] is List) {
        return data['results'];
      }

      throw Exception('Format de réponse inattendu');
    }

    if (response.statusCode == 401) {
      throw Exception('Session expirée, reconnectez-vous');
    }

    throw Exception(
      'Erreur ${response.statusCode}: ${response.body}',
    );
  }

  // Créer une conversation ou récupérer celle qui existe déjà
  static Future<Map<String, dynamic>> creerConversation(
    int logementId,
  ) async {
    final token = await getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Utilisateur non connecté');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/api/messagerie/conversations/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'logement': logementId,
      }),
    );

    if (response.statusCode == 200 ||
        response.statusCode == 201) {
      final data = jsonDecode(response.body);

      if (data is Map<String, dynamic>) {
        return data;
      }

      throw Exception('Format de réponse inattendu');
    }

    if (response.statusCode == 401) {
      throw Exception('Session expirée, reconnectez-vous');
    }

    throw Exception(
      'Erreur création conversation ${response.statusCode}: ${response.body}',
    );
  }
}
