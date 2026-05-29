import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

const Color _kVerde  = Color(0xFF1D9E75);
DispersaludColors _c(BuildContext ctx) =>
    Theme.of(ctx).extension<DispersaludColors>() ?? DispersaludColors.dark;

class ConfigScreen extends StatefulWidget {
  ConfigScreen({super.key});
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
  // ignore: unused_field
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
      backgroundColor: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
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
              content: Text('Perfil actualizado correctamente ✓'),
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
        backgroundColor: Theme.of(context).cardColor,
        title: Text('Sincronizar datos', style: TextStyle(color: _c(context).textPrimary)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.cloud_upload_outlined, color: _kVerde, size: 48),
          SizedBox(height: 14),
          Text(
            'Los datos se sincronizan automáticamente cuando hay conexión a internet.\n\nActualmente estás en modo offline — todos los registros están guardados localmente.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _c(context).textSecondary, fontSize: 13, height: 1.5),
          ),
          SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3))),
            child: Row(children: [
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
            child: Text('Cerrar', style: TextStyle(color: _kVerde)),
          ),
        ],
      ),
    );
  }

  void _abrirVoz() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      isScrollControlled: true,
      useSafeArea: true,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) {
          final bottom = MediaQuery.of(context).padding.bottom;
          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.fromLTRB(24, 24, 24, bottom < 16 ? 48 : bottom + 24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(color: _c(context).border, borderRadius: BorderRadius.circular(2)))),
                Text('Configurar voz',
                    style: TextStyle(color: _c(context).textPrimary, fontSize: 17, fontWeight: FontWeight.bold)),
                SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: _c(context).bg, borderRadius: BorderRadius.circular(14)),
                  child: Row(children: [
                    Icon(Icons.mic_rounded, color: _kVerde, size: 22),
                    SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Consulta por voz', style: TextStyle(color: _c(context).textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
                      Text('Activar reconocimiento de voz en el dashboard',
                          style: TextStyle(color: _c(context).textHint, fontSize: 12)),
                    ])),
                    Switch(
                      value: _vozActiva,
                      activeThumbColor: _kVerde,
                      onChanged: (v) async {
                        setS(() {});
                        setState(() => _vozActiva = v);
                        await _guardarPreferencia('voz_activa', v);
                      },
                    ),
                  ]),
                ),
                SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: _c(context).bg, borderRadius: BorderRadius.circular(14)),
                  child: Row(children: [
                    Icon(Icons.record_voice_over_outlined, color: _kVerde, size: 22),
                    SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Idioma', style: TextStyle(color: _c(context).textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
                      Text('Español colombiano', style: TextStyle(color: _c(context).textHint, fontSize: 12)),
                    ])),
                    Icon(Icons.check_circle, color: _kVerde, size: 20),
                  ]),
                ),
                SizedBox(height: 24),
                SizedBox(
                  width: double.infinity, height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(backgroundColor: _kVerde,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: Text('Guardar', style: TextStyle(color: _c(context).textPrimary, fontWeight: FontWeight.bold)),
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
      backgroundColor: Theme.of(context).cardColor,
      isScrollControlled: true,
      useSafeArea: true,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) {
        final bottom = MediaQuery.of(context).padding.bottom;
        return SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.fromLTRB(24, 24, 24, bottom < 16 ? 48 : bottom + 24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(color: _c(context).border, borderRadius: BorderRadius.circular(2)))),
              Text('Seguridad y privacidad',
                  style: TextStyle(color: _c(context).textPrimary, fontSize: 17, fontWeight: FontWeight.bold)),
              SizedBox(height: 20),
              _InfoTile(icon: Icons.lock_outline, color: Colors.green,
                  titulo: 'Cifrado AES-256 activo',
                  desc: 'Documentos, teléfonos y diagnósticos cifrados en el dispositivo'),
              SizedBox(height: 10),
              _InfoTile(icon: Icons.phone_android_outlined, color: _kVerde,
                  titulo: 'Datos solo en tu celular',
                  desc: 'Sin envío a servidores externos. Cumple Ley 1581 de protección de datos'),
              SizedBox(height: 10),
              _InfoTile(icon: Icons.sync_outlined, color: Colors.blue,
                  titulo: 'Sincronización cifrada',
                  desc: 'Cuando haya internet, los datos se envían con TLS 1.3'),
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity, height: 48,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                      side: BorderSide(color: _c(context).border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: Text('Cerrar', style: TextStyle(color: _c(context).textSecondary, fontWeight: FontWeight.bold)),
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
        backgroundColor: Theme.of(context).cardColor,
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
  width: 95,
  height: 95,
  decoration: BoxDecoration(
    shape: BoxShape.circle,
    color: _kVerde.withValues(alpha: 0.10),
    border: Border.all(
      color: _kVerde.withValues(alpha: 0.25),
      width: 2,
    ),
    boxShadow: [
      BoxShadow(
        color: _kVerde.withValues(alpha: 0.15),
        blurRadius: 20,
        spreadRadius: 2,
      ),
    ],
  ),
  child: Padding(
    padding: const EdgeInsets.all(14),
    child: ClipOval(
      child: Image.asset(
        'assets/logo_dispersalud.png',
        fit: BoxFit.cover,
      ),
    ),
  ),
),
          SizedBox(height: 16),
          Text('DISPERSALUD IA',
              style: TextStyle(color: _c(context).textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 4),
          Text('Versión 1.0.0',
              style: TextStyle(color: _c(context).textHint, fontSize: 13)),
          SizedBox(height: 14),
          Text(
            'Sistema de Asistencia en Salud para zonas rurales dispersas de Colombia.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _c(context).textSecondary, fontSize: 13, height: 1.5),
          ),
          SizedBox(height: 14),
          _InfoTile(icon: Icons.wifi_off, color: Colors.orange,
              titulo: 'Funciona sin internet',
              desc: 'Todos los módulos operan 100% offline'),
          SizedBox(height: 8),
          _InfoTile(icon: Icons.health_and_safety_outlined, color: _kVerde,
              titulo: '7 módulos de ciclo vital',
              desc: 'Gestación · Infancia · Adolescencia · Adultez · Vejez'),
          SizedBox(height: 8),
          _InfoTile(icon: Icons.shield_outlined, color: Colors.blue,
              titulo: 'Ley 1581 — Habeas Data',
              desc: 'Datos cifrados y protegidos en el dispositivo'),
          SizedBox(height: 16),
          Text('© 2025 DISPERSALUD IA · Colombia',
              style: TextStyle(color: _c(context).textHint, fontSize: 11)),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cerrar', style: TextStyle(color: _kVerde)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _c(context).bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // Header
            Text('Configuración',
                style: TextStyle(color: _c(context).textPrimary, fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text('Personaliza tu experiencia DISPERSALUD IA',
                style: TextStyle(color: _c(context).textHint, fontSize: 13)),
            SizedBox(height: 20),

            // Perfil del promotor
            if (_nombrePromotor.isNotEmpty)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _kVerde.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _kVerde.withValues(alpha: 0.3)),
                ),
                child: Row(children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: _kVerde.withValues(alpha: 0.2),
                    child: Text(
                      _nombrePromotor.isNotEmpty ? _nombrePromotor[0].toUpperCase() : '?',
                      style: TextStyle(color: _kVerde, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_nombrePromotor,
                        style: TextStyle(color: _c(context).textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                    if (_vereda.isNotEmpty || _municipio.isNotEmpty)
                      Text('$_vereda · $_municipio${_departamento.isNotEmpty ? ', $_departamento' : ''}',
                          style: TextStyle(color: _c(context).textHint, fontSize: 12)),
                  ])),
                  Icon(Icons.verified_outlined, color: _kVerde, size: 20),
                ]),
              ),

            // Sección personal
            _SeccionLabel(texto: 'Personal'),
            _Item(icon: Icons.person_outline, label: 'Perfil del promotor',
                desc: _nombrePromotor.isNotEmpty ? _nombrePromotor : 'Sin configurar',
                onTap: _abrirPerfil),
            SizedBox(height: 8),

            // Sección sistema
            _SeccionLabel(texto: 'Sistema'),
            _Item(icon: Icons.sync_outlined,   label: 'Sincronizar datos',
                desc: 'Offline · 0 registros pendientes', onTap: _abrirSincronizar),
            SizedBox(height: 8),
            _Item(icon: Icons.mic_outlined,    label: 'Configurar voz',
                desc: _vozActiva ? 'Activada · Español colombiano' : 'Desactivada',
                onTap: _abrirVoz),
            SizedBox(height: 8),

            // Sección privacidad
            _SeccionLabel(texto: 'Privacidad'),
            _Item(icon: Icons.lock_outline,    label: 'Seguridad y privacidad',
                desc: 'AES-256 · Ley 1581', onTap: _abrirSeguridad),
            SizedBox(height: 8),

            // Sección app
            _SeccionLabel(texto: 'Aplicación'),
            _Item(icon: Icons.notifications_outlined, label: 'Alertas y notificaciones',
                trailing: Switch(
                  value: _alertasActivas, activeThumbColor: _kVerde,
                  onChanged: (v) async {
                    setState(() => _alertasActivas = v);
                    await _guardarPreferencia('alertas_activas', v);
                  },
                )),
            SizedBox(height: 8),
            _Item(icon: Icons.info_outline, label: 'Acerca de DISPERSALUD IA',
                desc: 'Versión 1.0.0', onTap: _abrirAcercaDe),

            SizedBox(height: 24),
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
        style: TextStyle(color: _c(context).textHint, fontSize: 11,
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
        color: _c(context).card, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _c(context).border),
      ),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
              color: _kVerde.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: _kVerde, size: 20),
        ),
        SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(color: _c(context).textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
          if (desc != null)
            Text(desc!, style: TextStyle(color: _c(context).textHint, fontSize: 12)),
        ])),
        trailing ?? Icon(Icons.chevron_right, color: _c(context).border, size: 20),
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
          color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
      child: Icon(icon, color: color, size: 20),
    ),
    SizedBox(width: 12),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(titulo, style: TextStyle(color: _c(context).textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
      Text(desc, style: TextStyle(color: _c(context).textHint, fontSize: 11, height: 1.3)),
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
                  color: _c(context).border,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Text('Perfil del promotor',
              style: TextStyle(color: _c(context).textPrimary, fontSize: 17,
                  fontWeight: FontWeight.bold)),
          SizedBox(height: 20),
          _Campo(label: 'Nombre completo', controller: _nombreCtrl),
          SizedBox(height: 12),
          _Campo(label: 'Vereda', controller: _veredaCtrl),
          SizedBox(height: 12),
          Row(children: [
            Expanded(child: _Campo(label: 'Municipio',    controller: _municipioCtrl)),
            SizedBox(width: 12),
            Expanded(child: _Campo(label: 'Departamento', controller: _deptoCtrl)),
          ]),
          SizedBox(height: 24),
          // Botones con altura fija para que no se corten
          Row(children: [
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                      side: BorderSide(color: _c(context).border),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  child: Text('Cancelar',
                      style: TextStyle(color: _c(context).textSecondary)),
                ),
              ),
            ),
            SizedBox(width: 12),
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
                  child: Text('Guardar',
                      style: TextStyle(color: _c(context).textPrimary,
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
      Text(label, style: TextStyle(color: _c(context).textHint, fontSize: 11)),
      SizedBox(height: 4),
      TextField(
        controller: controller,
        style: TextStyle(color: _c(context).textPrimary, fontSize: 14),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          filled: true, fillColor: _c(context).border,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        ),
      ),
    ],
  );
}