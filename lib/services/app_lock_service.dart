import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

// Verrouillage de l'app par code PIN (+ biométrie optionnelle). Le PIN
// n'est jamais stocké en clair : seul son hash SHA-256 est conservé dans
// le stockage sécurisé (Keystore Android / Keychain iOS).
class AppLockService {
  // Singleton
  static final AppLockService _instance = AppLockService._internal();
  factory AppLockService() => _instance;
  AppLockService._internal();

  static const _clePinHash = 'app_lock_pin_hash';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final LocalAuthentication _localAuth = LocalAuthentication();

  String _hacher(String pin) => sha256.convert(utf8.encode(pin)).toString();

  // Le verrouillage est actif dès qu'un PIN a été défini
  Future<bool> estActif() async {
    final hash = await _storage.read(key: _clePinHash);
    return hash != null;
  }

  Future<void> definirPin(String pin) async {
    await _storage.write(key: _clePinHash, value: _hacher(pin));
  }

  Future<bool> verifierPin(String pin) async {
    final hash = await _storage.read(key: _clePinHash);
    return hash != null && hash == _hacher(pin);
  }

  Future<void> desactiver() async {
    await _storage.delete(key: _clePinHash);
  }

  // Vérifie si la biométrie est configurée et utilisable sur l'appareil
  Future<bool> biometrieDisponible() async {
    try {
      final supporte = await _localAuth.isDeviceSupported();
      final peutVerifier = await _localAuth.canCheckBiometrics;
      return supporte && peutVerifier;
    } catch (_) {
      return false;
    }
  }

  Future<bool> authentifierParBiometrie() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Authentifiez-vous pour accéder à Njangi',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } catch (_) {
      return false;
    }
  }
}
