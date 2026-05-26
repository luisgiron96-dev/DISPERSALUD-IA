import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const Color _kBg     = Color(0xFF111111);
const Color _kCard   = Color(0xFF1E1E1E);
const Color _kVerde  = Color(0xFF1D9E75);
const Color _kBorder = Color(0xFF2A2A2A);

class ConfigScreen extends StatefulWidget {
  const ConfigScreen({super.key});
  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  String _nombrePromotor  = '';
  String _vereda          = '';
  String _municipio       = '';
  String _departamento    = '';
  bool   _vozActiva       = true;
  bool   _alertasActivas  = true;
  bool   _modoOffline     = true;

  @override
  void initState() {
    super.initState();
    _cargarPreferencias();
  }

  Future<void> _cargarPreferencias() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nombrePromotor = prefs.getString('promotor_nombre')   ?? '';
      _vereda         = prefs.getString('promotor_vereda')   ?? '';
      _municipio      = prefs.getString('promotor_municipio')  ?? '';
      _departamento   = prefs.getString('promotor_departamento') ?? '';
      _vozActiva      = prefs.getBool('voz_activa')   ?? true;
      _alertasActivas = prefs.getBool('alertas_activas') ?? true;
      _modoOffline    = prefs.getBool('modo_offline')  ?? true;
    });
  }

  Future<void> _guardarPreferencia(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool)   await prefs.setBool(key, value);
    if (value is String) await prefs.setString(key, value);
  }

  void _abrirPerfil() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: _kCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _PerfilSheet(
        nombre:       _nombrePromotor,
        vereda:       _vereda,
        municipio:    _municipio,
        departamento: _departamento,
        onGuardar: (n, v, m, d) async {
          await _guardarPreferencia('promotor_nombre',       n);
          await _guardarPreferencia('promotor_vereda',       v);
          await _guardarPreferencia('promotor_municipio',    m);
          await _guardarPreferencia('promotor_departamento', d);
          setState(() {
            _nombrePromotor = n;
            _vereda         = v;
            _municipio      = m;
            _departamento   = d;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: const Text('Perfil actualizado correctamente ✓'),
              backgroundColor: _kVerde,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ));
          }
        },
      ),
    );
  }

  void _abrirSincronizar() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _kCard,
        title: const Text('Sincronizar datos', style: TextStyle(color: Colors.white)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.cloud_upload_outlined, color: _kVerde, size: 48),
          const SizedBox(height: 14),
          const Text(
            'Los datos se sincronizan automáticamente cuando hay conexión a internet.\n\nActualmente estás en modo offline — todos los registros están guardados localmente.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange.withOpacity(0.3))),
            child: const Row(children: [
              Icon(Icons.wifi_off, color: Colors.orange, size: 18),
              SizedBox(width: 8),
              Expanded(child: Text('Sin conexión a internet',
                  style: TextStyle(color: Colors.orange, fontSize: 12))),
            ]),
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar', style: TextStyle(color: _kVerde)),
          ),
        ],
      ),
    );
  }

  void _abrirVoz() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _kCard,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) {
          final bottom = MediaQuery.of(context).padding.bottom;
          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.fromLTRB(24, 24, 24, bottom < 16 ? 48 : bottom + 24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
                const Text('Configurar voz',
                    style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: _kBg, borderRadius: BorderRadius.circular(14)),
                  child: Row(children: [
                    const Icon(Icons.mic_rounded, color: _kVerde, size: 22),
                    const SizedBox(width: 12),
                    const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Consulta por voz', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                      Text('Activar reconocimiento de voz en el dashboard',
                          style: TextStyle(color: Colors.white54, fontSize: 12)),
                    ])),
                    Switch(
                      value: _vozActiva,
                      activeColor: _kVerde,
                      onChanged: (v) async {
                        setS(() {});
                        setState(() => _vozActiva = v);
                        await _guardarPreferencia('voz_activa', v);
                      },
                    ),
                  ]),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: _kBg, borderRadius: BorderRadius.circular(14)),
                  child: Row(children: [
                    const Icon(Icons.record_voice_over_outlined, color: _kVerde, size: 22),
                    const SizedBox(width: 12),
                    const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Idioma', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                      Text('Español colombiano', style: TextStyle(color: Colors.white54, fontSize: 12)),
                    ])),
                    const Icon(Icons.check_circle, color: _kVerde, size: 20),
                  ]),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity, height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(backgroundColor: _kVerde,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: const Text('Guardar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ]),
            ),
          );
        },
      ),
    );
  }

  void _abrirSeguridad() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _kCard,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) {
        final bottom = MediaQuery.of(context).padding.bottom;
        return SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.fromLTRB(24, 24, 24, bottom < 16 ? 48 : bottom + 24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
              const Text('Seguridad y privacidad',
                  style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              _InfoTile(icon: Icons.lock_outline, color: Colors.green,
                  titulo: 'Cifrado AES-256 activo',
                  desc: 'Documentos, teléfonos y diagnósticos cifrados en el dispositivo'),
              const SizedBox(height: 10),
              _InfoTile(icon: Icons.phone_android_outlined, color: _kVerde,
                  titulo: 'Datos solo en tu celular',
                  desc: 'Sin envío a servidores externos. Cumple Ley 1581 de protección de datos'),
              const SizedBox(height: 10),
              _InfoTile(icon: Icons.sync_outlined, color: Colors.blue,
                  titulo: 'Sincronización cifrada',
                  desc: 'Cuando haya internet, los datos se envían con TLS 1.3'),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity, height: 48,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white24),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text('Cerrar', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                ),
              ),
            ]),
          ),
        );
      },
    );
  }

  void _abrirAcercaDe() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _kCard,
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
                shape: BoxShape.circle, color: _kVerde.withOpacity(0.15),
                border: Border.all(color: _kVerde.withOpacity(0.3))),
            child: const Icon(Icons.monitor_heart_outlined, color: _kVerde, size: 40),
          ),
          const SizedBox(height: 16),
          const Text('DISPERSALUD IA',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Versión 1.0.0',
              style: TextStyle(color: Colors.white54, fontSize: 13)),
          const SizedBox(height: 14),
          const Text(
            'Sistema de Asistencia en Salud para zonas rurales dispersas de Colombia.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 14),
          _InfoTile(icon: Icons.wifi_off, color: Colors.orange,
              titulo: 'Funciona sin internet',
              desc: 'Todos los módulos operan 100% offline'),
          const SizedBox(height: 8),
          _InfoTile(icon: Icons.health_and_safety_outlined, color: _kVerde,
              titulo: '7 módulos de ciclo vital',
              desc: 'Gestación · Infancia · Adolescencia · Adultez · Vejez'),
          const SizedBox(height: 8),
          _InfoTile(icon: Icons.shield_outlined, color: Colors.blue,
              titulo: 'Ley 1581 — Habeas Data',
              desc: 'Datos cifrados y protegidos en el dispositivo'),
          const SizedBox(height: 16),
          const Text('© 2025 DISPERSALUD IA · Colombia',
              style: TextStyle(color: Colors.white38, fontSize: 11)),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar', style: TextStyle(color: _kVerde)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // Header
            const Text('Configuración',
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('Personaliza tu experiencia DISPERSALUD IA',
                style: TextStyle(color: Colors.white54, fontSize: 13)),
            const SizedBox(height: 20),

            // Perfil del promotor
            if (_nombrePromotor.isNotEmpty)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _kVerde.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _kVerde.withOpacity(0.3)),
                ),
                child: Row(children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: _kVerde.withOpacity(0.2),
                    child: Text(
                      _nombrePromotor.isNotEmpty ? _nombrePromotor[0].toUpperCase() : '?',
                      style: const TextStyle(color: _kVerde, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_nombrePromotor,
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                    if (_vereda.isNotEmpty || _municipio.isNotEmpty)
                      Text('$_vereda · $_municipio${_departamento.isNotEmpty ? ', $_departamento' : ''}',
                          style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  ])),
                  const Icon(Icons.verified_outlined, color: _kVerde, size: 20),
                ]),
              ),

            // Sección personal
            _SeccionLabel(texto: 'Personal'),
            _Item(icon: Icons.person_outline, label: 'Perfil del promotor',
                desc: _nombrePromotor.isNotEmpty ? _nombrePromotor : 'Sin configurar',
                onTap: _abrirPerfil),
            const SizedBox(height: 8),

            // Sección sistema
            _SeccionLabel(texto: 'Sistema'),
            _Item(icon: Icons.sync_outlined,   label: 'Sincronizar datos',
                desc: 'Offline · 0 registros pendientes', onTap: _abrirSincronizar),
            const SizedBox(height: 8),
            _Item(icon: Icons.mic_outlined,    label: 'Configurar voz',
                desc: _vozActiva ? 'Activada · Español colombiano' : 'Desactivada',
                onTap: _abrirVoz),
            const SizedBox(height: 8),

            // Sección privacidad
            _SeccionLabel(texto: 'Privacidad'),
            _Item(icon: Icons.lock_outline,    label: 'Seguridad y privacidad',
                desc: 'AES-256 · Ley 1581', onTap: _abrirSeguridad),
            const SizedBox(height: 8),

            // Sección app
            _SeccionLabel(texto: 'Aplicación'),
            _Item(icon: Icons.notifications_outlined, label: 'Alertas y notificaciones',
                trailing: Switch(
                  value: _alertasActivas, activeColor: _kVerde,
                  onChanged: (v) async {
                    setState(() => _alertasActivas = v);
                    await _guardarPreferencia('alertas_activas', v);
                  },
                )),
            const SizedBox(height: 8),
            _Item(icon: Icons.info_outline, label: 'Acerca de DISPERSALUD IA',
                desc: 'Versión 1.0.0', onTap: _abrirAcercaDe),

            const SizedBox(height: 24),
          ]),
        ),
      ),
    );
  }
}

