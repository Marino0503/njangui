import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/pret.dart';
import '../models/tontine.dart';
import '../models/notification_model.dart';
import '../providers/app_provider.dart';
import '../services/firestore_service.dart';
import '../utils/formatage.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_state.dart';
import 'demande_pret_screen.dart';

class PretsScreen extends StatelessWidget {
  final Tontine tontine;

  const PretsScreen({super.key, required this.tontine});

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
                                  ? 'Prêts - ${tontine.nom}'
                                  : 'Loans - ${tontine.nom}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF7B2D8B),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ── Bouton nouvelle demande ──
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  DemanderPretScreen(tontine: tontine),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7B2D8B),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.add,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                provider.langue == 'fr' ? 'Nouveau' : 'New',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Liste des prêts ──
                Expanded(
                  child: StreamBuilder<List<Pret>>(
                    stream: FirestoreService().getPretsTontine(tontine.id),
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
                              ? 'Impossible de charger les prêts.'
                              : 'Unable to load loans.',
                          onReessayer: () {},
                        );
                      }

                      final prets = snapshot.data ?? [];

                      if (prets.isEmpty) {
                        return EmptyState(
                          icon: Icons.account_balance_outlined,
                          titre: provider.langue == 'fr'
                              ? 'Aucun prêt'
                              : 'No loans',
                          message: provider.langue == 'fr'
                              ? 'Aucun prêt pour cette tontine.\nAppuyez sur + pour en créer un.'
                              : 'No loans for this tontine.\nTap + to create one.',
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: prets.length,
                        itemBuilder: (context, index) {
                          return _buildPretCard(
                            context,
                            prets[index],
                            provider,
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

  Widget _buildPretCard(BuildContext context, Pret pret, AppProvider provider) {
    Color couleurStatut;
    String libelleStatut;
    IconData iconeStatut;

    switch (pret.statut) {
      case StatutPret.enAttente:
        couleurStatut = Colors.orange;
        libelleStatut = provider.langue == 'fr' ? 'En attente' : 'Pending';
        iconeStatut = Icons.hourglass_empty;
        break;
      case StatutPret.accepte:
        couleurStatut = const Color(0xFF2E9E6E);
        libelleStatut = provider.langue == 'fr' ? 'Accepté' : 'Accepted';
        iconeStatut = Icons.check_circle;
        break;
      case StatutPret.refuse:
        couleurStatut = Colors.red;
        libelleStatut = provider.langue == 'fr' ? 'Refusé' : 'Refused';
        iconeStatut = Icons.cancel;
        break;
      case StatutPret.enCours:
        couleurStatut = const Color(0xFF7B2D8B);
        libelleStatut = provider.langue == 'fr' ? 'En cours' : 'In progress';
        iconeStatut = Icons.sync;
        break;
      case StatutPret.rembourse:
        couleurStatut = const Color(0xFF2E9E6E);
        libelleStatut = provider.langue == 'fr' ? 'Remboursé' : 'Repaid';
        iconeStatut = Icons.done_all;
        break;
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                DetailPretScreen(pret: pret, tontine: tontine),
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
              color: Colors.grey.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // ── Nom membre ──
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 20,
                      backgroundColor: Color(0xFF90EED4),
                      child: Icon(Icons.person, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      pret.membreNom,
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
                    color: couleurStatut.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: couleurStatut.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(iconeStatut, color: couleurStatut, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        libelleStatut,
                        style: TextStyle(
                          color: couleurStatut,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Montant ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  provider.langue == 'fr' ? 'Montant' : 'Amount',
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
                Text(
                  Formatage.montant(pret.montant),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 4),

            // ── Total à rembourser ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  provider.langue == 'fr'
                      ? 'Total à rembourser'
                      : 'Total to repay',
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
                Text(
                  Formatage.montant(pret.montantTotal),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF7B2D8B),
                  ),
                ),
              ],
            ),

            // ── Barre de progression si en cours ──
            if (pret.statut == StatutPret.enCours ||
                pret.statut == StatutPret.rembourse) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    provider.langue == 'fr' ? 'Remboursé' : 'Repaid',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    '${(pret.progressionRemboursement * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E9E6E),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: pret.progressionRemboursement,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF2E9E6E),
                  ),
                  minHeight: 8,
                ),
              ),
            ],

            const SizedBox(height: 8),

            // ── Date ──
            Text(
              '${provider.langue == 'fr' ? 'Demandé le' : 'Requested on'} ${Formatage.date(pret.dateDemande)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),

            // ── Boutons accepter/refuser si en attente ──
            if (pret.statut == StatutPret.enAttente) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        await FirestoreService().accepterPret(pret.id);
                        await FirestoreService().creerNotification(
                          NotificationModel(
                            id: DateTime.now().millisecondsSinceEpoch
                                .toString(),
                            titre: provider.langue == 'fr'
                                ? 'Prêt accepté'
                                : 'Loan accepted',
                            message: provider.langue == 'fr'
                                ? 'Votre prêt de ${Formatage.montant(pret.montant)} a été accepté !'
                                : 'Your loan of ${Formatage.montant(pret.montant)} has been accepted!',
                            date: DateTime.now(),
                            type: TypeNotification.nouveauDepot,
                          ),
                        );
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              provider.langue == 'fr'
                                  ? 'Prêt accepté !'
                                  : 'Loan accepted!',
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
                        provider.langue == 'fr' ? 'Accepter' : 'Accept',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        await FirestoreService().refuserPret(pret.id);
                        await FirestoreService().creerNotification(
                          NotificationModel(
                            id: DateTime.now().millisecondsSinceEpoch
                                .toString(),
                            titre: provider.langue == 'fr'
                                ? 'Prêt refusé'
                                : 'Loan refused',
                            message: provider.langue == 'fr'
                                ? 'Votre prêt de ${Formatage.montant(pret.montant)} a été refusé.'
                                : 'Your loan of ${Formatage.montant(pret.montant)} has been refused.',
                            date: DateTime.now(),
                            type: TypeNotification.retardContribution,
                          ),
                        );
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              provider.langue == 'fr'
                                  ? 'Prêt refusé.'
                                  : 'Loan refused.',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        provider.langue == 'fr' ? 'Refuser' : 'Refuse',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════
// PAGE DÉTAILS PRÊT
// ════════════════════════════════════════

class DetailPretScreen extends StatelessWidget {
  final Pret pret;
  final Tontine tontine;

  const DetailPretScreen({
    super.key,
    required this.pret,
    required this.tontine,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        final TextEditingController montantController = TextEditingController();
        final TextEditingController noteController = TextEditingController();

        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // ── Bouton retour ──
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
                              ? 'Détails du prêt'
                              : 'Loan details',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF7B2D8B),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Infos du prêt ──
                  _buildInfoTile(
                    provider.langue == 'fr' ? 'Membre' : 'Member',
                    pret.membreNom,
                  ),
                  _buildInfoTile(
                    provider.langue == 'fr' ? 'Montant' : 'Amount',
                    Formatage.montant(pret.montant),
                  ),
                  _buildInfoTile(
                    provider.langue == 'fr'
                        ? 'Taux d\'intérêt'
                        : 'Interest rate',
                    '${pret.tauxInteret.toStringAsFixed(0)}%',
                  ),
                  _buildInfoTile(
                    provider.langue == 'fr'
                        ? 'Total à rembourser'
                        : 'Total to repay',
                    Formatage.montant(pret.montantTotal),
                  ),
                  _buildInfoTile(
                    provider.langue == 'fr' ? 'Durée' : 'Duration',
                    provider.langue == 'fr'
                        ? '${pret.dureeEnMois} mois'
                        : '${pret.dureeEnMois} months',
                  ),
                  _buildInfoTile(
                    provider.langue == 'fr' ? 'Motif' : 'Reason',
                    pret.motif,
                  ),
                  if (pret.dateEcheance != null)
                    _buildInfoTile(
                      provider.langue == 'fr' ? 'Date d\'échéance' : 'Due date',
                      Formatage.date(pret.dateEcheance!),
                    ),

                  const SizedBox(height: 20),

                  // ── Progression ──
                  if (pret.statut == StatutPret.enCours ||
                      pret.statut == StatutPret.rembourse) ...[
                    Text(
                      provider.langue == 'fr'
                          ? 'Progression du remboursement'
                          : 'Repayment progress',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: pret.progressionRemboursement,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF2E9E6E),
                        ),
                        minHeight: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${Formatage.montant(pret.montantRembourse)} ${provider.langue == 'fr' ? 'remboursé' : 'repaid'}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF2E9E6E),
                          ),
                        ),
                        Text(
                          '${Formatage.montant(pret.montantRestant)} ${provider.langue == 'fr' ? 'restant' : 'remaining'}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ── Historique remboursements ──
                    Text(
                      provider.langue == 'fr'
                          ? 'Historique des remboursements'
                          : 'Repayment history',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...pret.remboursements.map(
                      (r) => _buildRemboursementTile(r, provider),
                    ),
                  ],

                  // ── Bouton ajouter remboursement ──
                  if (pret.statut == StatutPret.accepte ||
                      pret.statut == StatutPret.enCours) ...[
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            builder: (context) => Padding(
                              padding: EdgeInsets.only(
                                bottom: MediaQuery.of(
                                  context,
                                ).viewInsets.bottom,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      provider.langue == 'fr'
                                          ? 'Ajouter un remboursement'
                                          : 'Add repayment',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    TextField(
                                      controller: montantController,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        labelText: provider.langue == 'fr'
                                            ? 'Montant remboursé'
                                            : 'Repayment amount',
                                        suffixText: 'FCFA',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    TextField(
                                      controller: noteController,
                                      decoration: InputDecoration(
                                        labelText: provider.langue == 'fr'
                                            ? 'Note (optionnel)'
                                            : 'Note (optional)',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 50,
                                      child: ElevatedButton(
                                        onPressed: () async {
                                          final montant = double.tryParse(
                                            montantController.text,
                                          );
                                          if (montant == null || montant <= 0) {
                                            return;
                                          }

                                          final remb = Remboursement(
                                            id: DateTime.now()
                                                .millisecondsSinceEpoch
                                                .toString(),
                                            montant: montant,
                                            date: DateTime.now(),
                                            note: noteController.text,
                                          );

                                          await FirestoreService()
                                              .ajouterRemboursement(
                                                pret.id,
                                                remb,
                                              );

                                          if (!context.mounted) return;
                                          Navigator.pop(context);
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                provider.langue == 'fr'
                                                    ? 'Remboursement ajouté !'
                                                    : 'Repayment added!',
                                              ),
                                              backgroundColor: const Color(
                                                0xFF2E9E6E,
                                              ),
                                            ),
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFF2E9E6E,
                                          ),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              30,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          provider.langue == 'fr'
                                              ? 'Confirmer'
                                              : 'Confirm',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add),
                        label: Text(
                          provider.langue == 'fr'
                              ? 'Ajouter un remboursement'
                              : 'Add repayment',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E9E6E),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoTile(String label, String valeur) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          Text(
            valeur,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildRemboursementTile(Remboursement r, AppProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF9F6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2E9E6E)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                Formatage.date(r.date),
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              if (r.note.isNotEmpty)
                Text(
                  r.note,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
            ],
          ),
          Text(
            Formatage.montant(r.montant),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E9E6E),
            ),
          ),
        ],
      ),
    );
  }
}
