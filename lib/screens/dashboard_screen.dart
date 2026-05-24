import 'package:flutter/material.dart';
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

class _DashboardScreenState extends State<DashboardScreen> {
  bool   _escuchando      = false;
  int    _consultasHoy    = 0;
  int    _totalPacientes  = 0;
  List<Map<String, dynamic>> _recientes = [];
  bool   _cargando        = true;

  @override
  void initState() { super.initState(); _cargar(); }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    final hoy      = await DatabaseHelper.instance.totalConsultasHoy();
    final total    = await DatabaseHelper.instance.totalPacientes();
    final recientes= await DatabaseHelper.instance.consultasRecientes(limit: 5);
    setState(() {
      _consultasHoy   = hoy;
      _totalPacientes = total;
      _recientes      = recientes;
      _cargando       = false;
    });
  }

  Color _nivelColor(String? nivel) {
    switch (nivel?.toLowerCase()) {
      case 'urgente': return Colors.red;
      case 'alerta':  return Colors.orange;
      default:        return _kVerde;
    }
  }

  String _nivelLabel(String? nivel) {
    switch (nivel?.toLowerCase()) {
      case 'urgente': return 'Urgente';
      case 'alerta':  return 'Alerta';
      default:        return 'Estable';
    }
  }

  String _tiempoRelativo(String? iso) {
    if (iso == null) return '';
    try {
      final dt   = DateTime.parse(iso);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
      if (diff.inHours < 24)   return 'hace ${diff.inHours}h';
      return 'hace ${diff.inDays}d';
    } catch (_) { return ''; }
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

              // ── Header ──────────────────────────────────────────────────
              Row(children: [
                Container(width: 38, height: 38,
                  decoration: BoxDecoration(color: _kVerde, borderRadius: BorderRadius.circular(10)),
                  child: const Center(child: Text('🌿', style: TextStyle(fontSize: 20))),
                ),
                const SizedBox(width: 10),
                const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('DISPERSALUD IA', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  Text('Promotora Ana · Vereda El Limón, Cauca', style: TextStyle(color: Colors.white54, fontSize: 11)),
                ])),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: _kCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: _kBorder)),
                  child: Row(children: [
                    Container(width: 7, height: 7, decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle)),
                    const SizedBox(width: 5),
                    const Text('Offline', style: TextStyle(color: Colors.white70, fontSize: 11)),
                  ]),
                ),
              ]),
              const SizedBox(height: 16),

              // ── Tarjeta bienvenida + micrófono ───────────────────────────
              Container(
                width: double.infinity, padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF0F6E56), Color(0xFF1D9E75)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Buenos días, Promotora Ana 👋',
                      style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('Vereda El Limón · Cauca', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 14),
                  Row(children: [
                    const Icon(Icons.mic_rounded, color: Colors.white, size: 18),
                    const SizedBox(width: 6),
                    Text(_escuchando ? 'Escuchando...' : 'Toca para consulta por voz',
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                  ]),
                  const SizedBox(height: 4),
                  const Text('"Paciente gestante de 28 semanas con náuseas..."',
                      style: TextStyle(color: Colors.white60, fontSize: 11, fontStyle: FontStyle.italic)),
                ]),
              ),
              const SizedBox(height: 8),

              GestureDetector(
                onTap: () => setState(() => _escuchando = !_escuchando),
                child: Container(
                  width: double.infinity, height: 56,
                  decoration: BoxDecoration(
                    color: _escuchando ? _kVerde : _kCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _escuchando ? _kVerde : _kBorder),
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(_escuchando ? Icons.mic_rounded : Icons.mic_outlined, color: Colors.white, size: 24),
                    const SizedBox(width: 10),
                    Text(_escuchando ? 'Escuchando... toca para detener' : 'Consulta por voz con IA',
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                  ]),
                ),
              ),
              const SizedBox(height: 20),

              // ── Estadísticas reales de SQLite ────────────────────────────
              Row(children: [
                Expanded(child: _StatCard(valor: '$_consultasHoy', label: 'Consultas hoy', color: _kVerde)),
                const SizedBox(width: 10),
                Expanded(child: _StatCard(valor: '$_totalPacientes', label: 'Pacientes', color: const Color(0xFF185FA5))),
                const SizedBox(width: 10),
                Expanded(child: _StatCard(valor: '0', label: 'Pendientes sync', color: Colors.orange)),
              ]),
              const SizedBox(height: 20),

              // ── Actividad reciente de SQLite ─────────────────────────────
              Row(children: [
                const Text('Actividad reciente', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                const Spacer(),
                if (_consultasHoy > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: _kVerde.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                    child: Text('$_consultasHoy hoy',
                        style: const TextStyle(color: Color(0xFF1D9E75), fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
              ]),
              const SizedBox(height: 12),

              if (_cargando)
                const Center(child: CircularProgressIndicator(color: Color(0xFF1D9E75)))
              else if (_recientes.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: _kCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: _kBorder)),
                  child: const Center(child: Text('Sin consultas registradas aún.\nRegistra un paciente y realiza tu primera consulta.',
                      textAlign: TextAlign.center, style: TextStyle(color: Colors.white38, fontSize: 13))),
                )
              else
                ..._recientes.map((c) {
                  final color = _nivelColor(c['nivel_riesgo']);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(color: _kCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
                    child: Row(children: [
                      CircleAvatar(
                        radius: 20, backgroundColor: color.withOpacity(0.2),
                        child: Text(((c['nombre'] as String?) ?? '?')[0].toUpperCase(),
                            style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(c['nombre'] ?? '—', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                        Text('${c['modulo'] ?? ''} · ${_tiempoRelativo(c['fecha'])}',
                            style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      ])),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                        child: Text(_nivelLabel(c['nivel_riesgo']),
                            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
                      ),
                    ]),
                  );
                }),
              const SizedBox(height: 20),

              // ── Estado del sistema ───────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: _kCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: _kBorder)),
                child: Row(children: [
                  const Text('🌿', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Modo sin conexión activo', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                    Text('Datos guardados localmente · Sincronización pendiente: 0 registros',
                        style: TextStyle(color: Colors.white54, fontSize: 11)),
                  ])),
                ]),
              ),
              const SizedBox(height: 10),
            ]),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String valor, label; final Color color;
  const _StatCard({required this.valor, required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
    decoration: BoxDecoration(color: _kCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white10)),
    child: Column(children: [
      Text(valor, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
      const SizedBox(height: 4),
      Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white54, fontSize: 11)),
    ]),
  );
}