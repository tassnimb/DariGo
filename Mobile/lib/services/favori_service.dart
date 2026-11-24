import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class FavoriService {
  static const String baseUrl =
      "http://127.0.0.1:8000/api/favoris/";

  static Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString("access");

    return {
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    };
  }

  // Ajouter aux favoris
  static Future<bool> addFavori(
    int logementId,
  ) async {

    final response = await http.post(
      Uri.parse(baseUrl),
      headers: await _headers(),
      body: jsonEncode({
        "logement": logementId,
      }),
    );

    print(response.statusCode);
    print(response.body);

    return response.statusCode == 201;
  }

  // Mes favoris
  static Future<List<Map<String, dynamic>>>
      getFavoris() async {

    final response = await http.get(
      Uri.parse(baseUrl),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {

      final List data =
          jsonDecode(response.body);

      return data
          .map(
            (e) => Map<String, dynamic>.from(e),
          )
          .toList();
    }

    throw Exception(
      "Erreur ${response.statusCode}",
    );
  }

  // Retirer des favoris
  static Future<bool> deleteFavori(
    int favoriId,
  ) async {

    final response = await http.delete(
      Uri.parse("$baseUrl$favoriId/"),
      headers: await _headers(),
    );

    return response.statusCode == 204;
  }
}