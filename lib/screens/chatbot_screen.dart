import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/chatbot_service.dart';

class MessageChat {
  final String texte;
  final bool estUtilisateur;
  final DateTime date;

  MessageChat({
    required this.texte,
    required this.estUtilisateur,
    required this.date,
  });
}

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<MessageChat> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    ChatbotService().initialiser();
    final provider = Provider.of<AppProvider>(context, listen: false);
    _ajouterMessageBot(
      provider.langue == 'fr'
          ? '👋 Bonjour ! Je suis l\'assistant Njangi.\n\nComment puis-je vous aider aujourd\'hui ?'
          : '👋 Hello! I\'m the Njangi assistant.\n\nHow can I help you today?',
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _ajouterMessageBot(String texte) {
    setState(() {
      _messages.add(
        MessageChat(texte: texte, estUtilisateur: false, date: DateTime.now()),
      );
    });
    _scrollerEnBas();
  }

  void _scrollerEnBas() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _envoyerMessage() async {
    final texte = _messageController.text.trim();
    if (texte.isEmpty) return;

    setState(() {
      _messages.add(
        MessageChat(texte: texte, estUtilisateur: true, date: DateTime.now()),
      );
      _isLoading = true;
    });

    _messageController.clear();
    _scrollerEnBas();

    final reponse = await ChatbotService().envoyerMessage(texte);

    if (!mounted) return;

    setState(() {
      _messages.add(
        MessageChat(
          texte: reponse,
          estUtilisateur: false,
          date: DateTime.now(),
        ),
      );
      _isLoading = false;
    });

    _scrollerEnBas();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),

                // ── Header ──
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
                      const SizedBox(width: 12),

                      // ── Avatar bot ──
                      Container(
                        width: 45,
                        height: 45,
                        decoration: const BoxDecoration(
                          color: Color(0xFF7B2D8B),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.smart_toy,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),

                      const SizedBox(width: 12),

                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            provider.langue == 'fr'
                                ? 'Assistant Njangi'
                                : 'Njangi Assistant',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF7B2D8B),
                            ),
                          ),
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF2E9E6E),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                provider.langue == 'fr' ? 'En ligne' : 'Online',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF2E9E6E),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const Divider(height: 24),

                // ── Questions rapides ──
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      _buildQuestionRapide(
                        provider.langue == 'fr'
                            ? 'Comment créer une tontine ?'
                            : 'How to create a tontine?',
                      ),
                      _buildQuestionRapide(
                        provider.langue == 'fr'
                            ? 'Comment rejoindre une tontine ?'
                            : 'How to join a tontine?',
                      ),
                      _buildQuestionRapide(
                        provider.langue == 'fr'
                            ? 'Comment payer ?'
                            : 'How to pay?',
                      ),
                      _buildQuestionRapide(
                        provider.langue == 'fr'
                            ? 'Comment ça marche ?'
                            : 'How does it work?',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // ── Liste des messages ──
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      return _buildMessage(_messages[index]);
                    },
                  ),
                ),

                // ── Indicateur de chargement ──
                if (_isLoading)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 45,
                          height: 45,
                          decoration: const BoxDecoration(
                            color: Color(0xFF7B2D8B),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.smart_toy,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              _buildDot(),
                              const SizedBox(width: 4),
                              _buildDot(),
                              const SizedBox(width: 4),
                              _buildDot(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                // ── Champ de saisie ──
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          textCapitalization: TextCapitalization.sentences,
                          onSubmitted: (_) => _envoyerMessage(),
                          decoration: InputDecoration(
                            hintText: provider.langue == 'fr'
                                ? 'Posez votre question...'
                                : 'Ask your question...',
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: const BorderSide(
                                color: Color(0xFF7B2D8B),
                                width: 1.5,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // ── Bouton envoyer ──
                      GestureDetector(
                        onTap: _envoyerMessage,
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: const BoxDecoration(
                            color: Color(0xFF7B2D8B),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.send,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMessage(MessageChat message) {
    final estUtilisateur = message.estUtilisateur;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: estUtilisateur
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!estUtilisateur) ...[
            Container(
              width: 35,
              height: 35,
              decoration: const BoxDecoration(
                color: Color(0xFF7B2D8B),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 8),
          ],

          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: estUtilisateur
                    ? const Color(0xFF7B2D8B)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: estUtilisateur
                      ? const Radius.circular(16)
                      : const Radius.circular(4),
                  bottomRight: estUtilisateur
                      ? const Radius.circular(4)
                      : const Radius.circular(16),
                ),
              ),
              child: Text(
                message.texte,
                style: TextStyle(
                  fontSize: 15,
                  color: estUtilisateur ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ),

          if (estUtilisateur) ...[
            const SizedBox(width: 8),
            Container(
              width: 35,
              height: 35,
              decoration: const BoxDecoration(
                color: Color(0xFF2E9E6E),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 20),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuestionRapide(String question) {
    return GestureDetector(
      onTap: () {
        _messageController.text = question;
        _envoyerMessage();
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF7B2D8B).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF7B2D8B).withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          question,
          style: const TextStyle(fontSize: 13, color: Color(0xFF7B2D8B)),
        ),
      ),
    );
  }

  Widget _buildDot() {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: Colors.grey.shade400,
        shape: BoxShape.circle,
      ),
    );
  }
}
