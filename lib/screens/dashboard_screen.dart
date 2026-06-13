import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/connectivity_service.dart';
import '../services/ia_service.dart';
import '../database/database_helper.dart';
import '../core/app_theme.dart';
import 'historia_clinica_screen.dart';
import 'pacientes_screen.dart';

const Color _kVerde = Color(0xFF1D9E75);
const Color _kDark  = Color(0xFF0F6E56);

const List<Color> _kModuloColores = [
  Color(0xFF1D9E75), Color(0xFF185FA5), Color(0xFF993556),
  Color(0xFF854F0B), Color(0xFF534AB7), Color(0xFF3B6D11), Color(0xFF5F5E5A),
];

// ─────────────────────────────────────────────────────────────────────────────
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with WidgetsBindingObserver {

  // Conectividad
  bool _tieneInternet = false;
  StreamSubscription<bool>? _connSub;

  // Datos
  int    _consultasHoy       = 0;
  int    _consultasAyer      = 0;
  int    _totalPacientes     = 0;
  int    _totalConsultas     = 0;
  int    _alertasPendientes  = 0;
  String _nivelRiesgo        = 'Estable';
  List<Map<String, dynamic>> _alertasRecientes = [];
  Map<String, int>           _porModulo        = {};
  List<Map<String, dynamic>> _porDia           = [];
  Map<String, int>           _porRiesgo        = {};
  bool _cargando = true;

  // Perfil
  String _nombre    = '';
  String _vereda    = '';
  String _municipio = '';

  // Tab gráfica: 0=módulo 1=7días 2=30días 3=riesgo
  int _graficaTab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cargarPerfil();
    _cargar();
    _initConectividad();
  }

  Future<void> _initConectividad() async {
    final v = await ConnectivityService.instance.verificarAhora();
    if (mounted) setState(() => _tieneInternet = v);
    _connSub = ConnectivityService.instance.cambios.listen((v) {
      if (mounted) setState(() => _tieneInternet = v);
    });
  }

  Future<void> _cargarPerfil() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _nombre    = prefs.getString('promotor_nombre')    ?? '';
      _vereda    = prefs.getString('promotor_vereda')    ?? '';
      _municipio = prefs.getString('promotor_municipio') ?? '';
    });
  }

  Future<void> _cargar() async {
    if (!mounted) return;
    setState(() => _cargando = true);

    final hoy       = await DatabaseHelper.instance.totalConsultasHoy();
    final total     = await DatabaseHelper.instance.totalPacientes();
    final totalCon  = await DatabaseHelper.instance.totalConsultas();
    final alertas   = await DatabaseHelper.instance.totalAlertasActivas();
    final urgentes  = await DatabaseHelper.instance.consultasUrgentesRecientes();
    final porModulo = await DatabaseHelper.instance.consultasPorModulo();
    final porDia    = await DatabaseHelper.instance.consultasUltimosDias(dias: 7);
    final porRiesgo = await DatabaseHelper.instance.distribucionRiesgo();

    // Consultas de ayer desde porDia
    final ayerStr = DateTime.now()
        .subtract(const Duration(days: 1))
        .toIso8601String()
        .substring(0, 10);
    final ayer = porDia
        .firstWhere((r) => r['dia'] == ayerStr, orElse: () => {'total': 0})['total'] as int? ?? 0;

    // Nivel de riesgo general
    String nivel = 'Estable';
    if ((porRiesgo['urgente'] ?? 0) > 0) nivel = 'Alto';
    else if ((porRiesgo['alerta'] ?? 0) > 0) nivel = 'Medio';

    if (!mounted) return;
    setState(() {
      _consultasHoy      = hoy;
      _consultasAyer     = ayer;
      _totalPacientes    = total;
      _totalConsultas    = totalCon;
      _alertasPendientes = alertas;
      _nivelRiesgo       = nivel;
      _alertasRecientes  = urgentes.take(3).toList();
      _porModulo         = porModulo;
      _porDia            = porDia;
      _porRiesgo         = porRiesgo;
      _cargando          = false;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _cargarPerfil();
      _cargar();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connSub?.cancel();
    super.dispose();
  }

  String _saludo() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Buenos días';
    if (h < 18) return 'Buenas tardes';
    return 'Buenas noches';
  }

  String _tiempoRelativo(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso);
      final d  = DateTime.now().difference(dt);
      if (d.inMinutes < 1)  return 'Ahora mismo';
      if (d.inMinutes < 60) return 'Hace ${d.inMinutes} min';
      if (d.inHours < 24)   return 'Hace ${d.inHours}h';
      return 'Hace ${d.inDays}d';
    } catch (_) { return ''; }
  }

  void _abrirAsistente() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AsistenteModal(tieneInternet: _tieneInternet),
    );
  }

  // ── Selector de paciente para Historia Clínica ─────────────────────────
  void _abrirSelectorHC() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SelectorPacienteHC(onSeleccionar: (pacienteId, nombre) {
        Navigator.pop(context);
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => HistoriaClinicaScreen(
            pacienteId: pacienteId,
            nombrePaciente: nombre,
          ),
        ));
      }),
    );
  }

  // ── comparativo vs ayer ──────────────────────────────────────────────────
  String _comparativo(int hoy, int ayer) {
    if (ayer == 0 && hoy == 0) return '↔ 0% vs ayer';
    if (ayer == 0 && hoy > 0)  return '↑ Nueva actividad';
    final pct = ((hoy - ayer) / ayer * 100).round();
    if (pct > 0) return '↑ $pct% vs ayer';
    if (pct < 0) return '↓ ${pct.abs()}% vs ayer';
    return '↔ Igual que ayer';
  }

  @override
  Widget build(BuildContext context) {
    final dt = DT(context);
    return Scaffold(
      backgroundColor: dt.bg,
      floatingActionButton: FloatingActionButton(
        onPressed: _abrirAsistente,
        backgroundColor: _kVerde,
        child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 26),
      ),
      body: RefreshIndicator(
        onRefresh: _cargar,
        color: _kVerde,
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              // ── SALUDO + LOGO ──────────────────────────────────────────
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    '${_saludo()}, ${_nombre.isNotEmpty ? _nombre : "Promotor/a"}! 👋',
                    style: TextStyle(
                        color: dt.textPrimary, fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text('Promotor de Salud Rural',
                      style: TextStyle(color: dt.textSecondary, fontSize: 12)),
                  if (_vereda.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Row(children: [
                      Icon(Icons.location_on_outlined, color: dt.textHint, size: 13),
                      const SizedBox(width: 3),
                      Text('$_vereda · $_municipio',
                          style: TextStyle(color: dt.textHint, fontSize: 11)),
                    ]),
                  ],
                  const SizedBox(height: 8),
                  // Badge online/offline
                  GestureDetector(
                    onTap: () async { await ConnectivityService.instance.verificarAhora(); },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _tieneInternet
                            ? _kVerde.withOpacity(0.12)
                            : dt.card,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: _tieneInternet ? _kVerde : dt.border),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Container(
                          width: 7, height: 7,
                          decoration: BoxDecoration(
                            color: _tieneInternet ? _kVerde : Colors.orange,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _tieneInternet ? 'Online' : 'Offline',
                          style: TextStyle(
                            color: _tieneInternet ? _kVerde : dt.textSecondary,
                            fontSize: 11, fontWeight: FontWeight.w600,
                          ),
                        ),
                      ]),
                    ),
                  ),
                ])),
                const SizedBox(width: 12),
                // Refresh + Logo
                Column(children: [
                  GestureDetector(
                    onTap: _cargar,
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                          color: dt.card,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: dt.border)),
                      child: _cargando
                          ? const Padding(
                              padding: EdgeInsets.all(10),
                              child: CircularProgressIndicator(
                                  color: _kVerde, strokeWidth: 2))
                          : Icon(Icons.refresh_rounded,
                              color: dt.textSecondary, size: 20),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 52, height: 52,
                    decoration: const BoxDecoration(
                        color: Colors.white, shape: BoxShape.circle),
                    child: ClipOval(
                      child: Image.asset(
                          'assets/logo_dispersalud.png', fit: BoxFit.contain),
                    ),
                  ),
                ]),
              ]),
              const SizedBox(height: 20),

              // ── TARJETA IA GRANDE ──────────────────────────────────────
              GestureDetector(
                onTap: _abrirAsistente,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF085041), Color(0xFF0F6E56), Color(0xFF1D9E75)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    // Icono robot
                    Container(
                      width: 64, height: 64,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Stack(alignment: Alignment.center, children: [
                        const Icon(Icons.smart_toy_rounded,
                            color: Colors.white, size: 36),
                        Positioned(
                          top: 6, right: 6,
                          child: Icon(Icons.auto_awesome,
                              color: Colors.white.withOpacity(0.7), size: 12)),
                      ]),
                    ),
                    const SizedBox(width: 14),
                    // Texto
                    Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      const Text('DISPERSALUD IA',
                          style: TextStyle(
                              color: Colors.white, fontSize: 16,
                              fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                      const Text('Tu asistente clínico inteligente',
                          style: TextStyle(
                              color: Color(0xFF9FE1CB), fontSize: 12,
                              fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      const Text(
                          'Obtén respuestas clínicas basadas en evidencia y protocolos actualizados.',
                          style: TextStyle(
                              color: Colors.white70, fontSize: 12, height: 1.4)),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 9),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white38),
                        ),
                        child: const Row(mainAxisSize: MainAxisSize.min, children: [
                          Text('Consultar IA',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 13,
                                  fontWeight: FontWeight.w700)),
                          SizedBox(width: 6),
                          Icon(Icons.arrow_forward_rounded,
                              color: Colors.white, size: 16),
                        ]),
                      ),
                    ])),
                    const SizedBox(width: 10),
                    // Mini stats derechos
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      _MiniStatCard(
                        icono: Icons.access_time_rounded,
                        titulo: 'Última actividad',
                        valor: _consultasHoy > 0 ? 'Hoy' : 'Sin actividad',
                      ),
                      const SizedBox(height: 8),
                      _MiniStatCard(
                        icono: Icons.people_rounded,
                        titulo: 'Pacientes activos',
                        valor: '$_totalPacientes',
                      ),
                      const SizedBox(height: 8),
                      _MiniStatCard(
                        icono: Icons.warning_amber_rounded,
                        titulo: 'Alertas pendientes',
                        valor: '$_alertasPendientes',
                        esAlerta: _alertasPendientes > 0,
                      ),
                    ]),
                  ]),
                ),
              ),
              const SizedBox(height: 16),

              // ── 4 ESTADÍSTICAS ─────────────────────────────────────────
              Row(children: [
                Expanded(child: _StatCard4(
                  icono: Icons.today_rounded,
                  valor: '$_consultasHoy',
                  label: 'Consultas\nhoy',
                  comparativo: _comparativo(_consultasHoy, _consultasAyer),
                  subColor: _consultasHoy >= _consultasAyer ? _kVerde : Colors.red,
                  dt: dt,
                )),
                const SizedBox(width: 8),
                Expanded(child: _StatCard4(
                  icono: Icons.people_rounded,
                  valor: '$_totalPacientes',
                  label: 'Pacientes\nregistrados',
                  comparativo: _totalPacientes > 0 ? '↑ 100% vs ayer' : '↔ Sin cambios',
                  subColor: _kVerde,
                  colorIcono: const Color(0xFF185FA5),
                  dt: dt,
                )),
                const SizedBox(width: 8),
                Expanded(child: _StatCard4(
                  icono: Icons.assignment_rounded,
                  valor: '$_totalConsultas',
                  label: 'Consultas\ntotales',
                  comparativo: _totalConsultas > 0 ? '↑ 100% vs ayer' : '↔ Sin cambios',
                  subColor: _kVerde,
                  colorIcono: Colors.purple,
                  dt: dt,
                )),
                const SizedBox(width: 8),
                Expanded(child: _StatCard4(
                  icono: Icons.shield_outlined,
                  valor: _nivelRiesgo,
                  label: 'Nivel de riesgo\ngeneral',
                  comparativo: _nivelRiesgo,
                  subColor: _nivelRiesgo == 'Alto'
                      ? Colors.red
                      : (_nivelRiesgo == 'Medio' ? Colors.orange : _kVerde),
                  colorIcono: _nivelRiesgo == 'Alto'
                      ? Colors.red
                      : (_nivelRiesgo == 'Medio' ? Colors.orange : const Color(0xFF854F0B)),
                  valorSmall: true,
                  dt: dt,
                )),
              ]),
              const SizedBox(height: 20),

              // ── ACCIONES RÁPIDAS ───────────────────────────────────────
              Text('Acciones rápidas',
                  style: TextStyle(
                      color: dt.textPrimary, fontSize: 15,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(children: [
                _AccionBtn(
                    icono: Icons.person_add_outlined,
                    label: 'Nuevo\npaciente',
                    color: _kVerde, dt: dt,
                    onTap: () => Navigator.pushNamed(context, '/nuevo-paciente')),
                const SizedBox(width: 8),
                _AccionBtn(
                    icono: Icons.assignment_turned_in_outlined,
                    label: 'Segui-\nmiento',
                    color: const Color(0xFF1D9E75), dt: dt,
                    onTap: () => Navigator.pushNamed(context, '/seguimiento')),
                const SizedBox(width: 8),
                _AccionBtn(
                    icono: Icons.add_alert_outlined,
                    label: 'Reportar\nalerta',
                    color: const Color(0xFFE24B4A), dt: dt,
                    onTap: () => Navigator.pushNamed(context, '/reportar-alerta')),
                const SizedBox(width: 8),
                _AccionBtn(
                    icono: Icons.medication_outlined,
                    label: 'Medica-\nmentos',
                    color: const Color(0xFF854F0B), dt: dt,
                    onTap: () => Navigator.pushNamed(context, '/medicamentos')),
                const SizedBox(width: 8),
                _AccionBtn(
                    icono: Icons.assignment_rounded,
                    label: 'Historia\nclínica',
                    color: const Color(0xFF534AB7), dt: dt,
                    onTap: () => _abrirSelectorHC()),
              ]),
              const SizedBox(height: 8),
              // ── SALUD INTEGRAL (Partera + Saberes Ancestrales) ─────────
              const SizedBox(height: 8),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => Navigator.pushNamed(context, '/salud-integral'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2D0A1A), Color(0xFF0D2A15)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: const Color(0xFF993556).withOpacity(0.5)),
                    ),
                    child: Row(children: [
                      // Íconos dobles partera + planta
                      SizedBox(width: 48, height: 40,
                        child: Stack(children: [
                          Positioned(left: 0, child: Container(
                            width: 34, height: 34,
                            decoration: BoxDecoration(
                              color: const Color(0xFF993556).withOpacity(0.2),
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: const Color(0xFF993556).withOpacity(0.5)),
                            ),
                            child: const Icon(Icons.favorite_rounded,
                                color: Color(0xFFF48FB1), size: 18),
                          )),
                          Positioned(left: 18, top: 6, child: Container(
                            width: 28, height: 28,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A7A42).withOpacity(0.3),
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: const Color(0xFF2ECC71).withOpacity(0.5)),
                            ),
                            child: const Icon(Icons.eco_rounded,
                                color: Color(0xFF2ECC71), size: 14),
                          )),
                        ]),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Salud Integral',
                              style: TextStyle(color: Colors.white,
                                  fontWeight: FontWeight.bold, fontSize: 13)),
                          SizedBox(height: 2),
                          Text('Partera · Saberes Ancestrales · IA',
                              style: TextStyle(
                                  color: Color(0xFFB2DFDB), fontSize: 10)),
                        ],
                      )),
                      const Icon(Icons.chevron_right_rounded,
                          color: Colors.white54, size: 20),
                    ]),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── ALERTAS RECIENTES ──────────────────────────────────────
              Row(children: [
                Text('Alertas recientes',
                    style: TextStyle(
                        color: dt.textPrimary, fontSize: 15,
                        fontWeight: FontWeight.bold)),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/alertas'),
                  child: const Text('Ver todas',
                      style: TextStyle(
                          color: _kVerde, fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ),
              ]),
              const SizedBox(height: 10),

              if (_cargando)
                const Center(child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(color: _kVerde)))
              else if (_alertasRecientes.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                      color: dt.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: dt.border)),
                  child: Center(child: Text('Sin alertas activas',
                      style: TextStyle(color: dt.textHint, fontSize: 13))),
                )
              else
                Container(
                  decoration: BoxDecoration(
                      color: dt.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: dt.border)),
                  child: Column(
                    children: _alertasRecientes.asMap().entries.map((e) {
                      final c     = e.value;
                      final last  = e.key == _alertasRecientes.length - 1;
                      final nivel = (c['nivel_riesgo'] as String? ?? '').toLowerCase();
                      final color = nivel == 'urgente'
                          ? const Color(0xFFE24B4A)
                          : const Color(0xFFEF9F27);
                      final label = nivel == 'urgente' ? 'Alta' : 'Media';
                      final nombre = c['nombre'] as String? ?? 'Paciente';
                      return Column(children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          child: Row(children: [
                            Container(
                              width: 36, height: 36,
                              decoration: BoxDecoration(
                                  color: color.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10)),
                              child: Icon(
                                nivel == 'urgente'
                                    ? Icons.pregnant_woman_rounded
                                    : Icons.vaccines_rounded,
                                color: color, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text(
                                (c['diagnostico'] as String?)?.isNotEmpty == true
                                    ? c['diagnostico'] as String
                                    : c['modulo'] as String? ?? '',
                                style: TextStyle(
                                    color: dt.textPrimary, fontSize: 13,
                                    fontWeight: FontWeight.w600)),
                              Text('$nombre · ${c['modulo'] ?? ''}',
                                  style: TextStyle(
                                      color: dt.textSecondary, fontSize: 11)),
                            ])),
                            Column(crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                    color: color,
                                    borderRadius: BorderRadius.circular(20)),
                                child: Text(label,
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 10,
                                        fontWeight: FontWeight.w700)),
                              ),
                              const SizedBox(height: 4),
                              Text(_tiempoRelativo(c['fecha'] as String?),
                                  style: TextStyle(
                                      color: dt.textHint, fontSize: 10)),
                            ]),
                            const SizedBox(width: 6),
                            Icon(Icons.chevron_right_rounded,
                                color: dt.textHint, size: 18),
                          ]),
                        ),
                        if (!last) Divider(height: 1, color: dt.border),
                      ]);
                    }).toList(),
                  ),
                ),
              const SizedBox(height: 20),

              // ── ESTADÍSTICAS / GRÁFICAS ────────────────────────────────
              Text('Estadísticas',
                  style: TextStyle(
                      color: dt.textPrimary, fontSize: 15,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              // Tabs
              Container(
                decoration: BoxDecoration(
                    color: dt.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: dt.border)),
                child: Row(children: [
                  _GrafTab(label: 'Por módulo', activo: _graficaTab == 0,
                      onTap: () => setState(() => _graficaTab = 0), dt: dt),
                  _GrafTab(label: '7 días',     activo: _graficaTab == 1,
                      onTap: () => setState(() => _graficaTab = 1), dt: dt),
                  _GrafTab(label: '30 días',    activo: _graficaTab == 2,
                      onTap: () => setState(() => _graficaTab = 2), dt: dt),
                  _GrafTab(label: 'Riesgo',     activo: _graficaTab == 3,
                      onTap: () => setState(() => _graficaTab = 3), dt: dt),
                ]),
              ),
              const SizedBox(height: 12),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
                decoration: BoxDecoration(
                    color: dt.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: dt.border)),
                child: _totalConsultas == 0
                    ? _sinDatos(dt)
                    : AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: KeyedSubtree(
                          key: ValueKey(_graficaTab),
                          child: [
                            _buildBarrasModulo(dt),
                            _buildLineaDias(dt),
                            _buildLineaDias(dt),
                            _buildDonaRiesgo(dt),
                          ][_graficaTab],
                        ),
                      ),
              ),
              const SizedBox(height: 80),
            ]),
          ),
        ),
      ),
    );
  }

  // ── Sin datos ────────────────────────────────────────────────────────────
  Widget _sinDatos(DispersaludColors dt) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 32),
    child: Center(child: Text(
      'Sin datos aún.\nRegistra consultas para ver estadísticas.',
      textAlign: TextAlign.center,
      style: TextStyle(color: dt.textHint, fontSize: 13))),
  );

  // ── Gráfica barras ───────────────────────────────────────────────────────
  Widget _buildBarrasModulo(DispersaludColors dt) {
    if (_porModulo.isEmpty) return _sinDatos(dt);
    final modulos = _porModulo.keys.toList();
    final maxVal  = _porModulo.values.fold(0, (a, b) => a > b ? a : b).toDouble();
    const abrev   = {
      'Gestación': 'Gestación', 'Primera infancia': 'Primera\ninfancia',
      'Infancia': 'Infancia',   'Adolescencia': 'Adolescencia',
      'Juventud': 'Juventud',   'Adultez': 'Adultez', 'Vejez': 'Vejez',
    };
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Consultas por módulo',
          style: TextStyle(color: dt.textSecondary, fontSize: 12)),
      const SizedBox(height: 16),
      SizedBox(height: 180, child: BarChart(BarChartData(
        maxY: (maxVal * 1.3).ceilToDouble(),
        gridData: FlGridData(
          show: true, drawVerticalLine: false,
          horizontalInterval: maxVal <= 3 ? 1 : (maxVal / 3).ceilToDouble(),
          getDrawingHorizontalLine: (_) =>
              FlLine(color: dt.border, strokeWidth: 1)),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true, reservedSize: 28,
            interval: maxVal <= 3 ? 1 : (maxVal / 3).ceilToDouble(),
            getTitlesWidget: (v, _) => Text(v.toInt().toString(),
                style: TextStyle(color: dt.textHint, fontSize: 10)),
          )),
          bottomTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true, reservedSize: 36,
            getTitlesWidget: (v, _) {
              final i = v.toInt();
              if (i < 0 || i >= modulos.length) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  abrev[modulos[i]] ?? modulos[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(color: dt.textSecondary, fontSize: 8)));
            },
          )),
          topTitles:   AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        barGroups: modulos.asMap().entries.map((e) {
          final color = _kModuloColores[e.key % _kModuloColores.length];
          return BarChartGroupData(x: e.key, barRods: [BarChartRodData(
            toY: (_porModulo[e.value] ?? 0).toDouble(),
            color: color, width: 16,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            backDrawRodData: BackgroundBarChartRodData(
              show: true, toY: maxVal * 1.3,
              color: dt.textHint.withOpacity(0.04)),
          )]);
        }).toList(),
        barTouchData: BarTouchData(touchTooltipData: BarTouchTooltipData(
          getTooltipItem: (g, _, rod, __) => BarTooltipItem(
            '${modulos[g.x]}\n${rod.toY.toInt()} consultas',
            TextStyle(color: dt.textPrimary, fontSize: 12,
                fontWeight: FontWeight.w600)),
        )),
      ))),
      const SizedBox(height: 4),
    ]);
  }

  // ── Gráfica línea 7 días ─────────────────────────────────────────────────
  Widget _buildLineaDias(DispersaludColors dt) {
    if (_porDia.isEmpty) return _sinDatos(dt);
    final hoy      = DateTime.now();
    final diasList = List.generate(7, (i) =>
        DateTime(hoy.year, hoy.month, hoy.day - (6 - i)));
    final diasStr  = diasList
        .map((d) => d.toIso8601String().substring(0, 10)).toList();
    final mapa     = {
      for (final r in _porDia) r['dia'] as String: (r['total'] as int?) ?? 0
    };
    final puntos   = diasStr.map((d) => (mapa[d] ?? 0).toDouble()).toList();
    final maxY     = puntos.fold(0.0, (a, b) => a > b ? a : b);
    final escala   = maxY < 3 ? 3.0 : (maxY * 1.3);
    const eti      = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
    final etiquetas = diasStr
        .map((d) => eti[DateTime.parse(d).weekday % 7]).toList();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Consultas últimos 7 días',
          style: TextStyle(color: dt.textSecondary, fontSize: 12)),
      const SizedBox(height: 16),
      SizedBox(height: 180, child: LineChart(LineChartData(
        minX: 0, maxX: 6, minY: 0, maxY: escala,
        gridData: FlGridData(
          show: true, drawVerticalLine: false,
          horizontalInterval: escala / 3,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: dt.border, strokeWidth: 1)),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true, reservedSize: 28, interval: escala / 3,
            getTitlesWidget: (v, _) => Text(v.toInt().toString(),
                style: TextStyle(color: dt.textHint, fontSize: 10)),
          )),
          bottomTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true, reservedSize: 28,
            getTitlesWidget: (v, _) {
              final i = v.toInt();
              if (i < 0 || i > 6) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                    i < etiquetas.length ? etiquetas[i] : '',
                    style: TextStyle(
                        color: dt.textSecondary, fontSize: 10)));
            },
          )),
          topTitles:   AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        lineBarsData: [LineChartBarData(
          spots: List.generate(7, (i) => FlSpot(i.toDouble(), puntos[i])),
          isCurved: true, curveSmoothness: 0.35,
          color: _kVerde, barWidth: 2.5,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
              radius: spot.y > 0 ? 4 : 2,
              color: spot.y > 0 ? _kVerde : dt.textHint.withOpacity(0.15),
              strokeColor: Colors.transparent)),
          belowBarData: BarAreaData(show: true, gradient: LinearGradient(
            colors: [_kVerde.withOpacity(0.25), _kVerde.withOpacity(0.0)],
            begin: Alignment.topCenter, end: Alignment.bottomCenter)),
        )],
      ))),
      const SizedBox(height: 4),
    ]);
  }

  // ── Gráfica dona riesgo ──────────────────────────────────────────────────
  Widget _buildDonaRiesgo(DispersaludColors dt) {
    if (_porRiesgo.isEmpty) return _sinDatos(dt);
    const colores = {
      'estable': Color(0xFF1D9E75),
      'alerta':  Color(0xFFEF9F27),
      'urgente': Color(0xFFE24B4A),
    };
    const nombres = {
      'estable': 'Estable', 'alerta': 'Alerta', 'urgente': 'Urgente'
    };
    final niveles   = ['estable', 'alerta', 'urgente'];
    final secciones = niveles
        .where((n) => (_porRiesgo[n] ?? 0) > 0)
        .map((n) => PieChartSectionData(
              value: (_porRiesgo[n] ?? 0).toDouble(),
              color: colores[n]!, radius: 48, showTitle: false))
        .toList();
    if (secciones.isEmpty) return _sinDatos(dt);
    final total = _porRiesgo.values.fold(0, (a, b) => a + b);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Distribución por nivel de riesgo',
          style: TextStyle(color: dt.textSecondary, fontSize: 12)),
      const SizedBox(height: 16),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        SizedBox(width: 140, height: 140, child: PieChart(PieChartData(
          sections: secciones, centerSpaceRadius: 40, sectionsSpace: 3,
          pieTouchData: PieTouchData(enabled: false)))),
        const SizedBox(width: 24),
        Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: niveles.map((n) {
            final val = _porRiesgo[n] ?? 0;
            if (val == 0) return const SizedBox.shrink();
            final pct = total > 0 ? (val / total * 100).round() : 0;
            return Padding(padding: const EdgeInsets.only(bottom: 10),
              child: Row(children: [
                Container(width: 10, height: 10, decoration: BoxDecoration(
                    color: colores[n], borderRadius: BorderRadius.circular(3))),
                const SizedBox(width: 8),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(nombres[n]!, style: TextStyle(
                      color: dt.textPrimary, fontSize: 13,
                      fontWeight: FontWeight.w600)),
                  Text('$val ($pct%)',
                      style: TextStyle(color: dt.textSecondary, fontSize: 11)),
                ]),
              ]));
          }).toList()),
      ]),
      const SizedBox(height: 4),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MODAL ASISTENTE IA — texto + voz
