import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main_screen.dart';

class OtpScreen extends StatefulWidget {
  final String verificationId;
  final String phoneNumber;

  const OtpScreen({
    super.key,
    required this.verificationId,
    required this.phoneNumber,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  // Un contrôleur par case
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );

  // Un focusNode par case pour passer automatiquement à la suivante
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isLoading = false;

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  // Récupère le code complet depuis les 6 cases
  String get _otpCode => _controllers.map((c) => c.text).join();

  // Vérifie le code avec Firebase
  Future<void> _verifyCode() async {
    if (_otpCode.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer le code complet')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: _otpCode,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      // Vérifie que le widget est encore actif après le await
      if (!mounted) return;

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Connexion réussie !')));

      // ✅ Connexion réussie → aller vers MainScreen
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      // Vérifie que le widget est encore actif après le await
      if (!mounted) return;

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Code incorrect : ${e.message}')));
    }
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

              const SizedBox(height: 20),

              // ── Numéro ──
              Text(
                widget.phoneNumber,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                'Entrez le code reçu par SMS',
                style: TextStyle(fontSize: 15, color: Colors.black54),
              ),

              const SizedBox(height: 40),

              // ── 6 cases OTP ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 48,
                    height: 58,
                    child: TextField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        counterText: '', // cache le compteur de caractères
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF7B2D8B),
                            width: 2,
                          ),
                        ),
                      ),
                      onChanged: (value) {
                        if (value.isNotEmpty && index < 5) {
                          // Passe automatiquement à la case suivante
                          FocusScope.of(
                            context,
                          ).requestFocus(_focusNodes[index + 1]);
                        }
                        if (value.isEmpty && index > 0) {
                          // Revient à la case précédente si on efface
                          FocusScope.of(
                            context,
                          ).requestFocus(_focusNodes[index - 1]);
                        }
                      },
                    ),
                  );
                }),
              ),

              const SizedBox(height: 20),

              // ── Renvoyer le code ──
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Renvoyer le code',
                  style: TextStyle(color: Color(0xFF7B2D8B), fontSize: 14),
                ),
              ),

              const Spacer(),

              // ── Bouton Valider ──
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyCode,
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
                          'Valider le code',
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
