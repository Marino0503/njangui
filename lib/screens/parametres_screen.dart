import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

class ParametresScreen extends StatelessWidget {
  const ParametresScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        final textes = provider.textes;

        return Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // ── Titre ──
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(
                          Icons.arrow_back_ios,
                          color: Color(0xFF7B2D8B),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        textes['parametres']!,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // ── Section Langue ──
                  _buildSectionTitre(textes['langue']!),
                  const SizedBox(height: 12),

                  // ── Français ──
                  _buildTileLangue(
                    context: context,
                    langue: 'fr',
                    nom: 'Français',
                    drapeau: '🇫🇷',
                    selectionne: provider.langue == 'fr',
                    onTap: () => provider.changerLangue('fr'),
                  ),

                  const SizedBox(height: 8),

                  // ── English ──
                  _buildTileLangue(
                    context: context,
                    langue: 'en',
                    nom: 'English',
                    drapeau: '🇬🇧',
                    selectionne: provider.langue == 'en',
                    onTap: () => provider.changerLangue('en'),
                  ),

                  const SizedBox(height: 24),

                  // ── Section À propos ──
                  _buildSectionTitre(textes['apropos']!),
                  const SizedBox(height: 12),

                  _buildTile(
                    context: context,
                    icon: Icons.info_outline,
                    titre: '${textes['version']} 1.0.0',
                    trailing: const SizedBox(),
                  ),

                  _buildTile(
                    context: context,
                    icon: Icons.description_outlined,
                    titre: textes['conditionsUtilisation']!,
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey,
                    ),
                    onTap: () {},
                  ),

                  _buildTile(
                    context: context,
                    icon: Icons.privacy_tip_outlined,
                    titre: textes['politiqueConfidentialite']!,
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey,
                    ),
                    onTap: () {},
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitre(String titre) {
    return Text(
      titre,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Color(0xFF7B2D8B),
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildTile({
    required BuildContext context,
    required IconData icon,
    required String titre,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF7B2D8B), size: 22),
            const SizedBox(width: 16),
            Expanded(child: Text(titre, style: const TextStyle(fontSize: 15))),
            trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildTileLangue({
    required BuildContext context,
    required String langue,
    required String nom,
    required String drapeau,
    required bool selectionne,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selectionne
              ? const Color(0xFF7B2D8B).withValues(alpha: 0.1)
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selectionne
                ? const Color(0xFF7B2D8B)
                : Colors.grey.withValues(alpha: 0.2),
            width: selectionne ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(drapeau, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                nom,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: selectionne ? FontWeight.bold : FontWeight.normal,
                  color: selectionne ? const Color(0xFF7B2D8B) : null,
                ),
              ),
            ),
            if (selectionne)
              const Icon(Icons.check_circle, color: Color(0xFF7B2D8B)),
          ],
        ),
      ),
    );
  }
}
