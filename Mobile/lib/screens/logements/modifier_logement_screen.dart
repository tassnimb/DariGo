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

  final _formKey = GlobalKey<FormState>();

  late TextEditingController titreController;
  late TextEditingController adresseController;
  late TextEditingController descriptionController;
  late TextEditingController prixController;

  @override
  void initState() {
    super.initState();

    titreController = TextEditingController(
      text: widget.logement.titre,
    );

    adresseController = TextEditingController(
      text: widget.logement.adresse,
    );

    descriptionController = TextEditingController(
      text: widget.logement.description,
    );

    prixController = TextEditingController(
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
        child: Form(
          key: _formKey,
          child: Column(
            children: [

              TextFormField(
                controller: titreController,
                decoration: const InputDecoration(
                  labelText: "Titre",
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

              TextFormField(
                controller: adresseController,
                decoration: const InputDecoration(
                  labelText: "Adresse",
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

              TextFormField(
                controller: prixController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Prix",
                ),
                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return "Le prix est obligatoire";
                  }

                  if (double.tryParse(value) ==
                      null) {
                    return "Veuillez saisir un prix valide";
                  }

                  return null;
                },
              ),

              const SizedBox(height: 15),

              TextFormField(
                controller: descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: "Description",
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

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {

                    if (!_formKey.currentState!
                        .validate()) {
                      return;
                    }

                    bool success =
                        await LogementService
                            .updateLogement(
                      id: widget.logement.id,
                      titre: titreController.text,
                      adresse: adresseController.text,
                      description:
                          descriptionController.text,
                      prix: prixController.text,
                    );

                    if (!mounted) return;

                    if (success) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Logement modifié ✅",
                          ),
                        ),
                      );

                      Navigator.pop(context, true);

                    } else {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}