// ─────────────────────────────────────────────────────────────────────────────
class _AsistenteModal extends StatefulWidget {
  final bool tieneInternet;
  const _AsistenteModal({required this.tieneInternet});
  @override
  State<_AsistenteModal> createState() => _AsistenteModalState();
}

class _AsistenteModalState extends State<_AsistenteModal> {
  final stt.SpeechToText     _stt    = stt.SpeechToText();
  final FlutterTts            _tts    = FlutterTts();
  final TextEditingController _ctrl   = TextEditingController();
  final ScrollController      _scroll = ScrollController();

  bool   _sttDisponible = false;
  bool   _escuchando    = false;
  bool   _cargando      = false;
  String _textoVoz      = '';
  String _respuesta     = '';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _sttDisponible = await _stt.initialize(
      onError:  (e) => setState(() { _escuchando = false; }),
      onStatus: (s) {
        if (s == 'done' || s == 'notListening') {
          setState(() => _escuchando = false);
        }
      },
    );
    await _tts.setLanguage('es-CO');
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1.0);
    if (mounted) setState(() {});
  }

  Future<void> _toggleVoz() async {
    if (!_sttDisponible) return;
    if (_escuchando) {
      await _stt.stop();
      setState(() => _escuchando = false);
      return;
    }
    setState(() {
      _escuchando = true;
      _textoVoz   = '';
      _respuesta  = '';
      _ctrl.clear();
    });
    await _stt.listen(
      localeId:  'es_CO',
      listenFor: const Duration(seconds: 15),
      pauseFor:  const Duration(seconds: 3),
      onResult:  (r) {
        setState(() => _textoVoz = r.recognizedWords);
        _ctrl.text = r.recognizedWords;
        if (r.finalResult && r.recognizedWords.isNotEmpty) {
          _consultar(r.recognizedWords);
        }
      },
    );
  }

  Future<void> _consultar(String texto) async {
    if (texto.trim().isEmpty) return;
    setState(() { _escuchando = false; _cargando = true; _respuesta = ''; });
    final resp = await IaService.instance.consultar(texto);
    if (!mounted) return;
    setState(() { _respuesta = resp; _cargando = false; });
    await _tts.speak(resp);
    await Future.delayed(const Duration(milliseconds: 200));
    if (_scroll.hasClients) {
      _scroll.animateTo(_scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  @override
  void dispose() {
    _stt.stop();
    _tts.stop();
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dt = DT(context);
    return Container(
      decoration: BoxDecoration(
        color: dt.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        controller: _scroll,
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

          // Handle
          Center(child: Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
                color: dt.border, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),

          // Título
          Row(children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF085041), Color(0xFF1D9E75)]),
                borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.smart_toy_rounded,
                  color: Colors.white, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Asistente DISPERSALUD IA',
                  style: TextStyle(color: dt.textPrimary, fontSize: 15,
                      fontWeight: FontWeight.w700)),
              Row(children: [
                Container(
                  width: 6, height: 6,
                  decoration: BoxDecoration(
                    color: widget.tieneInternet ? _kVerde : Colors.orange,
                    shape: BoxShape.circle)),
                const SizedBox(width: 5),
                Text(
                  widget.tieneInternet
                      ? 'Online — IA clínica mejorada'
                      : 'Offline — motor local',
                  style: TextStyle(color: dt.textSecondary, fontSize: 11)),
              ]),
            ])),
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(Icons.close_rounded, color: dt.textHint)),
          ]),
          const SizedBox(height: 16),

          // Campo de texto
          Row(children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                style: TextStyle(color: dt.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Escribe tu consulta clínica...',
                  hintStyle: TextStyle(color: dt.textHint),
                  filled: true, fillColor: dt.bg,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: dt.border)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: dt.border)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: _kVerde, width: 1.5)),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                ),
                onSubmitted: _consultar,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _consultar(_ctrl.text),
              child: Container(
                width: 46, height: 46,
                decoration: BoxDecoration(
                    color: _kVerde, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.send_rounded,
                    color: Colors.white, size: 20)),
            ),
          ]),
          const SizedBox(height: 10),

          // Botón micrófono
          GestureDetector(
            onTap: _toggleVoz,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity, height: 52,
              decoration: BoxDecoration(
                color: _escuchando ? _kVerde : dt.bg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: _escuchando ? _kVerde : dt.border),
                boxShadow: _escuchando
                    ? [BoxShadow(color: _kVerde.withOpacity(0.35),
                        blurRadius: 10, spreadRadius: 1)]
                    : [],
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                Icon(
                  _escuchando ? Icons.mic_rounded : Icons.mic_outlined,
                  color: _escuchando ? Colors.white : dt.textPrimary,
                  size: 22),
                const SizedBox(width: 8),
                Text(
                  _escuchando
                      ? 'Escuchando... toca para detener'
                      : 'Hablar con la IA',
                  style: TextStyle(
                    color: _escuchando ? Colors.white : dt.textPrimary,
                    fontSize: 14, fontWeight: FontWeight.w600)),
              ]),
            ),
          ),

          // Texto reconocido por voz
          if (_textoVoz.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('"$_textoVoz"',
                style: TextStyle(color: dt.textHint, fontSize: 12,
                    fontStyle: FontStyle.italic)),
          ],

          // Cargando
          if (_cargando) ...[
            const SizedBox(height: 20),
            const Center(child: CircularProgressIndicator(
                color: _kVerde, strokeWidth: 2)),
            const SizedBox(height: 8),
            Center(child: Text('Consultando DISPERSALUD IA...',
                style: TextStyle(color: dt.textSecondary, fontSize: 12))),
          ],

          // Respuesta
          if (_respuesta.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity, padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _kVerde.withOpacity(0.10),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _kVerde.withOpacity(0.35)),
              ),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Icon(Icons.psychology_outlined,
                      color: _kVerde, size: 16),
                  const SizedBox(width: 6),
                  const Text('Respuesta DISPERSALUD IA',
                      style: TextStyle(color: _kVerde, fontSize: 12,
                          fontWeight: FontWeight.w600)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () async { await _tts.speak(_respuesta); },
                    child: const Icon(Icons.volume_up_rounded,
                        color: _kVerde, size: 18)),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => setState(() {
                      _respuesta = '';
                      _textoVoz  = '';
                      _ctrl.clear();
                    }),
                    child: Icon(Icons.refresh_rounded,
                        color: dt.textHint, size: 18)),
                ]),
                const SizedBox(height: 10),
                Text(_respuesta,
                    style: TextStyle(color: dt.textPrimary,
                        fontSize: 13, height: 1.5)),
              ]),
            ),
          ],
          const SizedBox(height: 8),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WIDGETS AUXILIARES
