import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
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

  List<Tontine> _filtrer(List<Tontine> tontines) {
    if (_recherche.isEmpty) return tontines;
    return tontines.where((t) {
      return t.nom.toLowerCase().contains(_recherche.toLowerCase()) ||
          t.gestionnaire.toLowerCase().contains(_recherche.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
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
                      Text(
                        provider.langue == 'fr'
                            ? 'Mes Tontines'
                            : 'My Tontines',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const RejoindreTonitneScreen(),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.group_add,
                          color: Color(0xFF7B2D8B),
                        ),
                        label: Text(
                          provider.langue == 'fr' ? 'Rejoindre' : 'Join',
                          style: const TextStyle(
                            color: Color(0xFF7B2D8B),
                            fontSize: 15,
                          ),
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
                      hintText: provider.langue == 'fr'
                          ? 'Rechercher une tontine...'
                          : 'Search a tontine...',
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

                const SizedBox(height: 12),

                // ── Liste avec sections ──
                Expanded(
                  child: RefreshIndicator(
                    color: const Color(0xFF2E9E6E),
                    onRefresh: () async {
                      await Future.delayed(const Duration(seconds: 1));
                    },
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── SECTION : Mes tontines ──
                          _buildSectionTitre(
                            provider.langue == 'fr'
                                ? 'Mes tontines créées'
                                : 'Tontines I created',
                          ),
                          const SizedBox(height: 8),
                          StreamBuilder<List<Tontine>>(
                            stream: FirestoreService().getMesTontines(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 20),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: Color(0xFF2E9E6E),
                                    ),
                                  ),
                                );
                              }

                              if (snapshot.hasError) {
                                return ErrorState(
                                  message: provider.langue == 'fr'
                                      ? 'Impossible de charger vos tontines.'
                                      : 'Unable to load your tontines.',
                                  onReessayer: () {},
                                );
                              }

                              final tontines = _filtrer(snapshot.data ?? []);

                              if (tontines.isEmpty) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  child: Text(
                                    provider.langue == 'fr'
                                        ? 'Vous n\'avez créé aucune tontine'
                                        : 'You haven\'t created any tontine',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 13,
                                    ),
                                  ),
                                );
                              }

                              return Column(
                                children: tontines.map((t) {
                                  return TontineCard(
                                    tontine: t,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              DetailTontineScreen(tontine: t),
                                        ),
                                      );
                                    },
                                  );
                                }).toList(),
                              );
                            },
                          ),

                          const SizedBox(height: 20),

                          // ── SECTION : Tontines rejointes ──
                          _buildSectionTitre(
                            provider.langue == 'fr'
                                ? 'Tontines rejointes'
                                : 'Tontines joined',
                          ),
                          const SizedBox(height: 8),
                          StreamBuilder<List<Tontine>>(
                            stream: FirestoreService().getTontinesRejointes(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 20),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: Color(0xFF2E9E6E),
                                    ),
                                  ),
                                );
                              }

                              if (snapshot.hasError) {
                                return ErrorState(
                                  message: provider.langue == 'fr'
                                      ? 'Impossible de charger les tontines rejointes.'
                                      : 'Unable to load joined tontines.',
                                  onReessayer: () {},
                                );
                              }

                              final tontines = _filtrer(snapshot.data ?? []);

                              if (tontines.isEmpty) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  child: Text(
                                    provider.langue == 'fr'
                                        ? 'Vous n\'avez rejoint aucune tontine'
                                        : 'You haven\'t joined any tontine',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 13,
                                    ),
                                  ),
                                );
                              }

                              return Column(
                                children: tontines.map((t) {
                                  return TontineCard(
                                    tontine: t,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              DetailTontineScreen(tontine: t),
                                        ),
                                      );
                                    },
                                  );
                                }).toList(),
                              );
                            },
                          ),

                          const SizedBox(height: 100),
                        ],
                      ),
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
      },
    );
  }

  Widget _buildSectionTitre(String titre) {
    return Text(
      titre,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Color(0xFF7B2D8B),
      ),
    );
  }
}
