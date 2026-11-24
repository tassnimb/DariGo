
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';

class FavoriService {
  static String get baseUrl =>
      '${ApiConfig.apiUrl}/favoris/';

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

  // AJOUTER AUX FAVORIS
  static Future<bool> addFavori(int logementId) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: await _headers(),
      body: jsonEncode({
        "logement": logementId,
      }),
    );

    print(response.statusCode);
    print(response.body);

    if (response.statusCode == 201) {
      return true;
    }

    if (response.statusCode == 400) {
      throw Exception(
        "Ce logement est peut-être déjà dans vos favoris.",
      );
    }

    throw Exception(
      "Impossible d'ajouter ce logement aux favoris. "
      "Erreur ${response.statusCode}.",
    );
  }

  // MES FAVORIS
  static Future<List<Map<String, dynamic>>> getFavoris() async {
    final response = await http.get(
      Uri.parse(baseUrl),
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
      "Erreur ${response.statusCode} lors du chargement des favoris.",
    );
  }

  // RETIRER DES FAVORIS
  static Future<bool> deleteFavori(int favoriId) async {
    final response = await http.delete(
      Uri.parse("${baseUrl}${favoriId}/"),
      headers: await _headers(),
    );

    if (response.statusCode == 204) {
      return true;
    }

    throw Exception(
      "Impossible de retirer ce favori. "
      "Erreur ${response.statusCode}.",
    );
  }
}