// ─────────────────────────────────────────────────────────────────────────────
class _MiniStatCard extends StatelessWidget {
  final IconData icono;
  final String titulo, valor;
  final bool esAlerta;
  const _MiniStatCard({
    required this.icono, required this.titulo, required this.valor,
    this.esAlerta = false,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.12),
      borderRadius: BorderRadius.circular(10)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icono, color: const Color(0xFF9FE1CB), size: 12),
        const SizedBox(width: 4),
        Text(titulo,
            style: const TextStyle(color: Colors.white60, fontSize: 9)),
      ]),
      const SizedBox(height: 3),
      Text(valor, style: TextStyle(
          color: esAlerta ? const Color(0xFFEF9F27) : Colors.white,
          fontSize: 13, fontWeight: FontWeight.w700)),
    ]),
  );
}

class _StatCard4 extends StatelessWidget {
  final IconData icono;
  final String valor, label, comparativo;
  final Color subColor;
  final DispersaludColors dt;
  final Color colorIcono;
  final bool valorSmall;
  const _StatCard4({
    required this.icono, required this.valor, required this.label,
    required this.comparativo, required this.subColor, required this.dt,
    this.colorIcono = const Color(0xFF1D9E75), this.valorSmall = false,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
    decoration: BoxDecoration(
        color: dt.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: dt.border)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icono, color: colorIcono, size: 18),
      const SizedBox(height: 6),
      Text(valor, style: TextStyle(
          color: dt.textPrimary,
          fontSize: valorSmall ? 14 : 20,
          fontWeight: FontWeight.bold)),
      const SizedBox(height: 3),
      Text(label, style: TextStyle(
          color: dt.textSecondary, fontSize: 9, height: 1.3)),
      const SizedBox(height: 4),
      Text(comparativo, style: TextStyle(
          color: subColor, fontSize: 9, fontWeight: FontWeight.w600)),
    ]),
  );
}

