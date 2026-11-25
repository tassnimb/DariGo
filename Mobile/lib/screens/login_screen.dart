
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/custom_popup.dart';
import '../services/api_service.dart';
import 'register_screen.dart';
import 'logements/logement_list_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController usernameController =
      TextEditingController();

  final TextEditingController passwordController =
      TextEditingController();

  bool isLoading = false;

  // Palette DariGo
  static const Color darkGreen = Color(0xFF1F3A32);
  static const Color warmBrown = Color(0xFF8B6B4A);
  static const Color offWhite = Color(0xFFF7F3EE);
  static const Color softCream = Color(0xFFEFE7DC);

  Future<void> login() async {
    if (usernameController.text.trim().isEmpty ||
        passwordController.text.isEmpty) {
      await CustomPopup.showWarningPopup(
        context: context,
        title: 'Champs obligatoires',
        message: 'Veuillez remplir tous les champs.',
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final result = await ApiService.login(
        username: usernameController.text.trim(),
        password: passwordController.text,
      );

      if (result == null) {
        if (!mounted) return;

        await CustomPopup.showErrorPopup(
          context: context,
          title: 'Connexion échouée',
          message: "Nom d'utilisateur ou mot de passe incorrect.",
        );
        return;
      }

      final String role =
          (result['role'] ?? '').toString().toLowerCase();

      final String access =
          (result['access'] ?? '').toString();

      final String refresh =
          (result['refresh'] ?? '').toString();

      final String profilePhoto =
          (result['profile_photo'] ?? '').toString();

      if (access.isEmpty || refresh.isEmpty) {
        throw Exception(
          "Les jetons d'authentification sont absents.",
        );
      }

      final SharedPreferences prefs =
          await SharedPreferences.getInstance();

      await prefs.setString('access', access);
      await prefs.setString('refresh', refresh);
      await prefs.setString('role', role);

      // Enregistrer l'URL de la photo de profil
      if (profilePhoto.isNotEmpty) {
        String photoUrl;

        if (profilePhoto.startsWith('http')) {
          photoUrl = profilePhoto;
        } else {
          photoUrl =
              'http://127.0.0.1:8000${profilePhoto.startsWith('/') ? '' : '/'}$profilePhoto';
        }

        await prefs.setString('profile_photo', photoUrl);
      } else {
        await prefs.remove('profile_photo');
      }

      if (!mounted) return;

      if (role == 'proprietaire' || role == 'visiteur') {
        await CustomPopup.showSuccessPopup(
          context: context,
          title: 'Connexion réussie',
          message: 'Bienvenue sur DariGo !',
        );

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const LogementListScreen(),
          ),
        );
      } else {
        await CustomPopup.showErrorPopup(
          context: context,
          title: 'Rôle inconnu',
          message: 'Le rôle "$role" ne permet pas de se connecter.',
        );
      }
    } catch (e) {
      if (!mounted) return;

      await CustomPopup.showErrorPopup(
        context: context,
        title: 'Erreur de connexion',
        message: 'Une erreur est survenue : $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  InputDecoration _buildInputDecoration(
    String hint,
    IconData icon,
  ) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: warmBrown.withOpacity(0.8),
        fontSize: 15,
      ),
      prefixIcon: Icon(
        icon,
        color: warmBrown,
        size: 21,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        vertical: 16,
        horizontal: 20,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(
          color: softCream,
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(
          color: darkGreen,
          width: 1.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: offWhite,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Image d'accueil
            ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(42),
                bottomRight: Radius.circular(42),
              ),
              child: Image.asset(
                'assets/images/i1.jpeg',
                height: 255,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 30,
                vertical: 22,
              ),
              child: Column(
                children: [
                  const Text(
                    'DariGo',
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: darkGreen,
                      letterSpacing: -0.5,
                    ),
                  ),

                  const SizedBox(height: 4),

                  const Text(
                    'Trouvez votre logement idéal',
                    style: TextStyle(
                      fontSize: 15,
                      color: warmBrown,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 26),

                  // Champ nom d'utilisateur
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: warmBrown.withOpacity(0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: usernameController,
                      style: const TextStyle(color: darkGreen),
                      decoration: _buildInputDecoration(
                        "Nom d'utilisateur",
                        Icons.person_rounded,
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // Champ mot de passe
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: warmBrown.withOpacity(0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: passwordController,
                      obscureText: true,
                      style: const TextStyle(color: darkGreen),
                      decoration: _buildInputDecoration(
                        'Mot de passe',
                        Icons.lock_rounded,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Bouton connexion
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: darkGreen,
                        foregroundColor: offWhite,
                        elevation: 6,
                        shadowColor: darkGreen.withOpacity(0.35),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                color: offWhite,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              'Se connecter',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Créer un compte
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RegisterScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'Créer un compte',
                      style: TextStyle(
                        color: warmBrown,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
