import 'package:flutter/material.dart';
import '../data/notifications_data.dart';
import '../models/notification_model.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final NotificationsData _data = NotificationsData();

  @override
  Widget build(BuildContext context) {
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
                  const Text(
                    'Notifications',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  // Bouton tout marquer comme lu
                  if (_data.nonLues > 0)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _data.marquerToutesCommeLues();
                        });
                      },
                      child: const Text(
                        'Tout lire',
                        style: TextStyle(color: Color(0xFF7B2D8B)),
                      ),
                    ),
                ],
              ),
            ),

            // ── Badge nombre non lues ──
            if (_data.nonLues > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
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
                    '${_data.nonLues} non lue(s)',
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // ── Liste des notifications ──
            Expanded(
              child: _data.notifications.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_none,
                            size: 70,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Aucune notification',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _data.notifications.length,
                      itemBuilder: (context, index) {
                        final notif = _data.notifications[index];
                        return _buildNotificationTile(notif);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationTile(NotificationModel notif) {
    final couleur = NotificationModel.couleurPourType(notif.type);
    final icone = NotificationModel.iconPourType(notif.type);

    return GestureDetector(
      onTap: () {
        setState(() {
          _data.marquerCommeLue(notif.id);
        });
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
            // ── Icône ──
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: couleur.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icone, color: couleur, size: 22),
            ),

            const SizedBox(width: 14),

            // ── Texte ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        notif.titre,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: notif.lu
                              ? FontWeight.normal
                              : FontWeight.bold,
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

            // ── Point rouge si non lu ──
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
