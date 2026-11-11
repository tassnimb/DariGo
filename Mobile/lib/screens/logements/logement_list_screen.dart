import 'package:flutter/material.dart';

import 'ajouter_logement_screen.dart';
import '../../models/logement.dart';
import '../../services/logement_service.dart';
import 'logement_detail_screen.dart';

class LogementListScreen extends StatefulWidget {
  const LogementListScreen({super.key});

  @override
  State<LogementListScreen> createState() =>
      _LogementListScreenState();
}

class _LogementListScreenState
    extends State<LogementListScreen> {

  late Future<List<Logement>> logementsFuture;

  List<Logement> logements = [];
  List<Logement> logementsFiltres = [];

  final TextEditingController rechercheController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    logementsFuture = LogementService.getLogements();
  }

 void filtrerLogements(String valeur) {
  setState(() {
    logementsFiltres = logements.where((logement) {

      final titre =
          logement.titre.toLowerCase();

      final adresse =
          logement.adresse.toLowerCase();

      final recherche =
          valeur.toLowerCase();

      return titre.contains(recherche) ||
             adresse.contains(recherche);

    }).toList();
  });
}
void trierPrixCroissant() {
  setState(() {
    logementsFiltres.sort(
      (a, b) => a.prix.compareTo(b.prix),
    );
  });
}

void trierPrixDecroissant() {
  setState(() {
    logementsFiltres.sort(
      (a, b) => b.prix.compareTo(a.prix),
    );
  });
}

  @override
  void dispose() {
    rechercheController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Logements"),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  const AjouterLogementScreen(),
            ),
          );

          setState(() {
            logementsFuture =
                LogementService.getLogements();
            logements.clear();
            logementsFiltres.clear();
          });
        },
        child: const Icon(Icons.add),
      ),

      body: FutureBuilder<List<Logement>>(
        future: logementsFuture,
        builder: (context, snapshot) {

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Erreur : ${snapshot.error}",
              ),
            );
          }

          final data = snapshot.data ?? [];

          if (logements.isEmpty) {
            logements = data;
            logementsFiltres = data;
          }

     if (data.isEmpty) {
  return const Center(
    child: Text(
      "Aucun logement disponible",
    ),
  );
}

          return Column(
            children: [

              Padding(
                padding: const EdgeInsets.all(10),
                child: TextField(
                  controller: rechercheController,
                  onChanged: filtrerLogements,
                  decoration: InputDecoration(
                    hintText:
                        "Rechercher un logement...",
                    prefixIcon:
                        const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
Padding(
  padding: const EdgeInsets.symmetric(
    horizontal: 10,
  ),
  child: Row(
    children: [

      Expanded(
        child: ElevatedButton.icon(
          onPressed: trierPrixCroissant,
          icon: const Icon(Icons.arrow_upward),
          label: const Text("Prix ↑"),
        ),
      ),

      const SizedBox(width: 10),

      Expanded(
        child: ElevatedButton.icon(
          onPressed: trierPrixDecroissant,
          icon: const Icon(Icons.arrow_downward),
          label: const Text("Prix ↓"),
        ),
      ),

    ],
  ),
),

          Expanded(
  child: logementsFiltres.isEmpty
      ? const Center(
          child: Text(
            "🔍 Aucun logement ne correspond à votre recherche",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        )
      : ListView.builder(
                  itemCount:
                      logementsFiltres.length,
                  itemBuilder: (context, index) {

                    final logement =
                        logementsFiltres[index];

                    return Card(
                      margin: const EdgeInsets.all(10),
                      child: ListTile(
                        title:
                            Text(logement.titre),
                        subtitle:
                            Text(logement.adresse),
                        trailing: Text(
                          "${logement.prix} DT",
                        ),
                        onTap: () async {

                          final result =
                              await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  LogementDetailScreen(
                                logement: logement,
                              ),
                            ),
                          );

                          if (result == true) {
                            setState(() {
                              logementsFuture =
                                  LogementService
                                      .getLogements();

                              logements.clear();
                              logementsFiltres
                                  .clear();
                            });
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