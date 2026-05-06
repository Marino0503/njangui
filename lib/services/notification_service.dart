import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  // Singleton
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  // Initialise le service
  Future<void> initialiser() async {
    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {},
    );
  }

  // Demande la permission Android
  Future<void> demanderPermission() async {
    final plugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (plugin != null) {
      await plugin.requestNotificationsPermission();
    }
  }

  // Envoie une notification immédiate
  Future<void> envoyerNotification({
    required int id,
    required String titre,
    required String message,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'njangi_channel',
          'Njangi Notifications',
          channelDescription: 'Notifications de l\'app Njangi',
          importance: Importance.high,
          priority: Priority.high,
        );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _notifications.show(id, titre, message, details);
  }

  // Programme un rappel
  Future<void> programmerRappel({
    required int id,
    required String titre,
    required String message,
    required DateTime dateRappel,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'njangi_rappels',
          'Rappels Njangi',
          channelDescription: 'Rappels de paiement Njangi',
          importance: Importance.high,
          priority: Priority.high,
        );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
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

  // Programme les rappels pour une tontine
  Future<void> programmerRappelsTontines({
    required String nomTontine,
    required double montant,
    required DateTime dateEcheance,
    required String langue,
  }) async {
    final String montantFormate = '${montant.toStringAsFixed(0)} FCFA';

    final DateTime veille = DateTime(
      dateEcheance.year,
      dateEcheance.month,
      dateEcheance.day - 1,
      9,
      0,
    );

    final DateTime jourMeme = DateTime(
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

  // Annule un rappel
  Future<void> annulerRappel(int id) async {
    await _notifications.cancel(id);
  }

  // Annule tous les rappels
  Future<void> annulerTousLesRappels() async {
    await _notifications.cancelAll();
  }
}
