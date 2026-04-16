import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'otp_screen.dart';

class VerifyScreen extends StatefulWidget {
  final String phoneNumber;

  const VerifyScreen({super.key, required this.phoneNumber});

  @override
  State<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends State<VerifyScreen> {
  bool _isLoading = false;

  // Envoie le SMS via Firebase
  Future<void> _sendSmsCode() async {
    setState(() => _isLoading = true);

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: widget.phoneNumber,

      // SMS envoyé avec succès → on navigue vers la page de saisie du code
      codeSent: (String verificationId, int? resendToken) {
        setState(() => _isLoading = false);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OtpScreen(
              verificationId: verificationId,
              phoneNumber: widget.phoneNumber,
            ),
          ),
        );
      },

      // Vérification automatique du code (Android uniquement)
      verificationCompleted: (PhoneAuthCredential credential) async {
        await FirebaseAuth.instance.signInWithCredential(credential);
      },

      // Erreur
      verificationFailed: (FirebaseAuthException e) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur : ${e.message}')));
      },

      codeAutoRetrievalTimeout: (String verificationId) {},
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
              const SizedBox(height: 20),

              // ── Bouton retour + Titre ──
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Row(
                  children: const [
                    Icon(
                      Icons.arrow_back_ios,
                      color: Color(0xFF7B2D8B),
                      size: 18,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Vérifiez votre Numéro',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF7B2D8B),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 50),

              // ── Avatar ──
              Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey.shade200,
                ),
                child: const Icon(Icons.person, size: 80, color: Colors.grey),
              ),

              const SizedBox(height: 30),

              // ── Numéro ──
              Text(
                widget.phoneNumber,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 20),

              // ── Message ──
              const Text(
                'Un code de vérification a été envoyé par SMS',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.black54),
              ),

              const Spacer(),

              // ── Bouton ──
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _sendSmsCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF90EED4),
                    foregroundColor: Colors.black87,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Recevoir le code',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
