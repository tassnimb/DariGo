
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

import 'login_screen.dart';
import '../services/api_service.dart';
import '../widgets/custom_popup.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  DateTime? birthDate;

  XFile? selectedImage;
  Uint8List? imageBytes;

  String role = 'visiteur';

  bool isLoading = false;

  Future<void> pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();

      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();

        if (!mounted) return;

        setState(() {
          selectedImage = image;
          imageBytes = bytes;
        });
      }
    } catch (e) {
      if (!mounted) return;

      await CustomPopup.showErrorPopup(
        context: context,
        title: 'Erreur',
        message: 'Impossible de choisir cette photo.',
      );
    }
  }

  Future<void> register() async {
    // Vérification des champs
    if (firstNameController.text.trim().isEmpty ||
        lastNameController.text.trim().isEmpty ||
        usernameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        phoneController.text.trim().isEmpty ||
        passwordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty ||
        birthDate == null) {
      await CustomPopup.showWarningPopup(
        context: context,
        title: 'Champs obligatoires',
        message: 'Veuillez remplir tous les champs.',
      );
      return;
    }

    // Vérification des mots de passe
    if (passwordController.text !=
        confirmPasswordController.text) {
      await CustomPopup.showErrorPopup(
        context: context,
        title: 'Mot de passe incorrect',
        message: 'Les mots de passe ne correspondent pas.',
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final bool success = await ApiService.register(
        username: usernameController.text.trim(),
        firstName: firstNameController.text.trim(),
        lastName: lastNameController.text.trim(),
        email: emailController.text.trim(),
        phone: phoneController.text.trim(),
        birthDate: birthDate!.toIso8601String().split('T')[0],
        password: passwordController.text,
        role: role,
        image: selectedImage,
      );

      if (!mounted) return;

      if (success) {
        await CustomPopup.showSuccessPopup(
          context: context,
          title: 'Inscription réussie !',
          message: 'Votre compte DariGo a été créé avec succès. Vous pouvez maintenant vous connecter.',
        );

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const LoginScreen(),
          ),
        );
      } else {
        await CustomPopup.showErrorPopup(
          context: context,
          title: 'Inscription échouée',
          message: 'Impossible de créer votre compte. Vérifiez vos informations et réessayez.',
        );
      }
    } catch (e) {
      if (!mounted) return;

      await CustomPopup.showErrorPopup(
        context: context,
        title: 'Erreur',
        message: 'Une erreur est survenue lors de l’inscription. Veuillez réessayer.',
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> selectBirthDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      setState(() {
        birthDate = pickedDate;
      });
    }
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    usernameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inscription'),
        backgroundColor: Colors.blue,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,

          children: [
            const SizedBox(height: 15),

            const Text(
              'DariGo',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),

            const SizedBox(height: 25),

            // Photo de profil
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 70,
                    backgroundColor: Colors.grey.shade300,
                    backgroundImage: imageBytes != null
                        ? MemoryImage(imageBytes!)
                        : null,
                    child: imageBytes == null
                        ? const Icon(
                            Icons.person,
                            size: 70,
                          )
                        : null,
                  ),

                  const SizedBox(height: 10),

                  ElevatedButton.icon(
                    onPressed: isLoading ? null : pickImage,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Choisir une photo'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Prénom
            TextField(
              controller: firstNameController,
              decoration: const InputDecoration(
                labelText: 'Prénom',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),

            const SizedBox(height: 15),

            // Nom
            TextField(
              controller: lastNameController,
              decoration: const InputDecoration(
                labelText: 'Nom',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),

            const SizedBox(height: 15),

            // Username
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(
                labelText: "Nom d'utilisateur",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.account_circle),
              ),
            ),

            const SizedBox(height: 15),

            // Email
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
            ),

            const SizedBox(height: 15),

            // Téléphone
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Téléphone',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
            ),

            const SizedBox(height: 15),

            // Date de naissance
            TextFormField(
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Date de naissance',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.calendar_today),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.date_range),
                  onPressed: isLoading ? null : selectBirthDate,
                ),
                hintText: birthDate == null
                    ? 'Choisir une date'
                    : '${birthDate!.day}/${birthDate!.month}/${birthDate!.year}',
              ),
              onTap: isLoading ? null : selectBirthDate,
            ),

            const SizedBox(height: 15),

            // Mot de passe
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mot de passe',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
            ),

            const SizedBox(height: 15),

            // Confirmation mot de passe
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirmer le mot de passe',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              'Choisir votre rôle',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            RadioListTile<String>(
              title: const Text('Visiteur'),
              value: 'visiteur',
              groupValue: role,
              onChanged: isLoading
                  ? null
                  : (value) {
                      setState(() {
                        role = value!;
                      });
                    },
            ),

            RadioListTile<String>(
              title: const Text('Propriétaire'),
              value: 'proprietaire',
              groupValue: role,
              onChanged: isLoading
                  ? null
                  : (value) {
                      setState(() {
                        role = value!;
                      });
                    },
            ),

            const SizedBox(height: 25),

            // Bouton inscription
            ElevatedButton(
              onPressed: isLoading ? null : register,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Créer un compte',
                      style: TextStyle(fontSize: 18),
                    ),
            ),

            TextButton(
              onPressed: isLoading
                  ? null
                  : () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LoginScreen(),
                        ),
                      );
                    },
              child: const Text(
                'Vous avez déjà un compte ? Se connecter',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
