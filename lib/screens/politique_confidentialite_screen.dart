import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

class PolitiqueConfidentialiteScreen extends StatelessWidget {
  const PolitiqueConfidentialiteScreen({super.key});

  static const String _contenuFr = '''
Dernière mise à jour : 22 juillet 2026

1. Données collectées
- Données de compte : numéro de téléphone (utilisé pour la connexion), nom complet.
- Photo de profil (facultative), si vous choisissez d'en ajouter une.
- Données de tontines : tontines créées ou rejointes, montants des cotisations, historique des paiements, prêts, sanctions de retard, et messages de notification.
- Messages envoyés au chatbot d'assistance (Njangi Assistant).

2. Utilisation des données
Ces données servent uniquement à faire fonctionner l'application : gérer votre compte, afficher vos tontines et celles de vos groupes, calculer les échéances et pénalités, et vous envoyer des notifications liées à votre activité.

3. Partage des données avec des tiers
Nous ne vendons aucune donnée. Certaines données transitent par des prestataires techniques nécessaires au fonctionnement du service :
- Google Firebase / Google Cloud (Cameroun n'ayant pas d'hébergeur reconnu équivalent) : hébergement de la base de données, authentification, notifications.
- Fapshi : lors d'un paiement par Orange Money ou MTN Mobile Money, votre identifiant utilisateur et le montant de la transaction sont transmis à Fapshi pour traiter le paiement. Njangi ne voit jamais votre numéro Mobile Money ni vos identifiants Fapshi.
- Google Gemini (Google Generative AI) : les messages que vous envoyez au chatbot d'assistance sont transmis à l'API Gemini de Google pour générer une réponse. N'envoyez pas d'informations sensibles (mots de passe, coordonnées bancaires complètes) dans le chatbot.

4. Conservation des données
Vos données sont conservées tant que votre compte est actif. En cas de suppression de compte, vos données de profil sont supprimées ; les données liées aux tontines dont vous êtes membre (paiements, historique) peuvent être conservées dans l'intérêt des autres membres du groupe, sous une forme ne permettant plus de vous identifier directement lorsque cela est possible.

5. Sécurité
L'accès aux données de chaque tontine est limité à son gestionnaire et à ses membres. Les paiements réels via Mobile Money sont vérifiés par une confirmation serveur avant d'être enregistrés comme effectués.

6. Vos droits
Vous pouvez à tout moment :
- consulter et corriger vos informations de profil depuis l'application ;
- demander la suppression de votre compte et de vos données personnelles en contactant le support ;
- retirer votre consentement à l'usage du chatbot en n'y envoyant simplement pas de message.

7. Âge minimum
L'application s'adresse à des utilisateurs majeurs, dans la mesure où elle implique la gestion d'argent réel entre particuliers.

8. Modifications
Cette politique peut être mise à jour ; la date de dernière mise à jour est indiquée en haut de ce document.

9. Contact
Pour toute question ou demande relative à vos données personnelles, contactez le support depuis l'application.

Ce document est un modèle fourni à titre indicatif et ne remplace pas un conseil juridique adapté à votre situation.
''';

  static const String _contenuEn = '''
Last updated: July 22, 2026

1. Data we collect
- Account data: phone number (used for login), full name.
- Profile photo (optional), if you choose to add one.
- Tontine data: tontines you created or joined, contribution amounts, payment history, loans, late-payment penalties, and notification messages.
- Messages you send to the assistant chatbot (Njangi Assistant).

2. How we use this data
This data is used solely to operate the application: manage your account, display your tontines and those of your groups, calculate due dates and penalties, and send you notifications related to your activity.

3. Sharing data with third parties
We do not sell any data. Some data passes through technical providers necessary for the service to function:
- Google Firebase / Google Cloud: database hosting, authentication, notifications.
- Fapshi: when you make a payment via Orange Money or MTN Mobile Money, your user ID and the transaction amount are sent to Fapshi to process the payment. Njangi never sees your Mobile Money number or your Fapshi credentials.
- Google Gemini (Google Generative AI): messages you send to the assistant chatbot are sent to Google's Gemini API to generate a reply. Do not send sensitive information (passwords, full bank details) through the chatbot.

4. Data retention
Your data is kept while your account is active. If you delete your account, your profile data is deleted; data related to tontines you were a member of (payments, history) may be retained in the interest of other group members, in a form that no longer directly identifies you where possible.

5. Security
Access to each tontine's data is limited to its manager and its members. Real Mobile Money payments are verified by a server-side confirmation before being recorded as completed.

6. Your rights
You may at any time:
- view and correct your profile information from within the app;
- request deletion of your account and personal data by contacting support;
- withdraw consent to chatbot usage simply by not sending it any message.

7. Minimum age
The application is intended for adult users, as it involves managing real money between individuals.

8. Changes
This policy may be updated; the last update date is shown at the top of this document.

9. Contact
For any question or request regarding your personal data, contact support from within the application.

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
                            ? 'Politique de confidentialité'
                            : 'Privacy policy',
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
