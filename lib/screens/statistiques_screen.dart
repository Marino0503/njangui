import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/firestore_service.dart';
import '../services/user_service.dart';
import '../models/tontine.dart';
import '../models/paiement.dart';
import '../utils/formatage.dart';
import '../widgets/error_state.dart';
import 'detail_tontine_screen.dart';

class StatistiquesScreen extends StatelessWidget {
  const StatistiquesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  Text(
                    provider.langue == 'fr' ? 'Statistiques' : 'Statistics',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Stats globales filtrées par utilisateur ──
                  StreamBuilder<List<Tontine>>(
                    stream: FirestoreService().getTontines(),
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
                          message: provider.langue == 'fr'
                              ? 'Impossible de charger les statistiques.'
                              : 'Unable to load statistics.',
                          onReessayer: () {},
                        );
                      }

                      final tontines = snapshot.data ?? [];
                      final monUid = UserService().uidActuel ?? '';

                      // Total collecté uniquement pour mes tontines
                      double totalCollecte = 0;
                      for (final t in tontines) {
                        totalCollecte += t.totalCollecte;
                      }

                      final nombreTontines = tontines.length;
                      final nombreMembres = tontines.fold<int>(
                        0,
                        (sum, t) => sum + t.membres.length,
                      );
                      final nombrePayes = tontines.fold<int>(
                        0,
                        (sum, t) =>
                            sum + t.membres.where((m) => m.aPaye).length,
                      );
                      final nombreRetards = tontines.fold<int>(
                        0,
                        (sum, t) =>
                            sum + t.membres.where((m) => !m.aPaye).length,
                      );

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
                                Text(
                                  provider.langue == 'fr'
                                      ? 'Total collecté'
                                      : 'Total collected',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.white70,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  Formatage.montant(totalCollecte),
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    _buildMiniStat(
                                      '$nombreTontines',
                                      provider.langue == 'fr'
                                          ? 'Tontines'
                                          : 'Tontines',
                                      Icons.description_outlined,
                                    ),
                                    _buildMiniStat(
                                      '$nombreMembres',
                                      provider.langue == 'fr'
                                          ? 'Membres'
                                          : 'Members',
                                      Icons.people_outline,
                                    ),
                                    _buildMiniStat(
                                      '$nombrePayes',
                                      provider.langue == 'fr'
                                          ? 'Paiements'
                                          : 'Payments',
                                      Icons.check_circle_outline,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // ── Taux de paiement global ──
                          Text(
                            provider.langue == 'fr'
                                ? 'Taux de paiement global'
                                : 'Global payment rate',
                            style: const TextStyle(
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
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      provider.langue == 'fr'
                                          ? 'Payés'
                                          : 'Paid',
                                      style: const TextStyle(fontSize: 15),
                                    ),
                                    Text(
                                      '$nombrePayes',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2E9E6E),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: LinearProgressIndicator(
                                    value: nombrePayes + nombreRetards > 0
                                        ? nombrePayes /
                                              (nombrePayes + nombreRetards)
                                        : 0,
                                    backgroundColor: Colors.red.shade100,
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                          Color(0xFF2E9E6E),
                                        ),
                                    minHeight: 10,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      provider.langue == 'fr'
                                          ? 'En retard'
                                          : 'Late',
                                      style: const TextStyle(fontSize: 15),
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

                          // ── Statistiques par tontine ──
                          Text(
                            provider.langue == 'fr'
                                ? 'Statistiques par tontine'
                                : 'Statistics per tontine',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 12),

                          if (tontines.isEmpty)
                            Center(
                              child: Text(
                                provider.langue == 'fr'
                                    ? 'Aucune tontine'
                                    : 'No tontine',
                                style: const TextStyle(color: Colors.grey),
                              ),
                            )
                          else
                            ...tontines.map(
                              (t) => _buildTontineStatCard(
                                t,
                                provider,
                                context,
                                monUid,
                              ),
                            ),

                          const SizedBox(height: 24),

                          // ── Paiements récents ──
                          Text(
                            provider.langue == 'fr'
                                ? 'Paiements récents'
                                : 'Recent payments',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 12),

                          StreamBuilder<List<Paiement>>(
                            stream: FirestoreService().getTousPaiements(),
                            builder: (context, paiementsSnapshot) {
                              final paiements = paiementsSnapshot.data ?? [];

                              // Filtre les paiements liés à mes tontines
                              final mesTontinesIds = tontines
                                  .map((t) => t.id)
                                  .toSet();
                              final mesPaiements = paiements
                                  .where(
                                    (p) => mesTontinesIds.contains(p.tontineId),
                                  )
                                  .toList();

                              if (mesPaiements.isEmpty) {
                                return Center(
                                  child: Text(
                                    provider.langue == 'fr'
                                        ? 'Aucun paiement'
                                        : 'No payment',
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                );
                              }

                              return Column(
                                children: mesPaiements
                                    .take(5)
                                    .map((p) => _buildPaiementStat(p, provider))
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
      },
    );
  }

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

  // ── Carte statistiques par tontine ──
  Widget _buildTontineStatCard(
    Tontine tontine,
    AppProvider provider,
    BuildContext context,
    String monUid,
  ) {
    final membresPayes = tontine.membres.where((m) => m.aPaye).length;
    final totalMembres = tontine.membres.length;
    final progression = totalMembres > 0 ? membresPayes / totalMembres : 0.0;
    final estGestionnaire = tontine.gestionnaireId == monUid;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailTontineScreen(tontine: tontine),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── En-tête ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      tontine.nom,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: estGestionnaire
                            ? const Color(0xFF7B2D8B).withOpacity(0.1)
                            : const Color(0xFF2E9E6E).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        estGestionnaire
                            ? (provider.langue == 'fr'
                                  ? 'Gestionnaire'
                                  : 'Manager')
                            : (provider.langue == 'fr' ? 'Membre' : 'Member'),
                        style: TextStyle(
                          fontSize: 10,
                          color: estGestionnaire
                              ? const Color(0xFF7B2D8B)
                              : const Color(0xFF2E9E6E),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Colors.grey,
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Montant et fréquence ──
            Text(
              '${Formatage.montant(tontine.montant)}/${tontine.frequence}',
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),

            const SizedBox(height: 12),

            // ── Barre de progression ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  provider.langue == 'fr'
                      ? '$membresPayes/$totalMembres membres ont payé'
                      : '$membresPayes/$totalMembres members paid',
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
                Text(
                  '${(progression * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E9E6E),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progression,
                backgroundColor: Colors.grey.shade200,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF2E9E6E),
                ),
                minHeight: 8,
              ),
            ),

            const SizedBox(height: 12),

            // ── Flux financiers ──
            Row(
              children: [
                Expanded(
                  child: _buildFluxItem(
                    provider.langue == 'fr' ? 'Collecté' : 'Collected',
                    Formatage.montant(tontine.totalCollecte),
                    const Color(0xFF2E9E6E),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildFluxItem(
                    provider.langue == 'fr' ? 'Distribué' : 'Distributed',
                    Formatage.montant(tontine.totalDistribue),
                    const Color(0xFF7B2D8B),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildFluxItem(
                    provider.langue == 'fr' ? 'Solde' : 'Balance',
                    Formatage.montant(tontine.soldeDisponible),
                    const Color(0xFFFF8C00),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFluxItem(String label, String valeur, Color couleur) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: couleur.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: couleur)),
          const SizedBox(height: 2),
          Text(
            valeur,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: couleur,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaiementStat(Paiement paiement, AppProvider provider) {
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
