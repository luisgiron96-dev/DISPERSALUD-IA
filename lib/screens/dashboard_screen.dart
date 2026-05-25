import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import '../database/database_helper.dart';

const Color _kBg     = Color(0xFF111111);
const Color _kCard   = Color(0xFF1E1E1E);
const Color _kVerde  = Color(0xFF1D9E75);
const Color _kBorder = Color(0xFF2A2A2A);

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with WidgetsBindingObserver {

  // ── Voz ────────────────────────────────────────────────────────────────
  final stt.SpeechToText _stt = stt.SpeechToText();
  final FlutterTts        _tts = FlutterTts();
  bool   _sttDisponible  = false;
  bool   _escuchando     = false;
  String _textoVoz       = '';
  String _respuestaIA    = '';

  // ── Datos SQLite ────────────────────────────────────────────────────────
  int    _consultasHoy   = 0;
  int    _totalPacientes = 0;
  int    _totalConsultas = 0;
  List<Map<String, dynamic>> _recientes = [];
  bool   _cargando       = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _iniciarVoz();
    _cargar();
  }

  // ── Inicializar voz ─────────────────────────────────────────────────────
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

  // ── Escuchar / detener ──────────────────────────────────────────────────
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

  // ── Lógica clínica de voz ───────────────────────────────────────────────
  Future<void> _procesarConsulta(String texto) async {
    setState(() => _escuchando = false);
    final t = texto.toLowerCase();
    String respuesta;

    if (t.contains('presión') || t.contains('tension') || t.contains('hipertension')) {
      respuesta = 'Para evaluar presión arterial, ve al módulo de Adultez o Vejez. '
          'Si la presión sistólica es mayor a 140, es hipertensión. '
          'Si supera 180, es una emergencia, remite de inmediato.';
    } else if (t.contains('gestante') || t.contains('embaraz') || t.contains('semanas')) {
      respuesta = 'Para control prenatal, ve al módulo de Gestación. '
          'Registra las semanas de gestación, presión arterial y altura uterina. '
          'Recuerda verificar toxoide tetánico y ácido fólico.';
    } else if (t.contains('niño') || t.contains('bebe') || t.contains('infan')) {
      respuesta = 'Para atención infantil usa el módulo de Primera Infancia o Infancia. '
          'Evalúa peso, talla, hemoglobina y esquema de vacunación.';
    } else if (t.contains('diabetes') || t.contains('glucemia') || t.contains('azucar')) {
      respuesta = 'Para evaluar diabetes, ingresa al módulo de Adultez. '
          'Glucemia en ayunas mayor a 126 miligramos indica posible diabetes. '
          'Mayor a 200 es una emergencia hiperglucémica.';
    } else if (t.contains('dengue') || t.contains('fiebre') || t.contains('sivigila')) {
      respuesta = 'Revisa la pestaña de Alertas para ver los eventos SIVIGILA activos en tu zona. '
          'Dengue, EDA e IRA son los principales eventos a vigilar.';
    } else if (t.contains('paciente') || t.contains('registrar') || t.contains('nuevo')) {
      respuesta = 'Para registrar un nuevo paciente, ve a la pestaña Pacientes '
          'y toca el botón Nuevo. Ingresa nombre, vereda y municipio.';
    } else if (t.contains('hola') || t.contains('buenos') || t.contains('ayuda')) {
      respuesta = 'Hola, soy DISPERSALUD IA. Puedo ayudarte con consultas de gestación, '
          'infancia, adolescencia, adultez, vejez, diabetes, presión arterial y alertas SIVIGILA. '
          '¿Qué necesitas?';
    } else {
      respuesta = 'Entendí: $texto. '
          'Puedo orientarte sobre gestación, infancia, adolescencia, adultez, vejez, '
          'diabetes, presión arterial y alertas de salud pública.';
    }

    setState(() => _respuestaIA = respuesta);
    await _tts.speak(respuesta);
  }

  // ── Datos SQLite ────────────────────────────────────────────────────────
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _cargar();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stt.stop();
    _tts.stop();
    super.dispose();
  }

  Future<void> _cargar() async {
    if (!mounted) return;
    setState(() => _cargando = true);
    final hoy      = await DatabaseHelper.instance.totalConsultasHoy();
    final total    = await DatabaseHelper.instance.totalPacientes();
    final totalCon = await DatabaseHelper.instance.totalConsultas();
    final recientes= await DatabaseHelper.instance.consultasRecientes(limit: 5);
    if (!mounted) return;
    setState(() {
      _consultasHoy   = hoy;
      _totalPacientes = total;
      _totalConsultas = totalCon;
      _recientes      = recientes;
      _cargando       = false;
    });
  }

  Color  _nivelColor(String? n) { switch (n?.toLowerCase()) { case 'urgente': return Colors.red; case 'alerta': return Colors.orange; default: return _kVerde; } }
  String _nivelLabel(String? n) { switch (n?.toLowerCase()) { case 'urgente': return 'Urgente'; case 'alerta': return 'Alerta'; default: return 'Estable'; } }
  String _tiempoRelativo(String? iso) { if (iso == null) return ''; try { final dt = DateTime.parse(iso); final d = DateTime.now().difference(dt); if (d.inMinutes < 1) return 'ahora mismo'; if (d.inMinutes < 60) return 'hace ${d.inMinutes} min'; if (d.inHours < 24) return 'hace ${d.inHours}h'; return 'hace ${d.inDays}d'; } catch (_) { return ''; } }
  String _saludo() { final h = DateTime.now().hour; if (h < 12) return 'Buenos días'; if (h < 18) return 'Buenas tardes'; return 'Buenas noches'; }

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

              // ── Header ────────────────────────────────────────────────
              Row(children: [
                Container(width: 38, height: 38,
                  decoration: BoxDecoration(color: _kVerde, borderRadius: BorderRadius.circular(10)),
                  child: const Center(child: Text('🌿', style: TextStyle(fontSize: 20)))),
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: _kCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: _kBorder)),
                  child: Row(children: [
                    Container(width: 7, height: 7, decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle)),
                    const SizedBox(width: 5),
                    const Text('Offline', style: TextStyle(color: Colors.white70, fontSize: 11)),
                  ])),
              ]),
              const SizedBox(height: 16),

              // ── Tarjeta bienvenida ────────────────────────────────────
              Container(
                width: double.infinity, padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF0F6E56), Color(0xFF1D9E75)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(16)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${_saludo()}, Promotor/a 👋', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('$_totalConsultas consultas registradas en total', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 14),
                  Row(children: [
                    Icon(_escuchando ? Icons.mic_rounded : Icons.mic_outlined, color: Colors.white, size: 18),
                    const SizedBox(width: 6),
                    Text(_escuchando ? 'Escuchando...' : 'Toca para consulta por voz',
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                  ]),
                  if (_textoVoz.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text('"$_textoVoz"', style: const TextStyle(color: Colors.white60, fontSize: 11, fontStyle: FontStyle.italic)),
                  ],
                ]),
              ),
              const SizedBox(height: 8),

              // ── Botón micrófono REAL ──────────────────────────────────
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

              // ── Respuesta de la IA ────────────────────────────────────
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
                        child: const Icon(Icons.volume_up_rounded, color: _kVerde, size: 18),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => setState(() => _respuestaIA = ''),
                        child: const Icon(Icons.close_rounded, color: Colors.white38, size: 18),
                      ),
                    ]),
                    const SizedBox(height: 8),
                    Text(_respuestaIA, style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.5)),
                  ]),
                ),
              ],
              const SizedBox(height: 20),

              // ── Estadísticas reales ───────────────────────────────────
              Row(children: [
                Expanded(child: _StatCard(valor: '$_consultasHoy', label: 'Consultas\nhoy', color: _kVerde, icono: Icons.today_rounded)),
                const SizedBox(width: 10),
                Expanded(child: _StatCard(valor: '$_totalPacientes', label: 'Pacientes\nregistrados', color: const Color(0xFF185FA5), icono: Icons.people_rounded)),
                const SizedBox(width: 10),
                Expanded(child: _StatCard(valor: '$_totalConsultas', label: 'Total\nconsultas', color: Colors.purple, icono: Icons.assignment_rounded)),
              ]),
              const SizedBox(height: 20),

              // ── Actividad reciente ────────────────────────────────────
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

              // ── Estado del sistema ────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: _kCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: _kBorder)),
                child: Row(children: [
                  Container(width: 36, height: 36,
                    decoration: BoxDecoration(color: _kVerde.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.cloud_off_rounded, color: _kVerde, size: 20)),
                  const SizedBox(width: 12),
                  const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Modo sin conexión activo', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                    Text('Datos guardados localmente · listos para sincronizar', style: TextStyle(color: Colors.white54, fontSize: 11)),
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
}

class _StatCard extends StatelessWidget {
  final String valor, label; final Color color; final IconData icono;
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