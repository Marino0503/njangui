import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/tontine.dart';
import '../services/firestore_service.dart';
import '../models/notification_model.dart';
import '../utils/formatage.dart';
import 'modifier_tontine_screen.dart';
import '../models/paiement.dart';
import '../utils/formatage.dart';
import '../models/notification_model.dart';
import 'historique_paiements_screen.dart';
import 'ajouter_membre_screen.dart';

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
      // Met à jour le statut du membre
      final membresMAJ = tontine.membres.map((m) {
        if (m.id == membre.id) {
          return Membre(
            id: m.id,
            nom: m.nom,
            aPaye: !m.aPaye, // inverse le statut
          );
        }
        return m;
      }).toList();

      // Met à jour dans Firestore
      await FirestoreService().mettreAJourMembres(tontine.id, membresMAJ);

      // ✅ Enregistre le paiement
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

      // ✅ Crée une notification
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            !membre.aPaye
                ? '${membre.nom} marqué comme payé ✅'
                : '${membre.nom} marqué en retard ❌',
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

  @override
  Widget build(BuildContext context) {
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

                    // ── Bouton retour + Nom tontine + Actions ──
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

                        // ── Menu actions ──
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
                                      ModifierTontineScreen(tontine: tontine),
                                ),
                              );
                            } else if (value == 'supprimer') {
                              _confirmerSuppression(context);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'modifier',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, color: Color(0xFF7B2D8B)),
                                  SizedBox(width: 8),
                                  Text('Modifier'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'supprimer',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text(
                                    'Supprimer',
                                    style: TextStyle(color: Colors.red),
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
                          const Text(
                            'Montant',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
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
                              const Text(
                                'Gestionnaire',
                                style: TextStyle(
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
                              const Text(
                                'Code d\'invitation',
                                style: TextStyle(
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
                          IconButton(
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(text: tontine.codeInvitation),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Code copié !'),
                                  backgroundColor: Color(0xFF2E9E6E),
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.copy,
                              color: Color(0xFF7B2D8B),
                            ),
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
                            'Membres (${tontine.membres.length}/${tontine.nombreMembres})',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),

                          // ── Bouton ajouter membre ──
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
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.add,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Ajouter',
                                    style: TextStyle(
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

                    // ── Liste des membres ──
                    tontine.membres.isEmpty
                        ? Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Aucun membre pour l\'instant',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
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

            // ── Prochaine échéance + Historique ──
            Column(
              children: [
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
                    decoration: const BoxDecoration(
                      color: Color(0xFF7B2D8B),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Row(
                          children: [
                            Icon(Icons.history, color: Colors.white, size: 22),
                            SizedBox(width: 10),
                            Text(
                              'Historique des paiements',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Prochaine échéance ──
                GestureDetector(
                  onTap: () {},
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 24,
                      horizontal: 20,
                    ),
                    decoration: const BoxDecoration(color: Colors.grey),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Prochaine échéance',
                              style: TextStyle(
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
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMembreTile(Membre membre, BuildContext context) {
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
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Text(
                      'Appui long pour supprimer',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),

            // ── Badge statut ──
            membre.aPaye
                ? Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Color(0xFF2E9E6E),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'En retard',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  void _confirmerSuppressionMembre(BuildContext context, Membre membre) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le membre'),
        content: Text(
          'Voulez-vous vraiment supprimer "${membre.nom}" de cette tontine ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await FirestoreService().supprimerMembre(tontine.id, membre.id);

                // Crée une notification
                await FirestoreService().creerNotification(
                  NotificationModel(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    titre: 'Membre supprimé',
                    message: '${membre.nom} a été retiré de "${tontine.nom}"',
                    date: DateTime.now(),
                    type: TypeNotification.nouveauMembre,
                  ),
                );

                if (!context.mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${membre.nom} supprimé avec succès !'),
                    backgroundColor: const Color(0xFF2E9E6E),
                  ),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erreur : $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _confirmerSuppression(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la tontine'),
        content: Text(
          'Voulez-vous vraiment supprimer "${tontine.nom}" ?\nCette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await FirestoreService().supprimerTontine(tontine.id);

                if (!context.mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Tontine supprimée avec succès !'),
                    backgroundColor: Color(0xFF2E9E6E),
                  ),
                );

                // Retour à la page précédente
                Navigator.pop(context);
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erreur : $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
