import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

class ConditionsUtilisationScreen extends StatelessWidget {
  const ConditionsUtilisationScreen({super.key});

  static const String _contenuFr = '''
Dernière mise à jour : 22 juillet 2026

1. Objet
Njangi est une application permettant à un groupe de personnes de créer, gérer et suivre des tontines (cotisations collectives tournantes) : cotisations, tours de réception, prêts entre membres et sanctions de retard.

2. Compte utilisateur
L'inscription se fait par numéro de téléphone. Vous êtes responsable de la confidentialité de l'accès à votre compte et de l'exactitude des informations fournies (nom, numéro de téléphone).

3. Rôles
- Le gestionnaire crée une tontine, en définit les règles (montant, fréquence, ordre de réception) et valide l'arrivée de nouveaux membres.
- Le membre rejoint une tontine par code d'invitation ou sur invitation du gestionnaire, et s'engage à respecter les règles définies par le gestionnaire.

4. Paiements
Les cotisations via Orange Money ou MTN Mobile Money sont traitées par un prestataire de paiement tiers (Fapshi). Njangi ne détient, ne conserve et ne transfère aucun fonds : l'application n'est qu'un outil de suivi et de coordination entre les membres d'une tontine. Njangi ne peut être tenu responsable d'un litige portant sur la remise effective des fonds entre membres, d'un défaut de paiement d'un membre, ou d'une erreur de saisie du montant ou du bénéficiaire.

5. Sanctions et prêts
Les pénalités de retard et les conditions de prêt affichées dans l'application sont calculées selon les règles définies par le gestionnaire de chaque tontine. Njangi ne garantit pas le recouvrement effectif d'une pénalité ou d'un prêt impayé.

6. Comportement attendu
Vous vous engagez à ne pas fournir de fausses informations, à ne pas usurper l'identité d'un tiers, et à ne pas utiliser l'application à des fins frauduleuses.

7. Suspension et suppression de compte
Nous pouvons suspendre ou supprimer un compte en cas d'usage frauduleux avéré ou de non-respect des présentes conditions. Vous pouvez demander la suppression de votre compte à tout moment (voir Politique de confidentialité).

8. Limitation de responsabilité
L'application est fournie "en l'état". Dans la mesure permise par la loi, l'éditeur ne saurait être tenu responsable des pertes financières résultant de litiges entre membres d'une tontine, d'une indisponibilité temporaire du service, ou d'une erreur de saisie de l'utilisateur.

9. Droit applicable
Les présentes conditions sont régies par le droit camerounais.

10. Contact
Pour toute question relative à ces conditions, contactez le support depuis l'application.

Ce document est un modèle fourni à titre indicatif et ne remplace pas un conseil juridique adapté à votre situation.
''';

  static const String _contenuEn = '''
Last updated: July 22, 2026

1. Purpose
Njangi is an application allowing a group of people to create, manage and track tontines (rotating collective savings groups): contributions, payout rounds, loans between members, and late-payment penalties.

2. User account
Registration is done via phone number. You are responsible for keeping access to your account confidential and for the accuracy of the information you provide (name, phone number).

3. Roles
- The manager creates a tontine, sets its rules (amount, frequency, payout order) and approves new members.
- The member joins a tontine via an invitation code or invitation from the manager, and agrees to follow the rules set by the manager.

4. Payments
Contributions via Orange Money or MTN Mobile Money are processed by a third-party payment provider (Fapshi). Njangi does not hold, store, or transfer any funds: the application is only a tracking and coordination tool between tontine members. Njangi cannot be held responsible for a dispute over the actual transfer of funds between members, a member's failure to pay, or an error in the amount or recipient entered.

5. Penalties and loans
Late-payment penalties and loan terms shown in the application are calculated according to the rules set by each tontine's manager. Njangi does not guarantee the actual recovery of an unpaid penalty or loan.

6. Expected behavior
You agree not to provide false information, not to impersonate a third party, and not to use the application for fraudulent purposes.

7. Account suspension and deletion
We may suspend or delete an account in case of proven fraudulent use or violation of these terms. You may request deletion of your account at any time (see Privacy Policy).

8. Limitation of liability
The application is provided "as is". To the extent permitted by law, the publisher cannot be held liable for financial losses resulting from disputes between tontine members, temporary service unavailability, or user input errors.

9. Governing law
These terms are governed by Cameroonian law.

10. Contact
For any question about these terms, contact support from within the application.

This document is a template provided for guidance and does not replace legal advice tailored to your situation.
''';

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        final estFr = provider.langue == 'fr';
        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(
                          Icons.arrow_back_ios,
                          color: Color(0xFF7B2D8B),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        estFr
                            ? 'Conditions d\'utilisation'
                            : 'Terms of use',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF7B2D8B),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    child: Text(
                      estFr ? _contenuFr : _contenuEn,
                      style: const TextStyle(fontSize: 14, height: 1.5),
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
}
