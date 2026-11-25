
import 'package:flutter/material.dart';

import '../../models/logement.dart';
import '../../services/logement_service.dart';
import '../../services/avis_service.dart';
import '../../services/messagerie_service.dart';
import '../../widgets/custom_popup.dart';

import 'modifier_logement_screen.dart';
import 'reservation_screen.dart';
import '../messagerie/chat_screen.dart';

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

class _LogementDetailScreenState
    extends State<LogementDetailScreen> {
  bool isDeleting = false;
  bool isContacting = false;

  late Future<List<Map<String, dynamic>>> avisFuture;

  static const violet = Color(0xFF6C4AB6);

  @override
  void initState() {
    super.initState();
    avisFuture = AvisService.getAvis(widget.logement.id);
  }

  Future<void> modifierLogement() async {
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

  Future<void> reserverLogement() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReservationScreen(
          logement: widget.logement,
        ),
      ),
    );
  }

  // CONTACTER LE PROPRIÉTAIRE
  Future<void> contacterProprietaire() async {
    if (isContacting) return;

    setState(() {
      isContacting = true;
    });

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
            conversationId:
                int.parse(conversationId.toString()),
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
        setState(() {
          isContacting = false;
        });
      }
    }
  }

  // SUPPRIMER UN LOGEMENT
  Future<void> supprimerLogement() async {
    final confirmer = await CustomPopup.showConfirmPopup(
      context: context,
      title: 'Supprimer le logement',
      message: 'Voulez-vous vraiment supprimer ce logement ?',
      confirmText: 'Supprimer',
      cancelText: 'Annuler',
    );

    if (!confirmer || !mounted) return;

    setState(() {
      isDeleting = true;
    });

    try {
      final success =
          await LogementService.deleteLogement(
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
        setState(() {
          isDeleting = false;
        });
      }
    }
  }

  // ÉTOILES DES AVIS
  Widget construireEtoiles(double note) {
    return Row(
      children: List.generate(5, (index) {
        return Icon(
          index < note.round()
              ? Icons.star
              : Icons.star_border,
          color: Colors.amber,
          size: 21,
        );
      }),
    );
  }

  // AFFICHER LES AVIS
  Widget afficherAvis() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: avisFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.red,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Impossible de charger les avis. Veuillez réessayer plus tard.',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          );
        }

        final avis = snapshot.data ?? [];

        if (avis.isEmpty) {
          return const Text(
            'Aucun avis pour le moment.',
            style: TextStyle(color: Colors.grey),
          );
        }

        final total = avis.fold<double>(
          0,
          (sum, item) =>
              sum + (item['note'] as num).toDouble(),
        );

        final moyenne = total / avis.length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: violet.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Text(
                    moyenne.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: violet,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        construireEtoiles(moyenne),
                        Text(
                          '${avis.length} avis',
                          style: const TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 15),

            ...avis.map((item) {
              final note =
                  (item['note'] as num).toDouble();

              return Card(
                margin:
                    const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['visiteur_username'] ??
                            'Visiteur',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 6),
                      construireEtoiles(note),
                      const SizedBox(height: 8),
                      Text(
                        (item['commentaire'] ?? '')
                                .toString()
                                .isEmpty
                            ? 'Aucun commentaire.'
                            : item['commentaire']
                                .toString(),
                        style:
                            const TextStyle(fontSize: 15),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final logement = widget.logement;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F6FA),

      appBar: AppBar(
        title: const Text('Détail du logement'),
        backgroundColor: violet,
        foregroundColor: Colors.white,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _GaleriePhotos(photos: logement.photos),

            const SizedBox(height: 22),

            Text(
              logement.titre,
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  color: violet,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    logement.adresse,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            Container(
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              decoration: BoxDecoration(
                color: violet.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                '${logement.prix.toStringAsFixed(0)} DT',
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                  color: violet,
                ),
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Description',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              logement.description,
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 28),

            const Text(
              'Avis des visiteurs',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            afficherAvis(),

            // BOUTONS DU VISITEUR
            if (!widget.isProprietaire) ...[
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isContacting
                      ? null
                      : contacterProprietaire,
                  icon: isContacting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.chat),
                  label: Text(
                    isContacting
                        ? 'Ouverture de la conversation...'
                        : 'Contacter le propriétaire',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(15),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: reserverLogement,
                  icon: const Icon(Icons.calendar_month),
                  label: const Text(
                    'Réserver ce logement',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: violet,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(15),
                  ),
                ),
              ),
            ],

            // BOUTONS DU PROPRIÉTAIRE
            if (widget.isProprietaire) ...[
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: modifierLogement,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text(
                    'Modifier le logement',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: violet,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(15),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed:
                      isDeleting ? null : supprimerLogement,
                  icon: const Icon(Icons.delete_outline),
                  label: Text(
                    isDeleting
                        ? 'Suppression...'
                        : 'Supprimer le logement',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(
                      color: Colors.red,
                    ),
                    padding: const EdgeInsets.all(15),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ======================================================
// GALERIE PHOTOS DU LOGEMENT
// ======================================================

class _GaleriePhotos extends StatefulWidget {
  final List<String> photos;

  const _GaleriePhotos({
    required this.photos,
  });

  @override
  State<_GaleriePhotos> createState() =>
      _GaleriePhotosState();
}

class _GaleriePhotosState extends State<_GaleriePhotos> {
  int photoActuelle = 0;

  static const violet = Color(0xFF6C4AB6);

  @override
  Widget build(BuildContext context) {
    // S'il n'y a aucune photo.
    if (widget.photos.isEmpty) {
      return Container(
        width: double.infinity,
        height: 250,
        decoration: BoxDecoration(
          color: violet.withOpacity(0.10),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(
          Icons.home_work_outlined,
          color: violet,
          size: 85,
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 250,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // Swipe entre les photos.
                PageView.builder(
                  itemCount: widget.photos.length,
                  onPageChanged: (index) {
                    setState(() {
                      photoActuelle = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    return Image.network(
                      widget.photos[index],
                      width: double.infinity,
                      height: 250,
                      fit: BoxFit.cover,
                      loadingBuilder:
                          (context, child, progress) {
                        if (progress == null) return child;

                        return Container(
                          color: violet.withOpacity(0.08),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: violet,
                            ),
                          ),
                        );
                      },
                      errorBuilder:
                          (context, error, stackTrace) {
                        return Container(
                          color: violet.withOpacity(0.10),
                          child: const Icon(
                            Icons.broken_image_outlined,
                            color: violet,
                            size: 60,
                          ),
                        );
                      },
                    );
                  },
                ),

                // Compteur en haut à droite.
                if (widget.photos.length > 1)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${photoActuelle + 1}/${widget.photos.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // Petits points sous les photos.
        if (widget.photos.length > 1) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.photos.length,
              (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(
                    horizontal: 4,
                  ),
                  width: photoActuelle == index ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: photoActuelle == index
                        ? violet
                        : violet.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(10),
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
