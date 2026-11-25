
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/logement_service.dart';
import '../../widgets/custom_popup.dart';
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

  final Color violet = const Color(0xFF6C4AB6);
  final Color violetClair = const Color(0xFFF3EEFC);

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
  List<XFile> photos = [];
  static const int maxPhotos = 10;

  // Étapes
  int currentStep = 0;
  bool isLoading = false;

  // IMPORTANT :
  // Les valeurs "value" doivent correspondre exactement
  // aux valeurs déclarées dans les choices de models.py.
  //
  // Si Django n'accepte pas "appartement", "maison" ou "villa",
  // remplace ces valeurs par les clés exactes de ton modèle.
  final List<Map<String, String>> typesLogement = [
    {'value': 'appartement', 'label': 'Appartement'},
    {'value': 'maison', 'label': 'Maison'},
    {'value': 'villa', 'label': 'Villa'},
    {'value': 'studio', 'label': 'Studio'},
    
  ];

  // Ces valeurs correspondent aux choices Django
  // montrés précédemment.
  final List<Map<String, String>> typesHebergement = [
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
    final resultat = await Navigator.push<PickedLocation>(
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
        await CustomPopup.showWarningPopup(
          context: context,
          title: 'Formulaire incomplet',
          message:
              'Veuillez corriger les champs indiqués avant de publier.',
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
      SnackBar(content: Text(message)),
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
        photos: photos,
      );

      if (!mounted) return;

      if (success) {
        await CustomPopup.showSuccessPopup(
          context: context,
          title: 'Logement ajouté !',
          message: 'Votre logement a été publié avec succès.',
        );

        if (!mounted) return;
        Navigator.pop(context, true);
      } else {
        await CustomPopup.showErrorPopup(
          context: context,
          title: 'Échec de publication',
          message:
              'Impossible d’ajouter le logement. Veuillez réessayer.',
        );
      }
    } catch (e) {
      if (!mounted) return;

      debugPrint('Erreur ajout logement : $e');

      await CustomPopup.showErrorPopup(
        context: context,
        title: 'Erreur inattendue',
        message:
            'Une erreur est survenue lors de l’ajout du logement.',
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
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.grey.shade300,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: violet,
            width: 2,
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
    required List<Map<String, String>> choix,
    required String? valeurSelectionnee,
    required ValueChanged<String> onSelection,
    required IconData icone,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titre,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
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
                color: selected ? violetClair : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected ? violet : Colors.grey.shade300,
                  width: selected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(icone, color: violet, size: 28),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (selected)
                    Icon(Icons.check_circle, color: violet),
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
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.symmetric(
        vertical: 12,
        horizontal: 15,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titre,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: diminuer,
            icon: const Icon(Icons.remove_circle_outline),
            color: violet,
          ),
          Text(
            '$valeur',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            onPressed: augmenter,
            icon: const Icon(Icons.add_circle_outline),
            color: violet,
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
        const Text(
          'Décrivez la capacité de votre logement',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
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
        const Text(
          'Où se trouve votre logement ?',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        const Text('Choisissez son emplacement sur la carte.'),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: violetClair,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Icon(Icons.location_on, size: 45, color: violet),
              const SizedBox(height: 10),
              Text(
                latitude == null
                    ? 'Aucune localisation sélectionnée'
                    : 'Localisation sélectionnée',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (latitude != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Latitude : $latitude\nLongitude : $longitude',
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 15),
              ElevatedButton.icon(
                onPressed: choisirLocalisation,
                icon: const Icon(Icons.map),
                label: const Text('Choisir sur la carte'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: violet,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
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
        const Text(
          'Ajoutez des photos de votre logement',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Ajoutez jusqu’à 10 photos.',
          style: TextStyle(color: Colors.grey.shade600),
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
            backgroundColor: violet,
            foregroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 20),
        if (photos.isEmpty)
          const Text('Aucune photo ajoutée.')
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
                    borderRadius: BorderRadius.circular(12),
                    child: FutureBuilder<Uint8List>(
                      future: photo.readAsBytes(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        return Image.memory(
                          snapshot.data!,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        );
                      },
                    ),
                  ),
                  if (index == 0)
                    Positioned(
                      left: 5,
                      top: 5,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: violet,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Principale',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    right: 5,
                    top: 5,
                    child: GestureDetector(
                      onTap: () => supprimerPhoto(index),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 18,
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
        const Text(
          'Présentez votre logement',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
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
      backgroundColor: const Color(0xFFFAF9FC),
      appBar: AppBar(
        title: const Text(
          'Ajouter un logement',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: violet,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Étape ${currentStep + 1} sur 6',
                    style: TextStyle(
                      color: violet,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: (currentStep + 1) / 6,
                      minHeight: 7,
                      backgroundColor: violetClair,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(violet),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    nomEtape,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
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
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  if (currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: isLoading ? null : precedent,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: violet,
                          side: BorderSide(color: violet),
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
                        backgroundColor: violet,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: 15,
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              currentStep == 5
                                  ? 'Publier le logement'
                                  : 'Suivant',
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
