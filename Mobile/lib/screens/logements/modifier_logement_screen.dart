
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
  static const violet = Color(0xFF6C4AB6);

  final _formKey = GlobalKey<FormState>();

  late TextEditingController titreController;
  late TextEditingController adresseController;
  late TextEditingController descriptionController;
  late TextEditingController prixController;

  bool isLoading = false;

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

  Future<void> modifierLogement() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
    });

    try {
      final success = await LogementService.updateLogement(
        id: widget.logement.id,
        titre: titreController.text.trim(),
        adresse: adresseController.text.trim(),
        description: descriptionController.text.trim(),
        prix: prixController.text.trim().replaceAll(',', '.'),
      );

      if (!mounted) return;

      if (success) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la modification'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  InputDecoration decoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: violet),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F6FA),
      appBar: AppBar(
        title: const Text('Modifier le logement'),
        backgroundColor: violet,
        foregroundColor: Colors.white,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: titreController,
                decoration: decoration(
                  'Titre',
                  Icons.home_outlined,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le titre est obligatoire';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: adresseController,
                decoration: decoration(
                  'Adresse',
                  Icons.location_on_outlined,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "L'adresse est obligatoire";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: prixController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: decoration(
                  'Prix en DT',
                  Icons.payments_outlined,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le prix est obligatoire';
                  }

                  final prix = double.tryParse(
                    value.trim().replaceAll(',', '.'),
                  );

                  if (prix == null || prix <= 0) {
                    return 'Veuillez saisir un prix valide';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: descriptionController,
                maxLines: 5,
                decoration: decoration(
                  'Description',
                  Icons.description_outlined,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'La description est obligatoire';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isLoading ? null : modifierLogement,
                  icon: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(
                    isLoading ? 'Enregistrement...' : 'Enregistrer',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: violet,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
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
