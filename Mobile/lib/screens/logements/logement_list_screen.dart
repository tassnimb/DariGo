import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/logement.dart';
import '../../services/favori_service.dart';
import '../../services/logement_service.dart';
import '../../services/messagerie_service.dart';
import '../../widgets/custom_popup.dart';
import '../favoris/mes_favoris_screen.dart';
import '../login_screen.dart';
import '../messagerie/conversations_screen.dart';
import 'ajouter_logement_screen.dart';
import 'gestion_reservations_screen.dart';
import 'logement_detail_screen.dart';
import 'mes_reservations_screen.dart';

class LogementListScreen extends StatefulWidget {
  const LogementListScreen({super.key});

  @override
  State<LogementListScreen> createState() =>
      _LogementListScreenState();
}

class _LogementListScreenState extends State<LogementListScreen> {
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

  // ===========================================================================
  // ÉTAT & CONTRÔLEURS
  // ===========================================================================
  late Future<List<Logement>> _logementsFuture;
  final TextEditingController _rechercheController =
      TextEditingController();

  String _role = '';
  String _recherche = '';
  String? _profilePhotoUrl;

  int _categorieActive = 0; // 0: Tout voir, 1: Logements, 2: Populaires
  int _ongletBas = 0; // 0: Explorer, 1: Favoris, 2: Réservations, 3: Messages

  RangeValues? _selectedRange;
  bool _afficherFiltrePrix = false;
  int _ordrePrix = 0;
  int _totalMessagesNonLus = 0;

  final Map<int, int> _favoris = {};
  final Set<int> _favorisEnCours = {};

  bool get _isProprietaire => _role == 'proprietaire';

