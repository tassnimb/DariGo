
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';

class AvisService {
  static String get baseUrl => ApiConfig.apiUrl;

  static Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");

    if (token == null || token.isEmpty) {
      throw Exception(
        "Session expirée. Veuillez vous reconnecter.",
      );
    }

    return {
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    };
  }

  // RÉCUPÉRER LES AVIS D'UN LOGEMENT
  static Future<List<Map<String, dynamic>>> getAvis(
    int logementId,
  ) async {
    final response = await http.get(
      Uri.parse("$baseUrl/logements/$logementId/avis/"),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      final List data = decoded is List
          ? decoded
          : decoded is Map && decoded['results'] is List
              ? decoded['results']
              : throw Exception(
                  "Format de réponse inattendu.",
                );

      return data
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }

    throw Exception(
      "Impossible de récupérer les avis "
      "(${response.statusCode})",
    );
  }

  // PUBLIER UN AVIS POUR UNE RÉSERVATION
  static Future<bool> ajouterAvis({
    required int reservationId,
    required int note,
    required String commentaire,
  }) async {
    final response = await http.post(
      Uri.parse(
        "$baseUrl/reservations/$reservationId/avis/",
      ),
      headers: await _headers(),
      body: jsonEncode({
        "note": note,
        "commentaire": commentaire,
      }),
    );

    if (response.statusCode == 201) {
      return true;
    }

    throw Exception(
      "Erreur ${response.statusCode} : ${response.body}",
    );
  }
}
