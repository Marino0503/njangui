import 'package:flutter/material.dart';
import '../models/paiement.dart';
import '../models/tontine.dart';
import '../services/firestore_service.dart';
import '../services/recu_service.dart';
import '../utils/formatage.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_state.dart';

class HistoriquePaiementsScreen extends StatelessWidget {
  final Tontine tontine;

  const HistoriquePaiementsScreen({super.key, required this.tontine});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            // ── Bouton retour + Titre ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Row(
                  children: [
                    const Icon(
                      Icons.arrow_back_ios,
                      color: Color(0xFF7B2D8B),
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Historique - ${tontine.nom}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF7B2D8B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Résumé ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: StreamBuilder<List<Paiement>>(
                stream: FirestoreService().getPaiements(tontine.id),
                builder: (context, snapshot) {
                  final paiements = snapshot.data ?? [];
                  final totalPaye = paiements
                      .where((p) => p.statut == 'paye')
                      .fold(0.0, (sum, p) => sum + p.montant);
                  final nombrePaies = paiements
                      .where((p) => p.statut == 'paye')
                      .length;
                  final nombreRetards = paiements
                      .where((p) => p.statut == 'en_retard')
                      .length;

                  return Row(
                    children: [
                      // Total payé
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E9E6E),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Total payé',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                Formatage.montant(totalPaye),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Paiements
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF90EED4),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Paiements',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$nombrePaies payés',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Retards
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Retards',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$nombreRetards retard(s)',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // ── Titre liste ──
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Tous les paiements',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 12),

            // ── Liste des paiements ──
            Expanded(
              child: StreamBuilder<List<Paiement>>(
                stream: FirestoreService().getPaiements(tontine.id),
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
                      message: 'Impossible de charger les paiements.',
                      onReessayer: () {},
                    );
                  }

                  final paiements = snapshot.data ?? [];

                  if (paiements.isEmpty) {
                    return const EmptyState(
                      icon: Icons.payment_outlined,
                      titre: 'Aucun paiement',
                      message:
                          'Les paiements apparaîtront ici\nquand les membres cotiseront.',
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: paiements.length,
                    itemBuilder: (context, index) {
                      return _buildPaiementTile(context, paiements[index]);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaiementTile(BuildContext context, Paiement paiement) {
    final estPaye = paiement.statut == 'paye';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: estPaye ? const Color(0xFFEFF9F6) : Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: estPaye ? const Color(0xFF2E9E6E) : Colors.red.shade200,
        ),
      ),
      child: Row(
        children: [
          // ── Icône ──
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: estPaye ? const Color(0xFF2E9E6E) : Colors.red,
              shape: BoxShape.circle,
            ),
            child: Icon(
              estPaye ? Icons.check : Icons.close,
              color: Colors.white,
              size: 22,
            ),
          ),

          const SizedBox(width: 14),

          // ── Infos ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  paiement.membreNom,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  Formatage.date(paiement.date),
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          ),

          // ── Montant ──
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                Formatage.montant(paiement.montant),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: estPaye ? const Color(0xFF2E9E6E) : Colors.red,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: estPaye ? const Color(0xFF2E9E6E) : Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  estPaye ? 'Payé' : 'En retard',
                  style: const TextStyle(fontSize: 11, color: Colors.white),
                ),
              ),
            ],
          ),

          // ── Reçu (uniquement pour les paiements confirmés) ──
          if (estPaye)
            IconButton(
              onPressed: () => _partagerRecu(context, paiement),
              icon: const Icon(
                Icons.receipt_long_outlined,
                color: Color(0xFF7B2D8B),
              ),
              tooltip: 'Partager le reçu',
            ),
        ],
      ),
    );
  }

  Future<void> _partagerRecu(BuildContext context, Paiement paiement) async {
    try {
      await RecuService.partagerRecu(paiement);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Impossible de générer le reçu : $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
