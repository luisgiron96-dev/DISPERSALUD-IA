import 'package:flutter/material.dart';
import 'home/home_screen.dart';
import 'dashboard_screen.dart';
import 'pacientes_screen.dart';
import 'alertas_screen.dart';
import 'config_screen.dart';

const Color _kBg     = Color(0xFF111111);
const Color _kCard   = Color(0xFF1E1E1E);
const Color _kVerde  = Color(0xFF1D9E75);
const Color _kBorder = Color(0xFF2A2A2A);

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _tab = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),   // Inicio
    HomeScreen(),        // Módulos
    PacientesScreen(),   // Pacientes ← nuevo con SQLite
    AlertasScreen(),     // Alertas
    ConfigScreen(),      // Config
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: IndexedStack(index: _tab, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: _kCard,
          border: Border(top: BorderSide(color: _kBorder, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _tab,
          onTap: (i) => setState(() => _tab = i),
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: _kVerde,
          unselectedItemColor: Colors.white30,
          selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined),          activeIcon: Icon(Icons.home_rounded),          label: 'Inicio'),
            BottomNavigationBarItem(icon: Icon(Icons.grid_view_outlined),     activeIcon: Icon(Icons.grid_view_rounded),     label: 'Módulos'),
            BottomNavigationBarItem(icon: Icon(Icons.people_outline),         activeIcon: Icon(Icons.people_rounded),        label: 'Pacientes'),
            BottomNavigationBarItem(icon: Icon(Icons.notifications_outlined), activeIcon: Icon(Icons.notifications_rounded), label: 'Alertas'),
            BottomNavigationBarItem(icon: Icon(Icons.settings_outlined),      activeIcon: Icon(Icons.settings_rounded),      label: 'Config'),
          ],
        ),
      ),
    );
  }
}