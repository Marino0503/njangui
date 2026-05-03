import 'package:flutter/material.dart';
import '../services/user_service.dart';
import 'main_screen.dart';

class CompleteProfilScreen extends StatefulWidget {
  final String phoneNumber;

  const CompleteProfilScreen({super.key, required this.phoneNumber});

  @override
  State<CompleteProfilScreen> createState() => _CompleteProfilScreenState();
}

class _CompleteProfilScreenState extends State<CompleteProfilScreen> {
  final TextEditingController _nomController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nomController.dispose();
    super.dispose();
  }

  Future<void> _sauvegarderProfil() async {
    if (_nomController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer votre nom'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Sauvegarde le profil dans Firestore
      await UserService().sauvegarderProfil(
        nom: _nomController.text.trim(),
        telephone: widget.phoneNumber,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      // Navigate vers MainScreen
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 60),

              // ── Logo ──
              Image.asset('assets/images/njangi_logo.PNG', height: 80),

              const SizedBox(height: 40),

              // ── Titre ──
              const Text(
                'Complétez votre profil',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF7B2D8B),
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                'Entrez votre nom pour continuer',
                style: TextStyle(fontSize: 15, color: Colors.grey),
              ),

              const SizedBox(height: 50),

              // ── Avatar ──
              const CircleAvatar(
                radius: 50,
                backgroundColor: Color(0xFF90EED4),
                child: Icon(Icons.person, size: 60, color: Colors.white),
              ),

              const SizedBox(height: 40),

              // ── Champ nom ──
              TextField(
                controller: _nomController,
                textCapitalization: TextCapitalization.words,
                style: const TextStyle(fontSize: 18),
                decoration: InputDecoration(
                  labelText: 'Votre nom complet',
                  hintText: 'Ex: Jean Dupont',
                  prefixIcon: const Icon(
                    Icons.person_outline,
                    color: Color(0xFF7B2D8B),
                  ),
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
              ),

              const SizedBox(height: 16),

              // ── Numéro (non modifiable) ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.phone_outlined, color: Colors.grey),
                    const SizedBox(width: 12),
                    Text(
                      widget.phoneNumber,
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // ── Bouton continuer ──
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _sauvegarderProfil,
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
                      : const Text('Continuer', style: TextStyle(fontSize: 16)),
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
