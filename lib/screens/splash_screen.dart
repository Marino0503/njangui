import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/app_provider.dart';
import '../services/user_service.dart';
import 'login_screen.dart';
import 'main_screen.dart';
import 'complete_profil_screen.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _verifierConnexion();
  }

  Future<void> _verifierConnexion() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // ✅ Vérifie si l'onboarding a déjà été vu
    final prefs = await SharedPreferences.getInstance();
    final onboardingComplete = prefs.getBool('onboarding_complete') ?? false;

    if (!mounted) return;

    // Première ouverture → Onboarding
    if (!onboardingComplete) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
      );
      return;
    }

    // Onboarding déjà vu → vérifie la connexion
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } else {
      final profilComplet = await UserService().profilEstComplet();

      if (!mounted) return;

      if (profilComplet) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      } else {
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
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
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

                // ── Tagline ──
                Text(
                  provider.langue == 'fr'
                      ? 'la tontine, sans conflit'
                      : 'the tontine, without conflict',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF7B2D8B),
                  ),
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
      },
    );
  }
}
