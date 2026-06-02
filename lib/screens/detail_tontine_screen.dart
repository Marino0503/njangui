import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/app_provider.dart';
import '../models/tontine.dart';
import '../models/paiement.dart';
import '../models/notification_model.dart';
import '../services/firestore_service.dart';
import '../utils/formatage.dart';
import 'modifier_tontine_screen.dart';
import 'historique_paiements_screen.dart';
import 'ajouter_membre_screen.dart';
import 'paiement_screen.dart';
import 'tours_screen.dart';
import 'prets_screen.dart';
import 'flux_financiers_screen.dart';
import 'sanctions_screen.dart';

class DetailTontineScreen extends StatelessWidget {
  final Tontine tontine;

  const DetailTontineScreen({super.key, required this.tontine});

  String _formaterDate(DateTime date) {
    const mois = [
      'Janvier',
      'Février',
      'Mars',
      'Avril',
      'Mai',
      'Juin',
      'Juillet',
      'Août',
      'Septembre',
      'Octobre',
      'Novembre',
      'Décembre',
    ];
    return '${date.day} ${mois[date.month - 1]}';
  }

  void _changerStatutMembre(BuildContext context, Membre membre) async {
    try {
      final membresMAJ = tontine.membres.map((m) {
        if (m.id == membre.id) {
          return Membre(id: m.id, nom: m.nom, aPaye: !m.aPaye);
        }
        return m;
      }).toList();
      // ── Vérifie et crée une sanction si le membre est en retard ──
      if (!membre.aPaye) {
        await FirestoreService().verifierEtCreerSanction(
          tontine: tontine,
          membre: membre,
          dateEcheance: tontine.dateDebut,
        );
      }

      await FirestoreService().mettreAJourMembres(tontine.id, membresMAJ);

      final paiement = Paiement(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        membreId: membre.id,
        membreNom: membre.nom,
        montant: tontine.montant,
        date: DateTime.now(),
        tontineId: tontine.id,
        tontineNom: tontine.nom,
        statut: !membre.aPaye ? 'paye' : 'en_retard',
      );

      await FirestoreService().enregistrerPaiement(paiement);
      await FirestoreService().mettreAJourFluxFinanciers(
        tontineId: tontine.id,
        montantPaiement: tontine.montant,
        typeFlux: !membre.aPaye ? 'paiement' : 'retrait',
      );
      await FirestoreService().creerNotification(
        NotificationModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          titre: !membre.aPaye ? 'Nouveau dépôt' : 'Retard de contribution',
          message: !membre.aPaye
              ? '${membre.nom} a payé ${Formatage.montant(tontine.montant)} dans "${tontine.nom}"'
              : '${membre.nom} est en retard dans "${tontine.nom}"',
          date: DateTime.now(),
          type: !membre.aPaye
              ? TypeNotification.nouveauDepot
              : TypeNotification.retardContribution,
        ),
      );

      if (!context.mounted) return;
      final provider = Provider.of<AppProvider>(context, listen: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            !membre.aPaye
                ? '${membre.nom} ${provider.langue == 'fr' ? 'marqué comme payé ✅' : 'marked as paid ✅'}'
                : '${membre.nom} ${provider.langue == 'fr' ? 'marqué en retard ❌' : 'marked as late ❌'}',
          ),
          backgroundColor: !membre.aPaye ? const Color(0xFF2E9E6E) : Colors.red,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _confirmerSuppressionMembre(BuildContext context, Membre membre) {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final textes = provider.textes;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          provider.langue == 'fr' ? 'Supprimer le membre' : 'Delete member',
        ),
        content: Text(
          provider.langue == 'fr'
              ? 'Voulez-vous vraiment supprimer "${membre.nom}" ?'
              : 'Are you sure you want to remove "${membre.nom}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(textes['annuler']!),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await FirestoreService().supprimerMembre(tontine.id, membre.id);
                await FirestoreService().creerNotification(
                  NotificationModel(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    titre: textes['membreSupprime']!,
                    message:
                        '${membre.nom} ${provider.langue == 'fr' ? 'a été retiré de' : 'was removed from'} "${tontine.nom}"',
                    date: DateTime.now(),
                    type: TypeNotification.nouveauMembre,
                  ),
                );
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(textes['membreSupprime2']!),
                    backgroundColor: const Color(0xFF2E9E6E),
                  ),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${textes['erreur']} : $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text(
              textes['supprimer']!,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmerSuppression(BuildContext context) {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final textes = provider.textes;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          provider.langue == 'fr' ? 'Supprimer la tontine' : 'Delete tontine',
        ),
        content: Text(
          provider.langue == 'fr'
              ? 'Voulez-vous vraiment supprimer "${tontine.nom}" ?\nCette action est irréversible.'
              : 'Are you sure you want to delete "${tontine.nom}"?\nThis action is irreversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(textes['annuler']!),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await FirestoreService().supprimerTontine(tontine.id);
                await FirestoreService().creerNotification(
                  NotificationModel(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    titre: provider.langue == 'fr'
                        ? 'Tontine supprimée'
                        : 'Tontine deleted',
                    message: provider.langue == 'fr'
                        ? 'Vous avez supprimé la tontine "${tontine.nom}"'
                        : 'You deleted the tontine "${tontine.nom}"',
                    date: DateTime.now(),
                    type: TypeNotification.nouvelleTontine,
                  ),
                );
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(textes['tontieSupprimee']!),
                    backgroundColor: const Color(0xFF2E9E6E),
                  ),
                );
                Navigator.pop(context);
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${textes['erreur']} : $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text(
              textes['supprimer']!,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Tontine?>(
      stream: FirestoreService().getTontineStream(tontine.id),
      builder: (context, snapshot) {
        final tontineActuelle = snapshot.data ?? tontine;

        return Consumer<AppProvider>(
          builder: (context, provider, child) {
            final textes = provider.textes;

            return Scaffold(
              backgroundColor: Colors.white,
              body: SafeArea(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 20),

                            // ── Bouton retour + Titre + Menu ──
                            Row(
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
                                        tontineActuelle.nom,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF7B2D8B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  icon: const Icon(
                                    Icons.more_vert,
                                    color: Color(0xFF7B2D8B),
                                  ),
                                  onSelected: (value) async {
                                    if (value == 'modifier') {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              ModifierTontineScreen(
                                                tontine: tontineActuelle,
                                              ),
                                        ),
                                      );
                                    } else if (value == 'supprimer') {
                                      _confirmerSuppression(context);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      value: 'modifier',
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.edit,
                                            color: Color(0xFF7B2D8B),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(textes['modifier']!),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'supprimer',
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            textes['supprimer']!,
                                            style: const TextStyle(
                                              color: Colors.red,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // ── Montant ──
                            _buildInfoCard(
                              label: textes['montant']!,
                              valeur: Formatage.montant(
                                tontineActuelle.montant,
                              ),
                            ),

                            const SizedBox(height: 12),

                            // ── Date de création ──
                            _buildInfoCard(
                              label: provider.langue == 'fr'
                                  ? 'Date de création'
                                  : 'Creation date',
                              valeur: _formaterDate(tontineActuelle.dateDebut),
                            ),

                            const SizedBox(height: 12),

                            // ── Fréquence ──
                            _buildInfoCard(
                              label: provider.langue == 'fr'
                                  ? 'Fréquence de cotisation'
                                  : 'Contribution frequency',
                              valeur: tontineActuelle.frequence,
                            ),

                            const SizedBox(height: 12),

                            // ── Gestionnaire ──
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        textes['gestionnaire']!,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        tontineActuelle.gestionnaire,
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const CircleAvatar(
                                    radius: 30,
                                    backgroundColor: Color(0xFF90EED4),
                                    child: Icon(
                                      Icons.person,
                                      size: 35,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 12),

                            // ── Code d'invitation ──
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        textes['codeInvitation']!,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        tontineActuelle.codeInvitation,
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 6,
                                          color: Color(0xFF2E9E6E),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        onPressed: () {
                                          Clipboard.setData(
                                            ClipboardData(
                                              text: tontineActuelle
                                                  .codeInvitation,
                                            ),
                                          );
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                textes['codeCopie']!,
                                              ),
                                              backgroundColor: const Color(
                                                0xFF2E9E6E,
                                              ),
                                            ),
                                          );
                                        },
                                        icon: const Icon(
                                          Icons.copy,
                                          color: Color(0xFF7B2D8B),
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () async {
                                          await SharePlus.instance.share(
                                            ShareParams(
                                              text: provider.langue == 'fr'
                                                  ? '🎉 Rejoins ma tontine "${tontineActuelle.nom}" sur Njangi !\n\n📱 Code : ${tontineActuelle.codeInvitation}\n\n💰 ${Formatage.montant(tontineActuelle.montant)}/${tontineActuelle.frequence}'
                                                  : '🎉 Join my tontine "${tontineActuelle.nom}" on Njangi!\n\n📱 Code: ${tontineActuelle.codeInvitation}\n\n💰 ${Formatage.montant(tontineActuelle.montant)}/${tontineActuelle.frequence}',
                                            ),
                                          );
                                        },
                                        icon: const Icon(
                                          Icons.share,
                                          color: Color(0xFF7B2D8B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 12),

                            // ── Membres ──
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${textes['membres']} (${tontineActuelle.membres.length}/${tontineActuelle.nombreMembres})',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              AjouterMembreScreen(
                                                tontine: tontineActuelle,
                                              ),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF2E9E6E),
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
                                            textes['ajouter']!,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 12),

                            // ── Liste des membres ──
                            tontineActuelle.membres.isEmpty
                                ? Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      provider.langue == 'fr'
                                          ? 'Aucun membre pour l\'instant'
                                          : 'No members yet',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.grey,
                                      ),
                                    ),
                                  )
                                : Column(
                                    children: tontineActuelle.membres
                                        .map(
                                          (m) => _buildMembreTile(m, context),
                                        )
                                        .toList(),
                                  ),

                            const SizedBox(height: 20),
                          ],
                        ),
                      ),

