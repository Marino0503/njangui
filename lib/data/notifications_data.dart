import '../models/notification_model.dart';

class NotificationsData {
  // Singleton
  static final NotificationsData _instance = NotificationsData._internal();
  factory NotificationsData() => _instance;
  NotificationsData._internal();

  // Liste des notifications
  final List<NotificationModel> notifications = [];

  // Nombre de notifications non lues
  int get nonLues => notifications.where((n) => !n.lu).length;

  // Ajouter une notification
  void ajouterNotification(NotificationModel notification) {
    notifications.insert(0, notification); // ajoute en haut de la liste
  }

  // Marquer une notification comme lue
  void marquerCommeLue(String id) {
    final index = notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      notifications[index].lu = true;
    }
  }

  // Marquer toutes comme lues
  void marquerToutesCommeLues() {
    for (var n in notifications) {
      n.lu = true;
    }
  }

  // ── Méthodes pour créer des notifications automatiquement ──

  // Quand une nouvelle tontine est créée
  void notifierNouvelleTontine(String nomTontine) {
    ajouterNotification(
      NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        titre: 'Nouvelle tontine créée',
        message: 'Vous avez créé la tontine "$nomTontine"',
        date: DateTime.now(),
        type: TypeNotification.nouvelleTontine,
      ),
    );
  }

  // Quand un nouveau membre rejoint
  void notifierNouveauMembre(String nomMembre, String nomTontine) {
    ajouterNotification(
      NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        titre: 'Nouveau membre',
        message: '$nomMembre a rejoint la tontine "$nomTontine"',
        date: DateTime.now(),
        type: TypeNotification.nouveauMembre,
      ),
    );
  }

  // Quand un membre est en retard
  void notifierRetard(String nomMembre, String nomTontine) {
    ajouterNotification(
      NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        titre: 'Retard de contribution',
        message: '$nomMembre est en retard dans la tontine "$nomTontine"',
        date: DateTime.now(),
        type: TypeNotification.retardContribution,
      ),
    );
  }

  // Quand un nouveau dépôt est fait
  void notifierNouveauDepot(
    String nomMembre,
    double montant,
    String nomTontine,
  ) {
    ajouterNotification(
      NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        titre: 'Nouveau dépôt',
        message:
            '$nomMembre a payé ${montant.toStringAsFixed(0)} FCFA dans "$nomTontine"',
        date: DateTime.now(),
        type: TypeNotification.nouveauDepot,
      ),
    );
  }
}
