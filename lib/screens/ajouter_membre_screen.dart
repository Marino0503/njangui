import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/tontine.dart';
import '../providers/app_provider.dart';
import '../services/firestore_service.dart';
import '../services/user_service.dart';

class AjouterMembreScreen extends StatefulWidget {
  final Tontine tontine;

  const AjouterMembreScreen({super.key, required this.tontine});

  @override
  State<AjouterMembreScreen> createState() => _AjouterMembreScreenState();
}

class _AjouterMembreScreenState extends State<AjouterMembreScreen> {
  final TextEditingController _telephoneController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _utilisateurTrouve;
  bool _recherche = false;

  @override
  void dispose() {
    _telephoneController.dispose();
    super.dispose();
  }

  Future<void> _rechercherUtilisateur() async {
    final provider = Provider.of<AppProvider>(context, listen: false);

    if (_telephoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.langue == 'fr'
                ? 'Veuillez entrer un numéro de téléphone'
                : 'Please enter a phone number',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _recherche = true;
      _utilisateurTrouve = null;
    });

    try {
      final resultat = await UserService().rechercherParTelephone(
        _telephoneController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _utilisateurTrouve = resultat;
          _recherche = false;
        });

        if (resultat == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                provider.langue == 'fr'
                    ? 'Aucun utilisateur Njangi trouvé avec ce numéro'
                    : 'No Njangi user found with this number',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _recherche = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _envoyerInvitation() async {
    final provider = Provider.of<AppProvider>(context, listen: false);

    if (_utilisateurTrouve == null) return;

    // Vérifie si la tontine est pleine
    if (widget.tontine.membres.length >= widget.tontine.nombreMembres) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.langue == 'fr'
                ? 'La tontine est complète (${widget.tontine.nombreMembres} membres maximum)'
                : 'The tontine is full (max ${widget.tontine.nombreMembres} members)',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Vérifie si l'utilisateur est déjà membre
    final dejaMembre = widget.tontine.membres.any(
      (m) => m.userId == _utilisateurTrouve!['uid'],
    );

    if (dejaMembre) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.langue == 'fr'
                ? 'Cet utilisateur est déjà membre ou a déjà été invité'
                : 'This user is already a member or has been invited',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final monNom = await UserService().getNomActuel();
      final monUid = UserService().uidActuel ?? '';

      await FirestoreService().envoyerInvitation(
        tontine: widget.tontine,
        userId: _utilisateurTrouve!['uid'],
        userNom: _utilisateurTrouve!['nom'],
        gestionnaireId: monUid,
        gestionnaireNom: monNom,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              provider.langue == 'fr'
                  ? 'Invitation envoyée à ${_utilisateurTrouve!['nom']} !'
                  : 'Invitation sent to ${_utilisateurTrouve!['nom']}!',
            ),
            backgroundColor: const Color(0xFF2E9E6E),
          ),
        );
        Navigator.pop(context);
      }
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
                      children: [
                        const Icon(
                          Icons.arrow_back_ios,
                          color: Color(0xFF7B2D8B),
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          provider.langue == 'fr'
                              ? 'Inviter un membre'
                              : 'Invite a member',
                          style: const TextStyle(
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
                      child: Icon(
                        Icons.person_search,
                        size: 50,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

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
                      '${widget.tontine.membres.length}/${widget.tontine.nombreMembres} ${provider.langue == 'fr' ? 'membres' : 'members'}',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ),

                  const SizedBox(height: 40),

                  Text(
                    provider.langue == 'fr'
                        ? 'Entrez le numéro de téléphone de la personne à inviter. Elle doit déjà avoir un compte Njangi.'
                        : 'Enter the phone number of the person to invite. They must already have a Njangi account.',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),

                  const SizedBox(height: 16),

                  // ── Champ téléphone ──
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _telephoneController,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(fontSize: 16),
                          decoration: InputDecoration(
                            labelText: provider.langue == 'fr'
                                ? 'Numéro de téléphone'
                                : 'Phone number',
                            hintText: 'Ex: +237658834387',
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
                          onChanged: (_) {
                            setState(() => _utilisateurTrouve = null);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _recherche ? null : _rechercherUtilisateur,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7B2D8B),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _recherche
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.search),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── Résultat de la recherche ──
                  if (_utilisateurTrouve != null)
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
                          const CircleAvatar(
                            radius: 24,
                            backgroundColor: Color(0xFF2E9E6E),
                            child: Icon(Icons.person, color: Colors.white),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _utilisateurTrouve!['nom'],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  _utilisateurTrouve!['telephone'],
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.check_circle,
                            color: Color(0xFF2E9E6E),
                          ),
                        ],
                      ),
                    ),

                  const Spacer(),

                  // ── Bouton inviter ──
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: (_isLoading || _utilisateurTrouve == null)
                          ? null
                          : _envoyerInvitation,
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
                          : Text(
                              provider.langue == 'fr'
                                  ? 'Envoyer l\'invitation'
                                  : 'Send invitation',
                              style: const TextStyle(fontSize: 16),
                            ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
