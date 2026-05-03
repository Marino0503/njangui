import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../services/user_service.dart';
import '../models/tontine.dart';
import '../widgets/tontine_card.dart';
import 'detail_tontine_screen.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_state.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // ── Logo + Nom app ──
              Row(
                children: [
                  Image.asset('assets/images/njangi_logo.PNG', height: 50),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Njangi',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF7B2D8B),
                        ),
                      ),
                      Text(
                        'la tontine, sans conflit',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF7B2D8B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ── Bonjour + vrai nom ──
              StreamBuilder<Map<String, dynamic>?>(
                stream: UserService().getProfilStream(),
                builder: (context, snapshot) {
                  final nom = snapshot.data?['nom'] ?? '';
                  return Center(
                    child: Text(
                      nom.isEmpty ? 'Bonjour !' : 'Bonjour $nom !',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              // ── Bannière ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF90EED4),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'Créez vos tontines en toute transparence, sans conflits',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),

              const SizedBox(height: 24),

              // ── Titre section ──
              const Text(
                'Mes tontines',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 16),

              // ── Liste depuis Firestore ──
              RefreshIndicator(
                color: const Color(0xFF2E9E6E),
                onRefresh: () async {
                  await Future.delayed(const Duration(seconds: 1));
                },
                child: StreamBuilder<List<Tontine>>(
                  stream: FirestoreService().getTontines(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF2E9E6E),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return ErrorState(
                        message:
                            'Impossible de charger les tontines.\nVérifiez votre connexion.',
                        onReessayer: () {},
                      );
                    }

                    final tontines = snapshot.data ?? [];

                    if (tontines.isEmpty) {
                      return EmptyState(
                        icon: Icons.groups_outlined,
                        titre: 'Pas encore de tontine',
                        message:
                            'Allez dans l\'onglet Tontines\npour en créer une !',
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: tontines.length,
                      itemBuilder: (context, index) {
                        return TontineCard(
                          tontine: tontines[index],
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DetailTontineScreen(
                                  tontine: tontines[index],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
