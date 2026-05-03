import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../models/tontine.dart';
import '../widgets/tontine_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_state.dart';
import 'create_tontine_screen.dart';
import 'rejoindre_tontine_screen.dart';
import 'detail_tontine_screen.dart';

class TontinesScreen extends StatefulWidget {
  const TontinesScreen({super.key});

  @override
  State<TontinesScreen> createState() => _TontinesScreenState();
}

class _TontinesScreenState extends State<TontinesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _recherche = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Filtre les tontines selon la recherche
  List<Tontine> _filtrer(List<Tontine> tontines) {
    if (_recherche.isEmpty) return tontines;
    return tontines.where((t) {
      return t.nom.toLowerCase().contains(_recherche.toLowerCase()) ||
          t.gestionnaire.toLowerCase().contains(_recherche.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            // ── Titre + bouton rejoindre ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
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
            ),

            const SizedBox(height: 12),

            // ── Barre de recherche ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() => _recherche = value);
                },
                decoration: InputDecoration(
                  hintText: 'Rechercher une tontine...',
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFF7B2D8B),
                  ),
                  suffixIcon: _recherche.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _recherche = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(
                      color: Color(0xFF7B2D8B),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Liste des tontines ──
            Expanded(
              child: RefreshIndicator(
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

                    // Filtre les tontines
                    final tontinesFiltrees = _filtrer(tontines);

                    if (tontines.isEmpty) {
                      return ListView(
                        children: [
                          const SizedBox(height: 80),
                          EmptyState(
                            icon: Icons.description_outlined,
                            titre: 'Aucune tontine',
                            message:
                                'Vous n\'avez pas encore de tontine.\nCréez-en une ou rejoignez-en une !',
                            boutonTexte: 'Créer une tontine',
                            onBoutonPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const CreateTontineScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      );
                    }

                    // Aucun résultat de recherche
                    if (tontinesFiltrees.isEmpty) {
                      return ListView(
                        children: [
                          const SizedBox(height: 80),
                          EmptyState(
                            icon: Icons.search_off,
                            titre: 'Aucun résultat',
                            message:
                                'Aucune tontine ne correspond\nà votre recherche "$_recherche"',
                            boutonTexte: 'Effacer la recherche',
                            onBoutonPressed: () {
                              _searchController.clear();
                              setState(() => _recherche = '');
                            },
                          ),
                        ],
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: tontinesFiltrees.length,
                      itemBuilder: (context, index) {
                        return TontineCard(
                          tontine: tontinesFiltrees[index],
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DetailTontineScreen(
                                  tontine: tontinesFiltrees[index],
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
            ),
          ],
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
