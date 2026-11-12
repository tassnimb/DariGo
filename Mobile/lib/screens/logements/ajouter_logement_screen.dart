
import 'package:flutter/material.dart';
import '../../services/logement_service.dart';
import '../login_screen.dart';

class AjouterLogementScreen extends StatefulWidget {
  const AjouterLogementScreen({super.key});

  @override
  State<AjouterLogementScreen> createState() =>
      _AjouterLogementScreenState();
}

class _AjouterLogementScreenState
    extends State<AjouterLogementScreen> {

  final _formKey = GlobalKey<FormState>();

  final titreController = TextEditingController();
  final adresseController = TextEditingController();
  final descriptionController = TextEditingController();
  final prixController = TextEditingController();

  @override
  void dispose() {
    titreController.dispose();
    adresseController.dispose();
    descriptionController.dispose();
    prixController.dispose();
    super.dispose();
  }

  // RETOUR VERS LOGIN
  void retournerLogin() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: retournerLogin,
        ),
        title: const Text("Ajouter un logement"),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: SingleChildScrollView(
          child: Form(
            key: _formKey,

            child: Column(
              children: [

                // TITRE
                TextFormField(
                  controller: titreController,
                  decoration: const InputDecoration(
                    labelText: "Titre",
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return "Le titre est obligatoire";
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 15),

                // ADRESSE
                TextFormField(
                  controller: adresseController,
                  decoration: const InputDecoration(
                    labelText: "Adresse",
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return "L'adresse est obligatoire";
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 15),

                // PRIX
                TextFormField(
                  controller: prixController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Prix",
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return "Le prix est obligatoire";
                    }

                    final prix = double.tryParse(value);

                    if (prix == null) {
                      return "Veuillez saisir un prix valide";
                    }

                    if (prix <= 0) {
                      return "Le prix doit être supérieur à 0";
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 15),

                // DESCRIPTION
                TextFormField(
                  controller: descriptionController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: "Description",
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return "La description est obligatoire";
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 25),

                // BOUTON AJOUTER
                SizedBox(
                  width: double.infinity,

                  child: ElevatedButton(
                    onPressed: () async {

                      if (!_formKey.currentState!.validate()) {
                        return;
                      }

                      bool success =
                          await LogementService.addLogement(
                        titre: titreController.text.trim(),
                        adresse: adresseController.text.trim(),
                        description:
                            descriptionController.text.trim(),
                        prix: prixController.text.trim(),
                      );

                      if (!mounted) return;

                      if (success) {

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Logement ajouté ✅"),
                          ),
                        );

                        titreController.clear();
                        adresseController.clear();
                        descriptionController.clear();
                        prixController.clear();

                        Navigator.pop(context);

                      } else {

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "Erreur lors de l'ajout ❌",
                            ),
                          ),
                        );
                      }
                    },

                    child: const Text("Ajouter"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
