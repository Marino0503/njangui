import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../services/firestore_service.dart';
import '../models/tontine.dart';
import 'login_screen.dart';
import '../utils/formatage.dart';

class ProfilScreen extends StatelessWidget {
  const ProfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: StreamBuilder<Map<String, dynamic>?>(
          stream: UserService().getProfilStream(),
          builder: (context, profilSnapshot) {
            if (profilSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF2E9E6E)),
              );
            }

            final profil = profilSnapshot.data;
            final nom = profil?['nom'] ?? 'Utilisateur';
            final telephone = profil?['telephone'] ?? '';

            return StreamBuilder<List<Tontine>>(
              stream: FirestoreService().getTontines(),
              builder: (context, tontinesSnapshot) {
                // Compte les tontines actives
                final tontines = tontinesSnapshot.data ?? [];
                final nombreTontines = tontines.length;

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 30),

                      // ── Titre ──
                      const Text(
                        'Mon Profil',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 30),

                      // ── Photo de profil ──
                      Stack(
                        children: [
                          const CircleAvatar(
                            radius: 60,
                            backgroundColor: Color(0xFF90EED4),
                            child: Icon(
                              Icons.person,
                              size: 70,
                              color: Colors.white,
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Color(0xFF7B2D8B),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.edit,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // ── Nom ──
                      Text(
                        nom,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 6),

                      // ── Numéro ──
                      Text(
                        telephone,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),

                      const SizedBox(height: 40),

                      // ── Informations ──
                      _buildInfoTile(
                        icon: Icons.person_outline,
                        titre: 'Nom complet',
                        valeur: nom,
                      ),
                      _buildInfoTile(
                        icon: Icons.phone_outlined,
                        titre: 'Téléphone',
                        valeur: Formatage.telephone(telephone),
                      ),
                      // ── Tontines actives depuis Firestore ──
                      _buildInfoTile(
                        icon: Icons.groups_outlined,
                        titre: 'Tontines actives',
                        valeur: nombreTontines.toString(),
                      ),

                      const SizedBox(height: 40),

                      // ── Bouton déconnexion ──
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final confirmer = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Déconnexion'),
                                content: const Text(
                                  'Voulez-vous vraiment vous déconnecter ?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Annuler'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text(
                                      'Déconnecter',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            );

                            if (confirmer == true) {
                              await UserService().deconnecter();

                              if (!context.mounted) return;

                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LoginScreen(),
                                ),
                                (route) => false,
                              );
                            }
                          },
                          icon: const Icon(Icons.logout),
                          label: const Text(
                            'Se déconnecter',
                            style: TextStyle(fontSize: 16),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade400,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String titre,
    required String valeur,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF7B2D8B), size: 22),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titre,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(
                valeur,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
