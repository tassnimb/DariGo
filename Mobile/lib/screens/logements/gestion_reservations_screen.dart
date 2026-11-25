import 'package:flutter/material.dart';

import '../../services/reservation_service.dart';
import '../../widgets/custom_popup.dart';

class GestionReservationsScreen extends StatefulWidget {
  const GestionReservationsScreen({super.key});

  @override
  State<GestionReservationsScreen> createState() =>
      _GestionReservationsScreenState();
}

class _GestionReservationsScreenState
    extends State<GestionReservationsScreen> {
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

  static const String _serveurUrl = 'http://127.0.0.1:8000';

  // ===========================================================================
  // ÉTAT
  // ===========================================================================
  List<Map<String, dynamic>> reservations = [];
  bool _chargement = true;
  String? _erreur;

  final Set<int> _reservationsEnCours = {};

  @override
  void initState() {
    super.initState();
    _chargerReservations();
  }

  // ===========================================================================
  // LOGIQUE MÉTIER
  // ===========================================================================
  Future<void> _chargerReservations() async {
    if (mounted) {
      setState(() {
        _chargement = true;
        _erreur = null;
      });
    }

    try {
      final data = await ReservationService.getReservations();
      if (!mounted) return;

      setState(() {
        reservations = data;
        _chargement = false;
        _erreur = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _erreur = e.toString();
        _chargement = false;
      });

      await CustomPopup.showErrorPopup(
        context: context,
        title: 'Erreur de chargement',
        message:
            'Impossible de récupérer les réservations. Vérifiez votre connexion.',
      );
    }
  }

  Future<void> _changerStatut(int id, String statut) async {
    if (_reservationsEnCours.contains(id)) return;

    final bool accepter = statut == 'acceptee';

    final confirmer = await CustomPopup.showConfirmPopup(
      context: context,
      title: accepter
          ? 'Accepter la réservation ?'
          : 'Refuser la réservation ?',
      message: accepter
          ? 'Voulez-vous vraiment accepter cette réservation ?'
          : 'Voulez-vous vraiment refuser cette réservation ?',
      confirmText: accepter ? 'Accepter' : 'Refuser',
      cancelText: 'Annuler',
    );

    if (!confirmer || !mounted) return;

    setState(() => _reservationsEnCours.add(id));

    try {
      await ReservationService.updateStatut(
        reservationId: id,
        statut: statut,
      );

      await _chargerReservations();
      if (!mounted) return;

      await CustomPopup.showSuccessPopup(
        context: context,
        title: accepter
            ? 'Réservation acceptée !'
            : 'Réservation refusée',
        message: accepter
            ? 'La réservation a été acceptée avec succès.'
            : 'La réservation a été refusée.',
      );
    } catch (e) {
      if (!mounted) return;

      await CustomPopup.showErrorPopup(
        context: context,
        title: 'Modification impossible',
        message:
            'Une erreur est survenue lors de la modification de la réservation.',
      );
      debugPrint('Erreur changement statut : $e');
    } finally {
      if (mounted) {
        setState(() => _reservationsEnCours.remove(id));
      }
    }
  }

  // ===========================================================================
  // FORMATAGE & STATUTS
  // ===========================================================================
  String _valeur(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) {
      return 'Non renseigné';
    }
    return value.toString().trim();
  }

  String _traduireStatut(String statut) {
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

  Color _couleurStatut(String statut) {
    switch (statut) {
      case 'acceptee':
        return _vertSapin;
      case 'refusee':
        return _rougeErreur;
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
      default:
        return _sableClair;
    }
  }

  String? _obtenirPhotoUrl(dynamic photo) {
    if (photo == null || photo.toString().trim().isEmpty) {
      return null;
    }

    String url = photo.toString().trim();
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }

    if (!url.startsWith('/')) {
      url = '/$url';
    }

    return '$_serveurUrl$url';
  }

  // ===========================================================================
  // COMPOSANTS UI
  // ===========================================================================
  Widget _afficherPhoto(dynamic photo) {
    final photoUrl = _obtenirPhotoUrl(photo);
    final fallback = Container(
      color: _sableClair,
      child: const Icon(
        Icons.person_outline,
        size: 36,
        color: _vertSapin,
      ),
    );

    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: _vertSapin,
          width: 1.8,
        ),
      ),
      child: ClipOval(
        child: photoUrl == null
            ? fallback
            : Image.network(
                photoUrl,
                width: 72,
                height: 72,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => fallback,
              ),
      ),
    );
  }

  Widget _ligneDetail(IconData icon, String titre, dynamic contenu) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 17,
            color: _vertSapin,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$titre : ${_valeur(contenu)}',
              style: const TextStyle(
                fontSize: 14,
                color: _textePrincipal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construireCarteReservation(Map<String, dynamic> r) {
    final statut = _valeur(r['statut']);
    final int id = r['id'] is int
        ? r['id'] as int
        : int.tryParse(r['id'].toString()) ?? 0;
    final bool enCours = _reservationsEnCours.contains(id);
    final couleur = _couleurStatut(statut);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
            _valeur(r['logement_titre']),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _textePrincipal,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _afficherPhoto(r['visiteur_photo']),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _valeur(r['visiteur_username']),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _textePrincipal,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _valeur(r['visiteur_email']),
                      style: const TextStyle(
                        fontSize: 13,
                        color: _texteSecondaire,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _valeur(r['visiteur_phone']),
                      style: const TextStyle(
                        fontSize: 13,
                        color: _texteSecondaire,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(color: _sableClair, height: 1),
          ),
          _ligneDetail(
            Icons.calendar_today_outlined,
            'Arrivée',
            r['date_arrivee'],
          ),
          _ligneDetail(
            Icons.calendar_month_outlined,
            'Départ',
            r['date_depart'],
          ),
          _ligneDetail(
            Icons.people_outline,
            'Personnes',
            r['nombre_personnes'],
          ),
          _ligneDetail(
            Icons.tune_outlined,
            'Besoins',
            r['besoins'],
          ),
          _ligneDetail(
            Icons.chat_bubble_outline,
            'Message',
            r['message'],
          ),
          const SizedBox(height: 10),
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
                  _traduireStatut(statut),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: couleur,
                  ),
                ),
              ),
            ],
          ),
          if (statut == 'en_attente') ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: enCours
                        ? null
                        : () => _changerStatut(id, 'acceptee'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _vertSapin,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: _vertSauge,
                      disabledForegroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: enCours
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Accepter'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: enCours
                        ? null
                        : () => _changerStatut(id, 'refusee'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _rougeErreur,
                      backgroundColor: _fondCreme,
                      disabledForegroundColor: _texteSecondaire,
                      side: const BorderSide(color: _rougeErreur),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: enCours
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: _rougeErreur,
                            ),
                          )
                        : const Text('Refuser'),
                  ),
                ),
              ],
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
          'Gestion des réservations',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: _fondCreme,
        foregroundColor: _vertSapin,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: _chargement
            ? const Center(
                child: CircularProgressIndicator(
                  color: _vertSapin,
                ),
              )
            : _erreur != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: _rougeErreur,
                            size: 48,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Impossible de charger les réservations.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: _textePrincipal),
                          ),
                          const SizedBox(height: 14),
                          ElevatedButton.icon(
                            onPressed: _chargerReservations,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Réessayer'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _vertSapin,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : reservations.isEmpty
                    ? RefreshIndicator(
                        color: _vertSapin,
                        backgroundColor: _surfaceClaire,
                        onRefresh: _chargerReservations,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 200),
                            Icon(
                              Icons.event_available_outlined,
                              size: 56,
                              color: _vertSapin,
                            ),
                            SizedBox(height: 12),
                            Center(
                              child: Text(
                                'Aucune réservation reçue.',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: _texteSecondaire,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        color: _vertSapin,
                        backgroundColor: _surfaceClaire,
                        onRefresh: _chargerReservations,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(
                            14,
                            8,
                            14,
                            24,
                          ),
                          itemCount: reservations.length,
                          itemBuilder: (_, index) =>
                              _construireCarteReservation(
                            reservations[index],
                          ),
                        ),
                      ),
      ),
    );
  }
}