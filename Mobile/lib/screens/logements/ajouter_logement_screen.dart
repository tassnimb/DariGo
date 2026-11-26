import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/logement_service.dart';
import 'map_picker_screen.dart';

class AjouterLogementScreen extends StatefulWidget {
  const AjouterLogementScreen({super.key});

  @override
  State<AjouterLogementScreen> createState() =>
      _AjouterLogementScreenState();
}

class _AjouterLogementScreenState
    extends State<AjouterLogementScreen> {
  final _formKey = GlobalKey<FormState>();

  // Palette DariGo
  final Color vertForet = const Color(0xFF1E3A2F);
  final Color vertSauge = const Color(0xFF3E6150);
  final Color sableClair = const Color(0xFFE7DFD3);
  final Color fondCreme = const Color(0xFFF5F1EB);
  final Color carteIvoire = const Color(0xFFFAF7F2);
  final Color brunTerre = const Color(0xFF4A3B32);

  // Contrôleurs
  final titreController = TextEditingController();
  final adresseController = TextEditingController();
  final descriptionController = TextEditingController();
  final prixController = TextEditingController();
  final villeController = TextEditingController();
  final gouvernoratController = TextEditingController();
  final paysController = TextEditingController(text: 'Tunisie');
  final codePostalController = TextEditingController();

  // Types envoyés à Django
  String? typeLogement;
  String? typeHebergement;

  // Capacité
  int nombreVoyageurs = 1;
  int chambres = 1;
  int lits = 1;
  int sallesBain = 1;

  // Localisation
  double? latitude;
  double? longitude;

  // Photos
  final ImagePicker imagePicker = ImagePicker();
  List photos = [];
  static const int maxPhotos = 10;

  // Étapes
  int currentStep = 0;
  bool isLoading = false;

  final typesLogement = [
    {'value': 'appartement', 'label': 'Appartement'},
    {'value': 'maison', 'label': 'Maison'},
    {'value': 'villa', 'label': 'Villa'},
    {'value': 'studio', 'label': 'Studio'},
  ];

  final typesHebergement = [
    {'value': 'entier', 'label': 'Logement entier'},
    {'value': 'privee', 'label': 'Chambre privée'},
    {'value': 'partagee', 'label': 'Chambre partagée'},
  ];

  @override
  void dispose() {
    titreController.dispose();
    adresseController.dispose();
    descriptionController.dispose();
    prixController.dispose();
    villeController.dispose();
    gouvernoratController.dispose();
    paysController.dispose();
    codePostalController.dispose();
    super.dispose();
  }

  // ============================
  // POPUP STYLE DARIGO
  // ============================

  Future<void> _afficherPopupDariGo({
    required String title,
    required String message,
    required IconData icon,
    required Color accentColor,
    String boutonTexte = 'OK',
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: carteIvoire,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: sableClair, width: 1.2),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 28,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: accentColor,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: accentColor,
                    size: 34,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: vertForet,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14.5,
                    color: brunTerre,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: 130,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: carteIvoire,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: Text(
                      boutonTexte,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================
  // PHOTOS
  // ============================

  Future<void> choisirPhotos() async {
    try {
      final images = await imagePicker.pickMultiImage(
        imageQuality: 80,
      );

      if (!mounted || images.isEmpty) return;

      final placesDisponibles = maxPhotos - photos.length;

      if (placesDisponibles <= 0) {
        afficherMessage(
          'Vous avez atteint la limite de 10 photos.',
        );
        return;
      }

      setState(() {
        photos.addAll(images.take(placesDisponibles));
      });

      if (images.length > placesDisponibles) {
        afficherMessage('Maximum 10 photos autorisées.');
      }
    } catch (e) {
      if (!mounted) return;
      afficherMessage('Erreur lors de la sélection : $e');
    }
  }

  void supprimerPhoto(int index) {
    setState(() {
      photos.removeAt(index);
    });
  }

  // ============================
  // LOCALISATION
  // ============================

  Future<void> choisirLocalisation() async {
    final resultat = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MapPickerScreen(),
      ),
    );

    if (resultat == null || !mounted) return;

    setState(() {
      latitude = resultat.latitude;
      longitude = resultat.longitude;

      adresseController.text = resultat.adresse;
      villeController.text = resultat.ville;
      gouvernoratController.text = resultat.gouvernorat;
      paysController.text = resultat.pays;
      codePostalController.text = resultat.codePostal;
    });
  }

  // ============================
  // ÉTAPES
  // ============================

  String get nomEtape {
    switch (currentStep) {
      case 0:
        return 'Type de logement';
      case 1:
        return 'Type d’hébergement';
      case 2:
        return 'Capacité';
      case 3:
        return 'Localisation';
      case 4:
        return 'Photos';
      default:
        return 'Description et prix';
    }
  }

  Future<void> suivant() async {
    if (currentStep == 0 && typeLogement == null) {
      afficherMessage('Veuillez choisir un type de logement.');
      return;
    }

    if (currentStep == 1 && typeHebergement == null) {
      afficherMessage(
        'Veuillez choisir un type d’hébergement.',
      );
      return;
    }

    if (currentStep == 3 &&
        (latitude == null || longitude == null)) {
      afficherMessage(
        'Veuillez sélectionner la localisation sur la carte.',
      );
      return;
    }

    if (currentStep == 5) {
      if (!_formKey.currentState!.validate()) {
        await _afficherPopupDariGo(
          title: 'Formulaire incomplet',
          message:
              'Veuillez corriger les champs indiqués avant de publier.',
          icon: Icons.warning_amber_rounded,
          accentColor: brunTerre,
          boutonTexte: 'Compris',
        );
        return;
      }

      await publierLogement();
      return;
    }

    setState(() {
      currentStep++;
    });
  }

  void precedent() {
    if (currentStep > 0) {
      setState(() {
        currentStep--;
      });
    }
  }

  void afficherMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: vertForet,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ============================
  // PUBLICATION
  // ============================

  Future<void> publierLogement() async {
    if (!_formKey.currentState!.validate()) return;

    debugPrint('TYPE LOGEMENT = $typeLogement');
    debugPrint('TYPE HEBERGEMENT = $typeHebergement');

    setState(() {
      isLoading = true;
    });

    try {
      final success = await LogementService.addLogement(
        titre: titreController.text.trim(),
        adresse: adresseController.text.trim(),
        description: descriptionController.text.trim(),
        prix: prixController.text.trim().replaceAll(',', '.'),
        typeLogement: typeLogement!,
        typeHebergement: typeHebergement!,
        pays: paysController.text.trim(),
        ville: villeController.text.trim(),
        gouvernorat: gouvernoratController.text.trim(),
        codePostal: codePostalController.text.trim(),
        nombreVoyageurs: nombreVoyageurs,
        chambres: chambres,
        lits: lits,
        sallesBain: sallesBain,
        latitude: latitude!,
        longitude: longitude!,
        photos: List.castFrom(photos),
      );

      if (!mounted) return;

      if (success) {
        await _afficherPopupDariGo(
          title: 'Logement ajouté !',
          message: 'Votre logement a été publié avec succès.',
          icon: Icons.check_rounded,
          accentColor: vertForet,
        );

        if (!mounted) return;
        Navigator.pop(context, true);
      } else {
        await _afficherPopupDariGo(
          title: 'Échec de publication',
          message:
              'Impossible d’ajouter le logement. Veuillez réessayer.',
          icon: Icons.error_outline_rounded,
          accentColor: brunTerre,
        );
      }
    } catch (e) {
      if (!mounted) return;

      debugPrint('Erreur ajout logement : $e');

      await _afficherPopupDariGo(
        title: 'Erreur inattendue',
        message:
            'Une erreur est survenue lors de l’ajout du logement.',
        icon: Icons.error_outline_rounded,
        accentColor: brunTerre,
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // ============================
  // CHAMP TEXTE
  // ============================

  Widget construireChamp({
    required String label,
    required TextEditingController controller,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(
        color: vertForet,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: brunTerre),
        filled: true,
        fillColor: carteIvoire,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: sableClair),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: sableClair),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: vertForet,
            width: 1.8,
          ),
        ),
      ),
    );
  }

  // ============================
  // CARTE DE SÉLECTION
  // ============================

  Widget construireCartesSelection({
    required String titre,
    required List choix,
    required String? valeurSelectionnee,
    required ValueChanged<String> onSelection,
    required IconData icone,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titre,
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.bold,
            color: vertForet,
          ),
        ),
        const SizedBox(height: 20),
        ...choix.map((item) {
          final value = item['value']!;
          final label = item['label']!;
          final selected = valeurSelectionnee == value;

          return GestureDetector(
            onTap: () {
              setState(() {
                onSelection(value);
              });
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: selected ? vertForet : carteIvoire,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: selected ? vertForet : sableClair,
                  width: selected ? 1.8 : 1.2,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: selected
                          ? Colors.white.withValues(alpha: 0.14)
                          : sableClair.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icone,
                      color: selected ? carteIvoire : vertForet,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: selected ? carteIvoire : vertForet,
                      ),
                    ),
                  ),
                  if (selected)
                    Icon(
                      Icons.check_circle,
                      color: carteIvoire,
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // ============================
  // ÉTAPE 1 : TYPE LOGEMENT
  // ============================

  Widget construireEtapeTypeLogement() {
    return construireCartesSelection(
      titre: 'Quel type de logement proposez-vous ?',
      choix: typesLogement,
      valeurSelectionnee: typeLogement,
      onSelection: (value) {
        typeLogement = value;
      },
      icone: Icons.home_outlined,
    );
  }

  // ============================
  // ÉTAPE 2 : HÉBERGEMENT
  // ============================

  Widget construireEtapeHebergement() {
    return construireCartesSelection(
      titre: 'Quel type d’hébergement proposez-vous ?',
      choix: typesHebergement,
      valeurSelectionnee: typeHebergement,
      onSelection: (value) {
        typeHebergement = value;
      },
      icone: Icons.bed_outlined,
    );
  }

  // ============================
  // COMPTEURS
  // ============================

  Widget construireCompteur({
    required String titre,
    required String description,
    required int valeur,
    required VoidCallback diminuer,
    required VoidCallback augmenter,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(
        vertical: 14,
        horizontal: 16,
      ),
      decoration: BoxDecoration(
        color: carteIvoire,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: sableClair, width: 1.2),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titre,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: vertForet,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    color: brunTerre,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: diminuer,
            icon: const Icon(Icons.remove_circle_outline),
            color: vertForet,
          ),
          SizedBox(
            width: 28,
            child: Text(
              '$valeur',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: vertForet,
              ),
            ),
          ),
          IconButton(
            onPressed: augmenter,
            icon: const Icon(Icons.add_circle_outline),
            color: vertForet,
          ),
        ],
      ),
    );
  }

  // ============================
  // ÉTAPE 3 : CAPACITÉ
  // ============================

  Widget construireEtapeCapacite() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Décrivez la capacité de votre logement',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.bold,
            color: vertForet,
          ),
        ),
        const SizedBox(height: 20),
        construireCompteur(
          titre: 'Voyageurs',
          description: 'Nombre maximum de personnes',
          valeur: nombreVoyageurs,
          diminuer: () {
            if (nombreVoyageurs > 1) {
              setState(() => nombreVoyageurs--);
            }
          },
          augmenter: () {
            setState(() => nombreVoyageurs++);
          },
        ),
        construireCompteur(
          titre: 'Chambres',
          description: 'Nombre de chambres',
          valeur: chambres,
          diminuer: () {
            if (chambres > 1) {
              setState(() => chambres--);
            }
          },
          augmenter: () {
            setState(() => chambres++);
          },
        ),
        construireCompteur(
          titre: 'Lits',
          description: 'Nombre de lits',
          valeur: lits,
          diminuer: () {
            if (lits > 1) {
              setState(() => lits--);
            }
          },
          augmenter: () {
            setState(() => lits++);
          },
        ),
        construireCompteur(
          titre: 'Salles de bain',
          description: 'Nombre de salles de bain',
          valeur: sallesBain,
          diminuer: () {
            if (sallesBain > 1) {
              setState(() => sallesBain--);
            }
          },
          augmenter: () {
            setState(() => sallesBain++);
          },
        ),
      ],
    );
  }

  // ============================
  // ÉTAPE 4 : LOCALISATION
  // ============================

  Widget construireEtapeLocalisation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Où se trouve votre logement ?',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.bold,
            color: vertForet,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Choisissez son emplacement sur la carte.',
          style: TextStyle(color: brunTerre),
        ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: carteIvoire,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: sableClair, width: 1.2),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: sableClair.withValues(alpha: 0.7),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.location_on,
                  size: 36,
                  color: vertForet,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                latitude == null
                    ? 'Aucune localisation sélectionnée'
                    : 'Localisation sélectionnée',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: vertForet,
                ),
              ),
              if (latitude != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Latitude : $latitude\nLongitude : $longitude',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: brunTerre),
                ),
              ],
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: choisirLocalisation,
                icon: const Icon(Icons.map),
                label: const Text('Choisir sur la carte'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: vertForet,
                  foregroundColor: carteIvoire,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        construireChamp(
          label: 'Adresse',
          controller: adresseController,
        ),
        const SizedBox(height: 12),
        construireChamp(
          label: 'Ville',
          controller: villeController,
        ),
        const SizedBox(height: 12),
        construireChamp(
          label: 'Gouvernorat',
          controller: gouvernoratController,
        ),
        const SizedBox(height: 12),
        construireChamp(
          label: 'Pays',
          controller: paysController,
        ),
        const SizedBox(height: 12),
        construireChamp(
          label: 'Code postal',
          controller: codePostalController,
        ),
      ],
    );
  }

  // ============================
  // ÉTAPE 5 : PHOTOS
  // ============================

  Widget construireEtapePhotos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ajoutez des photos de votre logement',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.bold,
            color: vertForet,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Ajoutez jusqu’à 10 photos.',
          style: TextStyle(color: brunTerre),
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: photos.length < maxPhotos
              ? choisirPhotos
              : null,
          icon: const Icon(Icons.add_photo_alternate_outlined),
          label: Text(
            'Ajouter des photos (${photos.length}/$maxPhotos)',
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: vertForet,
            foregroundColor: carteIvoire,
            disabledBackgroundColor: sableClair,
            disabledForegroundColor: brunTerre,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 14,
            ),
          ),
        ),
        const SizedBox(height: 20),
        if (photos.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: carteIvoire,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: sableClair),
            ),
            child: Text(
              'Aucune photo ajoutée.',
              style: TextStyle(color: brunTerre),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: photos.length,
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemBuilder: (context, index) {
              final photo = photos[index];

              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: FutureBuilder(
                      future: photo.readAsBytes(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return Center(
                            child: CircularProgressIndicator(
                              color: vertForet,
                            ),
                          );
                        }

                        return Image.memory(
                          snapshot.data! as Uint8List,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        );
                      },
                    ),
                  ),
                  if (index == 0)
                    Positioned(
                      left: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: vertForet,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Principale',
                          style: TextStyle(
                            color: carteIvoire,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: GestureDetector(
                      onTap: () => supprimerPhoto(index),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: brunTerre,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close,
                          color: carteIvoire,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
      ],
    );
  }

  // ============================
  // ÉTAPE 6 : DESCRIPTION
  // ============================

  Widget construireEtapeDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Présentez votre logement',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.bold,
            color: vertForet,
          ),
        ),
        const SizedBox(height: 20),
        construireChamp(
          label: 'Titre du logement',
          controller: titreController,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Veuillez saisir un titre.';
            }
            return null;
          },
        ),
        const SizedBox(height: 18),
        construireChamp(
          label: 'Description',
          controller: descriptionController,
          maxLines: 5,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Veuillez saisir une description.';
            }
            if (value.trim().length < 10) {
              return 'Minimum 10 caractères.';
            }
            return null;
          },
        ),
        const SizedBox(height: 18),
        construireChamp(
          label: 'Prix par nuit (DT)',
          controller: prixController,
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Veuillez saisir le prix.';
            }

            final prix = double.tryParse(
              value.trim().replaceAll(',', '.'),
            );

            if (prix == null || prix <= 0) {
              return 'Veuillez saisir un prix valide.';
            }

            return null;
          },
        ),
      ],
    );
  }

  // ============================
  // ÉTAPE COURANTE
  // ============================

  Widget construireEtape() {
    switch (currentStep) {
      case 0:
        return construireEtapeTypeLogement();
      case 1:
        return construireEtapeHebergement();
      case 2:
        return construireEtapeCapacite();
      case 3:
        return construireEtapeLocalisation();
      case 4:
        return construireEtapePhotos();
      default:
        return construireEtapeDescription();
    }
  }

  // ============================
  // INTERFACE
  // ============================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fondCreme,
      appBar: AppBar(
        title: Text(
          'Ajouter un logement',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: vertForet,
          ),
        ),
        backgroundColor: fondCreme,
        foregroundColor: vertForet,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Étape ${currentStep + 1} sur 6',
                    style: TextStyle(
                      color: vertSauge,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: (currentStep + 1) / 6,
                      minHeight: 7,
                      backgroundColor: sableClair,
                      valueColor:
                          AlwaysStoppedAnimation(vertForet),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    nomEtape,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: vertForet,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: construireEtape(),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: carteIvoire,
                border: Border(
                  top: BorderSide(color: sableClair),
                ),
              ),
              child: Row(
                children: [
                  if (currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: isLoading ? null : precedent,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: vertForet,
                          side: BorderSide(color: vertForet),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 15,
                          ),
                        ),
                        child: const Text('Précédent'),
                      ),
                    ),
                  if (currentStep > 0)
                    const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isLoading ? null : suivant,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: vertForet,
                        foregroundColor: carteIvoire,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 15,
                        ),
                      ),
                      child: isLoading
                          ? SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: carteIvoire,
                              ),
                            )
                          : Text(
                              currentStep == 5 ? 'Publier' : 'Suivant',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
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