// ─── Widgets ───────────────────────────────────────────────────────────────

class _SeccionLabel extends StatelessWidget {
  final String texto;
  const _SeccionLabel({required this.texto});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(texto.toUpperCase(),
        style: const TextStyle(color: Colors.white38, fontSize: 11,
            fontWeight: FontWeight.w500, letterSpacing: 0.8)),
  );
}

class _Item extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? desc;
  final VoidCallback? onTap;
  final Widget? trailing;
  const _Item({required this.icon, required this.label,
      this.desc, this.onTap, this.trailing});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: _kCard, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
              color: _kVerde.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: _kVerde, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
          if (desc != null)
            Text(desc!, style: const TextStyle(color: Colors.white38, fontSize: 12)),
        ])),
        trailing ?? const Icon(Icons.chevron_right, color: Colors.white24, size: 20),
      ]),
    ),
  );
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String titulo, desc;
  const _InfoTile({required this.icon, required this.color,
      required this.titulo, required this.desc});
  @override
  Widget build(BuildContext context) => Row(children: [
    Container(
      width: 36, height: 36,
      decoration: BoxDecoration(
          color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
      child: Icon(icon, color: color, size: 20),
    ),
    const SizedBox(width: 12),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(titulo, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
      Text(desc, style: const TextStyle(color: Colors.white54, fontSize: 11, height: 1.3)),
    ])),
  ]);
}

