import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/notification_service.dart';
import '../services/user_service.dart';
import 'conditions_utilisation_screen.dart';
import 'login_screen.dart';
import 'politique_confidentialite_screen.dart';

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

                  // ── Section Test notifications ──
                  _buildSectionTitre(
                    provider.langue == 'fr' ? 'Notifications' : 'Notifications',
                  ),

                  const SizedBox(height: 12),

                  _buildTile(
                    context: context,
                    icon: Icons.notifications_active_outlined,
                    titre: provider.langue == 'fr'
                        ? 'Tester les notifications'
                        : 'Test notifications',
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey,
                    ),
                    onTap: () async {
                      await NotificationService().envoyerNotification(
                        id: 1,
                        titre: provider.langue == 'fr'
                            ? '🔔 Test Njangi'
                            : '🔔 Njangi Test',
                        message: provider.langue == 'fr'
                            ? 'Les notifications fonctionnent correctement !'
                            : 'Notifications are working correctly!',
                      );
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            provider.langue == 'fr'
                                ? 'Notification envoyée !'
                                : 'Notification sent!',
                          ),
                          backgroundColor: const Color(0xFF2E9E6E),
                        ),
                      );
                    },
                  ),

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
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const ConditionsUtilisationScreen(),
                        ),
                      );
                    },
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
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const PolitiqueConfidentialiteScreen(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // ── Section Compte (zone dangereuse) ──
                  _buildSectionTitre(textes['compte']!),
                  const SizedBox(height: 12),

                  _buildTile(
                    context: context,
                    icon: Icons.delete_forever_outlined,
                    titre: textes['supprimerCompte']!,
                    titreColor: Colors.red,
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey,
                    ),
                    onTap: () => _confirmerSuppressionCompte(context, provider),
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

  // Demande confirmation puis supprime le compte (voir Cloud Function
  // supprimerCompte dans functions/index.js).
  Future<void> _confirmerSuppressionCompte(
    BuildContext context,
    AppProvider provider,
  ) async {
    final textes = provider.textes;

    final confirmer = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(textes['confirmSuppressionCompteTitre']!),
        content: Text(textes['confirmSuppressionCompteMessage']!),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(textes['annuler']!),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              textes['supprimerCompte']!,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmer != true || !context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(color: Color(0xFF7B2D8B)),
            const SizedBox(width: 20),
            Expanded(child: Text(textes['suppressionEnCours']!)),
          ],
        ),
      ),
    );

    try {
      await UserService().supprimerCompte();

      if (!context.mounted) return;
      Navigator.pop(context); // ferme le dialogue de chargement

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    } on FirebaseFunctionsException catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context); // ferme le dialogue de chargement

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(textes['erreur']!),
          content: Text(e.message ?? textes['erreur']!),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context); // ferme le dialogue de chargement

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(textes['erreur']!),
          content: Text('$e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
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
    Color? titreColor,
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
            Icon(icon, color: titreColor ?? const Color(0xFF7B2D8B), size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                titre,
                style: TextStyle(fontSize: 15, color: titreColor),
              ),
            ),
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
