import 'package:flutter/material.dart';
import '../../models/logement.dart';
import 'modifier_logement_screen.dart';
import '../../services/logement_service.dart';
class LogementDetailScreen extends StatelessWidget {
  final Logement logement;

  const LogementDetailScreen({
    super.key,
    required this.logement,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(logement.titre),
      ),  floatingActionButton: FloatingActionButton(
    child: const Icon(Icons.edit),
  onPressed: () async {
  final result = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ModifierLogementScreen(
        logement: logement,
      ),
    ),
  );

  if (result == true) {
    Navigator.pop(context, true);
  }
},
  ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              logement.titre,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            Text(
              "Adresse : ${logement.adresse}",
            ),

            const SizedBox(height: 10),

            Text(
              "Prix : ${logement.prix} DT",
            ),

            const SizedBox(height: 15),

            const Text(
              "Description",
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

           Text(logement.description),

const SizedBox(height: 30),

SizedBox(
  width: double.infinity,
  child: ElevatedButton(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.red,
    ),
    onPressed: () async {
      bool success =
          await LogementService.deleteLogement(
        logement.id,
      );

      if (!context.mounted) return;

      if (success) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              "Logement supprimé ✅",
            ),
          ),
        );

        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              "Erreur suppression ❌",
            ),
          ),
        );
      }
    },
    child: const Text("Supprimer"),
  ),
),
          ],
        ),
      ),
    );
  }
}