import 'package:flutter/material.dart';
import '../data/tontines_data.dart';
import '../widgets/tontine_card.dart';
import 'create_tontine_screen.dart';
import 'rejoindre_tontine_screen.dart';
import 'detail_tontine_screen.dart';

class TontinesScreen extends StatefulWidget {
  const TontinesScreen({super.key});

  @override
  State<TontinesScreen> createState() => _TontinesScreenState();
}

class _TontinesScreenState extends State<TontinesScreen> {
  final TontinesData _data = TontinesData();

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

                  // ── Bouton rejoindre ──
                  TextButton.icon(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RejoindreTonitneScreen(),
                        ),
                      );
                      setState(() {});
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

              // ── Liste des tontines ──
              Expanded(
                child: _data.tontines.isEmpty
                    ? const Center(
                        child: Text(
                          'Aucune tontine pour l\'instant\nAppuyez sur + pour en créer une',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _data.tontines.length,
                        itemBuilder: (context, index) {
                          return TontineCard(
                            tontine: _data.tontines[index],
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DetailTontineScreen(
                                    tontine: _data.tontines[index],
                                  ),
                                ),
                              );
                              setState(() {});
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),

      // ── Bouton + créer une tontine ──
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateTontineScreen(),
            ),
          );
          setState(() {});
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
