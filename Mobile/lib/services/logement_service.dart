
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/browser_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';

import '../config/api_config.dart';
import '../models/logement.dart';

class LogementService {
  static String get baseUrl =>
      '${ApiConfig.apiUrl}/logements/';

  // Récupérer le token JWT
  static Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access');

    if (token == null || token.isEmpty) {
      throw Exception(
        'Session expirée. Veuillez vous reconnecter.',
      );
    }

    return token;
  }

  // Headers pour les requêtes JSON
  static Future<Map<String, String>> _jsonHeaders() async {
    final token = await _getToken();

    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  // AFFICHER LES LOGEMENTS
  static Future<List<Logement>> getLogements() async {
    final response = await http.get(
      Uri.parse(baseUrl),
      headers: await _jsonHeaders(),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(
        utf8.decode(response.bodyBytes),
      );

      final List<dynamic> data = decoded is List
          ? decoded
          : decoded['results'] ?? [];

      return data
          .map((e) => Logement.fromJson(e))
          .toList();
    }

    throw Exception(
      'Erreur ${response.statusCode} : ${response.body}',
    );
  }

  // AJOUTER UN LOGEMENT AVEC PLUSIEURS PHOTOS
  static Future<bool> addLogement({
    required String titre,
    required String adresse,
    required String description,
    required String prix,
    required double latitude,
    required double longitude,
    String typeLogement = 'appartement',
    String typeHebergement = 'entier',
    String pays = 'Tunisie',
    String ville = '',
    String gouvernorat = '',
    String codePostal = '',
    int nombreVoyageurs = 1,
    int chambres = 1,
    int lits = 1,
    int sallesBain = 1,
    List<XFile> photos = const [],
  }) async {
    final client = BrowserClient();

    try {
      if (photos.length > 10) {
        throw Exception(
          'Maximum 10 photos autorisées.',
        );
      }

      final token = await _getToken();

      final request = http.MultipartRequest(
        'POST',
        Uri.parse(baseUrl),
      );

      request.headers['Authorization'] = 'Bearer $token';

      request.fields.addAll({
        'titre': titre,
        'adresse': adresse,
        'description': description,
        'prix': prix,
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'type_logement': typeLogement,
        'type_hebergement': typeHebergement,
        'pays': pays,
        'ville': ville,
        'gouvernorat': gouvernorat,
        'code_postal': codePostal,
        'nombre_voyageurs': nombreVoyageurs.toString(),
        'chambres': chambres.toString(),
        'lits': lits.toString(),
        'salles_bain': sallesBain.toString(),
      });

      // Ajouter les photos
      for (final photo in photos) {
        final bytes = await photo.readAsBytes();

        request.files.add(
          http.MultipartFile.fromBytes(
            'photos',
            bytes,
            filename: photo.name,
          ),
        );
      }

      final streamedResponse = await client.send(request);

      final response = await http.Response.fromStream(
        streamedResponse,
      );

      if (response.statusCode == 201) {
        return true;
      }

      throw Exception(
        'Erreur ${response.statusCode} : ${response.body}',
      );
    } catch (e) {
      throw Exception(
        'Erreur lors de l’ajout : $e',
      );
    } finally {
      client.close();
    }
  }

  // MODIFIER UN LOGEMENT ET GÉRER SES PHOTOS
  static Future<bool> updateLogement({
    required int id,
    required String titre,
    required String adresse,
    required String description,
    required String prix,
    List<XFile> nouvellesPhotos = const [],
    List<int> photosASupprimer = const [],
  }) async {
    final client = BrowserClient();

    try {
      if (nouvellesPhotos.length > 10) {
        throw Exception(
          'Maximum 10 photos autorisées.',
        );
      }

      final token = await _getToken();

      final request = http.MultipartRequest(
        'PUT',
        Uri.parse('$baseUrl$id/'),
      );

      request.headers['Authorization'] = 'Bearer $token';

      request.fields.addAll({
        'titre': titre,
        'adresse': adresse,
        'description': description,
        'prix': prix,
        'photos_a_supprimer': jsonEncode(photosASupprimer),
      });

      // Ajouter les nouvelles photos
      for (final photo in nouvellesPhotos) {
        final bytes = await photo.readAsBytes();

        request.files.add(
          http.MultipartFile.fromBytes(
            'photos',
            bytes,
            filename: photo.name,
          ),
        );
      }

      final streamedResponse = await client.send(request);

      final response = await http.Response.fromStream(
        streamedResponse,
      );

      if (response.statusCode == 200) {
        return true;
      }

      throw Exception(
        'Erreur ${response.statusCode} : ${response.body}',
      );
    } catch (e) {
      throw Exception(
        'Erreur lors de la modification : $e',
      );
    } finally {
      client.close();
    }
  }

  // SUPPRIMER UN LOGEMENT
  static Future<bool> deleteLogement(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl$id/'),
      headers: await _jsonHeaders(),
    );

    if (response.statusCode == 204 ||
        response.statusCode == 200) {
      return true;
    }

    throw Exception(
      'Erreur lors de la suppression : '
      '${response.statusCode} - ${response.body}',
    );
  }
}
