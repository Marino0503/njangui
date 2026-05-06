import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/tontine.dart';
import '../models/notification_model.dart';
import '../services/firestore_service.dart';
import '../utils/formatage.dart';

class CreateTontineScreen extends StatefulWidget {
  const CreateTontineScreen({super.key});

  @override
  State<CreateTontineScreen> createState() => _CreateTontineScreenState();
}

class _CreateTontineScreenState extends State<CreateTontineScreen> {
  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _montantController = TextEditingController();
  final TextEditingController _nombreMembresController =
      TextEditingController();

  DateTime _dateDebut = DateTime.now();
  String _ordreReception = 'aleatoire';
  String _frequence = 'mois';
  bool _paiementsEnregistres = true;
  bool _prevuesObligatoires = true;
  bool _membresVoientHistorique = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nomController.dispose();
    _montantController.dispose();
    _nombreMembresController.dispose();
    super.dispose();
  }

  Future<void> _choisirDate() async {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dateDebut,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF2E9E6E)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _dateDebut = picked);
    }
  }

  Future<void> _creerTontine() async {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final textes = provider.textes;

    if (_nomController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.langue == 'fr'
                ? 'Veuillez entrer le nom de la tontine'
                : 'Please enter the tontine name',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_nomController.text.trim().length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.langue == 'fr'
                ? 'Le nom doit contenir au moins 3 caractères'
                : 'Name must be at least 3 characters',
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
            provider.langue == 'fr'
                ? 'Le montant doit être supérieur à 0'
                : 'Amount must be greater than 0',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final nombreMembres = int.tryParse(_nombreMembresController.text.trim());
    if (nombreMembres == null || nombreMembres < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.langue == 'fr'
                ? 'Le nombre de membres doit être au moins 2'
                : 'Number of members must be at least 2',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final code =
          'TN${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

      final nouvelleTontine = Tontine(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        nom: _nomController.text.trim(),
        montant: montant,
        frequence: _frequence,
        prochaineEcheance: Formatage.date(_dateDebut),
        enCours: false,
        dateDebut: _dateDebut,
        ordreReception: _ordreReception,
        nombreMembres: nombreMembres,
        paiementsEnregistres: _paiementsEnregistres,
        prevuesObligatoires: _prevuesObligatoires,
        membresVoientHistorique: _membresVoientHistorique,
        gestionnaire: 'Moi',
        membres: [],
        codeInvitation: code,
        tours: [],
      );

      await FirestoreService().creerTontine(nouvelleTontine);

      await FirestoreService().creerNotification(
        NotificationModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          titre: textes['nouvelleTontineCreee']!,
          message: provider.langue == 'fr'
              ? 'Vous avez créé la tontine "${nouvelleTontine.nom}"'
              : 'You created the tontine "${nouvelleTontine.nom}"',
          date: DateTime.now(),
          type: TypeNotification.nouvelleTontine,
        ),
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${textes['tontineCreee']} Code : $code'),
          backgroundColor: const Color(0xFF2E9E6E),
          duration: const Duration(seconds: 4),
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
        final textes = provider.textes;

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
                                textes['reglesTontine']!,
                                style: const TextStyle(
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
                            decoration: InputDecoration(
                              labelText: textes['nomTontine']!,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.all(16),
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
                            decoration: InputDecoration(
                              labelText: textes['montant']!,
                              suffixText: 'FCFA',
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.all(16),
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
                              items: [
                                DropdownMenuItem(
                                  value: 'semaine',
                                  child: Text(
                                    provider.langue == 'fr'
                                        ? 'Chaque semaine'
                                        : 'Every week',
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'mois',
                                  child: Text(
                                    provider.langue == 'fr'
                                        ? 'Chaque mois'
                                        : 'Every month',
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'trimestre',
                                  child: Text(
                                    provider.langue == 'fr'
                                        ? 'Chaque trimestre'
                                        : 'Every quarter',
                                  ),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() => _frequence = value!);
                              },
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ── Date de début ──
                        GestureDetector(
                          onTap: _choisirDate,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  textes['dateDebut']!,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  Formatage.date(_dateDebut),
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
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
                              Text(
                                textes['ordreReception']!,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Radio<String>(
                                    value: 'aleatoire',
                                    groupValue: _ordreReception,
                                    activeColor: const Color(0xFF2E9E6E),
                                    onChanged: (value) => setState(
                                      () => _ordreReception = value!,
                                    ),
                                  ),
                                  Text(textes['tirageAleatoire']!),
                                ],
                              ),
                              Row(
                                children: [
                                  Radio<String>(
                                    value: 'defini',
                                    groupValue: _ordreReception,
                                    activeColor: const Color(0xFF2E9E6E),
                                    onChanged: (value) => setState(
                                      () => _ordreReception = value!,
                                    ),
                                  ),
                                  Text(textes['ordreDefini']!),
                                ],
                              ),
                            ],
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
                            decoration: InputDecoration(
                              hintText: textes['nombreMembres']!,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.all(16),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ── Cases à cocher ──
                        _buildCheckbox(
                          titre: textes['paiementsEnregistres']!,
                          valeur: _paiementsEnregistres,
                          onChanged: (val) =>
                              setState(() => _paiementsEnregistres = val!),
                        ),
                        _buildCheckbox(
                          titre: textes['prevuesObligatoires']!,
                          valeur: _prevuesObligatoires,
                          onChanged: (val) =>
                              setState(() => _prevuesObligatoires = val!),
                        ),
                        _buildCheckbox(
                          titre: textes['membresVoientHistorique']!,
                          valeur: _membresVoientHistorique,
                          onChanged: (val) =>
                              setState(() => _membresVoientHistorique = val!),
                        ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),

                // ── Bouton créer ──
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _creerTontine,
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
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  textes['creerLaTontine']!,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Icon(Icons.arrow_forward_ios, size: 18),
                              ],
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
