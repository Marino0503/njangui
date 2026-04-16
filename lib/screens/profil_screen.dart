import 'package:flutter/material.dart';

class ProfilScreen extends StatelessWidget {
  const ProfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 30),

              // ── Titre ──
              const Text(
                'Mon Profil',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 30),

              // ── Photo de profil ──
              Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: const Color(0xFF90EED4),
                    child: const Icon(
                      Icons.person,
                      size: 70,
                      color: Colors.white,
                    ),
                  ),
                  // Bouton modifier photo
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
              const Text(
                'Mégane',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 6),

              // ── Numéro ──
              const Text(
                '+237 658 834 387',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),

              const SizedBox(height: 40),

              // ── Informations ──
              _buildInfoTile(
                icon: Icons.person_outline,
                titre: 'Nom complet',
                valeur: 'Mégane Dupont',
              ),
              _buildInfoTile(
                icon: Icons.phone_outlined,
                titre: 'Téléphone',
                valeur: '+237 658 834 387',
              ),
              _buildInfoTile(
                icon: Icons.calendar_today_outlined,
                titre: 'Membre depuis',
                valeur: 'Janvier 2024',
              ),
              _buildInfoTile(
                icon: Icons.groups_outlined,
                titre: 'Tontines actives',
                valeur: '2',
              ),

              const SizedBox(height: 40),

              // ── Bouton déconnexion ──
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // TODO: déconnexion Firebase
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
        ),
      ),
    );
  }

  // ── Widget réutilisable pour chaque ligne d'info ──
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
