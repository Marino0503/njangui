import 'package:flutter/material.dart';
import '../data/notifications_data.dart';
import 'home_screen.dart';
import 'tontines_screen.dart';
import 'profil_screen.dart';
import 'notification_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final NotificationsData _notifData = NotificationsData();

  final List<Widget> _pages = const [
    HomeScreen(),
    TontinesScreen(),
    NotificationScreen(),
    ProfilScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
        selectedItemColor: const Color(0xFF7B2D8B),
        unselectedItemColor: Colors.grey,
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

          // ── Icône notifications avec badge ──
          BottomNavigationBarItem(
            icon: Badge(
              isLabelVisible: _notifData.nonLues > 0,
              label: Text('${_notifData.nonLues}'),
              child: const Icon(Icons.notifications_outlined),
            ),
            activeIcon: Badge(
              isLabelVisible: _notifData.nonLues > 0,
              label: Text('${_notifData.nonLues}'),
              child: const Icon(Icons.notifications),
            ),
            label: 'Alertes',
          ),

          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
