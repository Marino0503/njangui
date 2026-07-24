import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/app_provider.dart';
import 'services/app_lock_service.dart';
import 'services/notification_service.dart';
import 'screens/lock_screen.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Crashlytics n'existe pas sur le web : on ne l'active que sur mobile/desktop.
  if (!kIsWeb) {
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  // Désactive Play Integrity/reCAPTCHA pour les numéros de test (debug uniquement,
  // nécessaire tant que le projet n'a pas le plan Blaze).
  if (kDebugMode) {
    await FirebaseAuth.instance.setSettings(
      appVerificationDisabledForTesting: true,
    );
  }

  // Initialise les préférences
  await AppProvider().initialiser();

  // Initialise les notifications de façon sécurisée
  try {
    await NotificationService().initialiser();
    await NotificationService().demanderPermission();
  } catch (e) {
    if (kDebugMode) {
      debugPrint('Notifications non disponibles : $e');
    }
  }

  runApp(
    ChangeNotifierProvider(create: (_) => AppProvider(), child: const MyApp()),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  bool _etaitEnArrierePlan = false;
  bool _verrouAffiche = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Reverrouille l'app quand elle revient de l'arrière-plan (et pas
  // seulement au lancement) : sans ça, poser son téléphone avec l'app déjà
  // ouverte contournerait totalement le verrouillage.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _etaitEnArrierePlan = true;
      return;
    }

    if (state == AppLifecycleState.resumed &&
        _etaitEnArrierePlan &&
        !_verrouAffiche) {
      _etaitEnArrierePlan = false;
      _verifierVerrouillage();
    }
  }

  Future<void> _verifierVerrouillage() async {
    if (!await AppLockService().estActif()) return;

    _verrouAffiche = true;
    await _navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (context) => const LockScreen(mode: LockScreenMode.verifier),
        fullscreenDialog: true,
      ),
    );
    _verrouAffiche = false;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        return MaterialApp(
          navigatorKey: _navigatorKey,
          title: 'Njangi',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF7B2D8B),
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: Colors.white,
            useMaterial3: true,
          ),
          themeMode: ThemeMode.light,
          home: const SplashScreen(),
        );
      },
    );
  }
}
