import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class ApiService {
  static const String baseUrl = "http://127.0.0.1:8000/api";

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

    // Ajout de l'image si elle existe
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

    print("REGISTER STATUS: ${response.statusCode}");
    print("REGISTER BODY: ${response.body}");

    return response.statusCode == 201;
  } catch (e) {
    print("REGISTER ERROR: $e");
    return false;
  }
}

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

      print("LOGIN STATUS: ${response.statusCode}");
      print("LOGIN BODY: ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return null;
    } catch (e) {
      print("LOGIN ERROR: $e");
      return null;
    }
  }
}
