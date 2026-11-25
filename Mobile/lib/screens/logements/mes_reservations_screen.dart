import 'package:flutter/material.dart';

import '../../services/avis_service.dart';
import '../../services/reservation_service.dart';
import '../../widgets/custom_popup.dart';

class MesReservationsScreen extends StatefulWidget {
  const MesReservationsScreen({super.key});

  @override
  State<MesReservationsScreen> createState() =>
      _MesReservationsScreenState();
}

class _MesReservationsScreenState
    extends State<MesReservationsScreen> {
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
  late Future<List> _reservationsFuture;

  @override
  void initState() {
    super.initState();
    _chargerReservations();
  }

  void _chargerReservations() {
    _reservationsFuture = ReservationService.getReservations();
  }

  Future<void> _actualiser() async {
    setState(() {
      _chargerReservations();
    });
    await _reservationsFuture;
  }

  // ===========================================================================
  // STATUTS & FORMATAGE
  // ===========================================================================
  Color _couleurStatut(String statut) {
    switch (statut) {
      case 'acceptee':
        return _vertSapin;
      case 'refusee':
        return _rougeErreur;
      case 'annulee':
        return _texteSecondaire;
      default:
        return _brunTerre;
    }
  }

  Color _fondStatut(String statut) {
    switch (statut) {
      case 'acceptee':
        return _vertSauge.withValues(alpha: 0.22);
      case 'refusee':
        return _rougeErreur.withValues(alpha: 0.12);
      case 'annulee':
        return _sableClair;
      default:
        return _sableClair;
    }
  }

  String _texteStatut(String statut) {
    switch (statut) {
      case 'acceptee':
        return 'Acceptée';
      case 'refusee':
        return 'Refusée';
      case 'annulee':
        return 'Annulée';
      default:
        return 'En attente';
    }
  }

  // ===========================================================================
  // ACTIONS MÉTIER
  // ===========================================================================
  Future<void> _annulerReservation(
    Map<String, dynamic> reservation,
  ) async {
    final confirmer = await CustomPopup.showConfirmPopup(
      context: context,
      title: 'Annuler la réservation ?',
      message:
          'Voulez-vous vraiment annuler cette réservation ?',
      confirmText: 'Oui, annuler',
      cancelText: 'Garder',
    );

    if (!confirmer || !mounted) return;

    try {
      final id = reservation['id'];
      final reservationId =
          id is num ? id.toInt() : int.tryParse(id.toString());

      if (reservationId == null) {
        throw Exception('Identifiant de réservation invalide.');
      }

      final success = await ReservationService.updateStatut(
        reservationId: reservationId,
        statut: 'annulee',
      );

      if (!mounted) return;

      if (success) {
        await CustomPopup.showSuccessPopup(
          context: context,
          title: 'Réservation annulée',
          message: 'Votre réservation a été annulée avec succès.',
        );
        if (!mounted) return;
        await _actualiser();
      } else {
        await CustomPopup.showErrorPopup(
          context: context,
          title: 'Annulation impossible',
          message:
              'Impossible d’annuler cette réservation. Veuillez réessayer.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      await CustomPopup.showErrorPopup(
        context: context,
        title: 'Erreur',
        message:
            'Une erreur est survenue lors de l’annulation de la réservation.',
      );
      debugPrint('Erreur annulation réservation : $e');
    }
  }

  Future<void> _donnerAvis(
    Map<String, dynamic> reservation,
  ) async {
    int note = 5;
    final commentaireController = TextEditingController();

    final confirmer = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: _surfaceClaire,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: const BorderSide(color: _sableClair),
              ),
              title: const Text(
                'Donner votre avis',
                style: TextStyle(
                  color: _textePrincipal,
                  fontWeight: FontWeight.w700,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Quelle note donnez-vous ?',
                      style: TextStyle(color: _texteSecondaire),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return IconButton(
                          onPressed: () {
                            setDialogState(() => note = index + 1);
                          },
                          icon: Icon(
                            index < note
                                ? Icons.star
                                : Icons.star_border,
                            color: _orEtoile,
                            size: 32,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: commentaireController,
                      maxLines: 4,
                      maxLength: 500,
                      style: const TextStyle(color: _textePrincipal),
                      decoration: InputDecoration(
                        labelText: 'Votre commentaire',
                        hintText: 'Ex : Très bon logement...',
                        hintStyle: const TextStyle(
                          color: _texteSecondaire,
                        ),
                        filled: true,
                        fillColor: _fondCreme,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: _sableClair,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: _vertSapin,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.pop(dialogContext, false),
                  child: const Text(
                    'Annuler',
                    style: TextStyle(color: _texteSecondaire),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _vertSapin,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () =>
                      Navigator.pop(dialogContext, true),
                  child: const Text('Publier'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmer != true || !mounted) {
      commentaireController.dispose();
      return;
    }

    try {
      final id = reservation['id'];
      final reservationId =
          id is num ? id.toInt() : int.tryParse(id.toString());

      if (reservationId == null) {
        throw Exception('Identifiant de réservation invalide.');
      }

      await AvisService.ajouterAvis(
        reservationId: reservationId,
        note: note,
        commentaire: commentaireController.text.trim(),
      );

      if (!mounted) return;

      await CustomPopup.showSuccessPopup(
        context: context,
        title: 'Avis publié',
        message: 'Merci ! Votre avis a été publié avec succès.',
      );

      if (!mounted) return;
      await _actualiser();
    } catch (e) {
      if (!mounted) return;
      await CustomPopup.showErrorPopup(
        context: context,
        title: 'Publication impossible',
        message:
            'Une erreur est survenue lors de la publication de votre avis. Veuillez réessayer.',
      );
      debugPrint('Erreur publication avis : $e');
    } finally {
      commentaireController.dispose();
    }
  }

  // ===========================================================================
  // COMPOSANTS UI
  // ===========================================================================
  Widget _afficherInformation(IconData icon, String texte) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: _vertSapin,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              texte,
              style: const TextStyle(
                color: _textePrincipal,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construireCarteReservation(
    Map<String, dynamic> reservation,
  ) {
    final statut =
        reservation['statut']?.toString() ?? 'en_attente';
    final couleur = _couleurStatut(statut);

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceClaire,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _sableClair),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            reservation['logement_titre']?.toString() ?? 'Logement',
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: _textePrincipal,
            ),
          ),
          const SizedBox(height: 14),
          _afficherInformation(
            Icons.calendar_today_outlined,
            'Arrivée : ${reservation['date_arrivee'] ?? '-'}',
          ),
          _afficherInformation(
            Icons.calendar_month_outlined,
            'Départ : ${reservation['date_depart'] ?? '-'}',
          ),
          _afficherInformation(
            Icons.people_outline,
            'Personnes : ${reservation['nombre_personnes'] ?? '-'}',
          ),
          if ((reservation['besoins'] ?? '')
              .toString()
              .isNotEmpty)
            _afficherInformation(
              Icons.tune_outlined,
              'Besoins : ${reservation['besoins']}',
            ),
          if ((reservation['message'] ?? '')
              .toString()
              .isNotEmpty)
            _afficherInformation(
              Icons.chat_bubble_outline,
              'Message : ${reservation['message']}',
            ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(color: _sableClair, height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Statut :',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: _textePrincipal,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _fondStatut(statut),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _texteStatut(statut),
                  style: TextStyle(
                    color: couleur,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          if (statut == 'acceptee') ...[
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _donnerAvis(reservation),
                icon: const Icon(Icons.star_outline),
                label: const Text('Donner mon avis'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _vertSapin,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),
          ],
          if (statut == 'en_attente') ...[
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.cancel_outlined),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _rougeErreur,
                  backgroundColor: _fondCreme,
                  side: const BorderSide(color: _rougeErreur),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                onPressed: () => _annulerReservation(reservation),
                label: const Text('Annuler la réservation'),
              ),
            ),
          ],
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
          'Mes réservations',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: _fondCreme,
        foregroundColor: _vertSapin,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: FutureBuilder<List>(
          future: _reservationsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: _vertSapin,
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: _rougeErreur,
                        size: 45,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Impossible de charger vos réservations.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: _textePrincipal),
                      ),
                      const SizedBox(height: 15),
                      ElevatedButton(
                        onPressed: _actualiser,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _vertSapin,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final reservations = snapshot.data ?? [];

            if (reservations.isEmpty) {
              return RefreshIndicator(
                color: _vertSapin,
                backgroundColor: _surfaceClaire,
                onRefresh: _actualiser,
                child: ListView(
                  children: const [
                    SizedBox(height: 160),
                    Icon(
                      Icons.event_busy_outlined,
                      size: 65,
                      color: _vertSapin,
                    ),
                    SizedBox(height: 15),
                    Center(
                      child: Text(
                        'Vous n’avez aucune réservation.',
                        style: TextStyle(color: _texteSecondaire),
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              color: _vertSapin,
              backgroundColor: _surfaceClaire,
              onRefresh: _actualiser,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: reservations.length,
                itemBuilder: (_, index) =>
                    _construireCarteReservation(reservations[index]),
              ),
            );
          },
        ),
      ),
    );
  }
}