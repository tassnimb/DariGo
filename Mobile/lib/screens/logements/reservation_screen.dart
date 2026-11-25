
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
  static const violet = Color(0xFF6C4AB6);

  final _formKey = GlobalKey<FormState>();

  final TextEditingController besoinsController =
      TextEditingController();

  final TextEditingController messageController =
      TextEditingController();

  DateTime? dateArrivee;
  DateTime? dateDepart;

  int nombrePersonnes = 1;
  bool isLoading = false;

  @override
  void dispose() {
    besoinsController.dispose();
    messageController.dispose();
    super.dispose();
  }

  String formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  Future<void> choisirDate(bool arrivee) async {
    final aujourdHui = DateTime.now();

    final date = await showDatePicker(
      context: context,
      initialDate: arrivee
          ? (dateArrivee != null &&
                  !dateArrivee!.isBefore(DateTime(
                    aujourdHui.year,
                    aujourdHui.month,
                    aujourdHui.day,
                  ))
              ? dateArrivee!
              : aujourdHui)
          : (dateDepart ?? dateArrivee ?? aujourdHui),
      firstDate: DateTime(
        aujourdHui.year,
        aujourdHui.month,
        aujourdHui.day,
      ),
      lastDate: DateTime(2030),
    );

    if (date == null) return;

    setState(() {
      if (arrivee) {
        dateArrivee = date;

        if (dateDepart != null &&
            !dateDepart!.isAfter(date)) {
          dateDepart = null;
        }
      } else {
        dateDepart = date;
      }
    });
  }

  Future<void> envoyerReservation() async {
    if (!_formKey.currentState!.validate()) return;

    if (dateArrivee == null || dateDepart == null) {
      await CustomPopup.showWarningPopup(
        context: context,
        title: 'Dates manquantes',
        message: 'Veuillez choisir les deux dates.',
      );
      return;
    }

    if (!dateDepart!.isAfter(dateArrivee!)) {
      await CustomPopup.showWarningPopup(
        context: context,
        title: 'Dates invalides',
        message:
            'La date de départ doit être après la date d’arrivée.',
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await ReservationService.addReservation(
        logementId: widget.logement.id,
        dateArrivee: formatDate(dateArrivee!),
        dateDepart: formatDate(dateDepart!),
        nombrePersonnes: nombrePersonnes,
        besoins: besoinsController.text.trim(),
        message: messageController.text.trim(),
      );

      if (!mounted) return;

      await CustomPopup.showSuccessPopup(
        context: context,
        title: 'Réservation envoyée',
        message: 'Votre réservation a été envoyée avec succès !',
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      final erreur = e.toString().toLowerCase();

      debugPrint('ERREUR RESERVATION : $e');

final logementOccupe =
    erreur.contains('déjà réservé') ||
    erreur.contains('deja reserve') ||
    erreur.contains('already reserved') ||
    erreur.contains('already booked') ||
    erreur.contains('indisponible') ||
    erreur.contains('not available') ||
    erreur.contains('overlap') ||
    erreur.contains('chevauchement') ||
    erreur.contains('n\'est pas disponible') ||
    erreur.contains('pas disponible');

      if (logementOccupe) {
        await CustomPopup.showErrorPopup(
          context: context,
          title: 'Logement déjà réservé',
          message:
              'Ce logement est déjà réservé pour cette période. '
              'Veuillez choisir d’autres dates.',
        );
      } else {
        await CustomPopup.showErrorPopup(
          context: context,
          title: 'Réservation impossible',
          message:
              'Une erreur est survenue lors de la réservation. '
              'Veuillez réessayer.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
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
        title: const Text('Réserver un logement'),
        backgroundColor: violet,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                logement.titre,
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                '${logement.prix.toStringAsFixed(0)} DT',
                style: const TextStyle(
                  fontSize: 20,
                  color: violet,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 25),

              const Text(
                'Date d’arrivée',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => choisirDate(true),
                  icon: const Icon(Icons.calendar_today),
                  label: Text(
                    dateArrivee == null
                        ? 'Choisir la date d’arrivée'
                        : formatDate(dateArrivee!),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              const Text(
                'Date de départ',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => choisirDate(false),
                  icon: const Icon(Icons.calendar_month),
                  label: Text(
                    dateDepart == null
                        ? 'Choisir la date de départ'
                        : formatDate(dateDepart!),
                  ),
                ),
              ),

              const SizedBox(height: 22),

              const Text(
                'Nombre de personnes',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              Row(
                children: [
                  IconButton(
                    onPressed: nombrePersonnes > 1
                        ? () {
                            setState(() {
                              nombrePersonnes--;
                            });
                          }
                        : null,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Text(
                    '$nombrePersonnes',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: nombrePersonnes < 20
                        ? () {
                            setState(() {
                              nombrePersonnes++;
                            });
                          }
                        : null,
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              TextFormField(
                controller: besoinsController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Besoins particuliers (facultatif)',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),

              const SizedBox(height: 18),

              TextFormField(
                controller: messageController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Message au propriétaire (facultatif)',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),

              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed:
                      isLoading ? null : envoyerReservation,
                  icon: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send),
                  label: Text(
                    isLoading
                        ? 'Envoi en cours...'
                        : 'Confirmer la réservation',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: violet,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