// ─── Sheet de perfil ───────────────────────────────────────────────────────
class _PerfilSheet extends StatefulWidget {
  final String nombre, vereda, municipio, departamento;
  final Function(String, String, String, String) onGuardar;
  const _PerfilSheet({required this.nombre, required this.vereda,
      required this.municipio, required this.departamento, required this.onGuardar});
  @override
  State<_PerfilSheet> createState() => _PerfilSheetState();
}

class _PerfilSheetState extends State<_PerfilSheet> {
  late TextEditingController _nombreCtrl;
  late TextEditingController _veredaCtrl;
  late TextEditingController _municipioCtrl;
  late TextEditingController _deptoCtrl;

  @override
  void initState() {
    super.initState();
    _nombreCtrl    = TextEditingController(text: widget.nombre);
    _veredaCtrl    = TextEditingController(text: widget.vereda);
    _municipioCtrl = TextEditingController(text: widget.municipio);
    _deptoCtrl     = TextEditingController(text: widget.departamento);
  }

  @override
  void dispose() {
    _nombreCtrl.dispose(); _veredaCtrl.dispose();
    _municipioCtrl.dispose(); _deptoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom
                 + MediaQuery.of(context).padding.bottom;
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, bottom < 16 ? 48 : bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Indicador drag
          Center(
            child: Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const Text('Perfil del promotor',
              style: TextStyle(color: Colors.white, fontSize: 17,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _Campo(label: 'Nombre completo', controller: _nombreCtrl),
          const SizedBox(height: 12),
          _Campo(label: 'Vereda', controller: _veredaCtrl),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _Campo(label: 'Municipio',    controller: _municipioCtrl)),
            const SizedBox(width: 12),
            Expanded(child: _Campo(label: 'Departamento', controller: _deptoCtrl)),
          ]),
          const SizedBox(height: 24),
          // Botones con altura fija para que no se corten
          Row(children: [
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white24),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  child: const Text('Cancelar',
                      style: TextStyle(color: Colors.white70)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    widget.onGuardar(
                      _nombreCtrl.text.trim(),
                      _veredaCtrl.text.trim(),
                      _municipioCtrl.text.trim(),
                      _deptoCtrl.text.trim(),
                    );
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: _kVerde,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  child: const Text('Guardar',
                      style: TextStyle(color: Colors.white,
                          fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}

class _Campo extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  const _Campo({required this.label, required this.controller});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
      const SizedBox(height: 4),
      TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          filled: true, fillColor: const Color(0xFF2A2A2A),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        ),
      ),
    ],
  );
}