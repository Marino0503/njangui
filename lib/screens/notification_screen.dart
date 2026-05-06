import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/firestore_service.dart';
import '../models/notification_model.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_state.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        final textes = provider.textes;

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

                const SizedBox(height: 16),

                // ── Liste des notifications ──
                Expanded(
                  child: StreamBuilder<List<NotificationModel>>(
                    stream: FirestoreService().getNotifications(),
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
                              ? 'Impossible de charger les notifications.'
                              : 'Unable to load notifications.',
                          onReessayer: () {},
                        );
                      }

                      final notifications = snapshot.data ?? [];

                      if (notifications.isEmpty) {
                        return EmptyState(
                          icon: Icons.notifications_none,
                          titre: textes['aucuneNotification']!,
                          message: provider.langue == 'fr'
                              ? 'Vous n\'avez pas encore de notifications.'
                              : 'You have no notifications yet.',
                        );
                      }

                      final nonLues = notifications.where((n) => !n.lu).length;

                      return Column(
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

                          Expanded(
                            child: ListView.builder(
                              itemCount: notifications.length,
                              itemBuilder: (context, index) {
                                return _buildNotificationTile(
                                  context,
                                  notifications[index],
                                  provider,
                                );
                              },
                            ),
                          ),
                        ],
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
