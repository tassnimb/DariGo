import 'package:flutter/material.dart';

import '../../models/logement.dart';
import '../../services/avis_service.dart';
import '../../services/logement_service.dart';
import '../../services/messagerie_service.dart';
import '../../widgets/custom_popup.dart';
import '../messagerie/chat_screen.dart';
import 'modifier_logement_screen.dart';
import 'reservation_screen.dart';

class LogementDetailScreen extends StatefulWidget {
  final Logement logement;
  final bool isProprietaire;

  const LogementDetailScreen({
    super.key,
    required this.logement,
    required this.isProprietaire,
  });

  @override
  State<LogementDetailScreen> createState() =>
      _LogementDetailScreenState();
}

class _LogementDetailScreenState extends State<LogementDetailScreen> {
  // ===========================================================================
  // THÈME DARIGO
  // ===========================================================================
  static const Color _fondCreme = Color(0xFFF5F2EB);
  static const Color _surfaceClaire = Color(0xFFFAF8F3);
  static const Color _sableClair = Color(0xFFEAE3D5);
  static const Color _vertSapin = Color(0xFF1F3D2B);
  static const Color _vertSauge = Color(0xFF6E8F79);
  static const Color _brunTerre = Color(0xFF6F5E4E);
  static const Color _textePrincipal = Color(0xFF1D2B22);
  static const Color _texteSecondaire = Color(0xFF677068);
  static const Color _rougeErreur = Color(0xFFB5483C);
  static const Color _orEtoile = Color(0xFFD49B27);

  // ===========================================================================
  // ÉTAT
  // ===========================================================================
  bool _isDeleting = false;
  bool _isContacting = false;

  late Future<List> _avisFuture;

  @override
  void initState() {
    super.initState();
    _avisFuture = AvisService.getAvis(widget.logement.id);
  }

