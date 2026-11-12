
import 'package:flutter/material.dart';

import '../../models/logement.dart';
import '../../services/logement_service.dart';
import 'modifier_logement_screen.dart';
import 'reservation_screen.dart';

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

  static const violet = Color(0xFF6C4AB6);

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

  Future<void> supprimerLogement() async {
    final confirmer = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer le logement'),
        content: const Text(
          'Voulez-vous vraiment supprimer ce logement ?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext, false);
            },
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(dialogContext, true);
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmer != true || !mounted) return;

    setState(() {
      isDeleting = true;
    });

    try {
      final success = await LogementService.deleteLogement(
        widget.logement.id,
      );

      if (!mounted) return;

      if (success) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la suppression'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isDeleting = false;
        });
      }
    }
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
            Container(
              width: double.infinity,
              height: 190,
              decoration: BoxDecoration(
                color: violet.withOpacity(0.10),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.home_work_outlined,
                color: violet,
                size: 85,
              ),
            ),

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
                color: violet.withOpacity(0.10),
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

            if (!widget.isProprietaire) ...[
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: reserverLogement,
                  icon: const Icon(Icons.calendar_month),
                  label: const Text('Réserver ce logement'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: violet,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(15),
                  ),
                ),
              ),
            ],

            if (widget.isProprietaire) ...[
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: modifierLogement,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Modifier le logement'),
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
                  onPressed: isDeleting ? null : supprimerLogement,
                  icon: const Icon(Icons.delete_outline),
                  label: Text(
                    isDeleting
                        ? 'Suppression...'
                        : 'Supprimer le logement',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
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
