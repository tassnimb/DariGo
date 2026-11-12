
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ReservationService {
  static const String baseUrl =
      "http://127.0.0.1:8000/api/reservations/";

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

  // AFFICHER LES RESERVATIONS
  static Future<List<Map<String, dynamic>>> getReservations() async {
    final response = await http.get(
      Uri.parse(baseUrl),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);

      return data
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }

    throw Exception(
      "Erreur ${response.statusCode} : ${response.body}",
    );
  }

  // AJOUTER UNE RESERVATION
  static Future<Map<String, dynamic>> addReservation({
    required int logementId,
    required String dateArrivee,
    required String dateDepart,
    required int nombrePersonnes,
    String besoins = "",
    String message = "",
  }) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: await _headers(),
      body: jsonEncode({
        "logement": logementId,
        "date_arrivee": dateArrivee,
        "date_depart": dateDepart,
        "nombre_personnes": nombrePersonnes,
        "besoins": besoins,
        "message": message,
      }),
    );

    if (response.statusCode == 201) {
      return Map<String, dynamic>.from(
        jsonDecode(response.body),
      );
    }

    throw Exception(
      "Erreur ${response.statusCode} : ${response.body}",
    );
  }

  // ACCEPTER OU REFUSER UNE RESERVATION
  static Future<bool> updateStatut({
    required int reservationId,
    required String statut,
  }) async {
    final response = await http.patch(
      Uri.parse("${baseUrl}${reservationId}/"),
      headers: await _headers(),
      body: jsonEncode({
        "statut": statut,
      }),
    );

    if (response.statusCode == 200) {
      return true;
    }

    throw Exception(
      "Erreur ${response.statusCode} : ${response.body}",
    );
  }
}
