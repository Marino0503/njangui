import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/user_service.dart';
import '../services/firestore_service.dart';
import '../models/tontine.dart';
import 'login_screen.dart';
import 'parametres_screen.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _uploadingPhoto = false;

  // Choisit une photo depuis la galerie ou l'appareil photo
  Future<void> _choisirPhoto(BuildContext context) async {
    final provider = Provider.of<AppProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.photo_library,
                color: Color(0xFF7B2D8B),
              ),
              title: Text(
                provider.langue == 'fr'
                    ? 'Choisir depuis la galerie'
                    : 'Choose from gallery',
              ),
              onTap: () {
                Navigator.pop(context);
                _selectionnerPhoto(ImageSource.gallery, context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF7B2D8B)),
              title: Text(
                provider.langue == 'fr' ? 'Prendre une photo' : 'Take a photo',
              ),
              onTap: () {
                Navigator.pop(context);
                _selectionnerPhoto(ImageSource.camera, context);
              },
            ),
          ],
        ),
      ),
    );
  }

  // Sélectionne et sauvegarde la photo
  Future<void> _selectionnerPhoto(
    ImageSource source,
    BuildContext context,
  ) async {
    final provider = Provider.of<AppProvider>(context, listen: false);

    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 70,
      );

      if (image == null) return;

      setState(() => _uploadingPhoto = true);

      // Convertit en Base64
      final bytes = await image.readAsBytes();
      final base64String = base64Encode(bytes);

      // Sauvegarde dans Firestore
      await UserService().sauvegarderPhoto(base64String);

      if (!context.mounted) return;
      setState(() => _uploadingPhoto = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.langue == 'fr' ? 'Photo mise à jour !' : 'Photo updated!',
          ),
          backgroundColor: const Color(0xFF2E9E6E),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      setState(() => _uploadingPhoto = false);
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
          body: SafeArea(
            child: StreamBuilder<Map<String, dynamic>?>(
              stream: UserService().getProfilStream(),
              builder: (context, profilSnapshot) {
                if (profilSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF2E9E6E)),
                  );
                }

                final profil = profilSnapshot.data;
                final nom = profil?['nom'] ?? 'Utilisateur';
                final telephone = profil?['telephone'] ?? '';
                final photoBase64 = profil?['photoBase64'] as String?;

                return StreamBuilder<List<Tontine>>(
                  stream: FirestoreService().getTontines(),
                  builder: (context, tontinesSnapshot) {
                    final tontines = tontinesSnapshot.data ?? [];
                    final nombreTontines = tontines.length;

                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          const SizedBox(height: 30),

                          // ── Titre + bouton paramètres ──
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                provider.langue == 'fr'
                                    ? 'Mon Profil'
                                    : 'My Profile',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const ParametresScreen(),
                                    ),
                                  );
                                },
                                icon: const Icon(
                                  Icons.settings_outlined,
                                  color: Color(0xFF7B2D8B),
                                  size: 26,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // ── Photo de profil ──
                          GestureDetector(
                            onTap: () => _choisirPhoto(context),
                            child: Stack(
                              children: [
                                // Photo ou avatar
                                _uploadingPhoto
                                    ? const CircleAvatar(
                                        radius: 60,
                                        backgroundColor: Color(0xFF90EED4),
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                        ),
                                      )
                                    : photoBase64 != null
                                    ? CircleAvatar(
                                        radius: 60,
                                        backgroundImage: MemoryImage(
                                          base64Decode(photoBase64),
                                        ),
                                      )
                                    : const CircleAvatar(
                                        radius: 60,
                                        backgroundColor: Color(0xFF90EED4),
                                        child: Icon(
                                          Icons.person,
                                          size: 70,
                                          color: Colors.white,
                                        ),
                                      ),

                                // Bouton modifier
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF7B2D8B),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // ── Nom ──
                          Text(
                            nom,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 6),

                          // ── Numéro ──
                          Text(
                            telephone,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),

                          const SizedBox(height: 40),

                          // ── Informations ──
                          _buildInfoTile(
                            icon: Icons.person_outline,
                            titre: provider.langue == 'fr'
                                ? 'Nom complet'
                                : 'Full name',
                            valeur: nom,
                          ),
                          _buildInfoTile(
                            icon: Icons.phone_outlined,
                            titre: provider.langue == 'fr'
                                ? 'Téléphone'
                                : 'Phone',
                            valeur: telephone,
                          ),
                          _buildInfoTile(
                            icon: Icons.groups_outlined,
                            titre: provider.langue == 'fr'
                                ? 'Tontines actives'
                                : 'Active tontines',
                            valeur: nombreTontines.toString(),
                          ),

                          const SizedBox(height: 40),

                          // ── Bouton déconnexion ──
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final confirmer = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text(
                                      provider.langue == 'fr'
                                          ? 'Déconnexion'
                                          : 'Sign out',
                                    ),
                                    content: Text(
                                      provider.langue == 'fr'
                                          ? 'Voulez-vous vraiment vous déconnecter ?'
                                          : 'Are you sure you want to sign out?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: Text(textes['annuler']!),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: Text(
                                          textes['deconnexion']!,
                                          style: const TextStyle(
                                            color: Colors.red,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirmer == true) {
                                  await UserService().deconnecter();
                                  if (!context.mounted) return;
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const LoginScreen(),
                                    ),
                                    (route) => false,
                                  );
                                }
                              },
                              icon: const Icon(Icons.logout),
                              label: Text(
                                textes['deconnexion']!,
                                style: const TextStyle(fontSize: 16),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.shade400,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ),

                          const SizedBox(height: 30),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String titre,
    required String valeur,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF7B2D8B), size: 22),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titre,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(
                valeur,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
