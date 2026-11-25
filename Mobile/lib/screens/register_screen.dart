
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

  // Palette DariGo
  static const Color darkGreen = Color(0xFF1F3A32);
 
  static const Color warmBrown = Color(0xFF8B6B4A);
  static const Color offWhite = Color(0xFFF7F3EE);
  static const Color softCream = Color(0xFFEFE7DC);

  // ==========================================
  // SELECTIONNER UNE PHOTO
  // ==========================================

  Future<void> pickImage() async {
    if (isLoading) return;

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

  // ==========================================
  // INSCRIPTION
  // ==========================================

  Future<void> register() async {
    if (isLoading) return;

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
          message:
              'Votre compte DariGo a été créé avec succès. Vous pouvez maintenant vous connecter.',
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
          message:
              'Impossible de créer votre compte. Vérifiez vos informations et réessayez.',
        );
      }
    } catch (e) {
      if (!mounted) return;

      await CustomPopup.showErrorPopup(
        context: context,
        title: 'Erreur',
        message:
            'Une erreur est survenue lors de l’inscription. Veuillez réessayer.',
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // ==========================================
  // DATE DE NAISSANCE
  // ==========================================

  Future<void> selectBirthDate() async {
    if (isLoading) return;

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: darkGreen,
              onPrimary: offWhite,
              surface: offWhite,
              onSurface: darkGreen,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null && mounted) {
      setState(() {
        birthDate = pickedDate;
      });
    }
  }

  // ==========================================
  // STYLE DES CHAMPS
  // ==========================================

  InputDecoration _buildCreamInput(
    String hint,
    IconData icon, {
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: warmBrown.withOpacity(0.75),
        fontSize: 14.5,
      ),
      prefixIcon: Icon(
        icon,
        color: warmBrown,
        size: 20,
      ),
      suffixIcon: suffix,
      filled: true,
      fillColor: softCream,
      contentPadding: const EdgeInsets.symmetric(
        vertical: 16,
        horizontal: 16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(
          color: warmBrown.withOpacity(0.15),
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(
          color: darkGreen,
          width: 1.5,
        ),
      ),
    );
  }

  // ==========================================
  // CARTES DE SELECTION DU ROLE
  // ==========================================

  Widget _buildRoleCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    final bool isSelected = role == value;

    return Expanded(
      child: GestureDetector(
        onTap: isLoading
            ? null
            : () {
                setState(() {
                  role = value;
                });
              },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 12,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? darkGreen.withOpacity(0.12)
                : softCream,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected
                  ? darkGreen
                  : warmBrown.withOpacity(0.2),
              width: isSelected ? 1.8 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? darkGreen : warmBrown,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.w500,
                    color: isSelected ? darkGreen : warmBrown,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                size: 18,
                color: isSelected
                    ? darkGreen
                    : warmBrown.withOpacity(0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // LIBERATION DES CONTROLEURS
  // ==========================================

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

  // ==========================================
  // INTERFACE GRAPHIQUE
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: offWhite,

      appBar: AppBar(
        backgroundColor: offWhite,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: darkGreen,
          ),
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
        ),
        title: const Text(
          'Inscription',
          style: TextStyle(
            color: darkGreen,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: 22,
          vertical: 10,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Avatar et photo de profil
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: warmBrown.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 54,
                      backgroundColor: softCream,
                      backgroundImage: imageBytes != null
                          ? MemoryImage(imageBytes!)
                          : null,
                      child: imageBytes == null
                          ? const Icon(
                              Icons.person_rounded,
                              size: 56,
                              color: warmBrown,
                            )
                          : null,
                    ),
                  ),

                  const SizedBox(height: 12),

                  OutlinedButton.icon(
                    onPressed: isLoading ? null : pickImage,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: darkGreen,
                      backgroundColor: Colors.white,
                      side: BorderSide(
                        color: warmBrown.withOpacity(0.4),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                    ),
                    icon: const Icon(
                      Icons.camera_alt_rounded,
                      size: 18,
                      color: warmBrown,
                    ),
                    label: const Text(
                      'Choisir une photo',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // Prénom et nom
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: firstNameController,
                    enabled: !isLoading,
                    style: const TextStyle(color: darkGreen),
                    decoration: _buildCreamInput(
                      'Prénom',
                      Icons.person_rounded,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: lastNameController,
                    enabled: !isLoading,
                    style: const TextStyle(color: darkGreen),
                    decoration: _buildCreamInput(
                      'Nom',
                      Icons.person_outline_rounded,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Username
            TextField(
              controller: usernameController,
              enabled: !isLoading,
              style: const TextStyle(color: darkGreen),
              decoration: _buildCreamInput(
                "Nom d'utilisateur",
                Icons.account_circle_rounded,
              ),
            ),

            const SizedBox(height: 14),

            // Email
            TextField(
              controller: emailController,
              enabled: !isLoading,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: darkGreen),
              decoration: _buildCreamInput(
                'Email',
                Icons.email_rounded,
              ),
            ),

            const SizedBox(height: 14),

            // Téléphone
            TextField(
              controller: phoneController,
              enabled: !isLoading,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: darkGreen),
              decoration: _buildCreamInput(
                'Téléphone',
                Icons.phone_rounded,
              ),
            ),

            const SizedBox(height: 14),

            // Date de naissance
            TextFormField(
              readOnly: true,
              enabled: !isLoading,
              style: const TextStyle(color: darkGreen),
              decoration: _buildCreamInput(
                birthDate == null
                    ? 'Date de naissance'
                    : '${birthDate!.day}/${birthDate!.month}/${birthDate!.year}',
                Icons.calendar_today_rounded,
                suffix: IconButton(
                  icon: const Icon(
                    Icons.date_range_rounded,
                    color: warmBrown,
                  ),
                  onPressed: isLoading ? null : selectBirthDate,
                ),
              ),
              onTap: isLoading ? null : selectBirthDate,
            ),

            const SizedBox(height: 14),

            // Mot de passe
            TextField(
              controller: passwordController,
              enabled: !isLoading,
              obscureText: true,
              style: const TextStyle(color: darkGreen),
              decoration: _buildCreamInput(
                'Mot de passe',
                Icons.lock_rounded,
              ),
            ),

            const SizedBox(height: 14),

            // Confirmation mot de passe
            TextField(
              controller: confirmPasswordController,
              enabled: !isLoading,
              obscureText: true,
              style: const TextStyle(color: darkGreen),
              decoration: _buildCreamInput(
                'Confirmer le mot de passe',
                Icons.lock_outline_rounded,
              ),
            ),

            const SizedBox(height: 22),

            const Text(
              'Choisir votre rôle',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: darkGreen,
              ),
            ),

            const SizedBox(height: 12),

            // Cartes Visiteur / Propriétaire
            Row(
              children: [
                _buildRoleCard(
                  title: 'Visiteur',
                  value: 'visiteur',
                  icon: Icons.luggage_rounded,
                ),
                const SizedBox(width: 12),
                _buildRoleCard(
                  title: 'Propriétaire',
                  value: 'proprietaire',
                  icon: Icons.home_work_rounded,
                ),
              ],
            ),

            const SizedBox(height: 26),

            // Bouton inscription
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: isLoading ? null : register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: darkGreen,
                  foregroundColor: offWhite,
                  elevation: 5,
                  shadowColor: darkGreen.withOpacity(0.35),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
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
                        'Créer un compte',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 10),

            // Retour connexion
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
                style: TextStyle(
                  color: warmBrown,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