class _AccionBtn extends StatelessWidget {
  final IconData icono;
  final String label;
  final Color color;
  final DispersaludColors dt;
  final VoidCallback onTap;
  const _AccionBtn({
    required this.icono, required this.label, required this.color,
    required this.dt, required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
            color: dt.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: dt.border)),
        child: Column(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icono, color: color, size: 18)),
          const SizedBox(height: 6),
          Text(label, textAlign: TextAlign.center,
              style: TextStyle(
                  color: dt.textSecondary, fontSize: 9, height: 1.3)),
        ]),
      ),
    ),
  );
}

class _GrafTab extends StatelessWidget {
  final String label;
  final bool activo;
  final VoidCallback onTap;
  final DispersaludColors dt;
  const _GrafTab({
    required this.label, required this.activo,
    required this.onTap, required this.dt,
  });
  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: activo ? _kVerde.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(10)),
        child: Text(label, textAlign: TextAlign.center,
            style: TextStyle(
              color: activo ? _kVerde : dt.textHint,
              fontSize: 10,
              fontWeight: activo ? FontWeight.w700 : FontWeight.normal)),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// SELECTOR DE PACIENTE PARA HISTORIA CLÍNICA (bottom sheet dentro del dashboard)
// ─────────────────────────────────────────────────────────────────────────────
class _SelectorPacienteHC extends StatefulWidget {
  final void Function(int pacienteId, String nombre) onSeleccionar;
  const _SelectorPacienteHC({required this.onSeleccionar});
  @override
  State<_SelectorPacienteHC> createState() => _SelectorPacienteHCState();
}

