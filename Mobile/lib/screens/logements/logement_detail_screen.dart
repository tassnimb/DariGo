import 'package:flutter/material.dart';
import '../../models/logement.dart';

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
          ],
        ),
      ),
    );
  }
}