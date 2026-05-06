/*import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialiser() async {
    tz_data.initializeTimeZones();

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@drawable/ic_notification'),
      iOS: DarwinInitializationSettings(),
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse r) {},
    );
  }

  Future<void> demanderPermission() async {
    // Permission gérée automatiquement
  }

  Future<void> envoyerNotification({
    required int id,
    required String titre,
    required String message,
  }) async {
    // ── Sans icône personnalisée ──
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'njangi_channel',
        'Njangi Notifications',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _notifications.show(id, titre, message, details);
  }

  Future<void> programmerRappel({
    required int id,
    required String titre,
    required String message,
    required DateTime dateRappel,
  }) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'njangi_rappels',
        'Rappels Njangi',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _notifications.zonedSchedule(
      id,
      titre,
      message,
      tz.TZDateTime.from(dateRappel, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> programmerRappelsTontines({
    required String nomTontine,
    required double montant,
    required DateTime dateEcheance,
    required String langue,
  }) async {
    final montantFormate = '${montant.toStringAsFixed(0)} FCFA';

    final veille = DateTime(
      dateEcheance.year,
      dateEcheance.month,
      dateEcheance.day - 1,
      9,
      0,
    );

    final jourMeme = DateTime(
      dateEcheance.year,
      dateEcheance.month,
      dateEcheance.day,
      8,
      0,
    );

    if (veille.isAfter(DateTime.now())) {
      await programmerRappel(
        id: veille.millisecondsSinceEpoch ~/ 1000,
        titre: langue == 'fr' ? '⏰ Rappel Njangi' : '⏰ Njangi Reminder',
        message: langue == 'fr'
            ? 'Votre cotisation de $montantFormate pour "$nomTontine" est due demain !'
            : 'Your contribution of $montantFormate for "$nomTontine" is due tomorrow!',
        dateRappel: veille,
      );
    }

    if (jourMeme.isAfter(DateTime.now())) {
      await programmerRappel(
        id: jourMeme.millisecondsSinceEpoch ~/ 1000,
        titre: langue == 'fr'
            ? '🔔 Cotisation due aujourd\'hui !'
            : '🔔 Contribution due today!',
        message: langue == 'fr'
            ? 'N\'oubliez pas de payer $montantFormate pour "$nomTontine" aujourd\'hui !'
            : 'Don\'t forget to pay $montantFormate for "$nomTontine" today!',
        dateRappel: jourMeme,
      );
    }
  }

  Future<void> annulerRappel(int id) async {
    await _notifications.cancel(id);
  }

  Future<void> annulerTousLesRappels() async {
    await _notifications.cancelAll();
  }
}*/

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  Future<void> initialiser() async {}

  Future<void> demanderPermission() async {}

  Future<void> envoyerNotification({
    required int id,
    required String titre,
    required String message,
  }) async {
    // Les notifications sont gérées via Firestore
    print('Notification : $titre - $message');
  }

  Future<void> programmerRappelsTontines({
    required String nomTontine,
    required double montant,
    required DateTime dateEcheance,
    required String langue,
  }) async {
    // Les rappels sont gérés via Firestore
    print('Rappel programmé pour $nomTontine');
  }

  Future<void> annulerRappel(int id) async {}

  Future<void> annulerTousLesRappels() async {}
}
