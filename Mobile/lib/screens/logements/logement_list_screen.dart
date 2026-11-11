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

  @override
  void initState() {
    super.initState();
    logementsFuture = LogementService.getLogements();
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

          final logements = snapshot.data ?? [];

          if (logements.isEmpty) {
            return const Center(
              child: Text(
                "Aucun logement disponible",
              ),
            );
          }

          return ListView.builder(
            itemCount: logements.length,
            itemBuilder: (context, index) {

              final logement = logements[index];
return Card(
  margin: const EdgeInsets.all(10),
  child: ListTile(
    title: Text(logement.titre),
    subtitle: Text(logement.adresse),
    trailing: Text(
      "${logement.prix} DT",
    ),
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LogementDetailScreen(
            logement: logement,
          ),
        ),
      );
    },
  ),
);
            },
          );
        },
      ),
    );
  }
}