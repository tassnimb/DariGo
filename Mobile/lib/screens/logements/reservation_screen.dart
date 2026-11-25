import 'package:flutter/material.dart';

import '../../models/logement.dart';
import '../../services/reservation_service.dart';
import '../../widgets/custom_popup.dart';

class ReservationScreen extends StatefulWidget {
  final Logement logement;

  const ReservationScreen({
    super.key,
    required this.logement,
  });

  @override
  State<ReservationScreen> createState() =>
      _ReservationScreenState();
}

class _ReservationScreenState extends State<ReservationScreen> {
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

  static const int _minPersonnes = 1;
  static const int _maxPersonnes = 20;

  // ===========================================================================
  // ÉTAT & CONTRÔLEURS
  // ===========================================================================
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _besoinsController =
      TextEditingController();
  final TextEditingController _messageController =
      TextEditingController();

  DateTime? _dateArrivee;
  DateTime? _dateDepart;
  int _nombrePersonnes = _minPersonnes;

  bool _isLoading = false;

  @override
  void dispose() {
    _besoinsController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // CALCULS & FORMATAGE
  // ===========================================================================
  int? get _nombreNuits {
    if (_dateArrivee == null || _dateDepart == null) return null;
    if (!_dateDepart!.isAfter(_dateArrivee!)) return null;

    final debut = DateTime(
      _dateArrivee!.year,
      _dateArrivee!.month,
      _dateArrivee!.day,
    );
    final fin = DateTime(
      _dateDepart!.year,
      _dateDepart!.month,
      _dateDepart!.day,
    );
    return fin.difference(debut).inDays;
  }

  double? get _totalEstime {
    final nuits = _nombreNuits;
    if (nuits == null) return null;
    return nuits * widget.logement.prix;
  }

  String _formatDateIso(DateTime date) {
    final annee = date.year.toString().padLeft(4, '0');
    final mois = date.month.toString().padLeft(2, '0');
    final jour = date.day.toString().padLeft(2, '0');
    return '$annee-$mois-$jour';
  }

  String _formatDateLisible(DateTime date) {
    const moisFr = [
      'janv.',
      'févr.',
      'mars',
      'avr.',
      'mai',
      'juin',
      'juil.',
      'août',
      'sept.',
      'oct.',
      'nov.',
      'déc.',
    ];
    final jour = date.day.toString().padLeft(2, '0');
    final mois = moisFr[date.month - 1];
    return '$jour $mois ${date.year}';
  }

  String _formatPrix(double montant) {
    return montant % 1 == 0
        ? '${montant.toStringAsFixed(0)} DT'
        : '${montant.toStringAsFixed(2)} DT';
  }

  // ===========================================================================
  // ACTIONS & VALIDATION
  // ===========================================================================
  Future<void> _choisirDate(bool estArrivee) async {
    final maintenant = DateTime.now();
    final aujourdHui = DateTime(
      maintenant.year,
      maintenant.month,
      maintenant.day,
    );

    final DateTime dateInitiale;
    if (estArrivee) {
      dateInitiale = (_dateArrivee != null &&
              !_dateArrivee!.isBefore(aujourdHui))
          ? _dateArrivee!
          : aujourdHui;
    } else {
      dateInitiale = _dateDepart ?? _dateArrivee ?? aujourdHui;
    }

    final selection = await showDatePicker(
      context: context,
      initialDate: dateInitiale,
      firstDate: aujourdHui,
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _vertSapin,
              onPrimary: Colors.white,
              surface: _surfaceClaire,
              onSurface: _textePrincipal,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selection == null || !mounted) return;

    setState(() {
      if (estArrivee) {
        _dateArrivee = selection;
        if (_dateDepart != null &&
            !_dateDepart!.isAfter(selection)) {
          _dateDepart = null;
        }
      } else {
        _dateDepart = selection;
      }
    });
  }

  void _effacerDate(bool estArrivee) {
    setState(() {
      if (estArrivee) {
        _dateArrivee = null;
        _dateDepart = null;
      } else {
        _dateDepart = null;
      }
    });
  }

  bool _estErreurDisponibilite(String erreurNormalisee) {
    const motifs = [
      'déjà réservé',
      'deja reserve',
      'already reserved',
      'already booked',
      'indisponible',
      'not available',
      'overlap',
      'chevauchement',
      "n'est pas disponible",
      'pas disponible',
    ];
    return motifs.any(erreurNormalisee.contains);
  }

  Future<bool> _validerAvantEnvoi() async {
    if (!_formKey.currentState!.validate()) return false;

    if (_dateArrivee == null || _dateDepart == null) {
      await CustomPopup.showWarningPopup(
        context: context,
        title: 'Dates manquantes',
        message: 'Veuillez sélectionner une date d’arrivée et de départ.',
      );
      return false;
    }

    if (!_dateDepart!.isAfter(_dateArrivee!)) {
      await CustomPopup.showWarningPopup(
        context: context,
        title: 'Dates invalides',
        message:
            'La date de départ doit être postérieure à la date d’arrivée.',
      );
      return false;
    }

    return true;
  }

  Future<void> _envoyerReservation() async {
    if (!await _validerAvantEnvoi()) return;

    setState(() => _isLoading = true);

    try {
      await ReservationService.addReservation(
        logementId: widget.logement.id,
        dateArrivee: _formatDateIso(_dateArrivee!),
        dateDepart: _formatDateIso(_dateDepart!),
        nombrePersonnes: _nombrePersonnes,
        besoins: _besoinsController.text.trim(),
        message: _messageController.text.trim(),
      );

      if (!mounted) return;

      await CustomPopup.showSuccessPopup(
        context: context,
        title: 'Réservation envoyée',
        message: 'Votre demande de réservation a été envoyée avec succès.',
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      debugPrint('ERREUR RESERVATION : $e');
      final messageErreur = e.toString().toLowerCase();

      if (_estErreurDisponibilite(messageErreur)) {
        await CustomPopup.showErrorPopup(
          context: context,
          title: 'Logement indisponible',
          message:
              'Ce logement est déjà réservé sur cette période. '
              'Veuillez choisir d’autres dates.',
        );
      } else {
        await CustomPopup.showErrorPopup(
          context: context,
          title: 'Réservation impossible',
          message:
              'Une erreur est survenue lors de l’envoi de votre réservation. '
              'Veuillez réessayer.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ===========================================================================
  // COMPOSANTS UI
  // ===========================================================================
  InputDecoration _decorationChamp({
    required String label,
    required IconData icon,
    required double iconBottomPadding,
  }) {
    return InputDecoration(
      labelText: label,
      alignLabelWithHint: true,
      labelStyle: const TextStyle(
        color: _texteSecondaire,
        fontSize: 14,
      ),
      floatingLabelStyle: const TextStyle(
        color: _vertSapin,
        fontWeight: FontWeight.w600,
      ),
      prefixIcon: Padding(
        padding: EdgeInsets.only(bottom: iconBottomPadding),
        child: Icon(icon, color: _vertSapin, size: 20),
      ),
      filled: true,
      fillColor: _fondCreme,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 14,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: _sableClair),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: _vertSapin, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: _rougeErreur),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: _rougeErreur, width: 1.5),
      ),
    );
  }

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

  Widget _construireEnTeteLogement() {
    return _carteConteneur(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _sableClair,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.home_work_outlined,
                  color: _vertSapin,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.logement.titre,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: _textePrincipal,
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: _sableClair,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '${_formatPrix(widget.logement.prix)} / nuit',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _vertSapin,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construireChampDateTuile({
    required String label,
    required String placeholder,
    required DateTime? date,
    required IconData icon,
    required VoidCallback onTap,
    required VoidCallback? onClear,
  }) {
    final estSelectionnee = date != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _texteSecondaire,
          ),
        ),
        const SizedBox(height: 6),
        Material(
          color: _fondCreme,
          borderRadius: BorderRadius.circular(15),
          child: InkWell(
            onTap: _isLoading ? null : onTap,
            borderRadius: BorderRadius.circular(15),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 13,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: estSelectionnee ? _vertSapin : _sableClair,
                  width: estSelectionnee ? 1.4 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 20,
                    color: estSelectionnee ? _vertSapin : _brunTerre,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      estSelectionnee
                          ? _formatDateLisible(date)
                          : placeholder,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: estSelectionnee
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: estSelectionnee
                            ? _textePrincipal
                            : _texteSecondaire,
                      ),
                    ),
                  ),
                  if (onClear != null)
                    IconButton(
                      onPressed: onClear,
                      icon: const Icon(
                        Icons.close,
                        size: 18,
                        color: _texteSecondaire,
                      ),
                      constraints: const BoxConstraints.tightFor(
                        width: 28,
                        height: 28,
                      ),
                      padding: EdgeInsets.zero,
                      tooltip: 'Effacer la date',
                    )
                  else
                    const Icon(
                      Icons.expand_more,
                      color: _brunTerre,
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _boutonCompteur({
    required IconData icon,
    required bool enabled,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: enabled ? _sableClair : _fondCreme,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(
            icon,
            size: 18,
            color: enabled ? _vertSapin : _texteSecondaire,
          ),
        ),
      ),
    );
  }

  Widget _construireSectionSejour() {
    final peutDiminuer =
        !_isLoading && _nombrePersonnes > _minPersonnes;
    final peutAugmenter =
        !_isLoading && _nombrePersonnes < _maxPersonnes;

    return _carteConteneur(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Détails du séjour',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _textePrincipal,
            ),
          ),
          const SizedBox(height: 14),
          _construireChampDateTuile(
            label: 'Date d’arrivée',
            placeholder: 'Choisir la date d’arrivée',
            date: _dateArrivee,
            icon: Icons.calendar_today_outlined,
            onTap: () => _choisirDate(true),
            onClear: _dateArrivee != null && !_isLoading
                ? () => _effacerDate(true)
                : null,
          ),
          const SizedBox(height: 12),
          _construireChampDateTuile(
            label: 'Date de départ',
            placeholder: 'Choisir la date de départ',
            date: _dateDepart,
            icon: Icons.calendar_month_outlined,
            onTap: () => _choisirDate(false),
            onClear: _dateDepart != null && !_isLoading
                ? () => _effacerDate(false)
                : null,
          ),
          const SizedBox(height: 16),
          const Divider(color: _sableClair, height: 1),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.people_outline,
                    color: _vertSapin,
                    size: 20,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Voyageurs',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _textePrincipal,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  _boutonCompteur(
                    icon: Icons.remove,
                    enabled: peutDiminuer,
                    onPressed: () =>
                        setState(() => _nombrePersonnes--),
                  ),
                  SizedBox(
                    width: 40,
                    child: Text(
                      '$_nombrePersonnes',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _textePrincipal,
                      ),
                    ),
                  ),
                  _boutonCompteur(
                    icon: Icons.add,
                    enabled: peutAugmenter,
                    onPressed: () =>
                        setState(() => _nombrePersonnes++),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _construireResumeTarif(int nombreNuits, double totalEstime) {
    final libelleNuit = nombreNuits > 1 ? 'nuits' : 'nuit';
    final prixUnitaireFormate = _formatPrix(widget.logement.prix);
    final totalFormate = _formatPrix(totalEstime);

    return _carteConteneur(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$prixUnitaireFormate × $nombreNuits $libelleNuit',
                style: const TextStyle(
                  fontSize: 14,
                  color: _texteSecondaire,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                totalFormate,
                style: const TextStyle(
                  fontSize: 14,
                  color: _textePrincipal,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(color: _sableClair, height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total estimé',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _textePrincipal,
                ),
              ),
              Text(
                totalFormate,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: _vertSapin,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _construireSectionDetailsSupplementaires() {
    return _carteConteneur(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informations complémentaires',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _textePrincipal,
            ),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _besoinsController,
            maxLines: 3,
            style: const TextStyle(
              color: _textePrincipal,
              fontSize: 15,
            ),
            decoration: _decorationChamp(
              label: 'Besoins particuliers (facultatif)',
              icon: Icons.tune_outlined,
              iconBottomPadding: 34,
            ),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _messageController,
            maxLines: 4,
            style: const TextStyle(
              color: _textePrincipal,
              fontSize: 15,
            ),
            decoration: _decorationChamp(
              label: 'Message au propriétaire (facultatif)',
              icon: Icons.chat_bubble_outline,
              iconBottomPadding: 50,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nuits = _nombreNuits;
    final total = _totalEstime;

    return Scaffold(
      backgroundColor: _fondCreme,
      appBar: AppBar(
        title: const Text(
          'Réserver un logement',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 19,
          ),
        ),
        backgroundColor: _fondCreme,
        foregroundColor: _vertSapin,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _construireEnTeteLogement(),
                const SizedBox(height: 16),
                _construireSectionSejour(),
                if (nuits != null && total != null) ...[
                  const SizedBox(height: 16),
                  _construireResumeTarif(nuits, total),
                ],
                const SizedBox(height: 16),
                _construireSectionDetailsSupplementaires(),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _envoyerReservation,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.check_circle_outline,
                            size: 20,
                          ),
                    label: Text(
                      _isLoading
                          ? 'Envoi en cours...'
                          : 'Confirmer la réservation',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _vertSapin,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: _vertSauge,
                      disabledForegroundColor: Colors.white,
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
            ),
          ),
        ),
      ),
    );
  }
}