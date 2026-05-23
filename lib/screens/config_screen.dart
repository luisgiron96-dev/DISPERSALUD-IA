import 'package:flutter/material.dart';

const Color _kBg    = Color(0xFF111111);
const Color _kCard  = Color(0xFF1E1E1E);
const Color _kVerde = Color(0xFF1D9E75);
const Color _kBorder= Color(0xFF2A2A2A);

class ConfigScreen extends StatelessWidget {
  const ConfigScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Configuración',
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _Item(icon: Icons.person_outline, label: 'Perfil del promotor'),
            _Item(icon: Icons.sync_outlined,  label: 'Sincronizar datos'),
            _Item(icon: Icons.mic_outlined,   label: 'Configurar voz'),
            _Item(icon: Icons.lock_outline,   label: 'Seguridad y privacidad'),
            _Item(icon: Icons.info_outline,   label: 'Acerca de DISPERSALUD IA'),
          ]),
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Item({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
      color: _kCard, borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _kBorder),
    ),
    child: Row(children: [
      Icon(icon, color: _kVerde, size: 22),
      const SizedBox(width: 14),
      Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
      const Spacer(),
      const Icon(Icons.chevron_right, color: Colors.white30, size: 20),
    ]),
  );
}