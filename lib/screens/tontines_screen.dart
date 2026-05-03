import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../models/tontine.dart';
import '../widgets/tontine_card.dart';
import 'create_tontine_screen.dart';
import 'rejoindre_tontine_screen.dart';
import 'detail_tontine_screen.dart';

class TontinesScreen extends StatelessWidget {
  const TontinesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // ── Titre + bouton rejoindre ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Mes Tontines',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RejoindreTonitneScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.group_add, color: Color(0xFF7B2D8B)),
                    label: const Text(
                      'Rejoindre',
                      style: TextStyle(color: Color(0xFF7B2D8B), fontSize: 15),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ── Liste des tontines depuis Firestore ──
              Expanded(
                child: StreamBuilder<List<Tontine>>(
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
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.description_outlined,
                              size: 70,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Aucune tontine pour l\'instant\nAppuyez sur + pour en créer une',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    // ── Liste des tontines ──
                    return ListView.builder(
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
            ],
          ),
        ),
      ),

      // ── Bouton + ──
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateTontineScreen(),
            ),
          );
        },
        backgroundColor: Colors.white,
        shape: const CircleBorder(
          side: BorderSide(color: Color(0xFF2E9E6E), width: 2),
        ),
        child: const Icon(Icons.add, color: Color(0xFF2E9E6E)),
      ),
    );
  }
}
