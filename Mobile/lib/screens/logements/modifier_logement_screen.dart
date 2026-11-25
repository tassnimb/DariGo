
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
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
  final ImagePicker _picker = ImagePicker();

  late TextEditingController titreController;
  late TextEditingController adresseController;
  late TextEditingController descriptionController;
  late TextEditingController prixController;

  late List<PhotoLogement> photosExistantes;

  final List<XFile> nouvellesPhotos = [];
  final List<int> photosASupprimer = [];

  bool isLoading = false;
  bool isPicking = false;

  int get nombrePhotos =>
      photosExistantes.length + nouvellesPhotos.length;

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

    photosExistantes = List.from(
      widget.logement.photoDetails,
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

  // SÉLECTIONNER DE NOUVELLES PHOTOS
  Future<void> ajouterPhotos() async {
    if (nombrePhotos >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum 10 photos autorisées.'),
        ),
      );
      return;
    }

    try {
      setState(() {
        isPicking = true;
      });

      final selection = await _picker.pickMultiImage(
        imageQuality: 85,
      );

      if (!mounted) return;

      final placesDisponibles = 10 - nombrePhotos;
      final photosAcceptees = selection.take(placesDisponibles);

      setState(() {
        nouvellesPhotos.addAll(photosAcceptees);
      });

      if (selection.length > placesDisponibles) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Maximum 10 photos : certaines photos n’ont pas été ajoutées.',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la sélection : $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isPicking = false;
        });
      }
    }
  }

  // MARQUER UNE ANCIENNE PHOTO POUR SUPPRESSION
  void supprimerPhotoExistante(PhotoLogement photo) {
    setState(() {
      photosExistantes.removeWhere(
        (element) => element.id == photo.id,
      );

      photosASupprimer.add(photo.id);
    });
  }

  // SUPPRIMER UNE NOUVELLE PHOTO AVANT ENREGISTREMENT
  void supprimerNouvellePhoto(int index) {
    setState(() {
      nouvellesPhotos.removeAt(index);
    });
  }

  // ENREGISTRER LES MODIFICATIONS
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
        nouvellesPhotos: nouvellesPhotos,
        photosASupprimer: photosASupprimer,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logement modifié avec succès.'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context, true);
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur : $e'),
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

  // GALERIE DES PHOTOS
  Widget construireGalerie() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Photos du logement',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '$nombrePhotos / 10',
              style: const TextStyle(
                color: violet,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        if (nombrePhotos == 0)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.image_outlined,
                  size: 45,
                  color: Colors.grey,
                ),
                SizedBox(height: 8),
                Text('Aucune photo ajoutée'),
              ],
            ),
          ),

        if (nombrePhotos > 0)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: nombrePhotos,
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1,
            ),
            itemBuilder: (context, index) {
              // Anciennes photos
              if (index < photosExistantes.length) {
                final photo = photosExistantes[index];

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        photo.image,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const ColoredBox(
                            color: Colors.white,
                            child: Icon(
                              Icons.broken_image_outlined,
                              color: Colors.grey,
                              size: 35,
                            ),
                          );
                        },
                      ),
                    ),
                    Positioned(
                      top: 5,
                      right: 5,
                      child: IconButton(
                        onPressed: isLoading
                            ? null
                            : () => supprimerPhotoExistante(photo),
                        icon: const Icon(
                          Icons.delete,
                          color: Colors.white,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                      ),
                    ),
                  ],
                );
              }

              // Nouvelles photos
              final nouvelleIndex =
                  index - photosExistantes.length;

              final photo = nouvellesPhotos[nouvelleIndex];

              return Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: FutureBuilder<List<int>>(
                      future: photo.readAsBytes(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          return Image.memory(
  Uint8List.fromList(snapshot.data!),
  height: 100,
  width: 100,
  fit: BoxFit.cover,
);
                        }

                        if (snapshot.hasError) {
                          return const ColoredBox(
                            color: Colors.white,
                            child: Icon(
                              Icons.broken_image_outlined,
                              color: Colors.grey,
                            ),
                          );
                        }

                        return const ColoredBox(
                          color: Colors.white,
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      },
                    ),
                  ),
                  Positioned(
                    top: 5,
                    right: 5,
                    child: IconButton(
                      onPressed: isLoading
                          ? null
                          : () => supprimerNouvellePhoto(
                                nouvelleIndex,
                              ),
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                    ),
                  ),
                  const Positioned(
                    bottom: 5,
                    left: 5,
                    child: Icon(
                      Icons.add_circle,
                      color: Colors.white,
                    ),
                  ),
                ],
              );
            },
          ),

        const SizedBox(height: 12),

        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: isLoading ||
                    isPicking ||
                    nombrePhotos >= 10
                ? null
                : ajouterPhotos,
            icon: isPicking
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(
                    Icons.add_photo_alternate_outlined,
                  ),
            label: Text(
              isPicking
                  ? 'Chargement...'
                  : 'Ajouter des photos',
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: violet,
              padding: const EdgeInsets.all(14),
              side: const BorderSide(color: violet),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
            ),
          ),
        ),
      ],
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

              const SizedBox(height: 25),

              construireGalerie(),

              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isLoading
                      ? null
                      : modifierLogement,
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
                    isLoading
                        ? 'Enregistrement...'
                        : 'Enregistrer',
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
