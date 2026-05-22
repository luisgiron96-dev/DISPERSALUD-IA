import 'package:flutter/material.dart';

// ─── Colores principales ───────────────────────────────────────────────────
const Color kPrimary = Color(0xFF0F6E56);
const Color kPrimaryDark = Color(0xFF085041);
const Color kPrimaryLight = Color(0xFFE1F5EE);
const Color kPrimaryMid = Color(0xFF9FE1CB);
const Color kAccent = Color(0xFF5DCAA5);

// ─── Modelo de módulo ──────────────────────────────────────────────────────
class ModuloCicloVital {
  final String nombre;
  final String rango;
  final IconData icono;
  final Color colorFondo;
  final Color colorIcono;
  final String ruta;

  const ModuloCicloVital({
    required this.nombre,
    required this.rango,
    required this.icono,
    required this.colorFondo,
    required this.colorIcono,
    required this.ruta,
  });
}

// ─── Datos de los 7 módulos ────────────────────────────────────────────────
const List<ModuloCicloVital> kModulos = [
  ModuloCicloVital(
    nombre: 'Gestación',
    rango: 'Control prenatal · signos de alarma',
    icono: Icons.favorite_border_rounded,
    colorFondo: Color(0xFFFBEAF0),
    colorIcono: Color(0xFF993556),
    ruta: '/gestacion',
  ),
  ModuloCicloVital(
    nombre: 'Primera infancia',
    rango: '0 a 5 años · crecimiento y desarrollo',
    icono: Icons.child_friendly_outlined,
    colorFondo: Color(0xFFFAEEDA),
    colorIcono: Color(0xFF854F0B),
    ruta: '/primera-infancia',
  ),
  ModuloCicloVital(
    nombre: 'Infancia',
    rango: '6 a 11 años · salud escolar',
    icono: Icons.school_outlined,
    colorFondo: Color(0xFFE6F1FB),
    colorIcono: Color(0xFF185FA5),
    ruta: '/infancia',
  ),
  ModuloCicloVital(
    nombre: 'Adolescencia',
    rango: '12 a 17 años · salud sexual y mental',
    icono: Icons.directions_run_rounded,
    colorFondo: Color(0xFFEEEDFE),
    colorIcono: Color(0xFF534AB7),
    ruta: '/adolescencia',
  ),
  ModuloCicloVital(
    nombre: 'Juventud',
    rango: '18 a 28 años · prevención y bienestar',
    icono: Icons.group_outlined,
    colorFondo: Color(0xFFEAF3DE),
    colorIcono: Color(0xFF3B6D11),
    ruta: '/juventud',
  ),
  ModuloCicloVital(
    nombre: 'Adultez',
    rango: '29 a 59 años · enfermedades crónicas',
    icono: Icons.medical_services_outlined,
    colorFondo: Color(0xFFE1F5EE),
    colorIcono: Color(0xFF0F6E56),
    ruta: '/adultez',
  ),
  ModuloCicloVital(
    nombre: 'Vejez',
    rango: '60 años o más · cuidado del adulto mayor',
    icono: Icons.accessible_forward_rounded,
    colorFondo: Color(0xFFF1EFE8),
    colorIcono: Color(0xFF5F5E5A),
    ruta: '/vejez',
  ),
];

// ─── Pantalla principal ────────────────────────────────────────────────────
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // Header verde
          _Header(),

          // Lista de módulos con scroll
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                const _SeccionLabel(texto: 'Módulos de atención'),
                const SizedBox(height: 4),
                ...kModulos.map((m) => _ModuloCard(modulo: m)).toList(),
                const SizedBox(height: 8),
              ],
            ),
          ),

          // Barra de navegación inferior
          _BottomBar(),
        ],
      ),
    );
  }
}

// ─── Header ────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: kPrimary,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo + nombre + campana
              Row(
                children: [
                  // Ícono circular
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: kPrimaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.monitor_heart_outlined,
                      color: kPrimary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Nombre de la app
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DISPERSALUD IA',
                          style: TextStyle(
                            color: Color(0xFFE1F5EE),
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                        Text(
                          'Salud rural inteligente · sin internet',
                          style: TextStyle(
                            color: Color(0xFF9FE1CB),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Campana
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.notifications_outlined,
                      color: Color(0xFF9FE1CB),
                      size: 24,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Tarjeta de bienvenida
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.account_circle_outlined,
                      color: Color(0xFF9FE1CB),
                      size: 36,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bienvenido, promotor',
                            style: TextStyle(
                              color: Color(0xFFE1F5EE),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Vereda El Palmar · Cauca',
                            style: TextStyle(
                              color: Color(0xFF9FE1CB),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Badge offline
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: kPrimaryDark,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            color: kAccent,
                            size: 13,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Offline',
                            style: TextStyle(
                              color: Color(0xFF9FE1CB),
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Etiqueta de sección ───────────────────────────────────────────────────
class _SeccionLabel extends StatelessWidget {
  final String texto;
  const _SeccionLabel({required this.texto});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 6),
      child: Text(
        texto.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: Color(0xFF888780),
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// ─── Tarjeta de módulo ─────────────────────────────────────────────────────
class _ModuloCard extends StatelessWidget {
  final ModuloCicloVital modulo;
  const _ModuloCard({required this.modulo});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => Navigator.pushNamed(context, modulo.ruta),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.black.withOpacity(0.07),
                width: 0.5,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                // Ícono del módulo
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: modulo.colorFondo,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    modulo.icono,
                    color: modulo.colorIcono,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                // Nombre y descripción
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        modulo.nombre,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF2C2C2A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        modulo.rango,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF888780),
                        ),
                      ),
                    ],
                  ),
                ),
                // Flecha
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFFB4B2A9),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Barra de navegación inferior ─────────────────────────────────────────
class _BottomBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.black.withOpacity(0.08),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: const [
          _NavItem(icono: Icons.home_outlined, label: 'Inicio', activo: true),
          _NavItem(icono: Icons.assignment_outlined, label: 'Pacientes'),
          _NavItem(icono: Icons.warning_amber_outlined, label: 'Alertas'),
          _NavItem(icono: Icons.settings_outlined, label: 'Config'),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icono;
  final String label;
  final bool activo;

  const _NavItem({
    required this.icono,
    required this.label,
    this.activo = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = activo ? kPrimary : const Color(0xFF888780);
    return GestureDetector(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, color: color, size: 24),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: activo ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}