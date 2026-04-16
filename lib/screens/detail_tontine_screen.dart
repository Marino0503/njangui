import 'package:flutter/material.dart';
import '../models/tontine.dart';
import '../data/notifications_data.dart';

class DetailTontineScreen extends StatelessWidget {
  final Tontine tontine;

  const DetailTontineScreen({super.key, required this.tontine});

  // Formate la date en français
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

  void _changerStatutMembre(BuildContext context, Membre membre) {
    // Crée une notification selon le statut
    if (membre.aPaye) {
      NotificationsData().notifierNouveauDepot(
        membre.nom,
        tontine.montant,
        tontine.nom,
      );
    } else {
      NotificationsData().notifierRetard(membre.nom, tontine.nom);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          membre.aPaye
              ? '${membre.nom} marqué comme payé'
              : '${membre.nom} marqué en retard',
        ),
        backgroundColor: membre.aPaye ? const Color(0xFF2E9E6E) : Colors.red,
      ),
    );
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

                    // ── Bouton retour + Nom tontine ──
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
                            '${tontine.montant.toStringAsFixed(0)} FCFA',
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

                                // ── Bouton copier ──
                                IconButton(
                                  onPressed: () {
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

                          // Avatar gestionnaire
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: const Color(0xFF90EED4),
                            child: const Icon(
                              Icons.person,
                              size: 35,
                              color: Colors.white,
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
                      child: Center(
                        child: Text(
                          'Membres (${tontine.membres.length})',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ── Liste des membres ──
                    ...tontine.membres.map(
                      (membre) => _buildMembreTile(membre),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // ── Prochaine échéance en bas ──
            GestureDetector(
              onTap: () {},
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 24,
                  horizontal: 20,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Prochaine échéance',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'le ${_formaterDate(tontine.dateDebut)}',
                          style: const TextStyle(
                            fontSize: 22,
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
      ),
    );
  }

  // ── Widget pour chaque membre ──
  Widget _buildMembreTile(Membre membre) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ── Icône statut + Nom ──
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
              Text(
                membre.nom,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
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
                  child: const Icon(Icons.check, color: Colors.white, size: 16),
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
    );
  }
}