                      // ── Prochaine échéance ──
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 20,
                        ),
                        color: Colors.grey.shade200,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  textes['prochaineEcheance']!,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  tontineActuelle.prochaineEcheance,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF7B2D8B),
                                  ),
                                ),
                              ],
                            ),
                            const Icon(
                              Icons.calendar_today,
                              color: Color(0xFF7B2D8B),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ── Boutons actions en grille ──
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            // ── Ligne 1 ──
                            Row(
                              children: [
                                Expanded(
                                  child: _buildBoutonAction(
                                    context: context,
                                    titre: provider.langue == 'fr'
                                        ? 'Flux financiers'
                                        : 'Financial flows',
                                    icone: Icons.account_balance,
                                    couleur: const Color(0xFF2E8B57),
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            FluxFinanciersScreen(
                                              tontine: tontineActuelle,
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildBoutonAction(
                                    context: context,
                                    titre: provider.langue == 'fr'
                                        ? 'Gestion des prêts'
                                        : 'Loan management',
                                    icone: Icons.account_balance_outlined,
                                    couleur: const Color(0xFFFF8C00),
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => PretsScreen(
                                          tontine: tontineActuelle,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // ── Ligne 2 ──
                            Row(
                              children: [
                                Expanded(
                                  child: _buildBoutonAction(
                                    context: context,
                                    titre: textes['gestionTours']!,
                                    icone: Icons.rotate_right,
                                    couleur: const Color(0xFF7B2D8B),
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ToursScreen(
                                          tontine: tontineActuelle,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildBoutonAction(
                                    context: context,
                                    titre: textes['historiquesPaiements']!,
                                    icone: Icons.history,
                                    couleur: const Color(0xFF2E9E6E),
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            HistoriquePaiementsScreen(
                                              tontine: tontineActuelle,
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // ── Ligne 3 — Sanctions ──
                            _buildBoutonAction(
                              context: context,
                              titre: provider.langue == 'fr'
                                  ? 'Sanctions'
                                  : 'Sanctions',
                              icone: Icons.warning_amber,
                              couleur: Colors.red,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      SanctionsScreen(tontine: tontineActuelle),
                                ),
                              ),
                              pleineLargeur: true,
                            ),

                            const SizedBox(height: 30),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ── Widget bouton action ──
  Widget _buildBoutonAction({
    required BuildContext context,
    required String titre,
    required IconData icone,
    required Color couleur,
    required VoidCallback onTap,
    bool pleineLargeur = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: pleineLargeur ? double.infinity : null,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: couleur,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icone, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                titre,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Widget info card ──
  Widget _buildInfoCard({required String label, required String valeur}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 6),
          Text(
            valeur,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildMembreTile(Membre membre, BuildContext context) {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final textes = provider.textes;

    return GestureDetector(
      onTap: () => _changerStatutMembre(context, membre),
      onLongPress: () => _confirmerSuppressionMembre(context, membre),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
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
                    color: membre.aPaye ? const Color(0xFF2E9E6E) : Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    membre.aPaye ? Icons.check : Icons.close,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      membre.nom,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      provider.langue == 'fr'
                          ? 'Appui long pour supprimer'
                          : 'Long press to delete',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            membre.aPaye
                ? Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E9E6E),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${textes['paye']} ✅',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                : GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              PaiementScreen(tontine: tontine, membre: membre),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7B2D8B),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.payment,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            provider.langue == 'fr' ? 'Payer' : 'Pay',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
