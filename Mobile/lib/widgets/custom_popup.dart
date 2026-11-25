
import 'package:flutter/material.dart';

class CustomPopup {
  static Future<void> showSuccessPopup({
    required BuildContext context,
    required String title,
    required String message,
  }) {
    return _showPopup(
      context: context,
      title: title,
      message: message,
      color: Colors.green,
      icon: Icons.check_circle_outline,
      buttonText: 'OK',
    );
  }

  static Future<void> showErrorPopup({
    required BuildContext context,
    required String title,
    required String message,
  }) {
    return _showPopup(
      context: context,
      title: title,
      message: message,
      color: Colors.red,
      icon: Icons.error_outline,
      buttonText: 'Fermer',
    );
  }

  static Future<void> showWarningPopup({
    required BuildContext context,
    required String title,
    required String message,
  }) {
    return _showPopup(
      context: context,
      title: title,
      message: message,
      color: Colors.orange,
      icon: Icons.warning_amber_rounded,
      buttonText: 'Compris',
    );
  }

  static Future<void> _showPopup({
    required BuildContext context,
    required String title,
    required String message,
    required Color color,
    required IconData icon,
    required String buttonText,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 58),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 12,
                ),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(buttonText),
            ),
          ],
        );
      },
    );
  }

  static Future<bool> showConfirmPopup({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Oui',
    String cancelText = 'Non',
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(title, textAlign: TextAlign.center),
          content: Text(message, textAlign: TextAlign.center),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(cancelText),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(confirmText),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }
}