  // ===========================================================================
  // ACTIONS MÉTIER
  // ===========================================================================
  Future<void> _modifierLogement() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ModifierLogementScreen(
          logement: widget.logement,
        ),
      ),
    );

    if (!mounted) return;

    if (result == true) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _reserverLogement() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReservationScreen(
          logement: widget.logement,
        ),
      ),
    );
  }

  Future<void> _contacterProprietaire() async {
    if (_isContacting) return;

    setState(() => _isContacting = true);

    try {
      final conversation =
          await MessagerieService.creerConversation(
        widget.logement.id,
      );

      if (!mounted) return;

      final conversationId = conversation['id'];
      final proprietaire = conversation['proprietaire'];

      if (conversationId == null) {
        throw Exception(
          'Identifiant de conversation introuvable.',
        );
      }

      final username = proprietaire is Map
          ? proprietaire['username'] ?? 'Propriétaire'
          : 'Propriétaire';

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            conversationId: int.parse(conversationId.toString()),
            username: username.toString(),
            logementTitre: widget.logement.titre,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      await CustomPopup.showErrorPopup(
        context: context,
        title: 'Impossible de contacter',
        message:
            'Une erreur est survenue lors de l’ouverture de la conversation. Veuillez réessayer.',
      );
      debugPrint('Erreur contact propriétaire : $e');
    } finally {
      if (mounted) {
        setState(() => _isContacting = false);
      }
    }
  }

  Future<void> _supprimerLogement() async {
    final confirmer = await CustomPopup.showConfirmPopup(
      context: context,
      title: 'Supprimer le logement',
      message: 'Voulez-vous vraiment supprimer ce logement ?',
      confirmText: 'Supprimer',
      cancelText: 'Annuler',
    );

    if (!confirmer || !mounted) return;

    setState(() => _isDeleting = true);

    try {
      final success = await LogementService.deleteLogement(
        widget.logement.id,
      );

      if (!mounted) return;

      if (success) {
        await CustomPopup.showSuccessPopup(
          context: context,
          title: 'Logement supprimé',
          message: 'Votre logement a été supprimé avec succès.',
        );
        if (!mounted) return;
        Navigator.pop(context, true);
      } else {
        await CustomPopup.showErrorPopup(
          context: context,
          title: 'Suppression échouée',
          message:
              'Impossible de supprimer ce logement. Veuillez réessayer.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      await CustomPopup.showErrorPopup(
        context: context,
        title: 'Erreur de suppression',
        message:
            'Une erreur est survenue lors de la suppression du logement.',
      );
      debugPrint('Erreur suppression logement : $e');
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  String _formatPrix(double montant) {
    return montant % 1 == 0
        ? '${montant.toStringAsFixed(0)} DT'
        : '${montant.toStringAsFixed(2)} DT';
  }

  // ===========================================================================
  // COMPOSANTS UI
  // ===========================================================================
  Widget _carteConteneur({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
  }) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: _surfaceClaire,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _sableClair),
      ),
      child: child,
    );
  }

  Widget _construireEtoiles(double note) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < note.round() ? Icons.star : Icons.star_border,
          color: _orEtoile,
          size: 20,
        );
      }),
    );
  }

  Widget _construireSectionInfosPrincipales(Logement logement) {
    return _carteConteneur(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            logement.titre,
            style: const TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w700,
              color: _textePrincipal,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                color: _vertSapin,
                size: 19,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  logement.adresse,
                  style: const TextStyle(
                    fontSize: 15,
                    color: _texteSecondaire,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: _sableClair,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              _formatPrix(logement.prix),
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: _vertSapin,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construireSectionDescription(String description) {
    return _carteConteneur(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Description',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _textePrincipal,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: const TextStyle(
              fontSize: 15,
              height: 1.55,
              color: _textePrincipal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _construireSectionAvis() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Avis des visiteurs',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: _textePrincipal,
          ),
        ),
        const SizedBox(height: 12),
        FutureBuilder<List>(
          future: _avisFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return _carteConteneur(
                padding: const EdgeInsets.all(24),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: _vertSapin,
                  ),
                ),
              );
            }

            if (snapshot.hasError) {
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _rougeErreur.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: _rougeErreur.withValues(alpha: 0.35),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.error_outline, color: _rougeErreur),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Impossible de charger les avis. Veuillez réessayer plus tard.',
                        style: TextStyle(color: _rougeErreur),
                      ),
                    ),
                  ],
                ),
              );
            }

            final avis = snapshot.data ?? [];

            if (avis.isEmpty) {
              return _carteConteneur(
                padding: const EdgeInsets.all(18),
                child: const Text(
                  'Aucun avis pour le moment.',
                  style: TextStyle(color: _texteSecondaire),
                ),
              );
            }

            final total = avis.fold<double>(
              0,
              (sum, item) => sum + (item['note'] as num).toDouble(),
            );
            final moyenne = total / avis.length;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _carteConteneur(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: _sableClair,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          moyenne.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: _vertSapin,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _construireEtoiles(moyenne),
                            const SizedBox(height: 4),
                            Text(
                              '${avis.length} avis',
                              style: const TextStyle(
                                color: _texteSecondaire,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                ...avis.map((item) {
                  final note = (item['note'] as num).toDouble();
                  final commentaire =
                      (item['commentaire'] ?? '').toString().trim();

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _carteConteneur(
                      padding: const EdgeInsets.all(15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  (item['visiteur_username'] ??
                                          'Visiteur')
                                      .toString(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: _textePrincipal,
                                  ),
                                ),
                              ),
                              _construireEtoiles(note),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            commentaire.isEmpty
                                ? 'Aucun commentaire.'
                                : commentaire,
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.45,
                              color: _textePrincipal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _construireBoutonsVisiteur() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isContacting ? null : _contacterProprietaire,
            icon: _isContacting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _vertSapin,
                    ),
                  )
                : const Icon(Icons.chat_bubble_outline),
            label: Text(
              _isContacting
                  ? 'Ouverture de la conversation...'
                  : 'Contacter le propriétaire',
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: _vertSapin,
              backgroundColor: _surfaceClaire,
              disabledForegroundColor: _texteSecondaire,
              padding: const EdgeInsets.symmetric(vertical: 15),
              side: const BorderSide(color: _vertSapin),
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _reserverLogement,
            icon: const Icon(Icons.calendar_month_outlined),
            label: const Text('Réserver ce logement'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _vertSapin,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _construireBoutonsProprietaire() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _modifierLogement,
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Modifier le logement'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _vertSapin,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isDeleting ? null : _supprimerLogement,
            icon: _isDeleting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _rougeErreur,
                    ),
                  )
                : const Icon(Icons.delete_outline),
            label: Text(
              _isDeleting
                  ? 'Suppression...'
                  : 'Supprimer le logement',
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: _rougeErreur,
              backgroundColor: _surfaceClaire,
              disabledForegroundColor: _texteSecondaire,
              side: const BorderSide(color: _rougeErreur),
              padding: const EdgeInsets.symmetric(vertical: 15),
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final logement = widget.logement;

    return Scaffold(
      backgroundColor: _fondCreme,
      appBar: AppBar(
        title: const Text(
          'Détail du logement',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: _fondCreme,
        foregroundColor: _vertSapin,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _GaleriePhotos(photos: logement.photos),
              const SizedBox(height: 18),
              _construireSectionInfosPrincipales(logement),
              const SizedBox(height: 16),
              _construireSectionDescription(logement.description),
              const SizedBox(height: 22),
              _construireSectionAvis(),
              const SizedBox(height: 24),
              if (widget.isProprietaire)
                _construireBoutonsProprietaire()
              else
                _construireBoutonsVisiteur(),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// GALERIE PHOTOS DU LOGEMENT
// =============================================================================
class _GaleriePhotos extends StatefulWidget {
  final List<String> photos;

  const _GaleriePhotos({
    required this.photos,
  });

  @override
  State<_GaleriePhotos> createState() => _GaleriePhotosState();
}

class _GaleriePhotosState extends State<_GaleriePhotos> {
  int _photoActuelle = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.photos.isEmpty) {
      return Container(
        width: double.infinity,
        height: 240,
        decoration: BoxDecoration(
          color: _LogementDetailScreenState._surfaceClaire,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _LogementDetailScreenState._sableClair,
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.home_work_outlined,
              color: _LogementDetailScreenState._brunTerre,
              size: 72,
            ),
            SizedBox(height: 8),
            Text(
              'Aucune photo disponible',
              style: TextStyle(
                color: _LogementDetailScreenState._texteSecondaire,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 240,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                PageView.builder(
                  itemCount: widget.photos.length,
                  onPageChanged: (index) {
                    setState(() => _photoActuelle = index);
                  },
                  itemBuilder: (context, index) {
                    return Image.network(
                      widget.photos[index],
                      width: double.infinity,
                      height: 240,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const ColoredBox(
                          color: _LogementDetailScreenState._sableClair,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: _LogementDetailScreenState._vertSapin,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return const ColoredBox(
                          color: _LogementDetailScreenState._sableClair,
                          child: Icon(
                            Icons.broken_image_outlined,
                            color: _LogementDetailScreenState._brunTerre,
                            size: 56,
                          ),
                        );
                      },
                    );
                  },
                ),
                if (widget.photos.length > 1)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _LogementDetailScreenState._vertSapin
                            .withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${_photoActuelle + 1}/${widget.photos.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (widget.photos.length > 1) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.photos.length,
              (index) {
                final actif = _photoActuelle == index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: actif ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: actif
                        ? _LogementDetailScreenState._vertSapin
                        : _LogementDetailScreenState._vertSauge
                            .withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(999),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}