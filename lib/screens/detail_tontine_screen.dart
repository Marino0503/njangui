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
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        final textes = provider.textes;

        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
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
                                    tontine.nom,
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
                                            tontine: tontine,
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
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                textes['montant']!,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                Formatage.montant(tontine.montant),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                    tontine.gestionnaire,
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                    tontine.codeInvitation,
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
                                          text: tontine.codeInvitation,
                                        ),
                                      );
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(textes['codeCopie']!),
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
                                              ? '🎉 Rejoins ma tontine "${tontine.nom}" sur Njangi !\n\n📱 Code : ${tontine.codeInvitation}\n\n💰 ${Formatage.montant(tontine.montant)}/${tontine.frequence}'
                                              : '🎉 Join my tontine "${tontine.nom}" on Njangi!\n\n📱 Code: ${tontine.codeInvitation}\n\n💰 ${Formatage.montant(tontine.montant)}/${tontine.frequence}',
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${textes['membres']} (${tontine.membres.length}/${tontine.nombreMembres})',
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
                                          AjouterMembreScreen(tontine: tontine),
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
                        tontine.membres.isEmpty
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
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              )
                            : Column(
                                children: tontine.membres
                                    .map((m) => _buildMembreTile(m, context))
                                    .toList(),
                              ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),

                // ── Boutons en bas ──
                Column(
                  children: [
                    // ── Bouton Prêts ──
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PretsScreen(tontine: tontine),
                          ),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 20,
                        ),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF8C00),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.account_balance_outlined,
                                  color: Colors.white,
                                  size: 22,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  provider.langue == 'fr'
                                      ? 'Gestion des prêts'
                                      : 'Loan management',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.white,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                    // ── Bouton Tours ──
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ToursScreen(tontine: tontine),
                          ),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 20,
                        ),
                        decoration: const BoxDecoration(
                          color: Color(0xFF7B2D8B),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.rotate_right,
                                  color: Colors.white,
                                  size: 22,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  textes['gestionTours']!,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.white,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ── Bouton Historique ──
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                HistoriquePaiementsScreen(tontine: tontine),
                          ),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 20,
                        ),
                        color: const Color(0xFF2E9E6E),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.history,
                                  color: Colors.white,
                                  size: 22,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  textes['historiquesPaiements']!,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.white,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ── Prochaine échéance ──
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 24,
                        horizontal: 20,
                      ),
                      color: Colors.grey,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                textes['prochaineEcheance']!,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'le ${_formaterDate(tontine.dateDebut)}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.white,
                            size: 24,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
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
