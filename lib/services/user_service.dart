import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  // Singleton
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Référence collection utilisateurs
  CollectionReference get _users => _db.collection('users');

  // Récupère l'utilisateur connecté
  User? get currentUser => _auth.currentUser;

  // Récupère l'ID de l'utilisateur connecté
  String? get currentUserId => _auth.currentUser?.uid;

  // Crée ou met à jour le profil utilisateur
  Future<void> sauvegarderProfil({
    required String nom,
    required String telephone,
  }) async {
    final uid = currentUserId;
    if (uid == null) return;

    await _users.doc(uid).set({
      'uid': uid,
      'nom': nom,
      'telephone': telephone,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Récupère le profil utilisateur
  Future<Map<String, dynamic>?> getProfil() async {
    final uid = currentUserId;
    if (uid == null) return null;

    final doc = await _users.doc(uid).get();
    if (!doc.exists) return null;

    return doc.data() as Map<String, dynamic>;
  }

  // Vérifie si le profil est complet
  Future<bool> profilEstComplet() async {
    final profil = await getProfil();
    if (profil == null) return false;
    return profil['nom'] != null && profil['nom'].toString().isNotEmpty;
  }

  // Stream du profil en temps réel
  Stream<Map<String, dynamic>?> getProfilStream() {
    final uid = currentUserId;
    if (uid == null) return Stream.value(null);

    return _users.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return doc.data() as Map<String, dynamic>;
    });
  }

  // Déconnexion
  Future<void> deconnecter() async {
    await _auth.signOut();
  }

  // Sauvegarde la photo de profil en Base64
  Future<void> sauvegarderPhoto(String base64Photo) async {
    final uid = currentUserId;
    if (uid == null) return;

    await _users.doc(uid).update({'photoBase64': base64Photo});
  }
}
