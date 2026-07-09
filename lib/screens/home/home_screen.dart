import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/app_theme.dart';
import '../../core/responsive.dart';
import '../../database/database_helper.dart';
import '../../services/connectivity_service.dart';

/// Construye el widget de la foto de perfil, ya sea que venga de un archivo
/// local (Android/iOS) o de un string base64 (web). Si el dato guardado
/// está vacío o corrupto, muestra [fallback] en su lugar en vez de fallar.
Widget _fotoPerfilWidget(String fotoPerfil, Widget fallback) {
  if (fotoPerfil.isEmpty) return fallback;
  try {
    if (kIsWeb) {
      final b64 = fotoPerfil.replaceFirst('data:base64,', '');
      return Image.memory(base64Decode(b64), fit: BoxFit.cover);
    } else {
      return Image.file(File(fotoPerfil), fit: BoxFit.cover);
    }
  } catch (_) {
    return fallback;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DATOS DE MÓDULOS
// ─────────────────────────────────────────────────────────────────────────────
class ModuloCicloVital {
  final String nombre, rango, ruta;
  final IconData icono;
  final Color colorFondo, colorIcono;
  const ModuloCicloVital({
    required this.nombre,
    required this.rango,
    required this.icono,
    required this.colorFondo,
    required this.colorIcono,
    required this.ruta,
  });
}

const List<ModuloCicloVital> kModulos = [
  ModuloCicloVital(
      nombre: 'Gestación',
      rango: 'Control prenatal\nsignos de alarma',
      icono: Icons.favorite_border_rounded,
      colorFondo: Color(0xFFFBEAF0),
      colorIcono: Color(0xFF993556),
      ruta: '/gestacion'),
  ModuloCicloVital(
      nombre: 'Primera infancia',
      rango: '0 a 5 años\ncrecimiento y desarrollo',
      icono: Icons.child_friendly_outlined,
      colorFondo: Color(0xFFFAEEDA),
      colorIcono: Color(0xFF854F0B),
      ruta: '/primera-infancia'),
  ModuloCicloVital(
      nombre: 'Infancia',
      rango: '6 a 11 años\nsalud escolar',
      icono: Icons.school_outlined,
      colorFondo: Color(0xFFE6F1FB),
      colorIcono: Color(0xFF185FA5),
      ruta: '/infancia'),
  ModuloCicloVital(
      nombre: 'Adolescencia',
      rango: '12 a 17 años\nsalud sexual y mental',
      icono: Icons.directions_run_rounded,
      colorFondo: Color(0xFFEEEDFE),
      colorIcono: Color(0xFF534AB7),
      ruta: '/adolescencia'),
  ModuloCicloVital(
      nombre: 'Juventud',
      rango: '18 a 28 años\nprevención y bienestar',
      icono: Icons.group_outlined,
      colorFondo: Color(0xFFEAF3DE),
      colorIcono: Color(0xFF3B6D11),
      ruta: '/juventud'),
  ModuloCicloVital(
      nombre: 'Adultez',
      rango: '29 a 59 años\nenfermedades crónicas',
      icono: Icons.medical_services_outlined,
      colorFondo: Color(0xFFE1F5EE),
      colorIcono: Color(0xFF0F6E56),
      ruta: '/adultez'),
  ModuloCicloVital(
      nombre: 'Vejez',
      rango: '60 años o más\ncuidado del adulto mayor',
      icono: Icons.accessible_forward_rounded,
      colorFondo: Color(0xFFF1EFE8),
      colorIcono: Color(0xFF5F5E5A),
      ruta: '/vejez'),
];

// ─────────────────────────────────────────────────────────────────────────────
// ESTADO POR MÓDULO
// ─────────────────────────────────────────────────────────────────────────────
class _ModuloEstado {
  final int alertas;
  final int pendientes;
  const _ModuloEstado({required this.alertas, required this.pendientes});

  bool get tieneAlertas    => alertas > 0;
  bool get tienePendientes => pendientes > 0 && !tieneAlertas;
  bool get sinNovedades    => !tieneAlertas && !tienePendientes;
}

// ─────────────────────────────────────────────────────────────────────────────
// PANTALLA PRINCIPAL
// ─────────────────────────────────────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  // Perfil
  String _nombre     = '';
  String _vereda     = '';
  String _municipio  = '';
  String _ultimaSync = '';
  String _fotoPerfil = '';

  // Conectividad
  bool _online = false;
  StreamSubscription<bool>? _connSub;

  // Datos
  int    _totalPacientes  = 0;
  int    _totalAlertas    = 0;
  int    _totalPendientes = 0;
  Map<String, Map<String, int>> _estadosPorModulo = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cargarPerfil();
    _cargarDatos();
    _initConectividad();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _cargarPerfil();
      _cargarDatos();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connSub?.cancel();
    super.dispose();
  }

  Future<void> _initConectividad() async {
    _online = await ConnectivityService.instance.verificarAhora();
    if (mounted) setState(() {});
    _connSub = ConnectivityService.instance.cambios.listen((v) {
      if (mounted) setState(() => _online = v);
    });
  }

  Future<void> _cargarPerfil() async {
    final prefs = await SharedPreferences.getInstance();

    final ahora = DateTime.now().toIso8601String();
    await prefs.setString('ultima_actividad_local', ahora);

    final syncTs      = prefs.getString('ultima_sincronizacion') ?? '';
    final actividadTs = prefs.getString('ultima_actividad_local') ?? ahora;
    final tsAMostrar  = syncTs.isNotEmpty ? syncTs : actividadTs;

    if (!mounted) return;
    setState(() {
      _nombre     = prefs.getString('promotor_nombre')    ?? '';
      _vereda     = prefs.getString('promotor_vereda')    ?? '';
      _municipio  = prefs.getString('promotor_municipio') ?? '';
      _fotoPerfil = prefs.getString('promotor_foto')      ?? '';
      _ultimaSync = _formatSync(tsAMostrar);
    });
  }

  Future<void> _cargarDatos() async {
    if (!mounted) return;
    final pacientes  = await DatabaseHelper.instance.totalPacientes();
    final alertas    = await DatabaseHelper.instance.totalAlertasActivas();
    final pendientes = await DatabaseHelper.instance.totalPendientesSync();
    final estados    = await DatabaseHelper.instance.estadosPorModulo();
    if (!mounted) return;
    setState(() {
      _totalPacientes   = pacientes;
      _totalAlertas     = alertas;
      _totalPendientes  = pendientes;
      _estadosPorModulo = estados;
    });
  }

  String _formatSync(String iso) {
    try {
      final dt   = DateTime.parse(iso);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1)  return 'hace un momento';
      if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
      final h  = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final m  = dt.minute.toString().padLeft(2, '0');
      final ap = dt.hour < 12 ? 'a.m.' : 'p.m.';
      return 'Hoy $h:$m $ap';
    } catch (_) {
      return 'hace un momento';
    }
  }

  String _saludo() {
    final h = DateTime.now().hour;
    if (h < 12) return '¡Buenos días';
    if (h < 18) return '¡Buenas tardes';
    return '¡Buenas noches';
  }

  _ModuloEstado _estadoDeModulo(ModuloCicloVital m) {
    final d = _estadosPorModulo[m.nombre];
    if (d == null) return const _ModuloEstado(alertas: 0, pendientes: 0);
    return _ModuloEstado(
      alertas:    d['alertas']    ?? 0,
      pendientes: d['pendientes'] ?? 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final dc    = DT(context);
    final verde = Theme.of(context).colorScheme.primary;
    // En celular esto da 3 (idéntico a como estaba siempre). Solo cambia
    // en tablet/escritorio, donde aprovecha el espacio con más columnas.
    final columnasModulos = columnasResponsivas(
      context.anchoPantalla,
      base: 3, tablet: 4, escritorio: 5,
    );

    return Scaffold(
      backgroundColor: dc.bg,
      body: ResponsiveCenter(
        child: RefreshIndicator(
        onRefresh: () async {
          await _cargarPerfil();
          await _cargarDatos();
        },
        color: verde,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [

            // ── HEADER ────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: _Header(
                nombre:     _nombre,
                vereda:     _vereda,
                municipio:  _municipio,
                ultimaSync: _ultimaSync,
                online:     _online,
                saludo:     _saludo(),
                fotoPerfil: _fotoPerfil,
              ),
            ),

            // ── STATS ─────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(children: [
                  _StatCard(
                    icono: Icons.people_alt_rounded,
                    valor: '$_totalPacientes',
                    label: 'Pacientes\nRegistrados',
                    color: verde,
                    dc: dc,
                  ),
                  const SizedBox(width: 10),
                  _StatCard(
                    icono: Icons.notifications_rounded,
                    valor: '$_totalAlertas',
                    label: 'Alertas\nActivas',
                    color: const Color(0xFFE24B4A),
                    dc: dc,
                  ),
                  const SizedBox(width: 10),
                  _StatCard(
                    icono: Icons.assignment_rounded,
                    valor: '$_totalPendientes',
                    label: 'Pendientes\nSeguimiento',
                    color: const Color(0xFFEF9F27),
                    dc: dc,
                  ),
                ]),
              ),
            ),

            // ── BOTÓN REPORTAR ALERTA ← NUEVO ─────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => Navigator.pushNamed(context, '/reportar-alerta'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0A5240), Color(0xFF1D9E75)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38, height: 38,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.20),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.notifications_active_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Reportar alerta',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Registra una situación de salud en tu comunidad',
                                  style: TextStyle(
                                    color: Color(0xFFB8F0DC),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── LABEL SECCIÓN ─────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 22, 16, 12),
                child: Row(children: [
                  Icon(Icons.people_alt_rounded, color: verde, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'CICLOS DE VIDA — RUTAS RIAS COLOMBIA',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: dc.textHint,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(),
                  Text('Ver todos ',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: verde)),
                  Icon(Icons.chevron_right_rounded, color: verde, size: 14),
                ]),
              ),
            ),

            // ── GRID DE MÓDULOS ───────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                // mainAxisExtent = alto FIJO de la tarjeta (166px, el mismo
                // que resultaba antes en celular con childAspectRatio 0.68).
                // Al fijar la altura en vez de calcularla por proporción,
                // las tarjetas se ensanchan en pantallas grandes pero NUNCA
                // se estiran de alto ni dejan espacios vacíos. En celular
                // columnasModulos = 3 siempre, así que el resultado es
                // exactamente igual a como estaba antes.
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount:   columnasModulos,
                  crossAxisSpacing: 10,
                  mainAxisSpacing:  10,
                  mainAxisExtent:   166,
                ),
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _ModuloCard(
                    modulo: kModulos[i],
                    estado: _estadoDeModulo(kModulos[i]),
                    dc:     dc,
                    onTap:  () => Navigator.pushNamed(context, kModulos[i].ruta),
                  ),
                  childCount: kModulos.length,
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 30)),
          ],
        ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HEADER
