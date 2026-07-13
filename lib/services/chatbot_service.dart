import 'package:google_generative_ai/google_generative_ai.dart';

class ChatbotService {
  // Singleton
  static final ChatbotService _instance = ChatbotService._internal();
  factory ChatbotService() => _instance;
  ChatbotService._internal();

  // Clé API Gemini, fournie via --dart-define-from-file (voir dart_defines.example.json)
  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY');

  // Modèle Gemini
  late final GenerativeModel _model;
  late final ChatSession _chat;

  // Initialise le chatbot
  void initialiser() {
    if (_apiKey.isEmpty) {
      throw StateError(
        'GEMINI_API_KEY manquante. Lancez l\'app avec '
        '--dart-define-from-file=dart_defines.json (voir dart_defines.example.json).',
      );
    }

    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: _apiKey,
      systemInstruction: Content.system('''
Tu es un assistant virtuel de l'application Njangi,
une application de gestion de tontines au Cameroun.

RÈGLE IMPORTANTE : Détecte automatiquement la langue de l'utilisateur et réponds TOUJOURS dans la même langue :
- Si la question est en français → réponds en français
- If the question is in English → answer in English
- Si la question est en d'autres langues → réponds en français par défaut

Tu aides les utilisateurs à :
- Créer et gérer leurs tontines / Create and manage their tontines
- Comprendre comment fonctionne l'application / Understand how the app works
- Résoudre leurs problèmes / Solve their problems
- Effectuer des paiements / Make payments

Utilise des emojis pour rendre les réponses plus agréables.
Sois sympathique et professionnel.
Réponds de manière claire et concise.

Fonctionnalités principales :
1. Créer une tontine avec un nom, montant et fréquence
2. Rejoindre une tontine via un code d\'invitation
3. Ajouter et gérer des membres
4. Paiements : Orange Money, MTN Money, virement bancaire
5. Statistiques et rapports
6. Notifications en temps réel
7. Historique des paiements
8. Partage du code d\'invitation via WhatsApp ou SMS
'''),
    );

    _chat = _model.startChat();
  }

  // Envoie un message
  Future<String> envoyerMessage(String message) async {
    try {
      final response = await _chat.sendMessage(Content.text(message));
      return response.text ??
          'Désolé je n\'ai pas compris. Pouvez-vous reformuler ?';
    } catch (e) {
      print('Erreur Gemini : $e'); // ← affiche l'erreur dans le terminal
      return 'Désolé, je rencontre un problème : $e';
    }
  }
}
