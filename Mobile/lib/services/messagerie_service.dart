
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import 'package:flutter/foundation.dart';
class MessagerieService {
  static String get baseUrl => ApiConfig.baseUrl;

  static String get apiUrl => ApiConfig.apiUrl;

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
      Uri.parse('$apiUrl/messagerie/conversations/'),
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

  final url = Uri.parse('$apiUrl/messagerie/conversations/');

  final body = jsonEncode({
    'logement': logementId,
  });

  debugPrint('========== CRÉATION CONVERSATION ==========');
  debugPrint('URL : $url');
  debugPrint('Logement ID : $logementId');

  final response = await http.post(
    url,
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
    body: body,
  );

  debugPrint('STATUS : ${response.statusCode}');
  debugPrint('RÉPONSE DJANGO : ${response.body}');
  debugPrint('===========================================');

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
    'Erreur ${response.statusCode}: ${response.body}',
  );
}
}
