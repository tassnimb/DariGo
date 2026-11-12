
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'mes_reservations_screen.dart';
import '../login_screen.dart';
import 'ajouter_logement_screen.dart';
import '../../models/logement.dart';
import '../../services/logement_service.dart';
import 'logement_detail_screen.dart';
import 'gestion_reservations_screen.dart';
class LogementListScreen extends StatefulWidget {
  const LogementListScreen({super.key});

  @override
  State<LogementListScreen> createState() =>
      _LogementListScreenState();
}

class _LogementListScreenState extends State<LogementListScreen> {
  late Future<List<Logement>> logementsFuture;

  final rechercheController = TextEditingController();

  String role = '';
  String recherche = '';

  RangeValues? selectedRange;
  int ordrePrix = 0;

  bool get isProprietaire => role == 'proprietaire';

  @override
  void initState() {
    super.initState();
    logementsFuture = LogementService.getLogements();
    chargerRole();
  }

  Future<void> chargerRole() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      role = (prefs.getString('role') ?? '').toLowerCase();
    });
  }

  void rechargerLogements() {
    setState(() {
      selectedRange = null;
      logementsFuture = LogementService.getLogements();
    });
  }

  Future<void> ouvrirAjout() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const AjouterLogementScreen(),
      ),
    );

    if (!mounted) return;

    if (result == true) {
      rechargerLogements();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Logement ajouté avec succès !'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  List<Logement> filtrerLogements(
    List<Logement> data,
    RangeValues range,
  ) {
    final resultat = data.where((logement) {
      final texte = recherche.toLowerCase();

      final correspondRecherche =
          logement.titre.toLowerCase().contains(texte) ||
          logement.adresse.toLowerCase().contains(texte);

      final correspondPrix =
          logement.prix >= range.start &&
          logement.prix <= range.end;

      return correspondRecherche && correspondPrix;
    }).toList();

    if (ordrePrix == 1) {
      resultat.sort((a, b) => a.prix.compareTo(b.prix));
    } else if (ordrePrix == 2) {
      resultat.sort((a, b) => b.prix.compareTo(a.prix));
    }

    return resultat;
  }

  void retournerLogin() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
      (route) => false,
    );
  }

  @override
  void dispose() {
    rechercheController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const violet = Color(0xFF6C4AB6);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F6FA),

      appBar: AppBar(
        backgroundColor: violet,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          isProprietaire ? 'Mes logements' : 'Découvrir les logements',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
actions: [
  if (!isProprietaire)
    IconButton(
      tooltip: 'Mes réservations',
      icon: const Icon(Icons.calendar_month),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const MesReservationsScreen(),
          ),
        );
      },
    ),
if (isProprietaire)
  IconButton(
    tooltip: 'Gérer les réservations',
    icon: const Icon(Icons.event_note),
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const GestionReservationsScreen(),
        ),
      );
    },
  ),
  IconButton(
    tooltip: 'Déconnexion',
    onPressed: retournerLogin,
    icon: const Icon(Icons.logout),
  ),
],
      ),

      floatingActionButton: isProprietaire
          ? FloatingActionButton.extended(
              onPressed: ouvrirAjout,
              backgroundColor: violet,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Ajouter'),
            )
          : null,

      body: FutureBuilder<List<Logement>>(
        future: logementsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: violet),
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
                      color: Colors.red,
                      size: 45,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Erreur : ${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 15),
                    ElevatedButton(
                      onPressed: rechargerLogements,
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
                style: TextStyle(fontSize: 17),
              ),
            );
          }

          final prix = data.map((e) => e.prix).toList();

          final minPrix = prix.reduce((a, b) => a < b ? a : b);
          final maxPrix = prix.reduce((a, b) => a > b ? a : b);

          // Évite une plage nulle lorsque tous les prix sont identiques.
          final sliderMax = maxPrix == minPrix
              ? minPrix + 1
              : maxPrix;

          final range = selectedRange ??
              RangeValues(minPrix, sliderMax);

          final logementsFiltres = filtrerLogements(data, range);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final rechercheWidget = TextField(
                      controller: rechercheController,
                      onChanged: (value) {
                        setState(() {
                          recherche = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Rechercher un logement...',
                        prefixIcon: const Icon(
                          Icons.search,
                          color: violet,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    );

                    final filtreWidget = Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Prix (DT)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: violet,
                          ),
                        ),
                        RangeSlider(
                          values: range,
                          min: minPrix,
                          max: sliderMax,
                          divisions: sliderMax > minPrix
                              ? 100
                              : null,
                          activeColor: violet,
                          labels: RangeLabels(
                            range.start.toStringAsFixed(0),
                            range.end.toStringAsFixed(0),
                          ),
                          onChanged: (values) {
                            setState(() {
                              selectedRange = values;
                            });
                          },
                        ),
                        Text(
                          '${range.start.toStringAsFixed(0)} - '
                          '${range.end.toStringAsFixed(0)} DT',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    );

                    if (constraints.maxWidth >= 600) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(child: rechercheWidget),
                          const SizedBox(width: 20),
                          SizedBox(
                            width: 230,
                            child: filtreWidget,
                          ),
                        ],
                      );
                    }

                    return Column(
                      children: [
                        rechercheWidget,
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: SizedBox(
                            width: 230,
                            child: filtreWidget,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(
                      '${logementsFiltres.length} logement(s)',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    DropdownButton<int>(
                      value: ordrePrix,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(
                          value: 0,
                          child: Text('Par défaut'),
                        ),
                        DropdownMenuItem(
                          value: 1,
                          child: Text('Prix croissant'),
                        ),
                        DropdownMenuItem(
                          value: 2,
                          child: Text('Prix décroissant'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          ordrePrix = value ?? 0;
                        });
                      },
                    ),
                  ],
                ),
              ),

              Expanded(
                child: logementsFiltres.isEmpty
                    ? const Center(
                        child: Text(
                          'Aucun logement ne correspond aux filtres',
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 90),
                        itemCount: logementsFiltres.length,
                        itemBuilder: (context, index) {
                          final logement = logementsFiltres[index];

                          return Card(
                            color: Colors.white,
                            elevation: 2,
                            margin: const EdgeInsets.symmetric(
                              vertical: 7,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(15),
                              leading: Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: violet.withOpacity(0.10),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.home_outlined,
                                  color: violet,
                                  size: 30,
                                ),
                              ),
                              title: Text(
                                logement.titre,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(logement.adresse),
                              ),
                              trailing: Text(
                                '${logement.prix.toStringAsFixed(0)} DT',
                                style: const TextStyle(
                                  color: violet,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onTap: () async {
                                final result =
                                    await Navigator.push<bool>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => LogementDetailScreen(
                                      logement: logement,
                                      isProprietaire: isProprietaire,
                                    ),
                                  ),
                                );

                                if (!mounted) return;

                                if (result == true) {
                                  rechargerLogements();
                                }
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
