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
    'accueil': 'Accueil',
    'tontines': 'Tontines',
    'alertes': 'Alertes',
    'stats': 'Stats',
    'profil': 'Profil',
    'bonjour': 'Bonjour',
    'mesTontines': 'Mes tontines',
    'creerTontine': 'Créer une tontine',
    'rejoindre': 'Rejoindre',
    'parametres': 'Paramètres',
    'apparence': 'Apparence',
    'modeSombre': 'Mode sombre',
    'langue': 'Langue',
    'apropos': 'À propos',
    'version': 'Version',
    'deconnexion': 'Se déconnecter',
    'aucuneTontine': 'Aucune tontine pour l\'instant',
    'banniere': 'Créez vos tontines en toute transparence, sans conflits',
  };

  // ── Textes anglais ──
  static const Map<String, String> _texteEn = {
    'accueil': 'Home',
    'tontines': 'Tontines',
    'alertes': 'Alerts',
    'stats': 'Stats',
    'profil': 'Profile',
    'bonjour': 'Hello',
    'mesTontines': 'My tontines',
    'creerTontine': 'Create a tontine',
    'rejoindre': 'Join',
    'parametres': 'Settings',
    'apparence': 'Appearance',
    'modeSombre': 'Dark mode',
    'langue': 'Language',
    'apropos': 'About',
    'version': 'Version',
    'deconnexion': 'Sign out',
    'aucuneTontine': 'No tontine yet',
    'banniere': 'Organize your tontines with clear rules and no conflicts',
  };
}
