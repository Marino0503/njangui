import 'package:flutter/material.dart';
import '../models/tontine.dart';
//import '../data/tontines_data.dart';
//import '../data/notifications_data.dart';
import '../services/firestore_service.dart';
import '../models/notification_model.dart';

class CreateTontineScreen extends StatefulWidget {
  const CreateTontineScreen({super.key});

  @override
  State<CreateTontineScreen> createState() => _CreateTontineScreenState();
}

class _CreateTontineScreenState extends State<CreateTontineScreen> {
  bool _isLoading = false;
  // ── Contrôleurs ──
  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _montantController = TextEditingController();
  final TextEditingController _nombreMembresController =
      TextEditingController();

  // ── Valeurs des champs ──
  DateTime _dateDebut = DateTime.now();
  String _ordreReception = 'aleatoire';
  String _frequence = 'mois'; // valeur par défaut
  bool _paiementsEnregistres = true;
  bool _prevuesObligatoires = true;
  bool _membresVoientHistorique = true;

  @override
  void dispose() {
    _nomController.dispose();
    _montantController.dispose();
    _nombreMembresController.dispose();
    super.dispose();
  }

  // ── Ouvre le sélecteur de date ──
  Future<void> _choisirDate() async {
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

  // ── Formate la date en français ──
  String _formaterDate(DateTime date) {
    const mois = [
      'Janvier',
      'Février',
      'Mars',
      'Avril',
      'Mai',
      'Juin',
      'Juillet',
      'Août',
      'Septembre',
      'Octobre',
      'Novembre',
      'Décembre',
    ];
    return '${date.day}er ${mois[date.month - 1]}';
  }

  // ── Crée la tontine ──
  Future<void> _creerTontine() async {
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

    if (_montantController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer le montant'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_nombreMembresController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer le nombre de membres'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // ── Génère un code unique ──
      final code =
          'TN${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

      // ── Crée la tontine ──
      final nouvelleTontine = Tontine(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        nom: _nomController.text.trim(),
        montant: double.parse(_montantController.text.trim()),
        frequence: _frequence,
        prochaineEcheance: _formaterDate(_dateDebut),
        enCours: false,
        dateDebut: _dateDebut,
        ordreReception: _ordreReception,
        nombreMembres: int.parse(_nombreMembresController.text.trim()),
        paiementsEnregistres: _paiementsEnregistres,
        prevuesObligatoires: _prevuesObligatoires,
        membresVoientHistorique: _membresVoientHistorique,
        gestionnaire: 'Moi',
        membres: [],
        codeInvitation: code,
      );

      // ── Sauvegarde dans Firestore ──
      await FirestoreService().creerTontine(nouvelleTontine);

      // ── Sauvegarde la notification dans Firestore ──
      await FirestoreService().creerNotification(
        NotificationModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          titre: 'Nouvelle tontine créée',
          message: 'Vous avez créé la tontine "${nouvelleTontine.nom}"',
          date: DateTime.now(),
          type: TypeNotification.nouvelleTontine,
        ),
      );

      if (!mounted) return;

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Tontine "${nouvelleTontine.nom}" créée ! Code : $code',
          ),
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
                            'Règles de la tontine',
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

                    // ── Nom de la tontine ──
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
                          hintText: 'Ex: Famille cité verte',
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
                          hintText: 'Ex: 10000',
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
                          hint: const Text('Fréquence de cotisation'),
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
                            const Text(
                              'Date de début',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _formaterDate(_dateDebut),
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
                          const Text(
                            'Ordre de réception',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Radio<String>(
                                value: 'aleatoire',
                                groupValue: _ordreReception,
                                activeColor: const Color(0xFF2E9E6E),
                                onChanged: (value) {
                                  setState(() => _ordreReception = value!);
                                },
                              ),
                              const Text(
                                'Tirage aléatoire',
                                style: TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Radio<String>(
                                value: 'defini',
                                groupValue: _ordreReception,
                                activeColor: const Color(0xFF2E9E6E),
                                onChanged: (value) {
                                  setState(() => _ordreReception = value!);
                                },
                              ),
                              const Text(
                                'Ordre défini',
                                style: TextStyle(fontSize: 16),
                              ),
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
                        decoration: const InputDecoration(
                          hintText: 'Nombre de membres',
                          hintStyle: TextStyle(fontSize: 20),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(16),
                        ),
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

            // ── Bouton Créer la tontine ──
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
                          children: const [
                            Text(
                              'Créer la tontine',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(width: 10),
                            Icon(Icons.arrow_forward_ios, size: 18),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Widget réutilisable pour les cases à cocher ──
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
        title: Text(titre, style: const TextStyle(fontSize: 15)),
        controlAffinity: ListTileControlAffinity.leading,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
