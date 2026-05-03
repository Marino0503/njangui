import 'package:flutter/material.dart';
import '../data/notifications_data.dart';
import '../services/firestore_service.dart';
import '../models/notification_model.dart';
import 'home_screen.dart';
import 'tontines_screen.dart';
import 'profil_screen.dart';
import 'notification_screen.dart';
import 'statistiques_screen.dart';

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
    return Scaffold(
      body: _pages[_currentIndex],
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
              const BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Home',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.description_outlined),
                activeIcon: Icon(Icons.description),
                label: 'Tontines',
              ),

              // ── Notifications avec badge ──
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
                label: 'Alertes',
              ),

              const BottomNavigationBarItem(
                icon: Icon(Icons.bar_chart_outlined),
                activeIcon: Icon(Icons.bar_chart),
                label: 'Stats',
              ),

              const BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Profil',
              ),
            ],
          );
        },
      ),
    );
  }
}
