import 'package:flutter/material.dart';

const Color _kBg    = Color(0xFF111111);
const Color _kCard  = Color(0xFF1E1E1E);
const Color _kBorder= Color(0xFF2A2A2A);

class AlertasScreen extends StatelessWidget {
  const AlertasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Alertas SIVIGILA',
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('Eventos de salud pública en tu zona',
                style: TextStyle(color: Colors.white54, fontSize: 13)),
            const SizedBox(height: 20),
            _AlertaItem(emoji: '🦟', titulo: 'Dengue · Alerta activa',
                desc: 'Cauca · 12 casos esta semana', color: Colors.red),
            _AlertaItem(emoji: '💩', titulo: 'EDA · Vigilancia',
                desc: 'Brote leve en zona rural', color: Colors.orange),
            _AlertaItem(emoji: '🤧', titulo: 'IRA · Normal',
                desc: 'Sin alertas activas', color: Colors.green),
          ]),
        ),
      ),
    );
  }
}

class _AlertaItem extends StatelessWidget {
  final String emoji, titulo, desc;
  final Color color;
  const _AlertaItem({required this.emoji, required this.titulo, required this.desc, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: _kCard, borderRadius: BorderRadius.circular(14),
      border: Border.all(color: color.withOpacity(0.4)),
    ),
    child: Row(children: [
      Text(emoji, style: const TextStyle(fontSize: 28)),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(titulo, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
        Text(desc, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ]),
    ]),
  );
}