class _SelectorPacienteHCState extends State<_SelectorPacienteHC> {
  final _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _todos     = [];
  List<Map<String, dynamic>> _filtrados = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    final lista = await DatabaseHelper.instance.obtenerPacientes();
    setState(() {
      _todos     = lista;
      _filtrados = lista;
      _cargando  = false;
    });
  }

  void _filtrar(String q) {
    final q2 = q.trim().toLowerCase();
    setState(() {
      _filtrados = q2.isEmpty
          ? _todos
          : _todos.where((p) {
              final nombre = (p['nombre'] ?? '').toLowerCase();
              final vereda = (p['vereda'] ?? '').toLowerCase();
              final mun    = (p['municipio'] ?? '').toLowerCase();
              return nombre.contains(q2) ||
                  vereda.contains(q2) ||
                  mun.contains(q2);
            }).toList();
    });
  }

  Color _colorModulo(String m) {
    switch (m) {
      case 'Gestación':        return const Color(0xFF993556);
      case 'Primera infancia': return const Color(0xFF854F0B);
      case 'Infancia':         return const Color(0xFF185FA5);
      case 'Adolescencia':     return const Color(0xFF534AB7);
      case 'Juventud':         return const Color(0xFF3B6D11);
      case 'Adultez':          return const Color(0xFF0F6E56);
      case 'Vejez':            return const Color(0xFF5F5E5A);
      default:                 return _kVerde;
    }
  }

  String _iniciales(String nombre) {
    final p = nombre.trim().split(' ');
    if (p.length >= 2) return '${p[0][0]}${p[1][0]}'.toUpperCase();
    return nombre.isNotEmpty ? nombre[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    final dt = DT(context);
    return Container(
      height: MediaQuery.of(context).size.height * 0.80,
      decoration: BoxDecoration(
        color: dt.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(children: [

        // ── Handle ───────────────────────────────────────────────────────
        const SizedBox(height: 12),
        Center(
          child: Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // ── Título ───────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0A5240), Color(0xFF1D9E75)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.assignment_rounded,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Historia Clínica',
                      style: TextStyle(
                          color: dt.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  Text('Selecciona el paciente',
                      style: TextStyle(
                          color: dt.textHint, fontSize: 12)),
                ],
              ),
            ),
            // Badge total
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _kVerde.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _kVerde.withOpacity(0.3)),
              ),
              child: Text('${_todos.length} pacientes',
                  style: const TextStyle(
                      color: _kVerde,
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ),
          ]),
        ),

        const SizedBox(height: 14),

        // ── Buscador ─────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: TextField(
            controller: _searchCtrl,
            onChanged: _filtrar,
            style: TextStyle(color: dt.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Buscar por nombre, vereda o municipio...',
              hintStyle: TextStyle(color: dt.textHint, fontSize: 13),
              prefixIcon: Icon(Icons.search_rounded,
                  color: dt.textHint, size: 20),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? GestureDetector(
                      onTap: () {
                        _searchCtrl.clear();
                        _filtrar('');
                      },
                      child: Icon(Icons.close_rounded,
                          color: dt.textHint, size: 18))
                  : null,
              filled: true,
              fillColor: dt.bg,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
            ),
          ),
        ),

        const SizedBox(height: 12),
        Divider(height: 1, color: dt.border),

        // ── Lista de pacientes ────────────────────────────────────────────
        Expanded(
          child: _cargando
              ? const Center(
                  child: CircularProgressIndicator(color: _kVerde))
              : _todos.isEmpty
                  ? _sinPacientes(dt)
                  : _filtrados.isEmpty
                      ? _sinResultados(dt)
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                          itemCount: _filtrados.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (_, i) =>
                              _tarjeta(_filtrados[i], dt),
                        ),
        ),
      ]),
    );
  }

  Widget _tarjeta(Map<String, dynamic> p, DispersaludColors dt) {
    final color = _colorModulo(p['modulo'] ?? '');
    return GestureDetector(
      onTap: () => widget.onSeleccionar(p['id'] as int, p['nombre'] as String),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: dt.bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: dt.border),
        ),
        child: Row(children: [

          // Avatar
          CircleAvatar(
            radius: 22,
            backgroundColor: color.withOpacity(0.18),
            child: Text(
              _iniciales(p['nombre'] ?? ''),
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14),
            ),
          ),

          const SizedBox(width: 12),

          // Datos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p['nombre'] ?? '',
                    style: TextStyle(
                        color: dt.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text(
                  '${p['vereda'] ?? ''}  ·  ${p['municipio'] ?? ''}',
                  style: TextStyle(
                      color: dt.textHint, fontSize: 12),
                ),
              ],
            ),
          ),

          // Badge módulo
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(p['modulo'] ?? '',
                  style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 6),
            // Indicador "Ver H.C."
            Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.assignment_rounded,
                  color: Color(0xFF534AB7), size: 13),
              const SizedBox(width: 4),
              const Text('Ver H.C.',
                  style: TextStyle(
                      color: Color(0xFF534AB7),
                      fontSize: 10,
                      fontWeight: FontWeight.w700)),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded,
                  color: dt.textHint, size: 16),
            ]),
          ]),
        ]),
      ),
    );
  }

  Widget _sinPacientes(DispersaludColors dt) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.people_outline,
            color: dt.textHint, size: 52),
        const SizedBox(height: 12),
        Text('No hay pacientes registrados',
            style: TextStyle(
                color: dt.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text(
          'Registra un paciente primero\npara crear su historia clínica.',
          textAlign: TextAlign.center,
          style: TextStyle(
              color: dt.textHint, fontSize: 13, height: 1.5),
        ),
      ]),
    ),
  );

  Widget _sinResultados(DispersaludColors dt) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.search_off_rounded, color: dt.textHint, size: 44),
      const SizedBox(height: 10),
      Text('Sin resultados para "${_searchCtrl.text}"',
          style: TextStyle(color: dt.textSecondary, fontSize: 13)),
      const SizedBox(height: 6),
      TextButton(
        onPressed: () { _searchCtrl.clear(); _filtrar(''); },
        child: const Text('Limpiar búsqueda',
            style: TextStyle(color: _kVerde)),
      ),
    ]),
  );
}