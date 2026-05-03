import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../models/tontine.dart';
import '../widgets/tontine_card.dart';
import 'detail_tontine_screen.dart';

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

              // ── Bonjour utilisateur ──
              const Center(
                child: Text(
                  'Bonjour !',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                ),
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
              StreamBuilder<List<Tontine>>(
                stream: FirestoreService().getTontines(),
                builder: (context, snapshot) {
                  // Chargement
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF2E9E6E),
                      ),
                    );
                  }

                  // Erreur
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Erreur : ${snapshot.error}',
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  }

                  final tontines = snapshot.data ?? [];

                  // Liste vide
                  if (tontines.isEmpty) {
                    return const Center(
                      child: Text(
                        'Aucune tontine pour l\'instant',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    );
                  }

                  // ── Liste des tontines ──
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
                              builder: (context) =>
                                  DetailTontineScreen(tontine: tontines[index]),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
