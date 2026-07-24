import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppProvider extends ChangeNotifier {
  // Singleton
  static final AppProvider _instance = AppProvider._internal();
  factory AppProvider() => _instance;
  AppProvider._internal();

  // ── Thème ──

  // ── Langue ──
  String _langue = 'fr'; // 'fr' ou 'en'
  String get langue => _langue;

  // Textes selon la langue
  Map<String, String> get textes => _langue == 'fr' ? _texteFr : _texteEn;

  // ── Initialise depuis les préférences sauvegardées ──
  Future<void> initialiser() async {
    final prefs = await SharedPreferences.getInstance();
    //_modeSombre = prefs.getBool('modeSombre') ?? false;
    _langue = prefs.getString('langue') ?? 'fr';
    notifyListeners();
  }

  // ── Change le thème ──

  // ── Change la langue ──
  Future<void> changerLangue(String langue) async {
    _langue = langue;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('langue', langue);
    notifyListeners();
  }

  // ── Textes français ──
  static const Map<String, String> _texteFr = {
    // Navigation
    'accueil': 'Accueil',
    'tontines': 'Tontines',
    'alertes': 'Alertes',
    'stats': 'Stats',
    'profil': 'Profil',

    // Home
    'bonjour': 'Bonjour',
    'mesTontines': 'Mes tontines',
    'banniere': 'Créez vos tontines en toute transparence, sans conflits',
    'aucuneTontine': 'Aucune tontine pour l\'instant',

    // Tontines
    'creerTontine': 'Créer une tontine',
    'rejoindre': 'Rejoindre',
    'rechercher': 'Rechercher une tontine...',
    'aucunResultat': 'Aucun résultat',
    'effacerRecherche': 'Effacer la recherche',

    // Notifications
    'notifications': 'Notifications',
    'toutLire': 'Tout lire',
    'aucuneNotification': 'Aucune notification',
    'nouvelleTontineCreee': 'Nouvelle tontine créée',
    'nouveauMembre': 'Nouveau membre',
    'retardContribution': 'Retard de contribution',
    'nouveauDepot': 'Nouveau dépôt',
    'paiementEffectue': 'Paiement effectué',
    'membreSupprime': 'Membre supprimé',

    // Profil
    'monProfil': 'Mon Profil',
    'nomComplet': 'Nom complet',
    'telephone': 'Téléphone',
    'tontinesActives': 'Tontines actives',
    'deconnexion': 'Se déconnecter',
    'confirmDeconnexion': 'Voulez-vous vraiment vous déconnecter ?',
    'annuler': 'Annuler',

    // Paramètres
    'parametres': 'Paramètres',
    'apparence': 'Apparence',
    'modeSombre': 'Mode sombre',
    'langue': 'Langue',
    'apropos': 'À propos',
    'version': 'Version',
    'conditionsUtilisation': 'Conditions d\'utilisation',
    'politiqueConfidentialite': 'Politique de confidentialité',
    'compte': 'Compte',
    'supprimerCompte': 'Supprimer mon compte',
    'confirmSuppressionCompteTitre': 'Supprimer définitivement le compte ?',
    'confirmSuppressionCompteMessage':
        'Cette action est irréversible. Vos tontines gérées seul, vos paiements, prêts et notifications seront définitivement supprimés. Si vous gérez une tontine avec d\'autres membres actifs, vous devrez d\'abord la transférer ou la fermer.',
    'suppressionEnCours': 'Suppression du compte en cours...',
    'compteSupprime': 'Compte supprimé avec succès.',

    // Création tontine
    'reglesTontine': 'Règles de la tontine',
    'nomTontine': 'Nom de la tontine',
    'montant': 'Montant',
    'frequence': 'Fréquence',
    'dateDebut': 'Date de début',
    'ordreReception': 'Ordre de réception',
    'tirageAleatoire': 'Tirage aléatoire',
    'ordreDefini': 'Ordre défini',
    'nombreMembres': 'Nombre de membres',
    'paiementsEnregistres': 'Tous les paiements sont enregistrés',
    'prevuesObligatoires': 'Les prévues sont obligatoires',
    'membresVoientHistorique': 'Les membres voient l\'historique',
    'creerLaTontine': 'Créer la tontine',

    // Détails tontine
    'gestionnaire': 'Gestionnaire',
    'codeInvitation': 'Code d\'invitation',
    'membres': 'Membres',
    'ajouter': 'Ajouter',
    'historiquesPaiements': 'Historique des paiements',
    'prochaineEcheance': 'Prochaine échéance',
    'gestionTours': 'Gestion des tours',
    'modifier': 'Modifier',
    'supprimer': 'Supprimer',
    'enRetard': 'En retard',
    'paye': 'Payé',

    // Paiements
    'modePaiement': 'Mode de paiement',
    'informations': 'Informations',
    'confirmation': 'Confirmation',
    'paiementReussi': 'Paiement réussi !',
    'continuer': 'Continuer',
    'confirmerPaiement': 'Confirmer le paiement',
    'retour': 'Retour',

    // Tours
    'cagnotteParTour': 'Cagnotte par tour',
    'genererTours': 'Générer les tours',
    'aucunTour': 'Aucun tour généré',
    'complete': 'Complété',
    'completer': 'Compléter',

    // Messages
    'succes': 'Succès',
    'erreur': 'Erreur',
    'veuillerEntrer': 'Veuillez entrer',
    'codeCopie': 'Code copié !',
    'tontineCreee': 'Tontine créée avec succès !',
    'tontineModifiee': 'Tontine mise à jour avec succès !',
    'tontieSupprimee': 'Tontine supprimée avec succès !',
    'membreAjoute': 'Membre ajouté avec succès !',
    'membreSupprime2': 'Membre supprimé avec succès !',
  };

  static const Map<String, String> _texteEn = {
    // Navigation
    'accueil': 'Home',
    'tontines': 'Tontines',
    'alertes': 'Alerts',
    'stats': 'Stats',
    'profil': 'Profile',

    // Home
    'bonjour': 'Hello',
    'mesTontines': 'My tontines',
    'banniere': 'Organize your tontines with clear rules and no conflicts',
    'aucuneTontine': 'No tontine yet',

    // Tontines
    'creerTontine': 'Create a tontine',
    'rejoindre': 'Join',
    'rechercher': 'Search a tontine...',
    'aucunResultat': 'No results',
    'effacerRecherche': 'Clear search',

    // Notifications
    'notifications': 'Notifications',
    'toutLire': 'Mark all read',
    'aucuneNotification': 'No notifications',
    'nouvelleTontineCreee': 'New tontine created',
    'nouveauMembre': 'New member',
    'retardContribution': 'Late contribution',
    'nouveauDepot': 'New deposit',
    'paiementEffectue': 'Payment made',
    'membreSupprime': 'Member removed',

    // Profil
    'monProfil': 'My Profile',
    'nomComplet': 'Full name',
    'telephone': 'Phone',
    'tontinesActives': 'Active tontines',
    'deconnexion': 'Sign out',
    'confirmDeconnexion': 'Are you sure you want to sign out?',
    'annuler': 'Cancel',

    // Paramètres
    'parametres': 'Settings',
    'apparence': 'Appearance',
    'modeSombre': 'Dark mode',
    'langue': 'Language',
    'apropos': 'About',
    'version': 'Version',
    'conditionsUtilisation': 'Terms of use',
    'politiqueConfidentialite': 'Privacy policy',
    'compte': 'Account',
    'supprimerCompte': 'Delete my account',
    'confirmSuppressionCompteTitre': 'Permanently delete your account?',
    'confirmSuppressionCompteMessage':
        'This action is irreversible. Tontines you manage alone, your payments, loans and notifications will be permanently deleted. If you manage a tontine with other active members, you must transfer or close it first.',
    'suppressionEnCours': 'Deleting account...',
    'compteSupprime': 'Account deleted successfully.',

    // Création tontine
    'reglesTontine': 'Tontine rules',
    'nomTontine': 'Tontine name',
    'montant': 'Amount',
    'frequence': 'Frequency',
    'dateDebut': 'Start date',
    'ordreReception': 'Reception order',
    'tirageAleatoire': 'Random draw',
    'ordreDefini': 'Defined order',
    'nombreMembres': 'Number of members',
    'paiementsEnregistres': 'All payments are recorded',
    'prevuesObligatoires': 'Meetings are mandatory',
    'membresVoientHistorique': 'Members can see history',
    'creerLaTontine': 'Create tontine',

    // Détails tontine
    'gestionnaire': 'Manager',
    'codeInvitation': 'Invitation code',
    'membres': 'Members',
    'ajouter': 'Add',
    'historiquesPaiements': 'Payment history',
    'prochaineEcheance': 'Next deadline',
    'gestionTours': 'Tour management',
    'modifier': 'Edit',
    'supprimer': 'Delete',
    'enRetard': 'Late',
    'paye': 'Paid',

    // Paiements
    'modePaiement': 'Payment method',
    'informations': 'Information',
    'confirmation': 'Confirmation',
    'paiementReussi': 'Payment successful!',
    'continuer': 'Continue',
    'confirmerPaiement': 'Confirm payment',
    'retour': 'Back',

    // Tours
    'cagnotteParTour': 'Jackpot per tour',
    'genererTours': 'Generate tours',
    'aucunTour': 'No tours generated',
    'complete': 'Completed',
    'completer': 'Complete',

    // Messages
    'succes': 'Success',
    'erreur': 'Error',
    'veuillerEntrer': 'Please enter',
    'codeCopie': 'Code copied!',
    'tontineCreee': 'Tontine created successfully!',
    'tontineModifiee': 'Tontine updated successfully!',
    'tontieSupprimee': 'Tontine deleted successfully!',
    'membreAjoute': 'Member added successfully!',
    'membreSupprime2': 'Member deleted successfully!',
  };
}
