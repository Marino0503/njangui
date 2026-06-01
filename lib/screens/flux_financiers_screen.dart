import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/tontine.dart';
import '../providers/app_provider.dart';
import '../services/firestore_service.dart';
import '../utils/formatage.dart';
import '../widgets/empty_state.dart';

class FluxFinanciersScreen extends StatelessWidget {
  final Tontine tontine;

  const FluxFinanciersScreen({super.key, required this.tontine});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
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
                            provider.langue == 'fr'
                                ? 'Flux financiers - ${tontine.nom}'
                                : 'Financial flows - ${tontine.nom}',
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

                // ── Cartes résumé ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      // ── Total collecté ──
                      _buildCarteResume(
                        titre: provider.langue == 'fr'
                            ? 'Total collecté'
                            : 'Total collected',
                        montant: tontine.totalCollecte,
                        couleur: const Color(0xFF2E9E6E),
                        icone: Icons.arrow_downward,
                      ),

                      const SizedBox(height: 12),

                      Row(
                        children: [
                          // ── Total distribué ──
                          Expanded(
                            child: _buildCarteResumeSmall(
                              titre: provider.langue == 'fr'
                                  ? 'Distribué'
                                  : 'Distributed',
                              montant: tontine.totalDistribue,
                              couleur: const Color(0xFF7B2D8B),
                              icone: Icons.arrow_upward,
                            ),
                          ),

                          const SizedBox(width: 12),

                          // ── Solde disponible ──
                          Expanded(
                            child: _buildCarteResumeSmall(
                              titre: provider.langue == 'fr'
                                  ? 'Solde'
                                  : 'Balance',
                              montant: tontine.soldeDisponible,
                              couleur: const Color(0xFFFF8C00),
                              icone: Icons.account_balance_wallet,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Titre liste ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    provider.langue == 'fr'
                        ? 'Historique des flux'
                        : 'Flow history',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // ── Liste des flux ──
                Expanded(
                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: FirestoreService().getFluxFinanciers(tontine.id),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF2E9E6E),
                          ),
                        );
                      }

                      final flux = snapshot.data ?? [];

                      if (flux.isEmpty) {
                        return EmptyState(
                          icon: Icons.account_balance_outlined,
                          titre: provider.langue == 'fr'
                              ? 'Aucun flux financier'
                              : 'No financial flows',
                          message: provider.langue == 'fr'
                              ? 'Les mouvements d\'argent\napparaîtront ici.'
                              : 'Money movements\nwill appear here.',
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: flux.length,
                        itemBuilder: (context, index) {
                          return _buildFluxTile(flux[index], provider);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Carte résumé grande ──
  Widget _buildCarteResume({
    required String titre,
    required double montant,
    required Color couleur,
    required IconData icone,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: couleur,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titre,
                style: const TextStyle(fontSize: 14, color: Colors.white70),
              ),
              const SizedBox(height: 4),
              Text(
                Formatage.montant(montant),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icone, color: Colors.white, size: 24),
          ),
        ],
      ),
    );
  }

  // ── Carte résumé petite ──
  Widget _buildCarteResumeSmall({
    required String titre,
    required double montant,
    required Color couleur,
    required IconData icone,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: couleur.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: couleur.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icone, color: couleur, size: 18),
              const SizedBox(width: 6),
              Text(
                titre,
                style: TextStyle(
                  fontSize: 13,
                  color: couleur,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            Formatage.montant(montant),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: couleur,
            ),
          ),
        ],
      ),
    );
  }

  // ── Tuile flux ──
  Widget _buildFluxTile(Map<String, dynamic> flux, AppProvider provider) {
    final estPaye = flux['statut'] == 'paye';
    final montant = (flux['montant'] as num).toDouble();
    final date = DateTime.parse(flux['date'] as String);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
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
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: estPaye ? const Color(0xFF2E9E6E) : Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  estPaye ? Icons.arrow_downward : Icons.warning_amber,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    flux['membreNom'] ?? '',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    Formatage.date(date),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                estPaye
                    ? '+ ${Formatage.montant(montant)}'
                    : '- ${Formatage.montant(montant)}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: estPaye ? const Color(0xFF2E9E6E) : Colors.red,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: estPaye ? const Color(0xFF2E9E6E) : Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  estPaye
                      ? (provider.langue == 'fr' ? 'Payé' : 'Paid')
                      : (provider.langue == 'fr' ? 'En retard' : 'Late'),
                  style: const TextStyle(fontSize: 11, color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
