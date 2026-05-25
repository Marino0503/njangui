import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/pret.dart';
import '../models/tontine.dart';
import '../models/notification_model.dart';
import '../providers/app_provider.dart';
import '../services/firestore_service.dart';
import '../utils/formatage.dart';

class DemanderPretScreen extends StatefulWidget {
  final Tontine tontine;

  const DemanderPretScreen({super.key, required this.tontine});

  @override
  State<DemanderPretScreen> createState() => _DemanderPretScreenState();
}

class _DemanderPretScreenState extends State<DemanderPretScreen> {
  final TextEditingController _montantController = TextEditingController();
  final TextEditingController _motifController = TextEditingController();

  double _tauxInteret = 0;
  int _dureeEnMois = 1;
  String _membreSelectionne = '';
  String _membreNomSelectionne = '';
  bool _isLoading = false;

  @override
  void dispose() {
    _montantController.dispose();
    _motifController.dispose();
    super.dispose();
  }

  Future<void> _soumettreDemande() async {
    final provider = Provider.of<AppProvider>(context, listen: false);

    if (_montantController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.langue == 'fr'
                ? 'Veuillez entrer le montant'
                : 'Please enter the amount',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final montant = double.tryParse(_montantController.text.trim());
    if (montant == null || montant <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.langue == 'fr' ? 'Montant invalide' : 'Invalid amount',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_membreSelectionne.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.langue == 'fr'
                ? 'Veuillez sélectionner un membre'
                : 'Please select a member',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_motifController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.langue == 'fr'
                ? 'Veuillez entrer le motif du prêt'
                : 'Please enter the loan reason',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final pret = Pret(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        tontineId: widget.tontine.id,
        tontineNom: widget.tontine.nom,
        membreId: _membreSelectionne,
        membreNom: _membreNomSelectionne,
        montant: montant,
        tauxInteret: _tauxInteret,
        dureeEnMois: _dureeEnMois,
        dateDemande: DateTime.now(),
        statut: StatutPret.enAttente,
        motif: _motifController.text.trim(),
        remboursements: [],
      );

      await FirestoreService().creerPret(pret);

      // Notification
      await FirestoreService().creerNotification(
        NotificationModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          titre: provider.langue == 'fr'
              ? 'Nouvelle demande de prêt'
              : 'New loan request',
          message: provider.langue == 'fr'
              ? '$_membreNomSelectionne a demandé un prêt de ${Formatage.montant(montant)} dans "${widget.tontine.nom}"'
              : '$_membreNomSelectionne requested a loan of ${Formatage.montant(montant)} in "${widget.tontine.nom}"',
          date: DateTime.now(),
          type: TypeNotification.nouveauDepot,
        ),
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.langue == 'fr'
                ? 'Demande de prêt soumise avec succès !'
                : 'Loan request submitted successfully!',
          ),
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
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
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
                            children: [
                              const Icon(
                                Icons.arrow_back_ios,
                                color: Color(0xFF7B2D8B),
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                provider.langue == 'fr'
                                    ? 'Demande de prêt'
                                    : 'Loan request',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF7B2D8B),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ── Info tontine ──
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF9F6),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF2E9E6E)),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.groups,
                                color: Color(0xFF2E9E6E),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                widget.tontine.nom,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2E9E6E),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ── Sélectionner un membre ──
                        Text(
                          provider.langue == 'fr'
                              ? 'Membre bénéficiaire'
                              : 'Beneficiary member',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
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
                              value: _membreSelectionne.isEmpty
                                  ? null
                                  : _membreSelectionne,
                              isExpanded: true,
                              hint: Text(
                                provider.langue == 'fr'
                                    ? 'Sélectionner un membre'
                                    : 'Select a member',
                              ),
                              items: widget.tontine.membres
                                  .map(
                                    (m) => DropdownMenuItem(
                                      value: m.id,
                                      child: Text(m.nom),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _membreSelectionne = value ?? '';
                                  _membreNomSelectionne = widget.tontine.membres
                                      .firstWhere((m) => m.id == value)
                                      .nom;
                                });
                              },
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ── Montant ──
                        TextField(
                          controller: _montantController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: provider.langue == 'fr'
                                ? 'Montant du prêt'
                                : 'Loan amount',
                            suffixText: 'FCFA',
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

                        // ── Taux d'intérêt ──
                        Text(
                          provider.langue == 'fr'
                              ? 'Taux d\'intérêt : ${_tauxInteret.toStringAsFixed(0)}%'
                              : 'Interest rate: ${_tauxInteret.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Slider(
                          value: _tauxInteret,
                          min: 0,
                          max: 20,
                          divisions: 20,
                          activeColor: const Color(0xFF7B2D8B),
                          label: '${_tauxInteret.toStringAsFixed(0)}%',
                          onChanged: (value) {
                            setState(() => _tauxInteret = value);
                          },
                        ),

                        const SizedBox(height: 8),

                        // ── Durée ──
                        Text(
                          provider.langue == 'fr'
                              ? 'Durée : $_dureeEnMois mois'
                              : 'Duration: $_dureeEnMois months',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Slider(
                          value: _dureeEnMois.toDouble(),
                          min: 1,
                          max: 12,
                          divisions: 11,
                          activeColor: const Color(0xFF2E9E6E),
                          label: '$_dureeEnMois mois',
                          onChanged: (value) {
                            setState(() => _dureeEnMois = value.toInt());
                          },
                        ),

                        const SizedBox(height: 16),

                        // ── Motif ──
                        TextField(
                          controller: _motifController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: provider.langue == 'fr'
                                ? 'Motif du prêt'
                                : 'Loan reason',
                            hintText: provider.langue == 'fr'
                                ? 'Ex: Frais médicaux, scolarité...'
                                : 'Ex: Medical fees, school fees...',
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

                        // ── Résumé ──
                        if (_montantController.text.isNotEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  provider.langue == 'fr'
                                      ? 'Résumé du prêt'
                                      : 'Loan summary',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _buildLigneResume(
                                  provider.langue == 'fr'
                                      ? 'Montant'
                                      : 'Amount',
                                  Formatage.montant(
                                    double.tryParse(_montantController.text) ??
                                        0,
                                  ),
                                ),
                                _buildLigneResume(
                                  provider.langue == 'fr'
                                      ? 'Intérêts'
                                      : 'Interest',
                                  '${_tauxInteret.toStringAsFixed(0)}%',
                                ),
                                _buildLigneResume(
                                  provider.langue == 'fr'
                                      ? 'Durée'
                                      : 'Duration',
                                  provider.langue == 'fr'
                                      ? '$_dureeEnMois mois'
                                      : '$_dureeEnMois months',
                                ),
                                const Divider(),
                                _buildLigneResume(
                                  provider.langue == 'fr'
                                      ? 'Total à rembourser'
                                      : 'Total to repay',
                                  Formatage.montant(
                                    (double.tryParse(_montantController.text) ??
                                            0) *
                                        (1 + _tauxInteret / 100),
                                  ),
                                  bold: true,
                                  couleur: const Color(0xFF7B2D8B),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),

                // ── Bouton soumettre ──
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _soumettreDemande,
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
                          : Text(
                              provider.langue == 'fr'
                                  ? 'Soumettre la demande'
                                  : 'Submit request',
                              style: const TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLigneResume(
    String label,
    String valeur, {
    bool bold = false,
    Color? couleur,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          Text(
            valeur,
            style: TextStyle(
              fontSize: 14,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              color: couleur ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
