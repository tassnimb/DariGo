
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../config/api_config.dart';

class ApiService {
  static String get baseUrl => ApiConfig.apiUrl;

  // INSCRIPTION
  static Future<bool> register({
    required String username,
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String birthDate,
    required String password,
    required String role,
    XFile? image,
  }) async {
    try {
      var request = http.MultipartRequest(
        "POST",
        Uri.parse("$baseUrl/register/"),
      );

      request.fields["username"] = username;
      request.fields["first_name"] = firstName;
      request.fields["last_name"] = lastName;
      request.fields["email"] = email;
      request.fields["phone"] = phone;
      request.fields["birth_date"] = birthDate;
      request.fields["password"] = password;
      request.fields["role"] = role;

      if (image != null) {
        final bytes = await image.readAsBytes();

        request.files.add(
          http.MultipartFile.fromBytes(
            "profile_photo",
            bytes,
            filename: image.name,
          ),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint("REGISTER STATUS: ${response.statusCode}");
      debugPrint("REGISTER BODY: ${response.body}");

      return response.statusCode == 201;
    } catch (e) {
      debugPrint("REGISTER ERROR: $e");
      return false;
    }
  }

  // CONNEXION
  static Future<Map<String, dynamic>?> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/token/"),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "username": username,
          "password": password,
        }),
      );

      debugPrint("LOGIN STATUS: ${response.statusCode}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      debugPrint("LOGIN ERROR BODY: ${response.body}");
      return null;
    } catch (e) {
      debugPrint("LOGIN ERROR: $e");
      return null;
    }
  }
}
