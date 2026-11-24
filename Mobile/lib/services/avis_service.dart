
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AvisService {
  static const String baseUrl =
      "http://127.0.0.1:8000/api";

  static Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");

    return {
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    };
  }

  // Récupérer les avis d'un logement
  static Future<List<Map<String, dynamic>>> getAvis(
    int logementId,
  ) async {
    final response = await http.get(
      Uri.parse("$baseUrl/logements/$logementId/avis/"),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);

      return data
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }

    throw Exception(
      "Impossible de récupérer les avis (${response.statusCode})",
    );
  }

  // Publier un avis pour une réservation
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
