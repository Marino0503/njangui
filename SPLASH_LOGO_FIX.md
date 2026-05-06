# Splash / Logo Fix Summary

## Contexte

Ce document récapitule les modifications faites pour corriger le logo de l'application et le splash screen.

## Modifications principales

### 1. Correction du nom de l'asset

- Le fichier logo a été renommé en `assets/images/njangi_logo.png` (minuscules).
- Cela corrige la casse et évite les erreurs de chargement sur les plateformes sensibles à la casse.

### 2. Mise à jour du code Flutter

- `lib/screens/login_screen.dart`
  - `Image.asset('assets/images/njangi_logo.PNG', ...)` → `Image.asset('assets/images/njangi_logo.png', ...)`
  - Emplacement : écran de connexion
- `lib/screens/home_screen.dart`
  - `Image.asset('assets/images/njangi_logo.PNG', ...)` → `Image.asset('assets/images/njangi_logo.png', ...)`
  - Emplacement : écran d'accueil

### 3. Configuration des assets Flutter

- `pubspec.yaml`
  - `assets/images/njangi_logo.PNG` → `assets/images/njangi_logo.png`
  - Ajout / correction des sections `flutter_launcher_icons` et `flutter_native_splash`
  - L'image de splash Android 12+ est configurée comme `assets/images/njangi_logo.png`

### 4. Outil d'aide pour préparer le splash

- Fichier ajouté : `prepare_splash_icon.py`
- Objectif : générer une image de splash `1152×1152` avec un logo centré et un ratio configurable.
- Usage recommandé :
  - `python prepare_splash_icon.py --input assets/images/njangi_logo.png --output assets/images/njangi_logo.png`
  - Ajuster `--logo-ratio` si le logo est trop grand ou trop petit

## Remarques

- Les ressources générées (`android/app/src/main/res/...`, `ios/Runner/...`, `web/splash/`) sont liées à la génération du splash et des icônes.
- Après modification du logo ou de `pubspec.yaml`, exécuter :
  1. `flutter pub get`
  2. `flutter pub run flutter_native_splash:create`
  3. `flutter pub run flutter_launcher_icons`
  4. Désinstaller l'app et relancer avec `flutter run`

## Résultat attendu

- Le logo se charge correctement dans l'app
- Le splash Android 12+ utilise une image centrée avec du padding
- Plus d'erreur de fichier introuvable à cause de la casse `PNG` / `png`
