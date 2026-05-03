import 'package:flutter/material.dart';
import '../models/mode_paiement.dart';
import '../models/tontine.dart';
import '../models/paiement.dart';
import '../models/notification_model.dart';
import '../services/firestore_service.dart';
import '../utils/formatage.dart';

class PaiementScreen extends StatefulWidget {
  final Tontine tontine;
  final Membre membre;

  const PaiementScreen({
    super.key,
    required this.tontine,
    required this.membre,
  });

  @override
  State<PaiementScreen> createState() => _PaiementScreenState();
}

class _PaiementScreenState extends State<PaiementScreen> {
  ModePaiement? _modeSelectionne;
  final TextEditingController _numeroController = TextEditingController();
  bool _isLoading = false;
  int _etape = 1; // 1: choix mode, 2: saisie infos, 3: confirmation

  @override
  void dispose() {
    _numeroController.dispose();
    super.dispose();
  }

  // Passe à l'étape suivante
  void _etapeSuivante() {
    if (_etape == 1) {
      if (_modeSelectionne == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez choisir un mode de paiement'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      setState(() => _etape = 2);
    } else if (_etape == 2) {
      if (_modeSelectionne!.type != TypePaiement.bancaire &&
          _numeroController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez entrer votre numéro'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      setState(() => _etape = 3);
    }
  }

  // Confirme le paiement
  Future<void> _confirmerPaiement() async {
    setState(() => _isLoading = true);

    try {
      // Simule un délai de traitement
      await Future.delayed(const Duration(seconds: 2));

      // Met à jour le statut du membre
      final membresMAJ = widget.tontine.membres.map((m) {
        if (m.id == widget.membre.id) {
          return Membre(id: m.id, nom: m.nom, aPaye: true);
        }
        return m;
      }).toList();

      await FirestoreService().mettreAJourMembres(
        widget.tontine.id,
        membresMAJ,
      );

      // Enregistre le paiement
      await FirestoreService().enregistrerPaiement(
        Paiement(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          membreId: widget.membre.id,
          membreNom: widget.membre.nom,
          montant: widget.tontine.montant,
          date: DateTime.now(),
          tontineId: widget.tontine.id,
          tontineNom: widget.tontine.nom,
          statut: 'paye',
        ),
      );

      // Crée une notification
      await FirestoreService().creerNotification(
        NotificationModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          titre: 'Paiement effectué',
          message:
              '${widget.membre.nom} a payé ${Formatage.montant(widget.tontine.montant)} via ${_modeSelectionne!.nom}',
          date: DateTime.now(),
          type: TypeNotification.nouveauDepot,
        ),
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      // Affiche la page de succès
      setState(() => _etape = 4);
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
            const SizedBox(height: 20),

            // ── Bouton retour + Titre ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  if (_etape < 4)
                    GestureDetector(
                      onTap: () {
                        if (_etape > 1) {
                          setState(() => _etape--);
                        } else {
                          Navigator.pop(context);
                        }
                      },
                      child: const Icon(
                        Icons.arrow_back_ios,
                        color: Color(0xFF7B2D8B),
                        size: 18,
                      ),
                    ),
                  const SizedBox(width: 6),
                  Text(
                    _etape == 1
                        ? 'Mode de paiement'
                        : _etape == 2
                        ? 'Informations'
                        : _etape == 3
                        ? 'Confirmation'
                        : 'Paiement réussi',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF7B2D8B),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Indicateur d'étapes ──
            if (_etape < 4)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: List.generate(3, (index) {
                    final actif = index + 1 <= _etape;
                    return Expanded(
                      child: Container(
                        margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
                        height: 4,
                        decoration: BoxDecoration(
                          color: actif
                              ? const Color(0xFF2E9E6E)
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
              ),

            const SizedBox(height: 24),

            // ── Contenu selon l'étape ──
            Expanded(
              child: _etape == 1
                  ? _buildEtape1()
                  : _etape == 2
                  ? _buildEtape2()
                  : _etape == 3
                  ? _buildEtape3()
                  : _buildEtape4(),
            ),

            // ── Bouton action ──
            if (_etape < 3)
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _etapeSuivante,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E9E6E),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Continuer',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ),

            if (_etape == 3)
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _confirmerPaiement,
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
                            'Confirmer le paiement',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ),
              ),

            if (_etape == 4)
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E9E6E),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 0,
                    ),
                    child: const Text('Retour', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Étape 1 : Choix du mode de paiement ──
  Widget _buildEtape1() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Info paiement ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF9F6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF2E9E6E)),
            ),
            child: Column(
              children: [
                Text(
                  widget.tontine.nom,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  Formatage.montant(widget.tontine.montant),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E9E6E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pour : ${widget.membre.nom}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            'Choisissez votre mode de paiement',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),

          const SizedBox(height: 16),

          // ── Modes de paiement ──
          ...ModePaiement.modes.map((mode) {
            final selectionne = _modeSelectionne?.type == mode.type;
            return GestureDetector(
              onTap: () {
                setState(() => _modeSelectionne = mode);
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: selectionne
                      ? mode.couleur.withValues(alpha: 0.1)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selectionne ? mode.couleur : Colors.grey.shade300,
                    width: selectionne ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Text(mode.logo, style: const TextStyle(fontSize: 30)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mode.nom,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: selectionne
                                  ? mode.couleur
                                  : Colors.black87,
                            ),
                          ),
                          Text(
                            mode.description,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (selectionne)
                      Icon(Icons.check_circle, color: mode.couleur),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Étape 2 : Saisie des informations ──
  Widget _buildEtape2() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Mode sélectionné ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _modeSelectionne!.couleur.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _modeSelectionne!.couleur),
            ),
            child: Row(
              children: [
                Text(
                  _modeSelectionne!.logo,
                  style: const TextStyle(fontSize: 30),
                ),
                const SizedBox(width: 12),
                Text(
                  _modeSelectionne!.nom,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _modeSelectionne!.couleur,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          if (_modeSelectionne!.type == TypePaiement.bancaire) ...[
            // ── Infos bancaires ──
            const Text(
              'Informations bancaires',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            _buildInfoBancaire('Banque', 'Afriland First Bank'),
            _buildInfoBancaire('Titulaire', 'Njangi App'),
            _buildInfoBancaire('RIB', '10005 00001 12345678901 23'),
            _buildInfoBancaire(
              'Montant',
              Formatage.montant(widget.tontine.montant),
            ),
            _buildInfoBancaire('Référence', widget.tontine.codeInvitation),
          ] else ...[
            // ── Numéro Mobile Money ──
            Text(
              'Entrez votre numéro ${_modeSelectionne!.nom}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _numeroController,
              keyboardType: TextInputType.phone,
              style: const TextStyle(fontSize: 18),
              decoration: InputDecoration(
                hintText: 'Ex: +237 658 834 387',
                prefixIcon: Icon(
                  Icons.phone_outlined,
                  color: _modeSelectionne!.couleur,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: _modeSelectionne!.couleur,
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.orange.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Vous recevrez une demande de confirmation sur votre téléphone',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Étape 3 : Confirmation ──
  Widget _buildEtape3() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 20),

          // ── Résumé ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Text(
                  'Récapitulatif du paiement',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                _buildLigneRecap('Tontine', widget.tontine.nom),
                _buildLigneRecap('Membre', widget.membre.nom),
                _buildLigneRecap(
                  'Montant',
                  Formatage.montant(widget.tontine.montant),
                ),
                _buildLigneRecap('Mode', _modeSelectionne!.nom),
                if (_modeSelectionne!.type != TypePaiement.bancaire)
                  _buildLigneRecap('Numéro', _numeroController.text),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      Formatage.montant(widget.tontine.montant),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E9E6E),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Étape 4 : Succès ──
  Widget _buildEtape4() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── Icône succès ──
            Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                color: Color(0xFF2E9E6E),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 60),
            ),

            const SizedBox(height: 24),

            const Text(
              'Paiement réussi !',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E9E6E),
              ),
            ),

            const SizedBox(height: 12),

            Text(
              '${Formatage.montant(widget.tontine.montant)} payé via ${_modeSelectionne!.nom}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),

            const SizedBox(height: 8),

            Text(
              'Pour ${widget.membre.nom} dans "${widget.tontine.nom}"',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  // ── Widget ligne récapitulatif ──
  Widget _buildLigneRecap(String label, String valeur) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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

  // ── Widget info bancaire ──
  Widget _buildInfoBancaire(String label, String valeur) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
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
