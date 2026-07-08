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

// ── Ítem de navegación con color propio por sección ─────────────────────────
class _ItemNav {
  final IconData icono, iconoActivo;
  final String   label;
  final Color    color; // color de acento único por sección
  const _ItemNav(this.icono, this.iconoActivo, this.label, this.color);
}

const List<_ItemNav> _kItemsNav = [
  _ItemNav(Icons.home_outlined,              Icons.home_rounded,              'Inicio',        Color(0xFF1D9E75)),
  _ItemNav(Icons.grid_view_outlined,         Icons.grid_view_rounded,         'Módulos',       Color(0xFF7C4FD6)),
  _ItemNav(Icons.people_outline,             Icons.people_rounded,            'Pacientes',     Color(0xFF3FA9D6)),
  _ItemNav(Icons.medical_services_outlined,  Icons.medical_services_rounded,  'Especialistas', Color(0xFFE8729A)),
  _ItemNav(Icons.health_and_safety_outlined, Icons.health_and_safety_rounded, 'Salud Pública', Color(0xFFEF9F27)),
  _ItemNav(Icons.settings_outlined,          Icons.settings_rounded,          'Config',        Color(0xFF3FB6A8)),
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

    if (context.isMovil) {
      return Scaffold(
        backgroundColor: dc.bg,
        body: IndexedStack(index: _tab, children: _screens),
        bottomNavigationBar: _BarraInferior(
          tab: _tab, verde: verde, dc: dc,
          onTap: (i) => setState(() => _tab = i),
        ),
      );
    }

    return Scaffold(
      backgroundColor: dc.bg,
      body: Row(children: [
        _SidebarNav(
          tab: _tab,
          dc: dc,
          extended: context.isDesktop,
          onTap: (i) => setState(() => _tab = i),
        ),
        Expanded(child: IndexedStack(index: _tab, children: _screens)),
      ]),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  Sidebar personalizado
// ════════════════════════════════════════════════════════════════════════════
class _SidebarNav extends StatelessWidget {
  final int    tab;
  final DispersaludColors dc;
  final bool   extended;
  final ValueChanged<int> onTap;

  const _SidebarNav({
    required this.tab,
    required this.dc,
    required this.extended,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    // Sidebar ligeramente más oscuro que la card para dar profundidad
    final sidebarBg = dark
        ? const Color(0xFF161616)
        : const Color(0xFFFFFFFF);

    final width = extended ? 220.0 : 72.0;

    // Items de navegación (todos menos Config)
    final navItems = _kItemsNav.sublist(0, _kItemsNav.length - 1);
    final configItem = _kItemsNav.last;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      width: width,
      decoration: BoxDecoration(
        color: sidebarBg,
        border: Border(
          right: BorderSide(color: dc.border, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(dark ? 0.3 : 0.06),
            blurRadius: 12,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(children: [

        // ── Logo / branding ──────────────────────────────────────────────
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 20, 12, 24),
            child: _Logo(extended: extended, dc: dc),
          ),
        ),

        // ── Items principales ────────────────────────────────────────────
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            itemCount: navItems.length,
            itemBuilder: (_, i) => _NavItem(
              item:     navItems[i],
              activo:   i == tab,
              extended: extended,
              dc:       dc,
              onTap:    () => onTap(i),
            ),
          ),
        ),

        // ── Separador ────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Divider(color: dc.border, height: 1),
        ),
        const SizedBox(height: 10),

        // ── Config (al fondo, separado) ───────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
          child: _NavItem(
            item:     configItem,
            activo:   tab == _kItemsNav.length - 1,
            extended: extended,
            dc:       dc,
            onTap:    () => onTap(_kItemsNav.length - 1),
          ),
        ),

        SafeArea(
          top: false,
          child: const SizedBox(height: 14),
        ),
      ]),
    );
  }
}

// ── Logo en la cabecera del sidebar ──────────────────────────────────────────
class _Logo extends StatelessWidget {
  final bool extended;
  final DispersaludColors dc;
  const _Logo({required this.extended, required this.dc});

  @override
  Widget build(BuildContext context) {
    // Logo real de la app
    final logoWidget = ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.asset(
        'assets/logo_dispersalud.png',
        width: 40, height: 40,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0A5240), Color(0xFF1D9E75)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.local_hospital_rounded,
              color: Colors.white, size: 22),
        ),
      ),
    );

    return Row(
      mainAxisAlignment: extended
          ? MainAxisAlignment.start
          : MainAxisAlignment.center,
      children: [
        logoWidget,
        if (extended) ...[
          const SizedBox(width: 10),
          Flexible(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('DISPERSALUD',
                  style: TextStyle(
                      color: Color(0xFF1D9E75),
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0),
                  overflow: TextOverflow.ellipsis),
              Text('IA · Salud rural',
                  style: TextStyle(color: dc.textHint, fontSize: 10)),
            ],
          )),
        ],
      ],
    );
  }
}

// ── Ítem individual del sidebar ───────────────────────────────────────────────
class _NavItem extends StatelessWidget {
  final _ItemNav item;
  final bool     activo;
  final bool     extended;
  final DispersaludColors dc;
  final VoidCallback onTap;

  const _NavItem({
    required this.item,
    required this.activo,
    required this.extended,
    required this.dc,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final color = item.color;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          splashColor: color.withOpacity(0.12),
          highlightColor: color.withOpacity(0.06),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            height: 48,
            padding: EdgeInsets.symmetric(
                horizontal: extended ? 12 : 0),
            decoration: BoxDecoration(
              // Fondo activo: gradiente suave con el color del ítem
              gradient: activo
                  ? LinearGradient(
                      colors: [
                        color.withOpacity(dark ? 0.22 : 0.15),
                        color.withOpacity(dark ? 0.10 : 0.07),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    )
                  : null,
              borderRadius: BorderRadius.circular(14),
              border: activo
                  ? Border.all(color: color.withOpacity(0.35), width: 1)
                  : null,
            ),
            child: Row(
              mainAxisAlignment: extended
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.center,
              children: [
                // ── Icono con fondo colored ─────────────────────────────
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: activo
                        ? color.withOpacity(dark ? 0.25 : 0.18)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    activo ? item.iconoActivo : item.icono,
                    color: activo ? color : dc.textHint,
                    size: 20,
                  ),
                ),

                // ── Etiqueta (solo cuando extended) ────────────────────
                if (extended) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item.label,
                      style: TextStyle(
                        color: activo ? color : dc.textSecondary,
                        fontSize: 13,
                        fontWeight: activo
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Punto indicador a la derecha cuando activo
                  if (activo)
                    Container(
                      width: 6, height: 6,
                      decoration: BoxDecoration(
                          color: color, shape: BoxShape.circle),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  Barra inferior móvil — rediseñada
// ════════════════════════════════════════════════════════════════════════════
class _BarraInferior extends StatelessWidget {
  const _BarraInferior({
    required this.tab,
    required this.verde,
    required this.dc,
    required this.onTap,
  });

  final int   tab;
  final Color verde;
  final DispersaludColors dc;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: dc.card,
        border: Border(top: BorderSide(color: dc.border, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: List.generate(_kItemsNav.length, (i) {
              final item   = _kItemsNav[i];
              final activo = i == tab;
              final color  = activo ? item.color : dc.textHint;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: activo
                              ? item.color.withOpacity(0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          activo ? item.iconoActivo : item.icono,
                          color: color,
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.label,
                        style: TextStyle(
                          color: color,
                          fontSize: 9,
                          fontWeight: activo
                              ? FontWeight.w700
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}