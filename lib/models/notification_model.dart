import 'package:flutter/material.dart';

enum TypeNotification {
  nouvelleTontine,
  nouveauMembre,
  retardContribution,
  nouveauDepot,
}

class NotificationModel {
  final String id;
  final String userId;
  final String titre;
  final String message;
  final DateTime date;
  final TypeNotification type;
  bool lu;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.titre,
    required this.message,
    required this.date,
    required this.type,
    this.lu = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'titre': titre,
      'message': message,
      'date': date.toIso8601String(),
      'type': type.index,
      'lu': lu,
    };
  }

  factory NotificationModel.fromMap(Map<String, dynamic> data) {
    return NotificationModel(
      id: data['id'],
      userId: data['userId'] ?? '',
      titre: data['titre'],
      message: data['message'],
      date: DateTime.parse(data['date']),
      type: TypeNotification.values[data['type']],
      lu: data['lu'] ?? false,
    );
  }

  // Icône selon le type
  static IconData iconPourType(TypeNotification type) {
    switch (type) {
      case TypeNotification.nouvelleTontine:
        return Icons.group;
      case TypeNotification.nouveauMembre:
        return Icons.person_add;
      case TypeNotification.retardContribution:
        return Icons.warning_amber;
      case TypeNotification.nouveauDepot:
        return Icons.payment;
    }
  }

  // Couleur selon le type
  static Color couleurPourType(TypeNotification type) {
    switch (type) {
      case TypeNotification.nouvelleTontine:
        return const Color(0xFF2E9E6E);
      case TypeNotification.nouveauMembre:
        return const Color(0xFF7B2D8B);
      case TypeNotification.retardContribution:
        return Colors.red;
      case TypeNotification.nouveauDepot:
        return Colors.blue;
    }
  }

  // Temps écoulé depuis la notification
  String get tempsEcoule {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    if (diff.inDays == 1) return 'Hier';
    return '${date.day}/${date.month}/${date.year}';
  }
}
