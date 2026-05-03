import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String titre;
  final String message;
  final String? boutonTexte;
  final VoidCallback? onBoutonPressed;

  const EmptyState({
    super.key,
    required this.icon,
    required this.titre,
    required this.message,
    this.boutonTexte,
    this.onBoutonPressed,
  });

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
                color: const Color(0xFF90EED4).withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 50, color: const Color(0xFF2E9E6E)),
            ),

            const SizedBox(height: 24),

            // ── Titre ──
            Text(
              titre,
              textAlign: TextAlign.center,
              style: const TextStyle(
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

            // ── Bouton optionnel ──
            if (boutonTexte != null && onBoutonPressed != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onBoutonPressed,
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
                child: Text(boutonTexte!, style: const TextStyle(fontSize: 15)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
