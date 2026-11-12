
import 'package:flutter/material.dart';
import '../../services/logement_service.dart';

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

  bool isLoading = false;

  static const Color violet = Color(0xFF6C4AB6);
  static const Color violetClair = Color(0xFFF3EEFC);

  @override
  void dispose() {
    titreController.dispose();
    adresseController.dispose();
    descriptionController.dispose();
    prixController.dispose();
    super.dispose();
  }

  // AJOUTER UN LOGEMENT
  Future<void> ajouterLogement() async {

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final success = await LogementService.addLogement(
        titre: titreController.text.trim(),
        adresse: adresseController.text.trim(),
        description: descriptionController.text.trim(),
        prix: prixController.text.trim().replaceAll(',', '.'),
      );

      if (!mounted) return;

      if (success) {
        // Retourner à la liste avec confirmation.
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Erreur lors de l'ajout du logement"),
            backgroundColor: Colors.red,
          ),
        );
      }

    } catch (e) {
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

  // STYLE DES CHAMPS
  InputDecoration decorationChamp({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(
        icon,
        color: violet,
      ),
      filled: true,
      fillColor: violetClair,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: violet,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 17,
      ),
    );
  }

  Widget titreSection(String texte) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        texte,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FC),

      appBar: AppBar(
        backgroundColor: violet,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Ajouter un logement",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: isLoading
              ? null
              : () => Navigator.pop(context),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),

          child: Form(
            key: _formKey,

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // EN-TETE
                Center(
                  child: Container(
                    width: 75,
                    height: 75,
                    decoration: BoxDecoration(
                      color: violetClair,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Icon(
                      Icons.add_home_work_outlined,
                      color: violet,
                      size: 40,
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                const Center(
                  child: Text(
                    "Publier votre logement",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                const Center(
                  child: Text(
                    "Remplissez les informations ci-dessous",
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // TITRE
                titreSection("Titre du logement"),
                const SizedBox(height: 9),

                TextFormField(
                  controller: titreController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: decorationChamp(
                    label: "Titre",
                    hint: "Ex : Appartement S+2",
                    icon: Icons.home_outlined,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Le titre est obligatoire";
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // ADRESSE
                titreSection("Adresse"),
                const SizedBox(height: 9),

                TextFormField(
                  controller: adresseController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: decorationChamp(
                    label: "Adresse",
                    hint: "Ex : Monastir, Tunisie",
                    icon: Icons.location_on_outlined,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "L'adresse est obligatoire";
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // PRIX
                titreSection("Prix du logement"),
                const SizedBox(height: 9),

                TextFormField(
                  controller: prixController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: decorationChamp(
                    label: "Prix en DT",
                    hint: "Ex : 45000",
                    icon: Icons.payments_outlined,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Le prix est obligatoire";
                    }

                    final prix = double.tryParse(
                      value.trim().replaceAll(',', '.'),
                    );

                    if (prix == null || !prix.isFinite) {
                      return "Veuillez saisir un prix valide";
                    }

                    if (prix <= 0) {
                      return "Le prix doit être supérieur à 0";
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // DESCRIPTION
                titreSection("Description"),
                const SizedBox(height: 9),

                TextFormField(
                  controller: descriptionController,
                  maxLines: 5,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: decorationChamp(
                    label: "Description",
                    hint: "Décrivez votre logement...",
                    icon: Icons.description_outlined,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "La description est obligatoire";
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 30),

                // BOUTON AJOUTER
                SizedBox(
                  width: double.infinity,
                  height: 55,

                  child: ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : ajouterLogement,

                    style: ElevatedButton.styleFrom(
                      backgroundColor: violet,
                      foregroundColor: Colors.white,
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),

                    child: isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_home),
                              SizedBox(width: 10),
                              Text(
                                "Ajouter le logement",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
