import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/firestore_service.dart';
import '../models/notification_model.dart';
import 'home_screen.dart';
import 'tontines_screen.dart';
import 'profil_screen.dart';
import 'notification_screen.dart';
import 'statistiques_screen.dart';
import 'chatbot_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomeScreen(),
    TontinesScreen(),
    NotificationScreen(),
    StatistiquesScreen(),
    ProfilScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        final textes = provider.textes;

        return Scaffold(
          body: _pages[_currentIndex],

          // ── Bouton flottant chatbot ──
          floatingActionButton: _currentIndex != 1
              ? FloatingActionButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ChatbotScreen(),
                      ),
                    );
                  },
                  backgroundColor: const Color(0xFF7B2D8B),
                  child: const Icon(Icons.smart_toy, color: Colors.white),
                )
              : null,

          bottomNavigationBar: StreamBuilder<List<NotificationModel>>(
            stream: FirestoreService().getNotifications(),
            builder: (context, snapshot) {
              final notifications = snapshot.data ?? [];
              final nonLues = notifications.where((n) => !n.lu).length;

              return BottomNavigationBar(
                currentIndex: _currentIndex,
                onTap: (index) {
                  setState(() => _currentIndex = index);
                },
                selectedItemColor: const Color(0xFF7B2D8B),
                unselectedItemColor: Colors.grey,
                type: BottomNavigationBarType.fixed,
                items: [
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.home_outlined),
                    activeIcon: const Icon(Icons.home),
                    label: textes['accueil']!,
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.description_outlined),
                    activeIcon: const Icon(Icons.description),
                    label: textes['tontines']!,
                  ),
                  BottomNavigationBarItem(
                    icon: Badge(
                      isLabelVisible: nonLues > 0,
                      label: Text('$nonLues'),
                      child: const Icon(Icons.notifications_outlined),
                    ),
                    activeIcon: Badge(
                      isLabelVisible: nonLues > 0,
                      label: Text('$nonLues'),
                      child: const Icon(Icons.notifications),
                    ),
                    label: textes['alertes']!,
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.bar_chart_outlined),
                    activeIcon: const Icon(Icons.bar_chart),
                    label: textes['stats']!,
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.person_outline),
                    activeIcon: const Icon(Icons.person),
                    label: textes['profil']!,
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
