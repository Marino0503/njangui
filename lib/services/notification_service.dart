import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  // Singleton
  static final NotificationService _instance =
      NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialise = false;

  // Initialise le service (idempotent)
  Future<void> initialiser() async {
    if (_initialise) return;

    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Africa/Douala'));

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@drawable/ic_notification'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
      linux: LinuxInitializationSettings(defaultActionName: 'Ouvrir'),
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse r) {},
    );

    _initialise = true;
  }

  // Demande les permissions nécessaires (Android 13+ et iOS)
  Future<void> demanderPermission() async {
    final android = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.requestNotificationsPermission();
    await android?.requestExactAlarmsPermission();

    final ios = _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    await ios?.requestPermissions(alert: true, badge: true, sound: true);
  }

  // Affiche une notification immédiate
  Future<void> envoyerNotification({
    required int id,
    required String titre,
    required String message,
  }) async {
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

  // Programme une notification à une date donnée
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

    try {
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
    } on Exception {
      // La permission d'alarme exacte peut être refusée par l'utilisateur :
      // on retombe sur un mode non-exact plutôt que de planter l'appel.
      await _notifications.zonedSchedule(
        id,
        titre,
        message,
        tz.TZDateTime.from(dateRappel, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  // Programme les rappels de cotisation (veille + jour même) pour une tontine
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
}
