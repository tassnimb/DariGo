import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/logement.dart';
import '../../services/logement_service.dart';
import '../../widgets/custom_popup.dart';

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
  // ===========================================================================
  // THÈME DARIGO (CRÈME CHAUD, VERT SAPIN, VERT SAUGE & SABLE)
  // ===========================================================================
  static const Color _fondCreme = Color(0xFFF5F2EB);
  static const Color _surfaceClaire = Color(0xFFFAF8F3);
  static const Color _sableClair = Color(0xFFEAE3D5);
  static const Color _vertForet = Color(0xFF1F3D2B);
  static const Color _vertSauge = Color(0xFF6E8F79);
  static const Color _brunTerre = Color(0xFF6F5E4E);
  static const Color _textePrincipal = Color(0xFF1D2B22);
  static const Color _texteSecondaire = Color(0xFF677068);
  static const Color _rougeSuppression = Color(0xFFB5483C);

  static const int _maxPhotos = 10;

  // ===========================================================================
  // ÉTAT & CONTRÔLEURS
  // ===========================================================================
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  late final TextEditingController _titreController;
  late final TextEditingController _adresseController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _prixController;

  late List<PhotoLogement> _photosExistantes;
  final List<XFile> _nouvellesPhotos = [];
  final List<int> _photosASupprimer = [];
  final Map<String, Uint8List> _cacheOctetsNouvellesPhotos = {};

  bool _isLoading = false;
  bool _isPicking = false;

  int get _nombrePhotos =>
      _photosExistantes.length + _nouvellesPhotos.length;

  @override
  void initState() {
    super.initState();
    _titreController = TextEditingController(
      text: widget.logement.titre,
    );
    _adresseController = TextEditingController(
      text: widget.logement.adresse,
    );
    _descriptionController = TextEditingController(
      text: widget.logement.description,
    );
    _prixController = TextEditingController(
      text: widget.logement.prix.toString(),
    );
    _photosExistantes = List.from(widget.logement.photoDetails);
  }

  @override
  void dispose() {
    _titreController.dispose();
    _adresseController.dispose();
    _descriptionController.dispose();
    _prixController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // LOGIQUE MÉTIER (PHOTOS & ENREGISTREMENT)
  // ===========================================================================
  Future<void> _ajouterPhotos() async {
    if (_nombrePhotos >= _maxPhotos) {
      await CustomPopup.showWarningPopup(
        context: context,
        title: 'Limite de photos',
        message: 'Maximum $_maxPhotos photos autorisées.',
      );
      return;
    }

    setState(() => _isPicking = true);

    try {
      final selection = await _picker.pickMultiImage(
        imageQuality: 85,
      );

      if (!mounted || selection.isEmpty) return;

      final placesDisponibles = _maxPhotos - _nombrePhotos;
      final photosAcceptees =
          selection.take(placesDisponibles).toList();

      final bytesEntries = <String, Uint8List>{};
      for (final photo in photosAcceptees) {
        bytesEntries[photo.path] = await photo.readAsBytes();
      }

      if (!mounted) return;

      setState(() {
        _nouvellesPhotos.addAll(photosAcceptees);
        _cacheOctetsNouvellesPhotos.addAll(bytesEntries);
      });

      if (selection.length > placesDisponibles) {
        await CustomPopup.showWarningPopup(
          context: context,
          title: 'Limite de photos',
          message:
              'Maximum $_maxPhotos photos : certaines photos n’ont pas été ajoutées.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      await CustomPopup.showErrorPopup(
        context: context,
        title: 'Erreur de sélection',
        message: 'Impossible de sélectionner les photos.',
      );
      debugPrint('Erreur sélection photos : $e');
    } finally {
      if (mounted) {
        setState(() => _isPicking = false);
      }
    }
  }

  void _supprimerPhotoExistante(PhotoLogement photo) {
    setState(() {
      _photosExistantes.removeWhere((item) => item.id == photo.id);
      _photosASupprimer.add(photo.id);
    });
  }

  void _supprimerNouvellePhoto(int index) {
    final photo = _nouvellesPhotos[index];
    setState(() {
      _cacheOctetsNouvellesPhotos.remove(photo.path);
      _nouvellesPhotos.removeAt(index);
    });
  }

  Future<void> _modifierLogement() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final success = await LogementService.updateLogement(
        id: widget.logement.id,
        titre: _titreController.text.trim(),
        adresse: _adresseController.text.trim(),
        description: _descriptionController.text.trim(),
        prix: _prixController.text.trim().replaceAll(',', '.'),
        nouvellesPhotos: _nouvellesPhotos,
        photosASupprimer: _photosASupprimer,
      );

      if (!mounted) return;

      if (success) {
        await CustomPopup.showConfirmPopup(
          context: context,
          title: 'Modification réussie',
          message: 'Votre logement a été modifié avec succès !',
        );
        if (!mounted) return;
        Navigator.pop(context, true);
      } else {
        await CustomPopup.showErrorPopup(
          context: context,
          title: 'Modification impossible',
          message:
              'Une erreur est survenue lors de la modification du logement.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      await CustomPopup.showErrorPopup(
        context: context,
        title: 'Erreur',
        message:
            'Impossible de modifier le logement. Veuillez réessayer.',
      );
      debugPrint('Erreur modification logement : $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ===========================================================================
  // COMPOSANTS UI
  // ===========================================================================
  InputDecoration _decorationChamp(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: _texteSecondaire),
      floatingLabelStyle: const TextStyle(
        color: _vertForet,
        fontWeight: FontWeight.w600,
      ),
      prefixIcon: Icon(icon, color: _vertForet),
      filled: true,
      fillColor: _surfaceClaire,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _sableClair),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _vertForet, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _rougeSuppression),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: _rougeSuppression,
          width: 1.5,
        ),
      ),
    );
  }

  Widget _boutonActionPhoto({
    required VoidCallback? onPressed,
    required IconData icon,
    required Color backgroundColor,
    required String tooltip,
  }) {
    return SizedBox(
      width: 30,
      height: 30,
      child: IconButton(
        padding: EdgeInsets.zero,
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white, size: 16),
        style: IconButton.styleFrom(
          backgroundColor: backgroundColor,
          shape: const CircleBorder(),
        ),
      ),
    );
  }

  Widget _construireTuilePhotoExistante(PhotoLogement photo) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.network(
            photo.image,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const ColoredBox(
              color: _sableClair,
              child: Icon(
                Icons.broken_image_outlined,
                color: _brunTerre,
                size: 32,
              ),
            ),
          ),
        ),
        Positioned(
          top: 6,
          right: 6,
          child: _boutonActionPhoto(
            onPressed: _isLoading
                ? null
                : () => _supprimerPhotoExistante(photo),
            icon: Icons.delete_outline,
            backgroundColor: _rougeSuppression,
            tooltip: 'Supprimer la photo',
          ),
        ),
      ],
    );
  }

  Widget _construireTuileNouvellePhoto(int index) {
    final photo = _nouvellesPhotos[index];
    final bytes = _cacheOctetsNouvellesPhotos[photo.path];

    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: bytes != null
              ? Image.memory(bytes, fit: BoxFit.cover)
              : FutureBuilder<Uint8List>(
                  future: photo.readAsBytes(),
                  builder: (_, snapshot) {
                    if (snapshot.hasData) {
                      return Image.memory(
                        snapshot.data!,
                        fit: BoxFit.cover,
                      );
                    }
                    if (snapshot.hasError) {
                      return const ColoredBox(
                        color: _sableClair,
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: _brunTerre,
                        ),
                      );
                    }
                    return const ColoredBox(
                      color: _sableClair,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: _vertForet,
                          strokeWidth: 2,
                        ),
                      ),
                    );
                  },
                ),
        ),
        Positioned(
          top: 6,
          right: 6,
          child: _boutonActionPhoto(
            onPressed: _isLoading
                ? null
                : () => _supprimerNouvellePhoto(index),
            icon: Icons.close,
            backgroundColor: _rougeSuppression,
            tooltip: 'Retirer la photo',
          ),
        ),
        Positioned(
          bottom: 6,
          left: 6,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 7,
              vertical: 3,
            ),
            decoration: BoxDecoration(
              color: _vertSauge,
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'Nouveau',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _construireGalerie() {
    final peutAjouter =
        !_isLoading && !_isPicking && _nombrePhotos < _maxPhotos;

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
                fontWeight: FontWeight.w700,
                color: _textePrincipal,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: _sableClair,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$_nombrePhotos / $_maxPhotos',
                style: const TextStyle(
                  color: _vertForet,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_nombrePhotos == 0)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _surfaceClaire,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _sableClair),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.image_outlined,
                  size: 42,
                  color: _brunTerre,
                ),
                SizedBox(height: 8),
                Text(
                  'Aucune photo ajoutée',
                  style: TextStyle(
                    color: _texteSecondaire,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _nombrePhotos,
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1,
            ),
            itemBuilder: (_, index) {
              if (index < _photosExistantes.length) {
                return _construireTuilePhotoExistante(
                  _photosExistantes[index],
                );
              }
              return _construireTuileNouvellePhoto(
                index - _photosExistantes.length,
              );
            },
          ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: peutAjouter ? _ajouterPhotos : null,
            icon: _isPicking
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _vertForet,
                    ),
                  )
                : const Icon(Icons.add_photo_alternate_outlined),
            label: Text(
              _isPicking ? 'Chargement...' : 'Ajouter des photos',
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: _vertForet,
              backgroundColor: _surfaceClaire,
              disabledForegroundColor: _texteSecondaire,
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: _vertForet),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _construireFormulaire() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _titreController,
            style: const TextStyle(color: _textePrincipal),
            decoration: _decorationChamp(
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
            controller: _adresseController,
            style: const TextStyle(color: _textePrincipal),
            decoration: _decorationChamp(
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
            controller: _prixController,
            style: const TextStyle(color: _textePrincipal),
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
            decoration: _decorationChamp(
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
            controller: _descriptionController,
            style: const TextStyle(color: _textePrincipal),
            maxLines: 5,
            decoration: _decorationChamp(
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
          const SizedBox(height: 24),
          _construireGalerie(),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _modifierLogement,
              icon: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_circle_outline),
              label: Text(
                _isLoading ? 'Enregistrement...' : 'Enregistrer',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _vertForet,
                foregroundColor: Colors.white,
                disabledBackgroundColor: _vertSauge,
                disabledForegroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _fondCreme,
      appBar: AppBar(
        title: const Text(
          'Modifier le logement',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: _fondCreme,
        foregroundColor: _vertForet,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: _construireFormulaire(),
        ),
      ),
    );
  }
}