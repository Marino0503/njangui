import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/app_lock_service.dart';

enum LockScreenMode { verifier, creer }

// Écran de verrouillage par code PIN (+ biométrie si disponible).
//
// - mode.verifier : demande le code déjà défini. Utilisé au lancement de
//   l'app et à chaque retour depuis l'arrière-plan (voir main.dart).
// - mode.creer : fait saisir un nouveau code deux fois (création +
//   confirmation) puis l'enregistre. Utilisé depuis les paramètres.
//
// Dans les deux cas, un succès se traduit par Navigator.pop(context, true) :
// cet écran ne navigue jamais lui-même vers une autre page, ce qui permet
// de l'utiliser aussi bien comme porte d'entrée initiale que comme overlay
// de reverrouillage par-dessus l'écran déjà affiché.
class LockScreen extends StatefulWidget {
  final LockScreenMode mode;

  const LockScreen({super.key, required this.mode});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  String _pin = '';
  String? _premierPin;
  bool _etapeConfirmation = false;
  String? _erreur;
  bool _biometrieDisponible = false;

  @override
  void initState() {
    super.initState();
    if (widget.mode == LockScreenMode.verifier) {
      _preparerBiometrie();
    }
  }

  Future<void> _preparerBiometrie() async {
    final disponible = await AppLockService().biometrieDisponible();
    if (!mounted) return;
    setState(() => _biometrieDisponible = disponible);
    if (disponible) {
      _tenterBiometrie();
    }
  }

  Future<void> _tenterBiometrie() async {
    final ok = await AppLockService().authentifierParBiometrie();
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context, true);
    }
  }

  void _ajouterChiffre(String chiffre) {
    if (_pin.length >= 4) return;
    setState(() {
      _erreur = null;
      _pin += chiffre;
    });
    if (_pin.length == 4) {
      _traiterPinComplet();
    }
  }

  void _effacer() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _traiterPinComplet() async {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final textes = provider.textes;

    if (widget.mode == LockScreenMode.verifier) {
      final valide = await AppLockService().verifierPin(_pin);
      if (!mounted) return;
      if (valide) {
        Navigator.pop(context, true);
      } else {
        setState(() {
          _erreur = textes['codeIncorrect'];
          _pin = '';
        });
      }
      return;
    }

    // Mode création : deux passes (saisie puis confirmation)
    if (!_etapeConfirmation) {
      setState(() {
        _premierPin = _pin;
        _pin = '';
        _etapeConfirmation = true;
      });
      return;
    }

    if (_pin == _premierPin) {
      await AppLockService().definirPin(_pin);
      if (!mounted) return;
      Navigator.pop(context, true);
    } else {
      setState(() {
        _erreur = textes['codesNeCorrespondentPas'];
        _pin = '';
        _premierPin = null;
        _etapeConfirmation = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        final textes = provider.textes;
        final estVerification = widget.mode == LockScreenMode.verifier;

        final titre = estVerification
            ? textes['entrerCode']!
            : (_etapeConfirmation
                  ? textes['confirmerCode']!
                  : textes['definirCode']!);

        return PopScope(
          canPop: !estVerification,
          child: Scaffold(
            backgroundColor: Colors.white,
            body: SafeArea(
              child: Column(
                children: [
                  const Spacer(),

                  Image.asset('assets/images/njangi_logo.PNG', height: 70),
                  const SizedBox(height: 24),

                  Text(
                    titre,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF7B2D8B),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Indicateurs (4 points) ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (index) {
                      final rempli = index < _pin.length;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: rempli
                              ? const Color(0xFF7B2D8B)
                              : Colors.transparent,
                          border: Border.all(
                            color: const Color(0xFF7B2D8B),
                            width: 2,
                          ),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 16),

                  SizedBox(
                    height: 20,
                    child: _erreur != null
                        ? Text(
                            _erreur!,
                            style: const TextStyle(color: Colors.red),
                          )
                        : null,
                  ),

                  const SizedBox(height: 20),

                  // ── Pavé numérique ──
                  ..._construirePave(),

                  if (!estVerification) ...[
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(textes['annuler']!),
                    ),
                  ] else if (_biometrieDisponible) ...[
                    const SizedBox(height: 12),
                    IconButton(
                      onPressed: _tenterBiometrie,
                      icon: const Icon(
                        Icons.fingerprint,
                        size: 36,
                        color: Color(0xFF7B2D8B),
                      ),
                    ),
                  ],

                  const Spacer(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _construirePave() {
    Widget bouton(String valeur) {
      return Expanded(
        child: AspectRatio(
          aspectRatio: 1.4,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: valeur.isEmpty
                ? const SizedBox()
                : Material(
                    color: Colors.grey.shade100,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: valeur == '⌫'
                          ? _effacer
                          : () => _ajouterChiffre(valeur),
                      child: Center(
                        child: valeur == '⌫'
                            ? const Icon(Icons.backspace_outlined)
                            : Text(
                                valeur,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ),
          ),
        ),
      );
    }

    const lignes = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', '⌫'],
    ];

    return lignes
        .map(
          (ligne) => Row(
            children: ligne.map(bouton).toList(),
          ),
        )
        .toList();
  }
}
