import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_service.dart';
import 'login_screen.dart';
import 'main_screen.dart';
import 'complete_profil_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Lance la vérification dès que la page s'affiche
    _verifierConnexion();
  }

  Future<void> _verifierConnexion() async {
    // Attendre 2 secondes pour afficher le splash
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // Pas connecté → Login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } else {
      // Connecté → vérifie si profil complet
      final profilComplet = await UserService().profilEstComplet();

      if (!mounted) return;

      if (profilComplet) {
        // Profil complet → MainScreen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      } else {
        // Profil incomplet → Compléter le profil
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                CompleteProfilScreen(phoneNumber: user.phoneNumber ?? ''),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── Logo ──
            Image.asset('assets/images/njangi_logo.PNG', height: 120),

            const SizedBox(height: 20),

            // ── Nom app ──
            const Text(
              'Njangi',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Color(0xFF7B2D8B),
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'la tontine, sans conflit',
              style: TextStyle(fontSize: 16, color: Color(0xFF7B2D8B)),
            ),

            const SizedBox(height: 60),

            // ── Indicateur de chargement ──
            const CircularProgressIndicator(
              color: Color(0xFF2E9E6E),
              strokeWidth: 3,
            ),
          ],
        ),
      ),
    );
  }
}