// ─────────────────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final String nombre, vereda, municipio, ultimaSync, saludo;
  final String fotoPerfil;
  final bool   online;

  const _Header({
    required this.nombre,
    required this.vereda,
    required this.municipio,
    required this.ultimaSync,
    required this.online,
    required this.saludo,
    required this.fotoPerfil,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0A5240), Color(0xFF1D9E75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // Logo + título
              Row(children: [
                Container(
                  width: 44, height: 44,
                  decoration: const BoxDecoration(
                      color: Colors.white, shape: BoxShape.circle),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: ClipOval(
                      child: Image.asset(
                          'assets/logo_dispersalud.png', fit: BoxFit.contain),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('DISPERSALUD IA',
                        style: TextStyle(
                            color: Colors.white, fontSize: 17,
                            fontWeight: FontWeight.bold, letterSpacing: 0.3)),
                    Text('Salud rural inteligente · sin internet',
                        style: TextStyle(
                            color: Color(0xFF9FE1CB), fontSize: 11)),
                  ],
                ),
              ]),

              const SizedBox(height: 14),

              // Tarjeta del promotor
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.25)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [

                    // Avatar
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withOpacity(0.5),
                            width: 1.5),
                      ),
                      child: ClipOval(
                        child: _fotoPerfilWidget(
                          fotoPerfil,
                          Center(
                            child: Text(
                              nombre.isNotEmpty
                                  ? nombre[0].toUpperCase()
                                  : 'P',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 20,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$saludo, ${nombre.isNotEmpty ? nombre : "Promotor/a"}!',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 14,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          const Text('Promotor de Salud Rural',
                              style: TextStyle(
                                  color: Color(0xFFB8F0DC), fontSize: 12)),
                          if (vereda.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Row(children: [
                              const Icon(Icons.location_on_rounded,
                                  color: Color(0xFF9FE1CB), size: 12),
                              const SizedBox(width: 2),
                              Flexible(
                                child: Text('$vereda · $municipio',
                                    style: const TextStyle(
                                        color: Color(0xFF9FE1CB),
                                        fontSize: 10)),
                              ),
                            ]),
                          ],
                          const SizedBox(height: 6),
                          Row(children: [
                            Container(
                              width: 7, height: 7,
                              decoration: BoxDecoration(
                                color: online
                                    ? const Color(0xFF5DCAA5)
                                    : Colors.orange,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                online
                                    ? 'Sincronizado · Última vez: $ultimaSync'
                                    : 'Sin conexión · Última vez: $ultimaSync',
                                style: TextStyle(
                                  color: online
                                      ? const Color(0xFF9FE1CB)
                                      : Colors.orange.shade200,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ]),
                        ],
                      ),
                    ),

                    const SizedBox(width: 10),

                    // Badge Online/Offline
                    Container(
                      width: 62,
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.3)),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            online
                                ? Icons.cloud_done_rounded
                                : Icons.cloud_off_rounded,
                            color: online
                                ? const Color(0xFF5DCAA5)
                                : Colors.orange.shade200,
                            size: 20,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            online
                                ? 'Modo\nOnline\nIA activa'
                                : 'Modo\nOffline',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: online
                                  ? const Color(0xFF9FE1CB)
                                  : Colors.orange.shade200,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              height: 1.4,
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

// ─────────────────────────────────────────────────────────────────────────────
// STAT CARD
// ─────────────────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final IconData icono;
  final String valor, label;
  final Color color;
  final DispersaludColors dc;

  const _StatCard({
    required this.icono,
    required this.valor,
    required this.label,
    required this.color,
    required this.dc,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: dc.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: dc.border),
      ),
      child: Column(children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
              color: color.withOpacity(0.12), shape: BoxShape.circle),
          child: Icon(icono, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(valor,
            style: TextStyle(
                color: color, fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: dc.textHint, fontSize: 10, height: 1.3)),
      ]),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// MÓDULO CARD
// ─────────────────────────────────────────────────────────────────────────────
class _ModuloCard extends StatelessWidget {
  final ModuloCicloVital  modulo;
  final _ModuloEstado     estado;
  final DispersaludColors dc;
  final VoidCallback      onTap;

  const _ModuloCard({
    required this.modulo,
    required this.estado,
    required this.dc,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dark = isDark(context);

    final Color  badgeColor;
    final String badgeText;

    if (estado.tieneAlertas) {
      badgeColor = const Color(0xFFE24B4A);
      badgeText  = estado.alertas == 1
          ? '1 alerta'
          : '${estado.alertas} alertas';
    } else if (estado.tienePendientes) {
      badgeColor = const Color(0xFFEF9F27);
      badgeText  = estado.pendientes == 1
          ? '1 seguimiento'
          : '${estado.pendientes} seguimientos';
    } else {
      badgeColor = const Color(0xFF1D9E75);
      badgeText  = 'Sin novedades';
    }

    final iconBg = dark
        ? modulo.colorIcono.withOpacity(0.20)
        : modulo.colorFondo;

    final borderColor = estado.tieneAlertas
        ? const Color(0xFFE24B4A).withOpacity(0.30)
        : estado.tienePendientes
            ? const Color(0xFFEF9F27).withOpacity(0.25)
            : dc.border;

    return Material(
      color: dc.card,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: 1.2),
          ),
          padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(modulo.icono, color: modulo.colorIcono, size: 22),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    modulo.nombre,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: dc.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    modulo.rango,
                    style: TextStyle(
                        fontSize: 9.5,
                        color: dc.textSecondary,
                        height: 1.3),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 5),
                      decoration: BoxDecoration(
                        color: badgeColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6, height: 6,
                            decoration: BoxDecoration(
                              color: badgeColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              badgeText,
                              style: TextStyle(
                                color: badgeColor,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right_rounded,
                      color: dc.textHint, size: 14),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}