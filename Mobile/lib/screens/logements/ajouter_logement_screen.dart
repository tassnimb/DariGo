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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ajouter un logement"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [

              TextField(
                controller: titreController,
                decoration: const InputDecoration(
                  labelText: "Titre",
                ),
              ),

              const SizedBox(height: 15),

              TextField(
                controller: adresseController,
                decoration: const InputDecoration(
                  labelText: "Adresse",
                ),
              ),

              const SizedBox(height: 15),

              TextField(
                controller: prixController,
                keyboardType:
                    TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Prix",
                ),
              ),

              const SizedBox(height: 15),

              TextField(
                controller: descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: "Description",
                ),
              ),

              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {

  bool success =
      await LogementService.addLogement(
    titre: titreController.text,
    adresse: adresseController.text,
    description: descriptionController.text,
    prix: prixController.text,
  );

  if (!mounted) return;

  if (success) {

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Logement ajouté ✅",
        ),
      ),
    );

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
                  child: const Text(
                    "Ajouter",
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}