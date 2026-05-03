import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../models/tontine.dart';
import '../models/notification_model.dart';

class RejoindreTonitneScreen extends StatefulWidget {
  const RejoindreTonitneScreen({super.key});

  @override
  State<RejoindreTonitneScreen> createState() => _RejoindreTontineScreenState();
}

class _RejoindreTontineScreenState extends State<RejoindreTonitneScreen> {
  final TextEditingController _codeController = TextEditingController();
  Tontine? _tontineTrouvee;
  bool _isLoading = false;
  bool _isJoining = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  // Recherche la tontine par code dans Firestore
  Future<void> _rechercherTontine() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer un code d\'invitation')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final tontine = await FirestoreService().trouverParCode(code);

    if (!mounted) return;

    setState(() {
      _tontineTrouvee = tontine;
      _isLoading = false;
    });

    if (tontine == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Code invalide. Aucune tontine trouvée.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Rejoindre la tontine
  Future<void> _rejoindre() async {
    if (_tontineTrouvee == null) return;

    setState(() => _isJoining = true);

    try {
      // Ajoute le nouveau membre
      final nouveauMembre = Membre(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        nom: 'Moi',
        aPaye: false,
      );

      final membresMAJ = [..._tontineTrouvee!.membres, nouveauMembre];

      // Met à jour les membres dans Firestore
      await FirestoreService().mettreAJourMembres(
        _tontineTrouvee!.id,
        membresMAJ,
      );

      // Crée une notification dans Firestore
      await FirestoreService().creerNotification(
        NotificationModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          titre: 'Nouveau membre',
          message: 'Vous avez rejoint "${_tontineTrouvee!.nom}"',
          date: DateTime.now(),
          type: TypeNotification.nouveauMembre,
        ),
      );

      if (!mounted) return;

      setState(() => _isJoining = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vous avez rejoint "${_tontineTrouvee!.nom}" !'),
          backgroundColor: const Color(0xFF2E9E6E),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isJoining = false);
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
                      'Rejoindre une tontine',
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
                child: Icon(
                  Icons.group_add,
                  size: 80,
                  color: Color(0xFF2E9E6E),
                ),
              ),

              const SizedBox(height: 20),

              const Center(
                child: Text(
                  'Entrez le code d\'invitation',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
              ),

              const SizedBox(height: 8),

              const Center(
                child: Text(
                  'Demandez le code au gestionnaire\nde la tontine',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ),

              const SizedBox(height: 40),

              // ── Champ code ──
              TextField(
                controller: _codeController,
                textAlign: TextAlign.center,
                textCapitalization: TextCapitalization.characters,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                ),
                decoration: InputDecoration(
                  hintText: 'XXXXXX',
                  hintStyle: TextStyle(
                    fontSize: 24,
                    letterSpacing: 8,
                    color: Colors.grey.shade300,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF2E9E6E),
                      width: 2,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ── Bouton rechercher ──
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _rechercherTontine,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7B2D8B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Rechercher',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),

              const SizedBox(height: 24),

              // ── Résultat ──
              if (_tontineTrouvee != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF9F6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF2E9E6E)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tontine trouvée !',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF2E9E6E),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow('Nom', _tontineTrouvee!.nom),
                      _buildInfoRow(
                        'Montant',
                        '${_tontineTrouvee!.montant.toStringAsFixed(0)} FCFA/${_tontineTrouvee!.frequence}',
                      ),
                      _buildInfoRow(
                        'Gestionnaire',
                        _tontineTrouvee!.gestionnaire,
                      ),
                      _buildInfoRow(
                        'Membres',
                        '${_tontineTrouvee!.membres.length}/${_tontineTrouvee!.nombreMembres}',
                      ),

                      const SizedBox(height: 16),

                      // ── Bouton rejoindre ──
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isJoining ? null : _rejoindre,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E9E6E),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 0,
                          ),
                          child: _isJoining
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  'Rejoindre cette tontine',
                                  style: TextStyle(fontSize: 16),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String valeur) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          Text(
            valeur,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
