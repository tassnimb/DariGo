
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/logement.dart';

class LogementService {
  static const String baseUrl =
      "http://127.0.0.1:8000/api/logements/";

  static Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");

    if (token == null || token.isEmpty) {
      throw Exception("Session expirée. Veuillez vous reconnecter.");
    }

    return {
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    };
  }

  // AFFICHER LES LOGEMENTS
  static Future<List<Logement>> getLogements() async {
    final response = await http.get(
      Uri.parse(baseUrl),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);

      return data
          .map((e) => Logement.fromJson(e))
          .toList();
    }

    throw Exception(
      "Erreur ${response.statusCode} : ${response.body}",
    );
  }

  // AJOUTER UN LOGEMENT
  static Future<bool> addLogement({
    required String titre,
    required String adresse,
    required String description,
    required String prix,
  }) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: await _headers(),
      body: jsonEncode({
        "titre": titre,
        "adresse": adresse,
        "description": description,
        "prix": prix,
      }),
    );

    return response.statusCode == 201;
  }

  // MODIFIER UN LOGEMENT
  static Future<bool> updateLogement({
    required int id,
    required String titre,
    required String adresse,
    required String description,
    required String prix,
  }) async {
    final response = await http.put(
      Uri.parse("$baseUrl$id/"),
      headers: await _headers(),
      body: jsonEncode({
        "titre": titre,
        "adresse": adresse,
        "description": description,
        "prix": prix,
      }),
    );

    return response.statusCode == 200;
  }

  // SUPPRIMER UN LOGEMENT
  static Future<bool> deleteLogement(int id) async {
    final response = await http.delete(
      Uri.parse("$baseUrl$id/"),
      headers: await _headers(),
    );

    return response.statusCode == 204;
  }
}
