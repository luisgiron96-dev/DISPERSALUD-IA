import 'package:flutter/material.dart';
import 'home/home_screen.dart';
import 'dashboard_screen.dart';
import 'pacientes_screen.dart';
import 'alertas_screen.dart';
import 'config_screen.dart';
import '../core/app_theme.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _tab = 0;

  // ← sin const porque los widgets usan Theme.of(context)
  // sin const — los widgets leen Theme.of(context) internamente
  final List<Widget> _screens = [
    DashboardScreen(),
    HomeScreen(),
    PacientesScreen(),
    AlertasScreen(),
    ConfigScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final t     = Theme.of(context);
    final dc    = t.extension<DispersaludColors>()!;
    final verde = t.colorScheme.primary;

    return Scaffold(
      backgroundColor: dc.bg,
      body: IndexedStack(index: _tab, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: dc.card,
          border: Border(top: BorderSide(color: dc.border, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _tab,
          onTap: (i) => setState(() => _tab = i),
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor:    verde,
          unselectedItemColor:  dc.textHint,
          selectedLabelStyle:   const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
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