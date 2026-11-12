
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';
import 'register_screen.dart';
import 'logements/logement_list_screen.dart';
import 'logements/ajouter_logement_screen.dart';

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

  // FONCTION LOGIN
  Future<void> login() async {

    if (usernameController.text.trim().isEmpty ||
        passwordController.text.isEmpty) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez remplir tous les champs"),
          backgroundColor: Colors.red,
        ),
      );

      return;
    }

    setState(() {
      isLoading = true;
    });

    try {

      // Appel API Django
      final result = await ApiService.login(
        username: usernameController.text.trim(),
        password: passwordController.text,
      );

      print("===== LOGIN =====");
      print("Réponse API : $result");

      if (result != null) {

        // Récupérer le rôle
        final String role =
            result['role'].toString().toLowerCase();

        print("ROLE UTILISATEUR : $role");

        // Sauvegarder les informations
        final SharedPreferences prefs =
            await SharedPreferences.getInstance();

        await prefs.setString(
          "access",
          result["access"],
        );

        await prefs.setString(
          "refresh",
          result["refresh"],
        );

        await prefs.setString(
          "role",
          role,
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Connexion réussie ✅"),
            backgroundColor: Colors.green,
          ),
        );

        // REDIRECTION SELON LE ROLE

        if (role == "proprietaire") {

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  const AjouterLogementScreen(),
            ),
          );

        } else if (role == "visiteur") {

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  const LogementListScreen(),
            ),
          );

        } else {

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Rôle inconnu : $role"),
              backgroundColor: Colors.red,
            ),
          );
        }

      } else {

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Nom d'utilisateur ou mot de passe incorrect ❌",
            ),
            backgroundColor: Colors.red,
          ),
        );
      }

    } catch (e) {

      print("ERREUR LOGIN : $e");

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur : $e"),
          backgroundColor: Colors.red,
        ),
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

  // INTERFACE LOGIN
  @override
  Widget build(BuildContext context) {

    return Scaffold(

      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),

          child: Column(
            children: [

              const Text(
                "DariGo",
                style: TextStyle(
                  fontSize: 35,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),

              const SizedBox(height: 40),

              // USERNAME
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(
                  labelText: "Username",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),

              const SizedBox(height: 20),

              // PASSWORD
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Password",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
              ),

              const SizedBox(height: 25),

              // BUTTON LOGIN
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : login,

                  child: isLoading
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                        )
                      : const Text("Sign In"),
                ),
              ),

              const SizedBox(height: 10),

              // CREATE ACCOUNT
              TextButton(
                onPressed: () {

                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const RegisterScreen(),
                    ),
                  );

                },
                child: const Text(
                  "Create Account",
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
