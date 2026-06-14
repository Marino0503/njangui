import 'package:flutter/material.dart';

enum TypePaiement { orangeMoney, mtnMoney, bancaire }

class ModePaiement {
  final TypePaiement type;
  final String nom;
  final String description;
  final String? logo;
  final String? image;
  final Color couleur;

  const ModePaiement({
    required this.type,
    required this.nom,
    required this.description,
    this.logo,
    this.image,
    required this.couleur,
  });

  static List<ModePaiement> get modes => [
    ModePaiement(
      type: TypePaiement.orangeMoney,
      nom: 'Orange Money',
      description: 'Paiement via Orange Money',
      image: 'assets/images/orange_money.PNG',
      couleur: const Color(0xFFFF6600),
    ),
    ModePaiement(
      type: TypePaiement.mtnMoney,
      nom: 'MTN Money',
      description: 'Paiement via MTN Mobile Money',
      image: 'assets/images/mtn_money.PNG',
      couleur: const Color(0xFFFFCC00),
    ),
    ModePaiement(
      type: TypePaiement.bancaire,
      nom: 'Virement bancaire',
      description: 'Bientot disponible',
      logo: '🏦',
      couleur: const Color(0xFF2E9E6E),
    ),
  ];
}
