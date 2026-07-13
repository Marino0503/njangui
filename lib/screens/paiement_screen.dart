import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/mode_paiement.dart';
import '../models/tontine.dart';
import '../models/paiement.dart';
import '../models/sanction.dart';
import '../providers/app_provider.dart';
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
  int _etape = 1;
  Sanction? _sanctionActive;
  double _montantTotal = 0;
  StreamSubscription<Paiement?>? _suiviPaiement;

  @override
  void initState() {
    super.initState();
    _montantTotal = widget.tontine.montant;
    _verifierSanction();
  }

  @override
  void dispose() {
    _numeroController.dispose();
    _suiviPaiement?.cancel();
    super.dispose();
  }

  // Vérifie s'il y a une sanction active
  Future<void> _verifierSanction() async {
    final sanction = await FirestoreService().getSanctionActive(
      widget.tontine.id,
      widget.membre.id,
    );

    if (sanction != null) {
      setState(() {
        _sanctionActive = sanction;
        _montantTotal = sanction.montantDu + widget.tontine.montant;
      });
    }
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

  // Initie un paiement mobile money réel via Fapshi et attend la
  // confirmation du webhook serveur avant de considérer le paiement
  // comme effectué (le montant est calculé côté serveur, jamais ici).
  Future<void> _confirmerPaiement() async {
    setState(() => _isLoading = true);

    try {
      final resultat = await FirestoreService().initierPaiementMobileMoney(
        tontineId: widget.tontine.id,
        membreId: widget.membre.id,
      );

      final ouvert = await launchUrl(
        Uri.parse(resultat.link),
        mode: LaunchMode.externalApplication,
      );
      if (!ouvert) {
        throw Exception('Impossible d\'ouvrir la page de paiement');
      }

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _etape = 4; // écran "en attente de confirmation"
      });

      _suiviPaiement = FirestoreService()
          .suivrePaiement(resultat.paiementId)
          .listen((paiement) {
            if (!mounted || paiement == null) return;
            if (paiement.statut == 'paye') {
              setState(() => _etape = 5); // écran succès
            } else if (paiement.statut == 'echec') {
              setState(() => _etape = 1);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Le paiement a échoué ou a expiré. Veuillez réessayer.',
                  ),
                  backgroundColor: Colors.red,
                ),
              );
            }
          });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red),
        );
      }
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
                            ? provider.langue == 'fr'
                                  ? 'Mode de paiement'
                                  : 'Payment method'
                            : _etape == 2
                            ? provider.langue == 'fr'
                                  ? 'Informations'
                                  : 'Information'
                            : _etape == 3
                            ? provider.langue == 'fr'
                                  ? 'Confirmation'
                                  : 'Confirmation'
                            : _etape == 4
                            ? provider.langue == 'fr'
                                  ? 'En attente'
                                  : 'Pending'
                            : provider.langue == 'fr'
                            ? 'Paiement réussi'
                            : 'Payment successful',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF7B2D8B),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ── Alerte sanction ──
                if (_sanctionActive != null && _etape < 4)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade300),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.warning_amber,
                            color: Colors.red,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              provider.langue == 'fr'
                                  ? '⚠️ Sanction active ! Vous devez payer ${Formatage.montant(_montantTotal)} au lieu de ${Formatage.montant(widget.tontine.montant)}'
                                  : '⚠️ Active sanction! You must pay ${Formatage.montant(_montantTotal)} instead of ${Formatage.montant(widget.tontine.montant)}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.red,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 12),

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
                      ? _buildEtape1(provider)
                      : _etape == 2
                      ? _buildEtape2(provider)
                      : _etape == 3
                      ? _buildEtape3(provider)
                      : _etape == 4
                      ? _buildEtapeAttente(provider)
                      : _buildEtape5(provider),
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
                        child: Text(
                          provider.langue == 'fr' ? 'Continuer' : 'Continue',
                          style: const TextStyle(fontSize: 16),
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
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : Text(
                                provider.langue == 'fr'
                                    ? 'Confirmer le paiement'
                                    : 'Confirm payment',
                                style: const TextStyle(fontSize: 16),
                              ),
                      ),
                    ),
                  ),

                if (_etape == 5)
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
                        child: Text(
                          provider.langue == 'fr' ? 'Retour' : 'Back',
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

  // ── Étape 1 : Choix du mode de paiement ──
  Widget _buildEtape1(AppProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SingleChildScrollView(
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
                    Formatage.montant(_montantTotal),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E9E6E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${provider.langue == 'fr' ? 'Pour' : 'For'} : ${widget.membre.nom}',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  // ── Détail sanction ──
                  if (_sanctionActive != null) ...[
                    const Divider(),
                    _buildLigneDetail(
                      provider.langue == 'fr'
                          ? 'Cotisation normale'
                          : 'Normal contribution',
                      Formatage.montant(widget.tontine.montant),
                    ),
                    _buildLigneDetail(
                      provider.langue == 'fr'
                          ? 'Pénalité (${_sanctionActive!.nombreFrequencesRetard} retard(s) × 10%)'
                          : 'Penalty (${_sanctionActive!.nombreFrequencesRetard} late(s) × 10%)',
                      Formatage.montant(
                        _sanctionActive!.montantDu - widget.tontine.montant,
                      ),
                      couleur: Colors.red,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            Text(
              provider.langue == 'fr'
                  ? 'Choisissez votre mode de paiement'
                  : 'Choose your payment method',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),

            const SizedBox(height: 16),

            // ── Modes de paiement ──
            ...ModePaiement.modes.map((mode) {
              final selectionne = _modeSelectionne?.type == mode.type;
              final estBancaire = mode.type == TypePaiement.bancaire;

              return GestureDetector(
                onTap: estBancaire
                    ? null
                    : () {
                        // ← désactive le tap pour bancaire
                        setState(() => _modeSelectionne = mode);
                      },
                child: Opacity(
                  opacity: estBancaire ? 0.5 : 1.0, // ← grisé
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: selectionne
                          ? mode.couleur.withOpacity(0.1)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selectionne
                            ? mode.couleur
                            : Colors.grey.shade300,
                        width: selectionne ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        // ── Logo ──
                        mode.image != null
                            ? Image.asset(
                                mode.image!,
                                width: 40,
                                height: 40,
                                fit: BoxFit.contain,
                              )
                            : Column(
                                children: [
                                  if (estBancaire)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.orange,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'Bientôt',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  const SizedBox(height: 4),
                                  const Icon(
                                    Icons.account_balance,
                                    size: 36,
                                    color: Color(0xFF2E9E6E),
                                  ),
                                ],
                              ),

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
                                estBancaire
                                    ? (provider.langue == 'fr'
                                          ? 'En attente — disponible prochainement'
                                          : 'Pending — coming soon')
                                    : mode.description,
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
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ── Étape 2 : Saisie des informations ──
  Widget _buildEtape2(AppProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _modeSelectionne!.couleur.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _modeSelectionne!.couleur),
            ),
            child: Row(
              children: [
                _modeSelectionne!.image != null
                    ? Image.asset(
                        _modeSelectionne!.image!,
                        width: 40,
                        height: 40,
                        fit: BoxFit.contain,
                      )
                    : Text(
                        _modeSelectionne!.logo ?? '🏦',
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
            Text(
              provider.langue == 'fr'
                  ? 'Informations bancaires'
                  : 'Bank information',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            _buildInfoBancaire('Banque', 'Afriland First Bank'),
            _buildInfoBancaire('Titulaire', 'Njangi App'),
            _buildInfoBancaire('RIB', '10005 00001 12345678901 23'),
            _buildInfoBancaire(
              provider.langue == 'fr' ? 'Montant' : 'Amount',
              Formatage.montant(_montantTotal),
            ),
            _buildInfoBancaire('Référence', widget.tontine.codeInvitation),
          ] else ...[
            Text(
              provider.langue == 'fr'
                  ? 'Entrez votre numéro ${_modeSelectionne!.nom}'
                  : 'Enter your ${_modeSelectionne!.nom} number',
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
                      provider.langue == 'fr'
                          ? 'Vous recevrez une demande de confirmation sur votre téléphone'
                          : 'You will receive a confirmation request on your phone',
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
  Widget _buildEtape3(AppProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  provider.langue == 'fr'
                      ? 'Récapitulatif du paiement'
                      : 'Payment summary',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                _buildLigneRecap(
                  provider.langue == 'fr' ? 'Tontine' : 'Tontine',
                  widget.tontine.nom,
                ),
                _buildLigneRecap(
                  provider.langue == 'fr' ? 'Membre' : 'Member',
                  widget.membre.nom,
                ),
                _buildLigneRecap(
                  provider.langue == 'fr' ? 'Cotisation' : 'Contribution',
                  Formatage.montant(widget.tontine.montant),
                ),
                if (_sanctionActive != null)
                  _buildLigneRecap(
                    provider.langue == 'fr'
                        ? 'Pénalité retard'
                        : 'Late penalty',
                    Formatage.montant(
                      _sanctionActive!.montantDu - widget.tontine.montant,
                    ),
                    couleur: Colors.red,
                  ),
                _buildLigneRecap(
                  provider.langue == 'fr' ? 'Mode' : 'Method',
                  _modeSelectionne!.nom,
                ),
                if (_modeSelectionne!.type != TypePaiement.bancaire)
                  _buildLigneRecap(
                    provider.langue == 'fr' ? 'Numéro' : 'Number',
                    _numeroController.text,
                  ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      provider.langue == 'fr' ? 'Total' : 'Total',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      Formatage.montant(_montantTotal),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _sanctionActive != null
                            ? Colors.red
                            : const Color(0xFF2E9E6E),
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

  // ── Étape 4 : en attente de confirmation du paiement (webhook Fapshi) ──
  Widget _buildEtapeAttente(AppProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Color(0xFF2E9E6E)),
            const SizedBox(height: 24),
            Text(
              provider.langue == 'fr'
                  ? 'En attente de confirmation...'
                  : 'Waiting for confirmation...',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E9E6E),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              provider.langue == 'fr'
                  ? 'Terminez le paiement ${_modeSelectionne!.nom} sur la page ouverte, puis revenez ici.'
                  : 'Complete the ${_modeSelectionne!.nom} payment on the page that opened, then come back here.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  // ── Étape 5 : Succès (paiement confirmé par le webhook) ──
  Widget _buildEtape5(AppProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
            Text(
              provider.langue == 'fr'
                  ? 'Paiement réussi !'
                  : 'Payment successful!',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E9E6E),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${Formatage.montant(_montantTotal)} ${provider.langue == 'fr' ? 'payé via' : 'paid via'} ${_modeSelectionne!.nom}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              '${provider.langue == 'fr' ? 'Pour' : 'For'} ${widget.membre.nom} ${provider.langue == 'fr' ? 'dans' : 'in'} "${widget.tontine.nom}"',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  // ── Widget ligne récapitulatif ──
  Widget _buildLigneRecap(String label, String valeur, {Color? couleur}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          Text(
            valeur,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: couleur ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // ── Widget ligne détail ──
  Widget _buildLigneDetail(String label, String valeur, {Color? couleur}) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(
            valeur,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: couleur ?? Colors.black87,
            ),
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
