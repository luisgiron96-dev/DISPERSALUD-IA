import 'package:flutter/material.dart';
import 'home/home_screen.dart';
import 'dashboard_screen.dart';
import 'pacientes_screen.dart';
import 'alertas_screen.dart';
import 'config_screen.dart';
import 'especialistas/especialistas_screen.dart';
import '../core/app_theme.dart';
import '../core/responsive.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

// ── Datos de navegación compartidos entre BottomNav y NavigationRail ────────
class _ItemNav {
  final IconData icono, iconoActivo;
  final String label;
  const _ItemNav(this.icono, this.iconoActivo, this.label);
}

const List<_ItemNav> _kItemsNav = [
  _ItemNav(Icons.home_outlined,               Icons.home_rounded,               'Inicio'),
  _ItemNav(Icons.grid_view_outlined,          Icons.grid_view_rounded,          'Módulos'),
  _ItemNav(Icons.people_outline,              Icons.people_rounded,             'Pacientes'),
  _ItemNav(Icons.medical_services_outlined,   Icons.medical_services_rounded,   'Especialistas'),
  _ItemNav(Icons.health_and_safety_outlined,  Icons.health_and_safety_rounded,  'Salud Pública'),
  _ItemNav(Icons.settings_outlined,           Icons.settings_rounded,           'Config'),
];

class _MainScreenState extends State<MainScreen> {
  int _tab = 0;

  final List<Widget> _screens = [
    DashboardScreen(),
    HomeScreen(),
    PacientesScreen(),
    EspecialistasScreen(),
    AlertasScreen(),
    ConfigScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final t     = Theme.of(context);
    final dc    = t.extension<DispersaludColors>()!;
    final verde = t.colorScheme.primary;

    // ── Móvil: comportamiento idéntico al original (barra inferior) ────────
    if (context.isMovil) {
      return Scaffold(
        backgroundColor: dc.bg,
        body: IndexedStack(index: _tab, children: _screens),
        bottomNavigationBar: _BarraInferior(
          tab: _tab,
          verde: verde,
          dc: dc,
          onTap: (i) => setState(() => _tab = i),
        ),
      );
    }

    // ── Tablet / Escritorio: menú lateral (NavigationRail) ──────────────────
    // extended = true muestra también las etiquetas de texto, no solo íconos.
    final extendido = context.isDesktop;

    return Scaffold(
      backgroundColor: dc.bg,
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _tab,
            onDestinationSelected: (i) => setState(() => _tab = i),
            extended: extendido,
            minExtendedWidth: 220,
            backgroundColor: dc.card,
            selectedIconTheme: IconThemeData(color: verde),
            selectedLabelTextStyle: TextStyle(
                color: verde, fontWeight: FontWeight.w700),
            unselectedIconTheme: IconThemeData(color: dc.textHint),
            unselectedLabelTextStyle: TextStyle(color: dc.textHint),
            leading: const SizedBox(height: 12),
            destinations: _kItemsNav
                .map((it) => NavigationRailDestination(
                      icon:          Icon(it.icono),
                      selectedIcon:  Icon(it.iconoActivo),
                      label:         Text(it.label),
                    ))
                .toList(),
          ),
          VerticalDivider(width: 1, thickness: 1, color: dc.border),
          // El contenido se centra y limita en ancho para no verse
          // estirado en monitores muy anchos; cada pantalla interna
          // sigue funcionando igual, solo cambia el contenedor externo.
          Expanded(
            child: IndexedStack(index: _tab, children: _screens),
          ),
        ],
      ),
    );
  }
}

class _BarraInferior extends StatelessWidget {
  const _BarraInferior({
    required this.tab,
    required this.verde,
    required this.dc,
    required this.onTap,
  });

  final int tab;
  final Color verde;
  final DispersaludColors dc;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: dc.card,
        border: Border(top: BorderSide(color: dc.border, width: 1)),
      ),
      child: BottomNavigationBar(
        currentIndex: tab,
        onTap: onTap,
        backgroundColor: Colors.transparent,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor:    verde,
        unselectedItemColor:  dc.textHint,
        selectedLabelStyle:   const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 10),
        items: _kItemsNav
            .map((it) => BottomNavigationBarItem(
                  icon:       Icon(it.icono),
                  activeIcon: Icon(it.iconoActivo),
                  label:      it.label,
                ))
            .toList(),
      ),
    );
  }
}