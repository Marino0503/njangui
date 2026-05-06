import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/onboarding_page.dart';
import '../providers/app_provider.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Pages d'onboarding
  List<OnboardingPage> _getPages(String langue) {
    if (langue == 'fr') {
      return const [
        OnboardingPage(
          titre: 'Bienvenue sur Njangi !',
          description:
              'Organisez vos tontines en toute transparence et sans conflits avec vos proches.',
          icone: Icons.groups,
          couleur: Color(0xFF7B2D8B),
        ),
        OnboardingPage(
          titre: 'Gérez vos cotisations',
          description:
              'Créez ou rejoignez une tontine, suivez les paiements en temps réel et gardez un historique complet.',
          icone: Icons.account_balance_wallet,
          couleur: Color(0xFF2E9E6E),
        ),
        OnboardingPage(
          titre: 'Paiements sécurisés',
          description:
              'Payez facilement via Orange Money, MTN Mobile Money ou virement bancaire.',
          icone: Icons.payment,
          couleur: Color(0xFF7B2D8B),
        ),
      ];
    } else {
      return const [
        OnboardingPage(
          titre: 'Welcome to Njangi!',
          description:
              'Organize your tontines transparently and without conflicts with your loved ones.',
          icone: Icons.groups,
          couleur: Color(0xFF7B2D8B),
        ),
        OnboardingPage(
          titre: 'Manage your contributions',
          description:
              'Create or join a tontine, track payments in real time and keep a complete history.',
          icone: Icons.account_balance_wallet,
          couleur: Color(0xFF2E9E6E),
        ),
        OnboardingPage(
          titre: 'Secure payments',
          description:
              'Pay easily via Orange Money, MTN Mobile Money or bank transfer.',
          icone: Icons.payment,
          couleur: Color(0xFF7B2D8B),
        ),
      ];
    }
  }

  // Termine l'onboarding
  Future<void> _terminerOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        final pages = _getPages(provider.langue);

        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Column(
              children: [
                // ── Bouton passer ──
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextButton(
                      onPressed: _terminerOnboarding,
                      child: Text(
                        provider.langue == 'fr' ? 'Passer' : 'Skip',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Pages ──
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: pages.length,
                    onPageChanged: (index) {
                      setState(() => _currentPage = index);
                    },
                    itemBuilder: (context, index) {
                      return _buildPage(pages[index]);
                    },
                  ),
                ),

                // ── Indicateurs ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    pages.length,
                    (index) =>
                        _buildIndicateur(index, pages[_currentPage].couleur),
                  ),
                ),

                const SizedBox(height: 40),

                // ── Bouton suivant / commencer ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentPage < pages.length - 1) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          _terminerOnboarding();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: pages[_currentPage].couleur,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _currentPage < pages.length - 1
                            ? (provider.langue == 'fr' ? 'Suivant' : 'Next')
                            : (provider.langue == 'fr'
                                  ? 'Commencer'
                                  : 'Get started'),
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Widget page ──
  Widget _buildPage(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ── Icône ──
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              color: page.couleur.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(page.icone, size: 80, color: page.couleur),
          ),

          const SizedBox(height: 50),

          // ── Titre ──
          Text(
            page.titre,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: page.couleur,
            ),
          ),

          const SizedBox(height: 20),

          // ── Description ──
          Text(
            page.description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── Indicateur de page ──
  Widget _buildIndicateur(int index, Color couleur) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: _currentPage == index ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: _currentPage == index ? couleur : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
