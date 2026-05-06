import 'package:flutter/material.dart';
import '../models/tontine.dart';
import '../services/firestore_service.dart';
import '../utils/formatage.dart';

class ToursScreen extends StatelessWidget {
  final Tontine tontine;

  const ToursScreen({super.key, required this.tontine});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            // ── Bouton retour + Titre ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.arrow_back_ios,
                      color: Color(0xFF7B2D8B),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Tours - ${tontine.nom}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF7B2D8B),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Info tontine ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7B2D8B), Color(0xFF2E9E6E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Cagnotte par tour',
                          style: TextStyle(fontSize: 13, color: Colors.white70),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          Formatage.montant(
                            tontine.montant * tontine.membres.length,
                          ),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Membres',
                          style: TextStyle(fontSize: 13, color: Colors.white70),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${tontine.membres.length}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Bouton générer les tours ──
            if (tontine.tours.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: tontine.membres.isEmpty
                        ? null
                        : () async {
                            await FirestoreService().genererTours(tontine);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Tours générés !'),
                                backgroundColor: Color(0xFF2E9E6E),
                              ),
                            );
                            Navigator.pop(context);
                          },
                    icon: const Icon(Icons.shuffle),
                    label: Text(
                      tontine.ordreReception == 'aleatoire'
                          ? 'Générer les tours (aléatoire)'
                          : 'Générer les tours (ordre défini)',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E9E6E),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // ── Titre liste ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                tontine.tours.isEmpty
                    ? 'Aucun tour généré'
                    : '${tontine.tours.length} tours',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── Liste des tours ──
            Expanded(
              child: tontine.tours.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.rotate_right,
                            size: 70,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Aucun tour généré',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            tontine.membres.isEmpty
                                ? 'Ajoutez des membres d\'abord'
                                : 'Appuyez sur le bouton pour générer',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: tontine.tours.length,
                      itemBuilder: (context, index) {
                        final tour = tontine.tours[index];
                        return _buildTourTile(context, tour, tontine);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTourTile(BuildContext context, Tour tour, Tontine tontine) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: tour.estComplete ? const Color(0xFFEFF9F6) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: tour.estComplete
              ? const Color(0xFF2E9E6E)
              : Colors.grey.shade300,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: tour.estComplete
                ? const Color(0xFF2E9E6E)
                : const Color(0xFF7B2D8B),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '${tour.numero}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        title: Text(
          tour.membreNom,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              Formatage.date(tour.date),
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              Formatage.montant(tour.montantTotal),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2E9E6E),
              ),
            ),
          ],
        ),
        trailing: tour.estComplete
            ? Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E9E6E),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Complété ✅',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              )
            : GestureDetector(
                onTap: () async {
                  final confirmer = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Compléter le tour'),
                      content: Text(
                        '${tour.membreNom} a reçu ${Formatage.montant(tour.montantTotal)} ?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Annuler'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text(
                            'Confirmer',
                            style: TextStyle(color: Color(0xFF2E9E6E)),
                          ),
                        ),
                      ],
                    ),
                  );

                  if (confirmer == true) {
                    await FirestoreService().completerTour(
                      tontine.id,
                      tour.numero,
                    );
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Tour ${tour.numero} complété !'),
                        backgroundColor: const Color(0xFF2E9E6E),
                      ),
                    );
                    Navigator.pop(context);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7B2D8B),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Compléter',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
      ),
    );
  }
}
