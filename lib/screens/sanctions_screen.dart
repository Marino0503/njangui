import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/tontine.dart';
import '../models/sanction.dart';
import '../providers/app_provider.dart';
import '../services/firestore_service.dart';
import '../services/user_service.dart';
import '../utils/formatage.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_state.dart';

class SanctionsScreen extends StatelessWidget {
  final Tontine tontine;

  const SanctionsScreen({super.key, required this.tontine});

  bool get _estGestionnaire =>
      tontine.gestionnaireId == UserService().uidActuel;

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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.arrow_back_ios,
                              color: Color(0xFF7B2D8B),
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              provider.langue == 'fr'
                                  ? 'Sanctions - ${tontine.nom}'
                                  : 'Sanctions - ${tontine.nom}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF7B2D8B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Info sanctions actives ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: tontine.sanctionsActives
                          ? const Color(0xFFEFF9F6)
                          : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: tontine.sanctionsActives
                            ? const Color(0xFF2E9E6E)
                            : Colors.red.shade200,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          tontine.sanctionsActives
                              ? Icons.check_circle
                              : Icons.cancel,
                          color: tontine.sanctionsActives
                              ? const Color(0xFF2E9E6E)
                              : Colors.red,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tontine.sanctionsActives
                                  ? (provider.langue == 'fr'
                                        ? 'Sanctions activées'
                                        : 'Sanctions enabled')
                                  : (provider.langue == 'fr'
                                        ? 'Sanctions désactivées'
                                        : 'Sanctions disabled'),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: tontine.sanctionsActives
                                    ? const Color(0xFF2E9E6E)
                                    : Colors.red,
                              ),
                            ),
                            if (tontine.sanctionsActives)
                              Text(
                                provider.langue == 'fr'
                                    ? 'Pénalité : ${Formatage.montant(tontine.penaliteParJour)}/jour'
                                    : 'Penalty: ${Formatage.montant(tontine.penaliteParJour)}/day',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ── Bouton appliquer sanction manuellement (gestionnaire uniquement) ──
                if (tontine.sanctionsActives && _estGestionnaire)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _afficherDialogSanction(context, provider);
                        },
                        icon: const Icon(Icons.warning_amber),
                        label: Text(
                          provider.langue == 'fr'
                              ? 'Appliquer une sanction'
                              : 'Apply a sanction',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 20),

                // ── Titre liste ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    provider.langue == 'fr'
                        ? 'Historique des sanctions'
                        : 'Sanctions history',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // ── Liste des sanctions ──
                Expanded(
                  child: StreamBuilder<List<Sanction>>(
                    stream: FirestoreService().getSanctionsTontine(tontine.id),
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
                              ? 'Impossible de charger les sanctions.'
                              : 'Unable to load sanctions.',
                          onReessayer: () {},
                        );
                      }

                      final sanctions = snapshot.data ?? [];

                      if (sanctions.isEmpty) {
                        return EmptyState(
                          icon: Icons.verified_user_outlined,
                          titre: provider.langue == 'fr'
                              ? 'Aucune sanction'
                              : 'No sanctions',
                          message: provider.langue == 'fr'
                              ? 'Aucun membre en retard\npour le moment.'
                              : 'No members are late\nfor now.',
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: sanctions.length,
                        itemBuilder: (context, index) {
                          return _buildSanctionCard(
                            context,
                            sanctions[index],
                            provider,
                            _estGestionnaire,
                          );
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

  // ── Dialog pour appliquer une sanction manuellement ──
  void _afficherDialogSanction(BuildContext context, AppProvider provider) {
    String membreSelectionne = '';
    String membreNomSelectionne = '';
    int joursRetard = 1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  provider.langue == 'fr'
                      ? 'Appliquer une sanction'
                      : 'Apply a sanction',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 16),

                // ── Sélectionner un membre ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: membreSelectionne.isEmpty
                          ? null
                          : membreSelectionne,
                      isExpanded: true,
                      hint: Text(
                        provider.langue == 'fr'
                            ? 'Sélectionner un membre'
                            : 'Select a member',
                      ),
                      items: tontine.membres
                          .map(
                            (m) => DropdownMenuItem(
                              value: m.id,
                              child: Text(m.nom),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          membreSelectionne = value ?? '';
                          membreNomSelectionne = tontine.membres
                              .firstWhere((m) => m.id == value)
                              .nom;
                        });
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ── Jours de retard ──
                Text(
                  provider.langue == 'fr'
                      ? 'Jours de retard : $joursRetard'
                      : 'Days late: $joursRetard',
                  style: const TextStyle(fontSize: 15),
                ),
                Slider(
                  value: joursRetard.toDouble(),
                  min: 1,
                  max: 30,
                  divisions: 29,
                  activeColor: Colors.red,
                  label: '$joursRetard',
                  onChanged: (value) {
                    setState(() => joursRetard = value.toInt());
                  },
                ),

                const SizedBox(height: 8),

                // ── Montant calculé ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    provider.langue == 'fr'
                        ? 'Pénalité totale : ${Formatage.montant(tontine.penaliteParJour * joursRetard)}'
                        : 'Total penalty: ${Formatage.montant(tontine.penaliteParJour * joursRetard)}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ── Bouton confirmer ──
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: membreSelectionne.isEmpty
                        ? null
                        : () async {
                            // ✅ Nouveau code
                            final sanction = Sanction(
                              id: DateTime.now().millisecondsSinceEpoch
                                  .toString(),
                              tontineId: tontine.id,
                              tontineNom: tontine.nom,
                              membreId: membreSelectionne,
                              membreNom: membreNomSelectionne,
                              montantInitial: tontine.montant,
                              montantDu: Sanction.calculerMontantDu(
                                tontine.montant,
                                joursRetard,
                              ),
                              nombreFrequencesRetard: joursRetard,
                              dateEcheance: DateTime.now().subtract(
                                Duration(days: joursRetard),
                              ),
                              dateSanction: DateTime.now(),
                              estPayee: false,
                            );

                            await FirestoreService().creerSanction(sanction);

                            if (!context.mounted) return;
                            Navigator.pop(context);

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  provider.langue == 'fr'
                                      ? 'Sanction appliquée !'
                                      : 'Sanction applied!',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      provider.langue == 'fr' ? 'Confirmer' : 'Confirm',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Carte sanction ──
  Widget _buildSanctionCard(
    BuildContext context,
    Sanction sanction,
    AppProvider provider,
    bool estGestionnaire,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: sanction.estPayee ? const Color(0xFFEFF9F6) : Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: sanction.estPayee
              ? const Color(0xFF2E9E6E)
              : Colors.red.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: sanction.estPayee
                        ? const Color(0xFF2E9E6E)
                        : Colors.red,
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    sanction.membreNom,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              // ── Badge statut ──
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: sanction.estPayee
                      ? const Color(0xFF2E9E6E)
                      : Colors.red,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  sanction.estPayee
                      ? (provider.langue == 'fr' ? 'Payée ✅' : 'Paid ✅')
                      : (provider.langue == 'fr' ? 'Non payée ❌' : 'Unpaid ❌'),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Détails ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                provider.langue == 'fr'
                    ? '${sanction.nombreFrequencesRetard} frequence(s) de retard'
                    : '${sanction.nombreFrequencesRetard} late period(s)',
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              Text(
                Formatage.montant(sanction.montantDu),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: sanction.estPayee
                      ? const Color(0xFF2E9E6E)
                      : Colors.red,
                ),
              ),
            ],
          ),

          Text(
            '${provider.langue == 'fr' ? 'Date' : 'Date'} : ${Formatage.date(sanction.dateSanction)}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),

          // ── Bouton marquer comme payée (gestionnaire uniquement) ──
          if (!sanction.estPayee && estGestionnaire) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await FirestoreService().payerSanction(sanction.id);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        provider.langue == 'fr'
                            ? 'Sanction marquée comme payée !'
                            : 'Sanction marked as paid!',
                      ),
                      backgroundColor: const Color(0xFF2E9E6E),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E9E6E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  provider.langue == 'fr'
                      ? 'Marquer comme payée'
                      : 'Mark as paid',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
