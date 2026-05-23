import 'package:flutter/material.dart';

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
  bool _escuchando = false;

  // Consultas del día — en producción vendrían de SQLite
  final List<Map<String, String>> _consultas = [
    {'nombre': 'María González', 'modulo': 'Hipertensión', 'tiempo': 'hace 2h', 'estado': 'Control',  'color': 'naranja'},
    {'nombre': 'Juan Pérez',     'modulo': 'Diabetes',     'tiempo': 'hace 4h', 'estado': 'Estable',  'color': 'verde'},
    {'nombre': 'Rosa Medina',    'modulo': 'Gestación',    'tiempo': 'hace 5h', 'estado': 'Urgente',  'color': 'rojo'},
  ];

  Color _estadoColor(String c) {
    if (c == 'rojo')    return Colors.red;
    if (c == 'naranja') return Colors.orange;
    return const Color(0xFF1D9E75);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // ── Header ─────────────────────────────────────────────────────
            Row(children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(color: _kVerde, borderRadius: BorderRadius.circular(10)),
                child: const Center(child: Text('🌿', style: TextStyle(fontSize: 20))),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('DISPERSALUD IA',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  Text('Promotora Ana · Vereda El Limón, Cauca',
                      style: TextStyle(color: Colors.white54, fontSize: 11)),
                ]),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _kCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _kBorder),
                ),
                child: Row(children: [
                  Container(width: 7, height: 7,
                      decoration: BoxDecoration(color: Colors.orange, shape: BoxShape.circle)),
                  const SizedBox(width: 5),
                  const Text('Offline', style: TextStyle(color: Colors.white70, fontSize: 11)),
                ]),
              ),
            ]),
            const SizedBox(height: 20),

            // ── Tarjeta bienvenida ──────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F6E56), Color(0xFF1D9E75)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Buenos días, Promotora Ana 👋',
                    style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text('Vereda El Limón · Cauca',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 14),
                Row(children: [
                  const Icon(Icons.mic_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    _escuchando ? 'Escuchando...' : 'Toca para consulta por voz',
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ]),
                const SizedBox(height: 4),
                const Text('"Paciente gestante de 28 semanas con náuseas..."',
                    style: TextStyle(color: Colors.white60, fontSize: 11, fontStyle: FontStyle.italic)),
              ]),
            ),
            const SizedBox(height: 8),

            // ── Botón micrófono ─────────────────────────────────────────────
            GestureDetector(
              onTap: () => setState(() => _escuchando = !_escuchando),
              child: Container(
                width: double.infinity, height: 64,
                decoration: BoxDecoration(
                  color: _escuchando ? _kVerde : _kCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _escuchando ? _kVerde : _kBorder),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(_escuchando ? Icons.mic_rounded : Icons.mic_outlined,
                      color: Colors.white, size: 26),
                  const SizedBox(width: 10),
                  Text(
                    _escuchando ? 'Escuchando... toca para detener' : 'Consulta por voz con IA',
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 20),

            // ── Resumen del día ─────────────────────────────────────────────
            Row(children: [
              const Text('Actividad hoy',
                  style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: _kVerde.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                child: Text('${_consultas.length} consultas',
                    style: const TextStyle(color: Color(0xFF1D9E75), fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ]),
            const SizedBox(height: 12),

            // ── Lista consultas del día ─────────────────────────────────────
            ..._consultas.map((c) => _ConsultaItem(
              nombre:  c['nombre']!,
              modulo:  c['modulo']!,
              tiempo:  c['tiempo']!,
              estado:  c['estado']!,
              color:   _estadoColor(c['color']!),
            )),
            const SizedBox(height: 20),

            // ── Accesos rápidos ─────────────────────────────────────────────
            const Text('Accesos rápidos',
                style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10, mainAxisSpacing: 10,
              childAspectRatio: 1.1,
              children: const [
                _AccesoRapido(emoji: '💉', label: 'Vacunas PAI', color: Color(0xFF0891B2)),
                _AccesoRapido(emoji: '🩸', label: 'Diabetes',    color: Color(0xFFB45309)),
                _AccesoRapido(emoji: '❤️', label: 'Hipertensión',color: Color(0xFFDC2626)),
                _AccesoRapido(emoji: '🤰', label: 'Gestación',   color: Color(0xFFC026D3)),
                _AccesoRapido(emoji: '🧠', label: 'Salud mental',color: Color(0xFF7C3AED)),
                _AccesoRapido(emoji: '📋', label: 'SIVIGILA',    color: Color(0xFF1D9E75)),
              ],
            ),
            const SizedBox(height: 20),

            // ── Estado del sistema ──────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _kCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _kBorder),
              ),
              child: Row(children: [
                const Text('🌿', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Modo sin conexión activo',
                      style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                  Text('Datos guardados localmente · Sincronización pendiente: 3 registros',
                      style: TextStyle(color: Colors.white54, fontSize: 11)),
                ])),
              ]),
            ),
            const SizedBox(height: 10),
          ]),
        ),
      ),
    );
  }
}

class _ConsultaItem extends StatelessWidget {
  final String nombre, modulo, tiempo, estado;
  final Color color;
  const _ConsultaItem({
    required this.nombre, required this.modulo,
    required this.tiempo, required this.estado, required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: _kCard,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFF2A2A2A)),
    ),
    child: Row(children: [
      CircleAvatar(
        radius: 20, backgroundColor: color.withOpacity(0.2),
        child: Text(nombre[0], style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(nombre, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
        Text('$modulo · $tiempo', style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ])),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
        child: Text(estado, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
      ),
    ]),
  );
}

class _AccesoRapido extends StatelessWidget {
  final String emoji, label;
  final Color color;
  const _AccesoRapido({required this.emoji, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: _kCard,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text(emoji, style: const TextStyle(fontSize: 24)),
      const SizedBox(height: 6),
      Text(label, textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w500)),
    ]),
  );
}