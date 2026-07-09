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
    final color = kVerde; // ← un solo color de acento para todos los ítems

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          splashColor: color.withOpacity(0.08),
          highlightColor: color.withOpacity(0.04),
          child: Container(
            height: 48,
            padding: EdgeInsets.symmetric(
                horizontal: extended ? 12 : 0),
            child: Row(
              mainAxisAlignment: extended
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.center,
              children: [
                Icon(
                  item.icono, // mismo ícono siempre, solo cambia el color
                  color: activo ? color : dc.textHint,
                  size: 21,
                ),

                // ── Etiqueta (solo cuando extended) ────────────────────
                if (extended) ...[
                  const SizedBox(width: 12),
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
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
        child: Container(
          height: 68,
          decoration: BoxDecoration(
            color: dc.card,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: dc.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.22),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: List.generate(_kItemsNav.length, (i) {
              final item   = _kItemsNav[i];
              final activo = i == tab;
              final color  = activo ? kVerde : dc.textHint; // ← un solo color
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item.icono, // mismo ícono siempre, solo cambia el color
                          color: color,
                          size: 21,
                        ),
                        const SizedBox(height: 3),
                        SizedBox(
                          width: 56,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              item.label,
                              maxLines: 1,
                              softWrap: false,
                              style: TextStyle(
                                color: color,
                                fontSize: 9,
                                fontWeight: activo
                                    ? FontWeight.w700
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
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