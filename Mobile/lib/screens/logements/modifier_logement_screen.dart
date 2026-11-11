import 'package:flutter/material.dart';
import '../../services/logement_service.dart';
import '../../models/logement.dart';

class ModifierLogementScreen extends StatefulWidget {
  final Logement logement;

  const ModifierLogementScreen({
    super.key,
    required this.logement,
  });

  @override
  State<ModifierLogementScreen> createState() =>
      _ModifierLogementScreenState();
}

class _ModifierLogementScreenState
    extends State<ModifierLogementScreen> {

  late TextEditingController titreController;
  late TextEditingController adresseController;
  late TextEditingController descriptionController;
  late TextEditingController prixController;

  @override
  void initState() {
    super.initState();

    titreController =
        TextEditingController(text: widget.logement.titre);

    adresseController =
        TextEditingController(text: widget.logement.adresse);

    descriptionController =
        TextEditingController(
      text: widget.logement.description,
    );

    prixController =
        TextEditingController(
      text: widget.logement.prix.toString(),
    );
  }

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
        title: const Text("Modifier logement"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
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

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () async {
  bool success =
      await LogementService.updateLogement(
    id: widget.logement.id,
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
          "Logement modifié ✅",
        ),
      ),
    );

    Navigator.pop(context,true);
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Erreur modification ❌",
        ),
      ),
    );
  }
},
              child: const Text(
                "Modifier",
              ),
            )
          ],
        ),
      ),
    );
  }
}