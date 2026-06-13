import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/firestore_service.dart';
import '../services/user_service.dart';
import '../models/notification_model.dart';
import '../models/demande_adhesion.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_state.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        final textes = provider.textes;
        final monUid = UserService().uidActuel;

        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // ── Titre + bouton tout lire ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        textes['notifications']!,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          await FirestoreService().marquerToutesCommeLues();
                        },
                        child: Text(
                          textes['toutLire']!,
                          style: const TextStyle(color: Color(0xFF7B2D8B)),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ── Liste ──
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── SECTION : Demandes d'adhésion en attente ──
                        if (monUid != null)
                          StreamBuilder<List<DemandeAdhesion>>(
                            stream: FirestoreService()
                                .getDemandesPourUtilisateur(monUid),
                            builder: (context, snapshot) {
                              final demandes = snapshot.data ?? [];
                              if (demandes.isEmpty) {
                                return const SizedBox.shrink();
                              }

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                    ),
                                    child: Text(
                                      provider.langue == 'fr'
                                          ? 'Demandes en attente'
                                          : 'Pending requests',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF7B2D8B),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ...demandes.map(
                                    (d) =>
                                        _buildDemandeTile(context, d, provider),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              );
                            },
                          ),

                        // ── SECTION : Notifications ──
                        StreamBuilder<List<NotificationModel>>(
                          stream: FirestoreService().getNotifications(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 40),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: Color(0xFF2E9E6E),
                                  ),
                                ),
                              );
                            }

                            if (snapshot.hasError) {
                              return ErrorState(
                                message: provider.langue == 'fr'
                                    ? 'Impossible de charger les notifications.'
                                    : 'Unable to load notifications.',
                                onReessayer: () {},
                              );
                            }

                            final notifications = snapshot.data ?? [];

                            if (notifications.isEmpty) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 60),
                                child: EmptyState(
                                  icon: Icons.notifications_none,
                                  titre: textes['aucuneNotification']!,
                                  message: provider.langue == 'fr'
                                      ? 'Vous n\'avez pas encore de notifications.'
                                      : 'You have no notifications yet.',
                                ),
                              );
                            }

                            final nonLues = notifications
                                .where((n) => !n.lu)
                                .length;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (nonLues > 0)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF7B2D8B),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        provider.langue == 'fr'
                                            ? '$nonLues non lue(s)'
                                            : '$nonLues unread',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 12),
                                ...notifications.map(
                                  (notif) => _buildNotificationTile(
                                    context,
                                    notif,
                                    provider,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Tile pour une demande d'adhésion ──
  Widget _buildDemandeTile(
    BuildContext context,
    DemandeAdhesion demande,
    AppProvider provider,
  ) {
    final estInvitation = demande.type == TypeDemande.invitation;

    final message = estInvitation
        ? (provider.langue == 'fr'
              ? '${demande.gestionnaireNom} veut vous ajouter à "${demande.tontineNom}"'
              : '${demande.gestionnaireNom} wants to add you to "${demande.tontineNom}"')
        : (provider.langue == 'fr'
              ? '${demande.userNom} veut rejoindre "${demande.tontineNom}"'
              : '${demande.userNom} wants to join "${demande.tontineNom}"');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF9F6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2E9E6E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.group_add, color: Color(0xFF2E9E6E)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    await FirestoreService().refuserDemande(demande);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(provider.langue == 'fr' ? 'Refuser' : 'Decline'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    await FirestoreService().accepterDemande(demande);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E9E6E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 0,
                  ),
                  child: Text(provider.langue == 'fr' ? 'Accepter' : 'Accept'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _traduireTitre(NotificationModel notif, AppProvider provider) {
    final textes = provider.textes;
    switch (notif.type) {
      case TypeNotification.nouvelleTontine:
        return textes['nouvelleTontineCreee']!;
      case TypeNotification.nouveauMembre:
        return textes['nouveauMembre']!;
      case TypeNotification.retardContribution:
        return textes['retardContribution']!;
      case TypeNotification.nouveauDepot:
        return textes['nouveauDepot']!;
    }
  }

  Widget _buildNotificationTile(
    BuildContext context,
    NotificationModel notif,
    AppProvider provider,
  ) {
    final couleur = NotificationModel.couleurPourType(notif.type);
    final icone = NotificationModel.iconPourType(notif.type);

    return GestureDetector(
      onTap: () async {
        await FirestoreService().marquerNotifCommeLue(notif.id);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: notif.lu ? Colors.white : const Color(0xFFEFF9F6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: notif.lu ? Colors.grey.shade200 : const Color(0xFF90EED4),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: couleur.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icone, color: couleur, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _traduireTitre(notif, provider),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: notif.lu
                                ? FontWeight.normal
                                : FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        notif.tempsEcoule,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notif.message,
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                ],
              ),
            ),
            if (!notif.lu)
              Container(
                margin: const EdgeInsets.only(left: 8),
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
