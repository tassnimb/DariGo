
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

  // EXTRAIRE UN MESSAGE CLAIR DE DJANGO
  static String _messageErreur(http.Response response) {
    try {
      final data = jsonDecode(response.body);

      if (data is Map) {
        final messages = <String>[];

        data.forEach((key, value) {
          if (value is List) {
            messages.addAll(value.map((e) => e.toString()));
          } else if (value is String) {
            messages.add(value);
          }
        });

        if (messages.isNotEmpty) {
          final texte = messages.join(' ').toLowerCase();

          if (texte.contains('disponible') ||
              texte.contains('chevauche') ||
              texte.contains('réservation existe') ||
              texte.contains('reservation existe')) {
            return "Ce logement n'est pas disponible pour ces dates. "
                "Veuillez choisir une autre période.";
          }

          return messages.join('\n');
        }
      }
    } catch (_) {
      // La réponse n'est pas du JSON.
    }

    if (response.statusCode == 400) {
      return "Les informations de réservation sont invalides.";
    }

    if (response.statusCode == 401) {
      return "Votre session a expiré. Veuillez vous reconnecter.";
    }

    if (response.statusCode == 403) {
      return "Vous n'avez pas l'autorisation d'effectuer cette action.";
    }

    return "Une erreur est survenue. Veuillez réessayer.";
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

    throw Exception(_messageErreur(response));
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

    throw Exception(_messageErreur(response));
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

    throw Exception(_messageErreur(response));
  }
}
