import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../models/tontine.dart';
import '../models/paiement.dart';
import '../utils/formatage.dart';
import '../widgets/error_state.dart';

class StatistiquesScreen extends StatelessWidget {
  const StatistiquesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // ── Titre ──
              const Text(
                'Statistiques',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 24),

              // ── Stats globales ──
              StreamBuilder<Map<String, dynamic>>(
                stream: FirestoreService().getStats(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF2E9E6E),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return ErrorState(
                      message: 'Impossible de charger les statistiques.',
                      onReessayer: () {},
                    );
                  }

                  final stats = snapshot.data ?? {};
                  final nombreTontines = stats['nombreTontines'] ?? 0;
                  final nombreMembres = stats['nombreMembres'] ?? 0;
                  final totalPaye = stats['totalPaye'] ?? 0.0;
                  final nombrePaies = stats['nombrePaies'] ?? 0;
                  final nombreRetards = stats['nombreRetards'] ?? 0;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Carte principale ──
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF7B2D8B), Color(0xFF2E9E6E)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total collecté',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              Formatage.montant((totalPaye as num).toDouble()),
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildMiniStat(
                                  '$nombreTontines',
                                  'Tontines',
                                  Icons.description_outlined,
                                ),
                                _buildMiniStat(
                                  '$nombreMembres',
                                  'Membres',
                                  Icons.people_outline,
                                ),
                                _buildMiniStat(
                                  '$nombrePaies',
                                  'Paiements',
                                  Icons.check_circle_outline,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ── Taux de paiement ──
                      const Text(
                        'Taux de paiement',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 12),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Payés',
                                  style: TextStyle(fontSize: 15),
                                ),
                                Text(
                                  '$nombrePaies',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2E9E6E),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Barre de progression
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: nombrePaies + nombreRetards > 0
                                    ? nombrePaies /
                                          (nombrePaies + nombreRetards)
                                    : 0,
                                backgroundColor: Colors.red.shade100,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xFF2E9E6E),
                                ),
                                minHeight: 10,
                              ),
                            ),

                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'En retard',
                                  style: TextStyle(fontSize: 15),
                                ),
                                Text(
                                  '$nombreRetards',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ── Tontines récentes ──
                      const Text(
                        'Tontines récentes',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 12),

                      StreamBuilder<List<Tontine>>(
                        stream: FirestoreService().getTontines(),
                        builder: (context, tontinesSnapshot) {
                          final tontines = tontinesSnapshot.data ?? [];

                          if (tontines.isEmpty) {
                            return const Center(
                              child: Text(
                                'Aucune tontine',
                                style: TextStyle(color: Colors.grey),
                              ),
                            );
                          }

                          return Column(
                            children: tontines
                                .take(3)
                                .map((t) => _buildTontineStat(t))
                                .toList(),
                          );
                        },
                      ),

                      const SizedBox(height: 24),

                      // ── Paiements récents ──
                      const Text(
                        'Paiements récents',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 12),

                      StreamBuilder<List<Paiement>>(
                        stream: FirestoreService().getTousPaiements(),
                        builder: (context, paiementsSnapshot) {
                          final paiements = paiementsSnapshot.data ?? [];

                          if (paiements.isEmpty) {
                            return const Center(
                              child: Text(
                                'Aucun paiement',
                                style: TextStyle(color: Colors.grey),
                              ),
                            );
                          }

                          return Column(
                            children: paiements
                                .take(5)
                                .map((p) => _buildPaiementStat(p))
                                .toList(),
                          );
                        },
                      ),

                      const SizedBox(height: 30),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Mini stat pour la carte principale ──
  Widget _buildMiniStat(String valeur, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 4),
        Text(
          valeur,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.white70),
        ),
      ],
    );
  }

  // ── Stat par tontine ──
  Widget _buildTontineStat(Tontine tontine) {
    final membresPayes = tontine.membres.where((m) => m.aPaye).length;
    final totalMembres = tontine.membres.length;
    final progression = totalMembres > 0 ? membresPayes / totalMembres : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                tontine.nom,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '$membresPayes/$totalMembres payés',
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progression,
              backgroundColor: Colors.grey.shade300,
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF2E9E6E),
              ),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            Formatage.montant(tontine.montant) + '/${tontine.frequence}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // ── Stat par paiement ──
  Widget _buildPaiementStat(Paiement paiement) {
    final estPaye = paiement.statut == 'paye';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: estPaye ? const Color(0xFFEFF9F6) : Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: estPaye ? const Color(0xFF2E9E6E) : Colors.red.shade200,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                estPaye ? Icons.check_circle : Icons.cancel,
                color: estPaye ? const Color(0xFF2E9E6E) : Colors.red,
                size: 20,
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    paiement.membreNom,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    paiement.tontineNom,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
          Text(
            Formatage.montant(paiement.montant),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: estPaye ? const Color(0xFF2E9E6E) : Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}
