import 'package:flutter/material.dart';

class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onReessayer;

  const ErrorState({super.key, required this.message, this.onReessayer});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── Icône ──
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                size: 50,
                color: Colors.red,
              ),
            ),

            const SizedBox(height: 24),

            // ── Titre ──
            const Text(
              'Une erreur est survenue',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 8),

            // ── Message ──
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),

            // ── Bouton réessayer ──
            if (onReessayer != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onReessayer,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E9E6E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 12,
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
