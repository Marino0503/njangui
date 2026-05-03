import 'package:flutter/material.dart';
import '../models/tontine.dart';
import '../models/notification_model.dart';
import '../services/firestore_service.dart';

class AjouterMembreScreen extends StatefulWidget {
  final Tontine tontine;

  const AjouterMembreScreen({super.key, required this.tontine});

  @override
  State<AjouterMembreScreen> createState() => _AjouterMembreScreenState();
}

class _AjouterMembreScreenState extends State<AjouterMembreScreen> {
  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _telephoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nomController.dispose();
    _telephoneController.dispose();
    super.dispose();
  }

  Future<void> _ajouterMembre() async {
    // ── Validations ──
    if (_nomController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer le nom du membre'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_nomController.text.trim().length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le nom doit contenir au moins 2 caractères'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_telephoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer le numéro de téléphone'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Vérifie si la tontine est pleine
    if (widget.tontine.membres.length >= widget.tontine.nombreMembres) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'La tontine est complète (${widget.tontine.nombreMembres} membres maximum)',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Vérifie si le membre existe déjà
    final nomExiste = widget.tontine.membres.any(
      (m) => m.nom.toLowerCase() == _nomController.text.trim().toLowerCase(),
    );

    if (nomExiste) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Un membre avec ce nom existe déjà'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Crée le nouveau membre
      final nouveauMembre = Membre(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        nom: _nomController.text.trim(),
        aPaye: false,
      );

      // Ajoute à la liste existante
      final membresMAJ = [...widget.tontine.membres, nouveauMembre];

      // Met à jour dans Firestore
      await FirestoreService().mettreAJourMembres(
        widget.tontine.id,
        membresMAJ,
      );

      // Crée une notification
      await FirestoreService().creerNotification(
        NotificationModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          titre: 'Nouveau membre',
          message:
              '${nouveauMembre.nom} a été ajouté à "${widget.tontine.nom}"',
          date: DateTime.now(),
          type: TypeNotification.nouveauMembre,
        ),
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${nouveauMembre.nom} ajouté avec succès !'),
          backgroundColor: const Color(0xFF2E9E6E),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red),
      );
    }
  }

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

              // ── Bouton retour + Titre ──
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Row(
                  children: const [
                    Icon(
                      Icons.arrow_back_ios,
                      color: Color(0xFF7B2D8B),
                      size: 18,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Ajouter un membre',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF7B2D8B),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // ── Icône ──
              const Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Color(0xFF90EED4),
                  child: Icon(Icons.person_add, size: 50, color: Colors.white),
                ),
              ),

              const SizedBox(height: 16),

              // ── Info tontine ──
              Center(
                child: Text(
                  widget.tontine.nom,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF7B2D8B),
                  ),
                ),
              ),

              Center(
                child: Text(
                  '${widget.tontine.membres.length}/${widget.tontine.nombreMembres} membres',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ),

              const SizedBox(height: 40),

              // ── Champ nom ──
              TextField(
                controller: _nomController,
                textCapitalization: TextCapitalization.words,
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  labelText: 'Nom du membre',
                  hintText: 'Ex: Jean Dupont',
                  prefixIcon: const Icon(
                    Icons.person_outline,
                    color: Color(0xFF7B2D8B),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF7B2D8B),
                      width: 2,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ── Champ téléphone ──
              TextField(
                controller: _telephoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  labelText: 'Numéro de téléphone',
                  hintText: 'Ex: +237 658 834 387',
                  prefixIcon: const Icon(
                    Icons.phone_outlined,
                    color: Color(0xFF7B2D8B),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF7B2D8B),
                      width: 2,
                    ),
                  ),
                ),
              ),

              const Spacer(),

              // ── Bouton ajouter ──
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _ajouterMembre,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E9E6E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Ajouter le membre',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
