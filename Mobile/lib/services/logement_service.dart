import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/logement.dart';

class LogementService {
  static const String baseUrl =
      "http://127.0.0.1:8000/api/logements/";

  static Future<List<Logement>> getLogements() async {
    SharedPreferences prefs =
        await SharedPreferences.getInstance();

    String? token = prefs.getString("access");

    final response = await http.get(
      Uri.parse(baseUrl),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    print("STATUS CODE : ${response.statusCode}");
    print("BODY : ${response.body}");

    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);

      return data
          .map((e) => Logement.fromJson(e))
          .toList();
    }

    throw Exception(
      "Erreur ${response.statusCode} : ${response.body}",
    );
  }

  // AJOUTE CETTE METHODE ICI
  static Future<bool> addLogement({
    required String titre,
    required String adresse,
    required String description,
    required String prix,
  }) async {
    SharedPreferences prefs =
        await SharedPreferences.getInstance();

    String? token = prefs.getString("access");

    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "titre": titre,
        "adresse": adresse,
        "description": description,
        "prix": prix,
      }),
    );

    print(response.statusCode);
    print(response.body);

    return response.statusCode == 201;
  }
    static Future<bool> updateLogement({
    required int id,
    required String titre,
    required String adresse,
    required String description,
    required String prix,
  }) async {
    SharedPreferences prefs =
        await SharedPreferences.getInstance();

    String? token = prefs.getString("access");

    final response = await http.put(
      Uri.parse("$baseUrl$id/"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "titre": titre,
        "adresse": adresse,
        "description": description,
        "prix": prix,
      }),
    );

    print(response.statusCode);
    print(response.body);

    return response.statusCode == 200;
  }
  static Future<bool> deleteLogement(int id) async {
  SharedPreferences prefs =
      await SharedPreferences.getInstance();

  String? token = prefs.getString("access");

  final response = await http.delete(
    Uri.parse("$baseUrl$id/"),
    headers: {
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    },
  );

  print(response.statusCode);

  return response.statusCode == 204;
}
}