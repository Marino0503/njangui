import 'package:flutter/material.dart';
import 'verify_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Contrôleur pour récupérer le texte saisi
  final TextEditingController _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _onReceiveCode() {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer votre numéro')),
      );
      return;
    }

    // ✅ Formate le numéro en E.164 : +237XXXXXXXXX
    String formattedPhone = phone;
    if (!phone.startsWith('+')) {
      formattedPhone = '+237$phone';
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VerifyScreen(phoneNumber: formattedPhone),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),

              // ── Logo + Nom de l'app ──
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/images/njangi_logo.PNG', height: 80),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Njangi',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF7B2D8B), // violet
                        ),
                      ),
                      Text(
                        'la tontine, sans conflit',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF7B2D8B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 60),

              // ── Titre de bienvenue ──
              const Text(
                'BIENVENUS SUR Njangi',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E8B9A), // bleu-vert
                ),
              ),

              const SizedBox(height: 24),

              // ── Texte descriptif ──
              const Text(
                'Organisez vos tontines avec des règles claires et des preuves',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.black87),
              ),

              const SizedBox(height: 50),

              // ── Champ numéro de téléphone ──
              // ── Champ numéro de téléphone ──
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: 'Entrez le numéro',
                  // ← Indicatif Cameroun affiché en préfixe
                  prefixIcon: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    child: Text(
                      '🇨🇲 +237',
                      style: TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(
                      color: Color(0xFF7B2D8B),
                      width: 2,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // ── Bouton "Recevoir le code" ──
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _onReceiveCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF90EED4), // vert menthe
                    foregroundColor: Colors.black87,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Recevoir le code',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