  static const List<_DestinationItem> _destinationsSuggestion = [
    _DestinationItem(
      nom: 'Tunis',
      sousTitre: 'Cœur de ville & médina',
      icone: Icons.location_city_outlined,
    ),
    _DestinationItem(
      nom: 'La Marsa',
      sousTitre: 'Bord de mer & détente',
      icone: Icons.beach_access_outlined,
    ),
    _DestinationItem(
      nom: 'Sousse',
      sousTitre: 'Ambiance côtière',
      icone: Icons.wb_sunny_outlined,
    ),
    _DestinationItem(
      nom: 'Djerba',
      sousTitre: 'Charme insulaire',
      icone: Icons.villa_outlined,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _logementsFuture = LogementService.getLogements();
    _chargerRole();
    _chargerMessagesNonLus();
  }

  @override
  void dispose() {
    _rechercheController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // CHARGEMENT DES DONNÉES
  // ===========================================================================
  Future<void> _chargerRole() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    final nouveauRole =
        (prefs.getString('role') ?? '').toLowerCase();
    final photo = prefs.getString('profile_photo');

    setState(() {
      _role = nouveauRole;
      _profilePhotoUrl = photo;
    });

    if (nouveauRole != 'proprietaire') {
      await _chargerFavoris();
    }
  }

  Future<void> _chargerMessagesNonLus() async {
    try {
      final liste = await MessagerieService.getConversations();
      int total = 0;

      for (final conversation in liste) {
        if (conversation is! Map) continue;
        final valeur = conversation['messages_non_lus'];
        if (valeur is num) {
          total += valeur.toInt();
        } else {
          total += int.tryParse(valeur?.toString() ?? '') ?? 0;
        }
      }

      if (!mounted) return;
      setState(() => _totalMessagesNonLus = total);
    } catch (e) {
      debugPrint('Erreur chargement messages non lus : $e');
    }
  }

  Future<void> _chargerFavoris() async {
    try {
      final liste = await FavoriService.getFavoris();
      final Map<int, int> nouveauxFavoris = {};

      for (final favori in liste) {
        final favoriId = favori['id'];
        final logement = favori['logement'];

        int? logementId;
        if (logement is Map) {
          logementId = logement['id'] is num
              ? (logement['id'] as num).toInt()
              : int.tryParse('${logement['id']}');
        } else if (logement is num) {
          logementId = logement.toInt();
        } else {
          logementId = int.tryParse('$logement');
        }

        final id = favoriId is num
            ? favoriId.toInt()
            : int.tryParse('$favoriId');

        if (logementId != null && id != null) {
          nouveauxFavoris[logementId] = id;
        }
      }

      if (!mounted) return;
      setState(() {
        _favoris
          ..clear()
          ..addAll(nouveauxFavoris);
      });
    } catch (e) {
      debugPrint('Erreur chargement favoris : $e');
    }
  }

  void _rechargerLogements() {
    setState(() {
      _selectedRange = null;
      _logementsFuture = LogementService.getLogements();
    });
  }

  // ===========================================================================
  // ACTIONS MÉTIER
  // ===========================================================================
  Future<void> _toggleFavori(int logementId) async {
    if (_favorisEnCours.contains(logementId)) return;

    setState(() => _favorisEnCours.add(logementId));

    try {
      if (_favoris.containsKey(logementId)) {
        final favoriId = _favoris[logementId]!;
        final succes = await FavoriService.deleteFavori(favoriId);

        if (succes) {
          if (!mounted) return;
          setState(() => _favoris.remove(logementId));
          await CustomPopup.showSuccessPopup(
            context: context,
            title: 'Favoris',
            message: 'Logement retiré des favoris.',
          );
        }
      } else {
        final succes = await FavoriService.addFavori(logementId);

        if (succes) {
          await _chargerFavoris();
          if (!mounted) return;
          await CustomPopup.showSuccessPopup(
            context: context,
            title: 'Favoris',
            message: 'Logement ajouté aux favoris avec succès !',
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      await CustomPopup.showErrorPopup(
        context: context,
        title: 'Erreur',
        message: 'Erreur lors de la modification du favori.',
      );
    } finally {
      if (mounted) {
        setState(() => _favorisEnCours.remove(logementId));
      }
    }
  }

  Future<void> _ouvrirConversations() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ConversationsScreen(),
      ),
    );
    if (!mounted) return;
    await _chargerMessagesNonLus();
  }

  Future<void> _ouvrirFavorisOuReservations() async {
    if (_isProprietaire) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const GestionReservationsScreen(),
        ),
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const MesFavorisScreen(),
      ),
    );
    if (!mounted) return;
    await _chargerFavoris();
  }

  Future<void> _ouvrirMesReservations() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _isProprietaire
            ? const GestionReservationsScreen()
            : const MesReservationsScreen(),
      ),
    );
  }

  Future<void> _ouvrirAjout() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const AjouterLogementScreen(),
      ),
    );

    if (!mounted) return;

    if (result == true) {
      _rechargerLogements();
      await CustomPopup.showSuccessPopup(
        context: context,
        title: 'Logement ajouté',
        message: 'Votre logement a été ajouté avec succès !',
      );
    }
  }

  List<Logement> _filtrerLogements(
    List<Logement> data,
    RangeValues range,
  ) {
    final texte = _recherche.trim().toLowerCase();

    final resultat = data.where((logement) {
      final correspondRecherche = texte.isEmpty ||
          logement.titre.toLowerCase().contains(texte) ||
          logement.adresse.toLowerCase().contains(texte);

      final correspondPrix =
          logement.prix >= range.start &&
          logement.prix <= range.end;

      final correspondCategorie = _categorieActive != 2 ||
          logement.photos.isNotEmpty;

      return correspondRecherche &&
          correspondPrix &&
          correspondCategorie;
    }).toList();

    if (_ordrePrix == 1) {
      resultat.sort((a, b) => a.prix.compareTo(b.prix));
    } else if (_ordrePrix == 2) {
      resultat.sort((a, b) => b.prix.compareTo(a.prix));
    }

    return resultat;
  }

  Future<void> _retournerLogin() async {
    final confirmer = await CustomPopup.showConfirmPopup(
      context: context,
      title: 'Déconnexion',
      message: 'Voulez-vous vraiment vous déconnecter ?',
      confirmText: 'Déconnexion',
      cancelText: 'Annuler',
    );

    if (!confirmer || !mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
      (route) => false,
    );
  }

  String _formatPrix(double montant) {
    return montant % 1 == 0
        ? '${montant.toStringAsFixed(0)} DT'
        : '${montant.toStringAsFixed(2)} DT';
  }

  // ===========================================================================
  // COMPOSANTS UI
  // ===========================================================================
  Widget _construireBarreRechercheEtFiltres({
    required double minPrix,
    required double sliderMax,
    required RangeValues range,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Barre de recherche flottante type capsule
          Container(
            decoration: BoxDecoration(
              color: _surfaceClaire,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: _sableClair),
              boxShadow: [
                BoxShadow(
                  color: _vertSapin.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _rechercheController,
              style: const TextStyle(
                color: _textePrincipal,
                fontWeight: FontWeight.w500,
              ),
              onChanged: (value) => setState(() => _recherche = value),
              decoration: InputDecoration(
                hintText: 'Commencer ma recherche',
                hintStyle: const TextStyle(
                  color: _textePrincipal,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: _vertSapin,
                  size: 22,
                ),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_recherche.isNotEmpty)
                      IconButton(
                        tooltip: 'Effacer',
                        icon: const Icon(
                          Icons.close,
                          color: _texteSecondaire,
                          size: 18,
                        ),
                        onPressed: () {
                          _rechercheController.clear();
                          setState(() => _recherche = '');
                        },
                      ),
                    IconButton(
                      tooltip: 'Filtrer par prix',
                      icon: Icon(
                        Icons.tune_rounded,
                        color: _afficherFiltrePrix
                            ? _vertSapin
                            : _brunTerre,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(
                          () => _afficherFiltrePrix = !_afficherFiltrePrix,
                        );
                      },
                    ),
                  ],
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Onglets rapides horizontaux (Tout voir / Logements / Populaires)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _PuceCategorie(
                  label: 'Tout voir',
                  icon: Icons.public,
                  selected: _categorieActive == 0,
                  onTap: () => setState(() => _categorieActive = 0),
                ),
                const SizedBox(width: 10),
                _PuceCategorie(
                  label: 'Logements',
                  icon: Icons.home_work_outlined,
                  selected: _categorieActive == 1,
                  onTap: () => setState(() => _categorieActive = 1),
                ),
                const SizedBox(width: 10),
                _PuceCategorie(
                  label: 'Avec photos',
                  icon: Icons.photo_library_outlined,
                  selected: _categorieActive == 2,
                  onTap: () => setState(() => _categorieActive = 2),
                ),
              ],
            ),
          ),

          // Panneau filtre prix (affiché au clic sur l'icône filtre)
          if (_afficherFiltrePrix) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
              decoration: BoxDecoration(
                color: _surfaceClaire,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _sableClair),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Fourchette de prix (DT)',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: _vertSapin,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        '${range.start.toStringAsFixed(0)} - ${range.end.toStringAsFixed(0)} DT',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _texteSecondaire,
                        ),
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: _vertSapin,
                      inactiveTrackColor: _sableClair,
                      thumbColor: _vertSapin,
                      overlayColor: _vertSapin.withValues(alpha: 0.12),
                      valueIndicatorColor: _vertSapin,
                    ),
                    child: RangeSlider(
                      values: range,
                      min: minPrix,
                      max: sliderMax,
                      divisions: sliderMax > minPrix ? 100 : null,
                      labels: RangeLabels(
                        range.start.toStringAsFixed(0),
                        range.end.toStringAsFixed(0),
                      ),
                      onChanged: (values) {
                        setState(() => _selectedRange = values);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _construireSectionDestinations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 10),
          child: Text(
            'Destinations pour vous',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _textePrincipal,
            ),
          ),
        ),
        SizedBox(
          height: 158,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _destinationsSuggestion.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, index) {
              final dest = _destinationsSuggestion[index];
              final actif =
                  _recherche.trim().toLowerCase() ==
                      dest.nom.toLowerCase();

              return InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () {
                  final nouveauTexte = actif ? '' : dest.nom;
                  _rechercheController.text = nouveauTexte;
                  setState(() => _recherche = nouveauTexte);
                },
                child: SizedBox(
                  width: 124,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 104,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: actif ? _vertSapin : _surfaceClaire,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: actif ? _vertSapin : _sableClair,
                            width: actif ? 1.5 : 1,
                          ),
                        ),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: actif
                                  ? Colors.white.withValues(alpha: 0.16)
                                  : _sableClair,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              dest.icone,
                              size: 28,
                              color:
                                  actif ? Colors.white : _vertSapin,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        dest.nom,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: _textePrincipal,
                        ),
                      ),
                      Text(
                        dest.sousTitre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: _texteSecondaire,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _construireTitreSectionLogements(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _isProprietaire
                  ? 'Mes logements ($count)'
                  : 'Logements populaires ($count)',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _textePrincipal,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: _surfaceClaire,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _sableClair),
            ),
            child: DropdownButton<int>(
              value: _ordrePrix,
              underline: const SizedBox(),
              icon: const Icon(
                Icons.arrow_forward,
                size: 16,
                color: _vertSapin,
              ),
              style: const TextStyle(
                color: _textePrincipal,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              items: const [
                DropdownMenuItem(value: 0, child: Text('Tri')),
                DropdownMenuItem(
                  value: 1,
                  child: Text('Prix ↑'),
                ),
                DropdownMenuItem(
                  value: 2,
                  child: Text('Prix ↓'),
                ),
              ],
              onChanged: (value) {
                setState(() => _ordrePrix = value ?? 0);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _construireCarteGrille(Logement logement) {
    final estFavori = _favoris.containsKey(logement.id);
    final chargement = _favorisEnCours.contains(logement.id);
    final photoPrincipale =
        logement.photos.isNotEmpty ? logement.photos.first : null;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () async {
        final result = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => LogementDetailScreen(
              logement: logement,
              isProprietaire: _isProprietaire,
            ),
          ),
        );

        if (!mounted) return;
        if (result == true) {
          _rechargerLogements();
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image carrée arrondie avec badge en haut à gauche et cœur en haut à droite
          AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (photoPrincipale != null)
                    Image.network(
                      photoPrincipale,
                      fit: BoxFit.cover,
                      loadingBuilder: (_, child, progress) {
                        if (progress == null) return child;
                        return const ColoredBox(
                          color: _sableClair,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: _vertSapin,
                              strokeWidth: 2,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (_, __, ___) => const ColoredBox(
                        color: _sableClair,
                        child: Icon(
                          Icons.home_work_outlined,
                          color: _vertSapin,
                          size: 40,
                        ),
                      ),
                    )
                  else
                    const ColoredBox(
                      color: _sableClair,
                      child: Icon(
                        Icons.home_work_outlined,
                        color: _vertSapin,
                        size: 40,
                      ),
                    ),

                  // Badge type maquette
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: _surfaceClaire.withValues(alpha: 0.94),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: _sableClair),
                      ),
                      child: const Text(
                        'Coup de cœur',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _vertSapin,
                        ),
                      ),
                    ),
                  ),

                  // Bouton favori en haut à droite
                  if (!_isProprietaire)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Material(
                        color: _vertSapin.withValues(alpha: 0.45),
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: chargement
                              ? null
                              : () => _toggleFavori(logement.id),
                          child: SizedBox(
                            width: 34,
                            height: 34,
                            child: Center(
                              child: chargement
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child:
                                          CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Icon(
                                      estFavori
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color: estFavori
                                          ? _rougeErreur
                                          : Colors.white,
                                      size: 19,
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          Text(
            logement.titre,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: _textePrincipal,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            logement.adresse,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: _texteSecondaire,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _formatPrix(logement.prix),
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: _vertSapin,
            ),
          ),
        ],
      ),
    );
  }

  Widget _construireBarreNavigationBas() {
    return Container(
      decoration: const BoxDecoration(
        color: _surfaceClaire,
        border: Border(
          top: BorderSide(color: _sableClair),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ItemBarreBas(
                label: 'Explorer',
                icon: Icons.search,
                actif: _ongletBas == 0,
                onTap: () => setState(() => _ongletBas = 0),
              ),
              _ItemBarreBas(
                label: _isProprietaire ? 'Réservations' : 'Favoris',
                icon: _isProprietaire
                    ? Icons.event_note_outlined
                    : Icons.favorite_border,
                actif: _ongletBas == 1,
                onTap: () async {
                  setState(() => _ongletBas = 1);
                  await _ouvrirFavorisOuReservations();
                  if (!mounted) return;
                  setState(() => _ongletBas = 0);
                },
              ),
              if (!_isProprietaire)
                _ItemBarreBas(
                  label: 'Séjours',
                  icon: Icons.calendar_month_outlined,
                  actif: _ongletBas == 2,
                  onTap: () async {
                    setState(() => _ongletBas = 2);
                    await _ouvrirMesReservations();
                    if (!mounted) return;
                    setState(() => _ongletBas = 0);
                  },
                ),
              _ItemBarreBas(
                label: 'Messages',
                icon: Icons.chat_bubble_outline,
                actif: _ongletBas == 3,
                badge: _totalMessagesNonLus,
                onTap: () async {
                  setState(() => _ongletBas = 3);
                  await _ouvrirConversations();
                  if (!mounted) return;
                  setState(() => _ongletBas = 0);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _fondCreme,
      appBar: AppBar(
        backgroundColor: _fondCreme,
        foregroundColor: _vertSapin,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'DariGo',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 22,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: CircleAvatar(
              radius: 17,
              backgroundColor: _sableClair,
              child: ClipOval(
                child: _profilePhotoUrl != null &&
                        _profilePhotoUrl!.isNotEmpty
                    ? Image.network(
                        _profilePhotoUrl!,
                        width: 34,
                        height: 34,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.person_outline,
                          color: _vertSapin,
                          size: 20,
                        ),
                      )
                    : const Icon(
                        Icons.person_outline,
                        color: _vertSapin,
                        size: 20,
                      ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Déconnexion',
            onPressed: _retournerLogin,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      floatingActionButton: _isProprietaire
          ? FloatingActionButton.extended(
              onPressed: _ouvrirAjout,
              backgroundColor: _vertSapin,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text(
                'Ajouter',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            )
          : null,
      bottomNavigationBar: _construireBarreNavigationBas(),
      body: SafeArea(
        child: FutureBuilder<List<Logement>>(
          future: _logementsFuture,
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
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: _rougeErreur,
                        size: 44,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Erreur : ${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: _textePrincipal,
                        ),
                      ),
                      const SizedBox(height: 14),
                      ElevatedButton(
                        onPressed: _rechargerLogements,
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

            final data = snapshot.data ?? [];

            if (data.isEmpty) {
              return const Center(
                child: Text(
                  'Aucun logement disponible',
                  style: TextStyle(
                    fontSize: 17,
                    color: _texteSecondaire,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }

            final prix = data.map((e) => e.prix).toList();
            final minPrix = prix.reduce((a, b) => a < b ? a : b);
            final maxPrix = prix.reduce((a, b) => a > b ? a : b);
            final sliderMax = maxPrix == minPrix ? minPrix + 1 : maxPrix;
            final range =
                _selectedRange ?? RangeValues(minPrix, sliderMax);

            final logementsFiltres = _filtrerLogements(data, range);

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _construireBarreRechercheEtFiltres(
                    minPrix: minPrix,
                    sliderMax: sliderMax,
                    range: range,
                  ),
                ),
                SliverToBoxAdapter(
                  child: _construireSectionDestinations(),
                ),
                SliverToBoxAdapter(
                  child: _construireTitreSectionLogements(
                    logementsFiltres.length,
                  ),
                ),
                if (logementsFiltres.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Aucun logement ne correspond aux filtres',
                          style: TextStyle(color: _texteSecondaire),
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 92),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 18,
                        childAspectRatio: 0.72,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (_, index) =>
                            _construireCarteGrille(logementsFiltres[index]),
                        childCount: logementsFiltres.length,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// =============================================================================
// SOUS-COMPOSANTS
// =============================================================================
class _DestinationItem {
  final String nom;
  final String sousTitre;
  final IconData icone;

  const _DestinationItem({
    required this.nom,
    required this.sousTitre,
    required this.icone,
  });
}

class _PuceCategorie extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _PuceCategorie({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? _LogementListScreenState._vertSapin
              : _LogementListScreenState._surfaceClaire,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? _LogementListScreenState._vertSapin
                : _LogementListScreenState._sableClair,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 17,
              color: selected
                  ? Colors.white
                  : _LogementListScreenState._vertSapin,
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: selected
                    ? Colors.white
                    : _LogementListScreenState._textePrincipal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemBarreBas extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool actif;
  final int badge;
  final VoidCallback onTap;

  const _ItemBarreBas({
    required this.label,
    required this.icon,
    required this.actif,
    this.badge = 0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final couleur = actif
        ? _LogementListScreenState._vertSapin
        : _LogementListScreenState._texteSecondaire;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: couleur, size: 22),
                if (badge > 0)
                  Positioned(
                    right: -8,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: const BoxDecoration(
                        color: _LogementListScreenState._rougeErreur,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        badge > 99 ? '99+' : badge.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: actif ? FontWeight.w700 : FontWeight.w500,
                color: couleur,
              ),
            ),
          ],
        ),
      ),
    );
  }
}