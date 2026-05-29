import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/connectivity_service.dart';
import '../services/ia_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';

const Color _kBg     = Color(0xFF111111);
const Color _kCard   = Color(0xFF1E1E1E);
const Color _kVerde  = Color(0xFF1D9E75);
const Color _kBorder = Color(0xFF2A2A2A);

// Colores para cada módulo (orden consistente)
const List<Color> _kModuloColores = [
  Color(0xFF1D9E75),
  Color(0xFF185FA5),
  Color(0xFF993556),
  Color(0xFF854F0B),
  Color(0xFF534AB7),
  Color(0xFF3B6D11),
  Color(0xFF5F5E5A),
];

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with WidgetsBindingObserver {

  // ── Voz ─────────────────────────────────────────────────────────────────
  final stt.SpeechToText _stt = stt.SpeechToText();
  final FlutterTts        _tts = FlutterTts();
  bool   _sttDisponible  = false;
  bool   _escuchando     = false;
  bool   _tieneInternet  = false;
  StreamSubscription<bool>? _connSub;
  String _textoVoz       = '';
  String _respuestaIA    = '';

  // ── Datos SQLite ─────────────────────────────────────────────────────────
  int    _consultasHoy   = 0;
  int    _totalPacientes = 0;
  int    _totalConsultas = 0;
  List<Map<String, dynamic>> _recientes = [];

  // ── Datos para gráficas ──────────────────────────────────────────────────
  Map<String, int>              _porModulo   = {};
  List<Map<String, dynamic>>    _porDia      = [];
  Map<String, int>              _porRiesgo   = {};
  bool _cargando = true;

  // ── Perfil del promotor ─────────────────────────────────────────────────
  String _nombrePromotor = '';
  String _veredaPromotor = '';
  String _municipioPromotor = '';

  // ── Gráfica activa (tab) ─────────────────────────────────────────────────
  int _graficaTab = 0; // 0=barras módulo, 1=línea días, 2=dona riesgo

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _iniciarVoz();
    _cargarPerfil();
    _cargar();
  }

  Future<void> _cargarPerfil() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nombrePromotor   = prefs.getString('promotor_nombre')    ?? '';
      _veredaPromotor   = prefs.getString('promotor_vereda')    ?? '';
      _municipioPromotor= prefs.getString('promotor_municipio') ?? '';
    });
  }

  Future<void> _iniciarVoz() async {
    _sttDisponible = await _stt.initialize(
      onError: (e) => setState(() { _escuchando = false; _textoVoz = 'Error de micrófono: ${e.errorMsg}'; }),
      onStatus: (s) { if (s == 'done' || s == 'notListening') setState(() => _escuchando = false); },
    );
    await _tts.setLanguage('es-CO');
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    setState(() {});
  }

  Future<void> _toggleVoz() async {
    if (!_sttDisponible) {
      setState(() => _textoVoz = 'Micrófono no disponible en este dispositivo.');
      return;
    }
    if (_escuchando) {
      await _stt.stop();
      setState(() => _escuchando = false);
      return;
    }
    setState(() { _escuchando = true; _textoVoz = ''; _respuestaIA = ''; });
    await _stt.listen(
      localeId: 'es_CO',
      listenFor: const Duration(seconds: 15),
      pauseFor: const Duration(seconds: 3),
      onResult: (result) {
        setState(() => _textoVoz = result.recognizedWords);
        if (result.finalResult && result.recognizedWords.isNotEmpty) {
          _procesarConsulta(result.recognizedWords);
        }
      },
    );
  }

  Future<void> _procesarConsulta(String texto) async {
    setState(() => _escuchando = false);
    final respuesta = await IaService.instance.consultar(texto);
    setState(() => _respuestaIA = respuesta);
    await _tts.speak(respuesta);
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
    _stt.stop();
    _tts.stop();
    super.dispose();
  }

  Future<void> _cargar() async {
    if (!mounted) return;
    setState(() => _cargando = true);
    final hoy       = await DatabaseHelper.instance.totalConsultasHoy();
    final total     = await DatabaseHelper.instance.totalPacientes();
    final totalCon  = await DatabaseHelper.instance.totalConsultas();
    final recientes = await DatabaseHelper.instance.consultasRecientes(limit: 5);
    final porModulo = await DatabaseHelper.instance.consultasPorModulo();
    final porDia    = await DatabaseHelper.instance.consultasUltimosDias(dias: 7);
    final porRiesgo = await DatabaseHelper.instance.distribucionRiesgo();
    if (!mounted) return;
    setState(() {
      _consultasHoy   = hoy;
      _totalPacientes = total;
      _totalConsultas = totalCon;
      _recientes      = recientes;
      _porModulo      = porModulo;
      _porDia         = porDia;
      _porRiesgo      = porRiesgo;
      _cargando       = false;
    });
  }

  Color  _nivelColor(String? n) { switch (n?.toLowerCase()) { case 'urgente': return Colors.red; case 'alerta': return Colors.orange; default: return _kVerde; } }
  String _nivelLabel(String? n) { switch (n?.toLowerCase()) { case 'urgente': return 'Urgente'; case 'alerta': return 'Alerta'; default: return 'Estable'; } }
  String _tiempoRelativo(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso);
      final d  = DateTime.now().difference(dt);
      if (d.inMinutes < 1)  return 'ahora mismo';
      if (d.inMinutes < 60) return 'hace ${d.inMinutes} min';
      if (d.inHours < 24)   return 'hace ${d.inHours}h';
      return 'hace ${d.inDays}d';
    } catch (_) { return ''; }
  }
  String _saludo() { final h = DateTime.now().hour; if (h < 12) return 'Buenos días'; if (h < 18) return 'Buenas tardes'; return 'Buenas noches'; }

  // ── Nombre corto para etiquetas de barras ────────────────────────────────
  String _cortoModulo(String nombre) {
    const abrev = {
      'Gestación': 'Gest.',
      'Primera infancia': '0-5',
      'Infancia': '6-11',
      'Adolescencia': 'Adol.',
      'Juventud': 'Juv.',
      'Adultez': 'Adult.',
      'Vejez': 'Vejez',
    };
    return abrev[nombre] ?? (nombre.length > 6 ? '${nombre.substring(0, 5)}.' : nombre);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: RefreshIndicator(
        onRefresh: _cargar,
        color: _kVerde,
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              // ── Header ─────────────────────────────────────────────────
              Row(children: [
                Container(
  width: 42,
  height: 42,
  decoration: BoxDecoration(
    color: Colors.white,
    shape: BoxShape.circle,
  ),
  child: Padding(
    padding: const EdgeInsets.all(6),
    child: ClipOval(
      child: Image.asset(
        'assets/logo_dispersalud.png',
        fit: BoxFit.contain,
      ),
    ),
  ),
),
                const SizedBox(width: 10),
                const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('DISPERSALUD IA', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  Text('Salud rural · sin internet', style: TextStyle(color: Colors.white54, fontSize: 11)),
                ])),
                IconButton(
                  onPressed: _cargar,
                  icon: _cargando
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: _kVerde, strokeWidth: 2))
                      : const Icon(Icons.refresh_rounded, color: Colors.white54, size: 22)),
                GestureDetector(
                  onTap: () async {
                    await ConnectivityService.instance.verificarAhora();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _tieneInternet ? const Color(0xFF1D9E75).withOpacity(0.15) : _kCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _tieneInternet ? const Color(0xFF1D9E75) : _kBorder),
                    ),
                    child: Row(children: [
                      Container(width: 7, height: 7, decoration: BoxDecoration(
                        color: _tieneInternet ? const Color(0xFF1D9E75) : Colors.orange,
                        shape: BoxShape.circle)),
                      const SizedBox(width: 5),
                      Text(_tieneInternet ? 'Online' : 'Offline',
                          style: TextStyle(
                            color: _tieneInternet ? const Color(0xFF1D9E75) : Colors.white70,
                            fontSize: 11, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ),
              ]),
              const SizedBox(height: 16),

              // ── Tarjeta bienvenida + voz ────────────────────────────────
              Container(
                width: double.infinity, padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF0F6E56), Color(0xFF1D9E75)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(16)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    _nombrePromotor.isNotEmpty
                        ? '${_saludo()}, $_nombrePromotor 👋'
                        : '${_saludo()}, Promotor/a 👋',
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _veredaPromotor.isNotEmpty
                        ? '$_veredaPromotor · $_municipioPromotor'
                        : '$_totalConsultas consultas registradas en total',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 14),
                  Row(children: [
                    Icon(_escuchando ? Icons.mic_rounded : Icons.mic_outlined, color: Colors.white, size: 18),
                    const SizedBox(width: 6),
                    Text(_escuchando ? 'Escuchando...' : _tieneInternet ? 'IA online — respuestas clínicas mejoradas' : 'IA offline — respuestas locales',
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                  ]),
                  if (_textoVoz.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text('"$_textoVoz"', style: const TextStyle(color: Colors.white60, fontSize: 11, fontStyle: FontStyle.italic)),
                  ],
                ]),
              ),
              const SizedBox(height: 8),

              // ── Botón micrófono ──────────────────────────────────────────
              GestureDetector(
                onTap: _toggleVoz,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: double.infinity, height: 56,
                  decoration: BoxDecoration(
                    color: _escuchando ? _kVerde : _kCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _escuchando ? _kVerde : _kBorder),
                    boxShadow: _escuchando ? [BoxShadow(color: _kVerde.withOpacity(0.4), blurRadius: 12, spreadRadius: 2)] : [],
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(_escuchando ? Icons.mic_rounded : Icons.mic_outlined, color: Colors.white, size: 24),
                    const SizedBox(width: 10),
                    Text(
                      _escuchando ? 'Escuchando... toca para detener' : 'Consulta por voz con IA',
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ]),
                ),
              ),

              // ── Respuesta IA ─────────────────────────────────────────────
              if (_respuestaIA.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity, padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _kVerde.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _kVerde.withOpacity(0.4)),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      const Icon(Icons.psychology_outlined, color: _kVerde, size: 16),
                      const SizedBox(width: 6),
                      const Text('Respuesta DISPERSALUD IA', style: TextStyle(color: _kVerde, fontSize: 12, fontWeight: FontWeight.w600)),
                      const Spacer(),
                      GestureDetector(
                        onTap: () async { await _tts.speak(_respuestaIA); },
                        child: const Icon(Icons.volume_up_rounded, color: _kVerde, size: 18)),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => setState(() => _respuestaIA = ''),
                        child: const Icon(Icons.close_rounded, color: Colors.white38, size: 18)),
                    ]),
                    const SizedBox(height: 8),
                    Text(_respuestaIA, style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.5)),
                  ]),
                ),
              ],
              const SizedBox(height: 20),

              // ── Estadísticas rápidas ─────────────────────────────────────
              Row(children: [
                Expanded(child: _StatCard(valor: '$_consultasHoy', label: 'Consultas\nhoy', color: _kVerde, icono: Icons.today_rounded)),
                const SizedBox(width: 10),
                Expanded(child: _StatCard(valor: '$_totalPacientes', label: 'Pacientes\nregistrados', color: const Color(0xFF185FA5), icono: Icons.people_rounded)),
                const SizedBox(width: 10),
                Expanded(child: _StatCard(valor: '$_totalConsultas', label: 'Total\nconsultas', color: Colors.purple, icono: Icons.assignment_rounded)),
              ]),
              const SizedBox(height: 24),

              // ══════════════════════════════════════════════════════════════
              // SECCIÓN GRÁFICAS
              // ══════════════════════════════════════════════════════════════
              const Text('Estadísticas', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              // Tabs de gráfica
              Container(
                decoration: BoxDecoration(color: _kCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: _kBorder)),
                child: Row(children: [
                  _GraficaTab(label: 'Por módulo',   icono: Icons.bar_chart_rounded,  activo: _graficaTab == 0, onTap: () => setState(() => _graficaTab = 0)),
                  _GraficaTab(label: '7 días',       icono: Icons.show_chart_rounded,  activo: _graficaTab == 1, onTap: () => setState(() => _graficaTab = 1)),
                  _GraficaTab(label: 'Riesgo',       icono: Icons.donut_large_rounded, activo: _graficaTab == 2, onTap: () => setState(() => _graficaTab = 2)),
                ]),
              ),
              const SizedBox(height: 12),

              // Contenedor de la gráfica activa
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
                decoration: BoxDecoration(color: _kCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: _kBorder)),
                child: _totalConsultas == 0
                  ? _SinDatos()
                  : AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: KeyedSubtree(
                        key: ValueKey(_graficaTab),
                        child: [
                          _buildBarrasModulo(),
                          _buildLineaDias(),
                          _buildDonaRiesgo(),
                        ][_graficaTab],
                      ),
                    ),
              ),
              const SizedBox(height: 24),

              // ── Actividad reciente ───────────────────────────────────────
              Row(children: [
                const Text('Actividad reciente', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                const Spacer(),
                if (_consultasHoy > 0) Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: _kVerde.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                  child: Text('$_consultasHoy hoy', style: const TextStyle(color: _kVerde, fontSize: 12, fontWeight: FontWeight.w600))),
              ]),
              const SizedBox(height: 12),

              if (_cargando)
                const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: _kVerde)))
              else if (_recientes.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: _kCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: _kBorder)),
                  child: const Column(children: [
                    Icon(Icons.medical_information_outlined, color: Colors.white24, size: 40),
                    SizedBox(height: 12),
                    Text('Sin consultas registradas aún.', style: TextStyle(color: Colors.white54, fontSize: 14, fontWeight: FontWeight.w600)),
                    SizedBox(height: 4),
                    Text('Ve a Módulos, selecciona un paciente\ny realiza tu primera consulta.',
                        textAlign: TextAlign.center, style: TextStyle(color: Colors.white38, fontSize: 12)),
                  ]))
              else
                ..._recientes.map((c) {
                  final color  = _nivelColor(c['nivel_riesgo']);
                  final nombre = (c['nombre'] as String?) ?? '?';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(color: _kCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.25))),
                    child: Row(children: [
                      CircleAvatar(radius: 20, backgroundColor: color.withOpacity(0.18),
                          child: Text(nombre[0].toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.bold))),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(nombre, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                        Text('${c['modulo'] ?? ''} · ${_tiempoRelativo(c['fecha'])}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                        if ((c['diagnostico'] as String? ?? '').isNotEmpty)
                          Padding(padding: const EdgeInsets.only(top: 3),
                            child: Text(c['diagnostico'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: color.withOpacity(0.8), fontSize: 11))),
                      ])),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                        child: Text(_nivelLabel(c['nivel_riesgo']), style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600))),
                    ]),
                  );
                }),

              const SizedBox(height: 20),

              // ── Estado del sistema ───────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: _kCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: _kBorder)),
                child: Row(children: [
                  Container(width: 36, height: 36,
                    decoration: BoxDecoration(color: _kVerde.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.cloud_off_rounded, color: _kVerde, size: 20)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_tieneInternet ? 'Modo online activo — IA mejorada disponible' : 'Modo sin conexión — datos guardados localmente', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                    Text(_tieneInternet ? 'Voz con IA de Claude activada · Sincronización disponible' : 'Datos guardados localmente · listos para sincronizar', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                  ])),
                ]),
              ),
              const SizedBox(height: 16),
            ]),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // GRÁFICA 1 — Barras por módulo
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildBarrasModulo() {
    if (_porModulo.isEmpty) return _SinDatos();
    final modulos = _porModulo.keys.toList();
    final maxVal  = _porModulo.values.fold(0, (a, b) => a > b ? a : b).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Consultas por módulo', style: TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: BarChart(
            BarChartData(
              maxY: (maxVal * 1.3).ceilToDouble(),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxVal <= 3 ? 1 : (maxVal / 3).ceilToDouble(),
                getDrawingHorizontalLine: (_) => FlLine(color: Colors.white10, strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(sideTitles: SideTitles(
                  showTitles: true, reservedSize: 28,
                  interval: maxVal <= 3 ? 1 : (maxVal / 3).ceilToDouble(),
                  getTitlesWidget: (v, _) => Text(v.toInt().toString(),
                      style: const TextStyle(color: Colors.white38, fontSize: 10)),
                )),
                bottomTitles: AxisTitles(sideTitles: SideTitles(
                  showTitles: true, reservedSize: 28,
                  getTitlesWidget: (v, _) {
                    final i = v.toInt();
                    if (i < 0 || i >= modulos.length) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(_cortoModulo(modulos[i]),
                          style: const TextStyle(color: Colors.white54, fontSize: 9)),
                    );
                  },
                )),
                topTitles:   AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              barGroups: modulos.asMap().entries.map((e) {
                final color = _kModuloColores[e.key % _kModuloColores.length];
                return BarChartGroupData(x: e.key, barRods: [
                  BarChartRodData(
                    toY: (_porModulo[e.value] ?? 0).toDouble(),
                    color: color,
                    width: 18,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                    backDrawRodData: BackgroundBarChartRodData(
                      show: true, toY: maxVal * 1.3, color: Colors.white.withOpacity(0.04)),
                  ),
                ]);
              }).toList(),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, _, rod, __) {
                    final nombre = modulos[group.x];
                    return BarTooltipItem(
                      '$nombre\n${rod.toY.toInt()} consultas',
                      const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Leyenda
        Wrap(spacing: 10, runSpacing: 6, children: modulos.asMap().entries.map((e) {
          final color = _kModuloColores[e.key % _kModuloColores.length];
          return Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 4),
            Text(e.value, style: const TextStyle(color: Colors.white54, fontSize: 10)),
          ]);
        }).toList()),
        const SizedBox(height: 4),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // GRÁFICA 2 — Línea últimos 7 días
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildLineaDias() {
    if (_porDia.isEmpty) return _SinDatos();

    // Generar los 7 días (puede haber huecos si no hubo consultas)
    final hoy   = DateTime.now();
    final dias  = List.generate(7, (i) => DateTime(hoy.year, hoy.month, hoy.day - (6 - i)));
    final diasStr = dias.map((d) => d.toIso8601String().substring(0, 10)).toList();
    final mapa  = { for (final r in _porDia) r['dia'] as String: (r['total'] as int?) ?? 0 };
    final puntos = diasStr.map((d) => (mapa[d] ?? 0).toDouble()).toList();
    final maxY  = puntos.fold(0.0, (a, b) => a > b ? a : b);
    final escala = maxY < 3 ? 3.0 : (maxY * 1.3);

    const etiquetasDia = ['L','M','M','J','V','S','D'];
    final etiquetas = diasStr.map((d) {
      final dt = DateTime.parse(d);
      return etiquetasDia[dt.weekday % 7];
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Consultas últimos 7 días', style: TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: LineChart(
            LineChartData(
              minX: 0, maxX: 6,
              minY: 0, maxY: escala,
              gridData: FlGridData(
                show: true, drawVerticalLine: false,
                horizontalInterval: escala / 3,
                getDrawingHorizontalLine: (_) => FlLine(color: Colors.white10, strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(sideTitles: SideTitles(
                  showTitles: true, reservedSize: 28,
                  interval: escala / 3,
                  getTitlesWidget: (v, _) => Text(v.toInt().toString(),
                      style: const TextStyle(color: Colors.white38, fontSize: 10)),
                )),
                bottomTitles: AxisTitles(sideTitles: SideTitles(
                  showTitles: true, reservedSize: 28,
                  getTitlesWidget: (v, _) {
                    final i = v.toInt();
                    if (i < 0 || i > 6) return const SizedBox.shrink();
                    final es = i < etiquetas.length ? etiquetas[i] : '';
                    return Padding(padding: const EdgeInsets.only(top: 6),
                        child: Text(es, style: const TextStyle(color: Colors.white54, fontSize: 10)));
                  },
                )),
                topTitles:   AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (spots) => spots.map((s) => LineTooltipItem(
                    '${s.y.toInt()} consultas', const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                  )).toList(),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: List.generate(7, (i) => FlSpot(i.toDouble(), puntos[i])),
                  isCurved: true, curveSmoothness: 0.35,
                  color: _kVerde,
                  barWidth: 2.5,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                      radius: spot.y > 0 ? 4 : 2,
                      color: spot.y > 0 ? _kVerde : Colors.white12,
                      strokeColor: Colors.transparent,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [_kVerde.withOpacity(0.25), _kVerde.withOpacity(0.0)],
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // GRÁFICA 3 — Dona nivel de riesgo
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildDonaRiesgo() {
    if (_porRiesgo.isEmpty) return _SinDatos();

    const coloresRiesgo = {
      'estable':  Color(0xFF1D9E75),
      'alerta':   Color(0xFFEF9F27),
      'urgente':  Color(0xFFE24B4A),
    };
    const nombresRiesgo = {
      'estable': 'Estable',
      'alerta':  'Alerta',
      'urgente': 'Urgente',
    };

    final niveles = ['estable', 'alerta', 'urgente'];
    final secciones = niveles
        .where((n) => (_porRiesgo[n] ?? 0) > 0)
        .map((n) => PieChartSectionData(
              value: (_porRiesgo[n] ?? 0).toDouble(),
              color: coloresRiesgo[n]!,
              radius: 48,
              showTitle: false,
            ))
        .toList();

    if (secciones.isEmpty) return _SinDatos();

    final total = _porRiesgo.values.fold(0, (a, b) => a + b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Distribución por nivel de riesgo', style: TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 140, height: 140,
              child: PieChart(PieChartData(
                sections: secciones,
                centerSpaceRadius: 40,
                sectionsSpace: 3,
                pieTouchData: PieTouchData(enabled: false),
              )),
            ),
            const SizedBox(width: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: niveles.map((n) {
                final val = _porRiesgo[n] ?? 0;
                if (val == 0) return const SizedBox.shrink();
                final pct = total > 0 ? (val / total * 100).round() : 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(children: [
                    Container(width: 10, height: 10, decoration: BoxDecoration(
                        color: coloresRiesgo[n], borderRadius: BorderRadius.circular(3))),
                    const SizedBox(width: 8),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(nombresRiesgo[n]!, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                      Text('$val ($pct%)', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                    ]),
                  ]),
                );
              }).toList(),
            ),
          ],
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}

// ── Widgets auxiliares ───────────────────────────────────────────────────────

class _SinDatos extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 32),
    child: Center(child: Text('Sin datos suficientes aún.\nRegistra consultas para ver las estadísticas.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white38, fontSize: 13))),
  );
}

class _GraficaTab extends StatelessWidget {
  final String label;
  final IconData icono;
  final bool activo;
  final VoidCallback onTap;
  const _GraficaTab({required this.label, required this.icono, required this.activo, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: activo ? _kVerde.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(children: [
          Icon(icono, color: activo ? _kVerde : Colors.white30, size: 18),
          const SizedBox(height: 3),
          Text(label, style: TextStyle(
              color: activo ? _kVerde : Colors.white38,
              fontSize: 10, fontWeight: activo ? FontWeight.w600 : FontWeight.normal)),
        ]),
      ),
    ),
  );
}

class _StatCard extends StatelessWidget {
  final String valor, label;
  final Color color;
  final IconData icono;
  const _StatCard({required this.valor, required this.label, required this.color, required this.icono});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
    decoration: BoxDecoration(color: _kCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white10)),
    child: Column(children: [
      Icon(icono, color: color, size: 20),
      const SizedBox(height: 6),
      Text(valor, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold)),
      const SizedBox(height: 4),
      Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white54, fontSize: 10)),
    ]),
  );
}