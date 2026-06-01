import 'package:flutter/material.dart';
import '../models/tontine.dart';
import '../services/firestore_service.dart';

class ModifierTontineScreen extends StatefulWidget {
  final Tontine tontine;

  const ModifierTontineScreen({super.key, required this.tontine});

  @override
  State<ModifierTontineScreen> createState() => _ModifierTontineScreenState();
}

class _ModifierTontineScreenState extends State<ModifierTontineScreen> {
  late TextEditingController _nomController;
  late TextEditingController _montantController;
  late TextEditingController _nombreMembresController;
  late String _frequence;
  late String _ordreReception;
  late bool _paiementsEnregistres;
  late bool _prevuesObligatoires;
  late bool _membresVoientHistorique;
  bool _isLoading = false;
  String _frequenceEcheance = 'semaine';

  @override
  void initState() {
    super.initState();
    // Initialise les champs avec les valeurs existantes
    _nomController = TextEditingController(text: widget.tontine.nom);
    _montantController = TextEditingController(
      text: widget.tontine.montant.toStringAsFixed(0),
    );
    _nombreMembresController = TextEditingController(
      text: widget.tontine.nombreMembres.toString(),
    );
    _frequence = widget.tontine.frequence;
    _ordreReception = widget.tontine.ordreReception;
    _paiementsEnregistres = widget.tontine.paiementsEnregistres;
    _prevuesObligatoires = widget.tontine.prevuesObligatoires;
    _membresVoientHistorique = widget.tontine.membresVoientHistorique;
    _frequenceEcheance = widget.tontine.frequenceEcheance;
  }

  @override
  void dispose() {
    _nomController.dispose();
    _montantController.dispose();
    _nombreMembresController.dispose();
    super.dispose();
  }

  Future<void> _sauvegarder() async {
    // ── Validations ──
    if (_nomController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer le nom de la tontine'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_nomController.text.trim().length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le nom doit contenir au moins 3 caractères'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final montant = double.tryParse(_montantController.text.trim());
    if (montant == null || montant <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le montant doit être un nombre supérieur à 0'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final nombreMembres = int.tryParse(_nombreMembresController.text.trim());
    if (nombreMembres == null || nombreMembres < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le nombre de membres doit être au moins 2'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Crée la tontine mise à jour
      final tontineMAJ = Tontine(
        id: widget.tontine.id,
        nom: _nomController.text.trim(),
        montant: montant,
        frequence: _frequence,
        frequenceEcheance: _frequenceEcheance,
        prochaineEcheance: widget.tontine.prochaineEcheance,
        enCours: widget.tontine.enCours,
        dateDebut: widget.tontine.dateDebut,
        ordreReception: _ordreReception,
        nombreMembres: nombreMembres,
        paiementsEnregistres: _paiementsEnregistres,
        prevuesObligatoires: _prevuesObligatoires,
        membresVoientHistorique: _membresVoientHistorique,
        gestionnaire: widget.tontine.gestionnaire,
        membres: widget.tontine.membres,
        codeInvitation: widget.tontine.codeInvitation,
        tours: [],
      );

      // Sauvegarde dans Firestore
      await FirestoreService().mettreAJourTontine(tontineMAJ);

      if (!mounted) return;
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tontine mise à jour avec succès !'),
          backgroundColor: Color(0xFF2E9E6E),
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
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
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
                            'Modifier la tontine',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF7B2D8B),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // ── Nom ──
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: _nomController,
                        style: const TextStyle(fontSize: 18),
                        decoration: const InputDecoration(
                          labelText: 'Nom de la tontine',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(16),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Montant ──
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: _montantController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 18),
                        decoration: const InputDecoration(
                          labelText: 'Montant',
                          suffixText: 'FCFA',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(16),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Fréquence ──
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _frequence,
                          isExpanded: true,
                          items: const [
                            DropdownMenuItem(
                              value: 'semaine',
                              child: Text('Chaque semaine'),
                            ),
                            DropdownMenuItem(
                              value: 'mois',
                              child: Text('Chaque mois'),
                            ),
                            DropdownMenuItem(
                              value: 'trimestre',
                              child: Text('Chaque trimestre'),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() => _frequence = value!);
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Nombre de membres ──
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: _nombreMembresController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 20),
                        decoration: const InputDecoration(
                          hintText: 'Nombre de membres',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(16),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Ordre de réception ──
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ordre de réception',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                          Row(
                            children: [
                              Radio<String>(
                                value: 'aleatoire',
                                groupValue: _ordreReception,
                                activeColor: const Color(0xFF2E9E6E),
                                onChanged: (value) =>
                                    setState(() => _ordreReception = value!),
                              ),
                              const Text('Tirage aléatoire'),
                            ],
                          ),
                          Row(
                            children: [
                              Radio<String>(
                                value: 'defini',
                                groupValue: _ordreReception,
                                activeColor: const Color(0xFF2E9E6E),
                                onChanged: (value) =>
                                    setState(() => _ordreReception = value!),
                              ),
                              const Text('Ordre défini'),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Cases à cocher ──
                    _buildCheckbox(
                      titre: 'Tous les paiements sont enregistrés',
                      valeur: _paiementsEnregistres,
                      onChanged: (val) =>
                          setState(() => _paiementsEnregistres = val!),
                    ),
                    _buildCheckbox(
                      titre: 'Les prévues sont obligatoires',
                      valeur: _prevuesObligatoires,
                      onChanged: (val) =>
                          setState(() => _prevuesObligatoires = val!),
                    ),
                    _buildCheckbox(
                      titre: "Les membres voient l'historique",
                      valeur: _membresVoientHistorique,
                      onChanged: (val) =>
                          setState(() => _membresVoientHistorique = val!),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // ── Bouton sauvegarder ──
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _sauvegarder,
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
                          'Sauvegarder',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckbox({
    required String titre,
    required bool valeur,
    required ValueChanged<bool?> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(12),
      ),
      child: CheckboxListTile(
        value: valeur,
        onChanged: onChanged,
        activeColor: const Color(0xFF2E9E6E),
        title: Text(titre),
        controlAffinity: ListTileControlAffinity.leading,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
