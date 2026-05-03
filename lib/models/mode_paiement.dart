import 'package:flutter/material.dart';

enum TypePaiement { orangeMoney, mtnMoney, bancaire }

class ModePaiement {
  final TypePaiement type;
  final String nom;
  final String description;
  final String logo;
  final Color couleur;

  const ModePaiement({
    required this.type,
    required this.nom,
    required this.description,
    required this.logo,
    required this.couleur,
  });

  // Liste des modes de paiement disponibles
  static List<ModePaiement> get modes => [
    ModePaiement(
      type: TypePaiement.orangeMoney,
      nom: 'Orange Money',
      description: 'Paiement via Orange Money',
      logo: '🟠',
      couleur: const Color(0xFFFF6600),
    ),
    ModePaiement(
      type: TypePaiement.mtnMoney,
      nom: 'MTN Money',
      description: 'Paiement via MTN Mobile Money',
      logo: '🟡',
      couleur: const Color(0xFFFFCC00),
    ),
    ModePaiement(
      type: TypePaiement.bancaire,
      nom: 'Virement bancaire',
      description: 'Paiement par virement bancaire',
      logo: '🏦',
      couleur: const Color(0xFF2E9E6E),
    ),
  ];
}
