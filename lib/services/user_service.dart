import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
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

  // Supprime définitivement le compte et toutes ses données (Cloud
  // Function, voir functions/index.js). Lève une FirebaseFunctionsException
  // (code 'failed-precondition') si l'utilisateur gère encore une tontine
  // avec d'autres membres actifs.
  Future<void> supprimerCompte() async {
    final callable = FirebaseFunctions.instance.httpsCallable(
      'supprimerCompte',
    );
    await callable.call();
  }

  // Sauvegarde la photo de profil en Base64
  Future<void> sauvegarderPhoto(String base64Photo) async {
    final uid = currentUserId;
    if (uid == null) return;

    await _users.doc(uid).update({'photoBase64': base64Photo});
  }

  // Recherche un utilisateur par numéro de téléphone
  Future<Map<String, dynamic>?> rechercherParTelephone(String telephone) async {
    String numero = telephone.replaceAll(' ', '');

    if (!numero.startsWith('+')) {
      numero = '+237$numero';
    }

    final snapshot = await _db
        .collection('users')
        .where('telephone', isEqualTo: numero)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;

    final data = snapshot.docs.first.data();
    return {
      'uid': snapshot.docs.first.id,
      'nom': data['nom'],
      'telephone': data['telephone'],
    };
  }

  // Récupère l'UID de l'utilisateur connecté
  String? get uidActuel => _auth.currentUser?.uid;

  // Récupère le nom de l'utilisateur connecté
  Future<String> getNomActuel() async {
    final uid = uidActuel;
    if (uid == null) return 'Utilisateur';

    final doc = await _db.collection('users').doc(uid).get();
    final data = doc.data();
    return data?['nom'] ?? 'Utilisateur';
  }
}
