import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/app_theme.dart';
import '../database/database_helper.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  reportar_alerta_screen.dart  —  DISPERSALUD IA
//  Diseño nuevo: imagen de referencia con todos los botones funcionales
// ═══════════════════════════════════════════════════════════════════════════

const Color _kVerde       = Color(0xFF1D9E75);
const Color _kVerdeOscuro = Color(0xFF0A5240);
const Color _kVerdeMedio  = Color(0xFF0F6E56);

DispersaludColors _dc(BuildContext ctx) =>
    Theme.of(ctx).extension<DispersaludColors>() ?? DispersaludColors.dark;

// ── Tipos de alerta ──────────────────────────────────────────────────────────
class _Tipo {
  final String id, label, emoji;
  final Color color;
  const _Tipo(this.id, this.label, this.emoji, this.color);
}

const List<_Tipo> _kTipos = [
  _Tipo('gestacion',    'Gestación',    '🤰', Color(0xFF993556)),
  _Tipo('vacunacion',   'Vacunación',   '💉', Color(0xFFE07B00)),
  _Tipo('infancia',     'Infancia',     '🧒', Color(0xFF185FA5)),
  _Tipo('adolescencia', 'Adolescencia', '🧑', Color(0xFF534AB7)),
  _Tipo('juventud',     'Juventud',     '🧍', Color(0xFF1D9E75)),
  _Tipo('adultez',      'Adultez',      '🧔', Color(0xFF3B6D11)),
  _Tipo('vejez',        'Vejez',        '🧓', Color(0xFFE07B00)),
];

// ── Niveles de riesgo ────────────────────────────────────────────────────────
class _Riesgo {
  final String id, label;
  final IconData icon;
  final Color color;
  const _Riesgo(this.id, this.label, this.icon, this.color);
}

const List<_Riesgo> _kRiesgos = [
  _Riesgo('bajo',     'Bajo',    Icons.shield_outlined,         Color(0xFF1D9E75)),
  _Riesgo('medio',    'Medio',   Icons.shield_moon_outlined,    Color(0xFFE07B00)),
  _Riesgo('alto',     'Alto',    Icons.shield_rounded,          Color(0xFFE24B4A)),
  _Riesgo('critico',  'Crítico', Icons.help_outline_rounded,    Color(0xFF888888)),
];

// ════════════════════════════════════════════════════════════════════════════
// PANTALLA PRINCIPAL
// ════════════════════════════════════════════════════════════════════════════
class ReportarAlertaScreen extends StatefulWidget {
  const ReportarAlertaScreen({super.key});
  @override
  State<ReportarAlertaScreen> createState() => _ReportarAlertaScreenState();
}

class _ReportarAlertaScreenState extends State<ReportarAlertaScreen> {
  // ── Estado ────────────────────────────────────────────────────────────────
  String _tipoSel    = 'gestacion';
  String _riesgoSel  = 'bajo';
  final  _descCtrl   = TextEditingController();
  final  _ubicCtrl   = TextEditingController();
  DateTime _fecha    = DateTime.now();
  List<XFile> _fotos = [];
  bool _enviando     = false;

  @override
  void initState() {
    super.initState();
    _cargarUbicacion();
  }

  @override
  void dispose() { _descCtrl.dispose(); _ubicCtrl.dispose(); super.dispose(); }

  // ── Carga la ubicación guardada en el perfil del promotor ─────────────────
  Future<void> _cargarUbicacion() async {
    final p     = await SharedPreferences.getInstance();
    final vered = p.getString('promotor_vereda')    ?? '';
    final mun   = p.getString('promotor_municipio') ?? '';
    final dep   = p.getString('promotor_departamento') ?? 'Cauca';
    final partes = [vered, mun, dep].where((s) => s.isNotEmpty).toList();
    _ubicCtrl.text = partes.isNotEmpty ? partes.join(' - ') : 'Sin ubicación configurada';
    if (mounted) setState(() {});
  }

  // ── Selector de fotos ─────────────────────────────────────────────────────
  Future<void> _tomarFoto() async {
    if (kIsWeb) { _snack('Cámara no disponible en web', error: true); return; }
    if (_fotos.length >= 3) { _snack('Máximo 3 fotos permitidas'); return; }
    final img = await ImagePicker().pickImage(
        source: ImageSource.camera, imageQuality: 80);
    if (img != null) setState(() => _fotos.add(img));
  }

  Future<void> _galeria() async {
    if (_fotos.length >= 3) { _snack('Máximo 3 fotos permitidas'); return; }
    final imgs = await ImagePicker().pickMultiImage(imageQuality: 80);
    if (imgs.isNotEmpty) {
      setState(() {
        final restante = 3 - _fotos.length;
        _fotos.addAll(imgs.take(restante));
      });
    }
  }

  void _eliminarFoto(int i) => setState(() => _fotos.removeAt(i));

  // ── Selector de fecha ────────────────────────────────────────────────────
  Future<void> _seleccionarFecha() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate:   DateTime(2020),
      lastDate:    DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(primary: _kVerde)),
        child: child!,
      ),
    );
    if (d == null) return;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_fecha),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(primary: _kVerde)),
        child: child!,
      ),
    );
    if (t == null) return;
    setState(() => _fecha = DateTime(d.year, d.month, d.day, t.hour, t.minute));
  }

  // ── Usar ubicación del perfil ─────────────────────────────────────────────
  Future<void> _usarMiUbicacion() async {
    await _cargarUbicacion();
    _snack('Ubicación del perfil cargada ✓');
  }

  // ── Enviar alerta ─────────────────────────────────────────────────────────
  Future<void> _enviar() async {
    if (_descCtrl.text.trim().isEmpty) {
      _snack('Describe la situación antes de enviar', error: true); return;
    }
    setState(() => _enviando = true);
    try {
      final tipo   = _kTipos.firstWhere((t) => t.id == _tipoSel);
      final riesgo = _kRiesgos.firstWhere((r) => r.id == _riesgoSel);
      final nivelDB = _riesgoSel == 'alto' || _riesgoSel == 'critico'
          ? 'urgente' : _riesgoSel == 'medio' ? 'alerta' : 'normal';

      await DatabaseHelper.instance.insertarAlerta({
        'modulo':   tipo.label,
        'paciente': '',
        'mensaje':  '${tipo.emoji} [${tipo.label} · ${riesgo.label}] ${_descCtrl.text.trim()}',
        'nivel':    nivelDB,
        'resuelta': 0,
      });

      if (!mounted) return;
      _snack('¡Alerta enviada! El equipo de salud revisará tu reporte.');
      Navigator.pop(context, true);
    } catch (e) {
      _snack('Error al enviar: $e', error: true);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? const Color(0xFFE24B4A) : _kVerde,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 3),
    ));
  }

  // ── Formato de fecha ───────────────────────────────────────────────────────
  String _fechaStr() {
    const meses = ['','Ene','Feb','Mar','Abr','May','Jun',
                   'Jul','Ago','Sep','Oct','Nov','Dic'];
    final h  = _fecha.hour % 12 == 0 ? 12 : _fecha.hour % 12;
    final m  = _fecha.minute.toString().padLeft(2, '0');
    final ap = _fecha.hour < 12 ? 'a. m.' : 'p. m.';
    return '${_fecha.day} ${meses[_fecha.month]} ${_fecha.year}  ·  $h:$m $ap';
  }

  // ════════════════════════════════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final dc = _dc(context);
    return Scaffold(
      backgroundColor: dc.bg,
      // ── APP BAR ──────────────────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: dc.card,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _kVerde.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: _kVerde, size: 18),
          ),
        ),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Reportar alerta', style: TextStyle(
              color: dc.textPrimary, fontSize: 17, fontWeight: FontWeight.bold)),
          Text('Cuéntanos qué está sucediendo',
              style: TextStyle(color: dc.textHint, fontSize: 11)),
        ]),
        actions: [
          GestureDetector(
            onTap: _mostrarAyuda,
            child: Container(
              margin: const EdgeInsets.only(right: 14),
              width: 34, height: 34,
              decoration: BoxDecoration(
                border: Border.all(color: _kVerde, width: 1.5),
                shape: BoxShape.circle,
              ),
              child: const Center(child: Text('i',
                  style: TextStyle(color: _kVerde, fontSize: 14,
                      fontStyle: FontStyle.italic, fontWeight: FontWeight.bold))),
            ),
          ),
        ],
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1),
            child: Divider(height: 1, color: dc.border)),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 40),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── BANNER SUPERIOR ───────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0A5240), Color(0xFF1D9E75)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(child: Text('🚨', style: TextStyle(fontSize: 28))),
              ),
              const SizedBox(width: 16),
              const Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Nueva alerta', style: TextStyle(
                      color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('Reporta situaciones que requieran atención del equipo de salud.',
                      style: TextStyle(color: Color(0xFF9FE1CB), fontSize: 12, height: 1.4)),
                ],
              )),
              // Escudo decorativo
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.health_and_safety_rounded,
                    color: Colors.white, size: 26),
              ),
            ]),
          ),

          // ── TIPO DE ALERTA ────────────────────────────────────────────────
          _secTitulo(dc, '🧩', 'Tipo de alerta'),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Column(children: [
              // Fila 1: 4 tipos
              Row(children: _kTipos.take(4).map((t) =>
                  _buildTipoChip(t, dc)).toList()),
              const SizedBox(height: 8),
              // Fila 2: 3 tipos
              Row(children: _kTipos.skip(4).map((t) =>
                  _buildTipoChip(t, dc)).toList()),
            ]),
          ),

          const SizedBox(height: 20),

          // ── NIVEL DE RIESGO ───────────────────────────────────────────────
          _secTitulo(dc, '🛡️', 'Nivel de riesgo'),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Row(children: _kRiesgos.map((r) =>
                _buildRiesgoChip(r, dc)).toList()),
          ),

          const SizedBox(height: 20),

          // ── DESCRIPCIÓN ───────────────────────────────────────────────────
          _secTitulo(dc, '✏️', 'Descripción de la situación'),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              TextField(
                controller: _descCtrl,
                maxLength: 500,
                maxLines: 5,
                onChanged: (_) => setState(() {}),
                style: TextStyle(color: dc.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Describe los síntomas, novedades o situación observada...',
                  hintStyle: TextStyle(color: dc.textHint, fontSize: 13),
                  counterText: '',
                  filled: true, fillColor: dc.card,
                  contentPadding: const EdgeInsets.all(14),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: dc.border)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: dc.border)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _kVerde, width: 1.5)),
                ),
              ),
              const SizedBox(height: 5),
              Text('${_descCtrl.text.length}/500',
                  style: TextStyle(color: dc.textHint, fontSize: 11)),
            ]),
          ),

          const SizedBox(height: 20),

          // ── ADJUNTAR EVIDENCIA ────────────────────────────────────────────
          _secTituloOpcional(dc, '📷', 'Adjuntar evidencia', '(opcional)'),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Botones cámara / galería
              Row(children: [
                Expanded(child: _btnFoto(
                  icono: Icons.camera_alt_rounded,
                  titulo: 'Tomar foto',
                  subtitulo: 'Usar cámara',
                  color: _kVerde, dc: dc,
                  onTap: kIsWeb ? null : _tomarFoto,
                )),
                const SizedBox(width: 12),
                Expanded(child: _btnFoto(
                  icono: Icons.photo_library_rounded,
                  titulo: 'Seleccionar',
                  subtitulo: 'Desde galería',
                  color: _kVerde, dc: dc,
                  onTap: _galeria,
                )),
              ]),

              // Vista previa de fotos
              if (_fotos.isNotEmpty) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 100,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _fotos.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) => Stack(
                      clipBehavior: Clip.none,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: kIsWeb
                              ? Container(width: 100, height: 100,
                                  color: _kVerde.withOpacity(0.2),
                                  child: const Icon(Icons.image_rounded,
                                      color: _kVerde, size: 40))
                              : Image.file(File(_fotos[i].path),
                                  width: 100, height: 100, fit: BoxFit.cover),
                        ),
                        Positioned(top: -6, right: -6,
                          child: GestureDetector(
                            onTap: () => _eliminarFoto(i),
                            child: Container(
                              width: 22, height: 22,
                              decoration: const BoxDecoration(
                                  color: Colors.white, shape: BoxShape.circle),
                              child: const Icon(Icons.close_rounded,
                                  color: Colors.black87, size: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                const SizedBox(height: 8),
                Text('Máx. 3 fotos · Se adjuntan al reporte para contexto visual.',
                    style: TextStyle(color: dc.textHint, fontSize: 11)),
              ],
            ]),
          ),

          const SizedBox(height: 20),

          // ── INFORMACIÓN DEL REPORTE ────────────────────────────────────────
          _secTitulo(dc, '📍', 'Información del reporte'),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Container(
              decoration: BoxDecoration(
                color: dc.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: dc.border),
              ),
              child: Column(children: [

                // Ubicación
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Ubicación', style: TextStyle(
                        color: dc.textHint, fontSize: 11, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    Row(children: [
                      Icon(Icons.location_on_rounded, color: _kVerde, size: 16),
                      const SizedBox(width: 6),
                      Expanded(child: TextField(
                        controller: _ubicCtrl,
                        style: TextStyle(color: dc.textPrimary, fontSize: 13),
                        decoration: InputDecoration.collapsed(
                          hintText: 'Vereda / Municipio',
                          hintStyle: TextStyle(color: dc.textHint, fontSize: 13),
                        ),
                      )),
                      GestureDetector(
                        onTap: _usarMiUbicacion,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _kVerde.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: const [
                            Icon(Icons.my_location_rounded, color: _kVerde, size: 12),
                            SizedBox(width: 4),
                            Text('Usar mi ubicación', style: TextStyle(
                                color: _kVerde, fontSize: 11, fontWeight: FontWeight.w600)),
                          ]),
                        ),
                      ),
                    ]),
                  ]),
                ),

                Divider(height: 1, color: dc.border),

                // Fecha y hora
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                  child: Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text('Fecha y hora', style: TextStyle(
                          color: dc.textHint, fontSize: 11, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 6),
                      Row(children: [
                        Icon(Icons.calendar_today_rounded, color: _kVerde, size: 14),
                        const SizedBox(width: 6),
                        Text(_fechaStr(), style: TextStyle(
                            color: dc.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
                      ]),
                    ])),
                    GestureDetector(
                      onTap: _seleccionarFecha,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _kVerde.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: const [
                          Icon(Icons.edit_calendar_rounded, color: _kVerde, size: 13),
                          SizedBox(width: 4),
                          Text('Editar', style: TextStyle(
                              color: _kVerde, fontSize: 11, fontWeight: FontWeight.w600)),
                        ]),
                      ),
                    ),
                  ]),
                ),
              ]),
            ),
          ),

          const SizedBox(height: 28),

          // ── BOTÓN REPORTAR ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity, height: 56,
              child: ElevatedButton(
                onPressed: _enviando ? null : _enviar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kVerde,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: _enviando
                    ? const SizedBox(width: 24, height: 24,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text('🚨', style: TextStyle(fontSize: 20)),
                        SizedBox(width: 10),
                        Text('Reportar alerta', style: TextStyle(
                            color: Colors.white, fontSize: 17,
                            fontWeight: FontWeight.bold, letterSpacing: 0.3)),
                      ]),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // ── NOTA PRIVACIDAD ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.lock_outline_rounded, size: 13,
                  color: _dc(context).textHint),
              const SizedBox(width: 5),
              Flexible(child: Text(
                'Tu información está segura y será revisada por el equipo de salud.',
                style: TextStyle(color: _dc(context).textHint, fontSize: 11),
                textAlign: TextAlign.center,
              )),
            ]),
          ),
        ]),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // BUILDERS INTERNOS
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildTipoChip(_Tipo t, DispersaludColors dc) {
    final sel = _tipoSel == t.id;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tipoSel = t.id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.only(right: 6, bottom: 0),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          decoration: BoxDecoration(
            color: sel ? t.color.withOpacity(0.12) : dc.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: sel ? t.color : dc.border,
                width: sel ? 2 : 1),
          ),
          child: Stack(alignment: Alignment.topRight, children: [
            Column(mainAxisSize: MainAxisSize.min, children: [
              Text(t.emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 5),
              Text(t.label, textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 10,
                      color: sel ? t.color : dc.textHint,
                      fontWeight: sel ? FontWeight.w700 : FontWeight.normal,
                      height: 1.2)),
            ]),
            if (sel)
              Container(
                width: 16, height: 16,
                margin: const EdgeInsets.only(right: 2, top: 2),
                decoration: BoxDecoration(color: t.color, shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 11),
              ),
          ]),
        ),
      ),
    );
  }

  Widget _buildRiesgoChip(_Riesgo r, DispersaludColors dc) {
    final sel = _riesgoSel == r.id;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _riesgoSel = r.id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: EdgeInsets.only(right: r == _kRiesgos.last ? 0 : 6),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            color: sel ? r.color.withOpacity(0.10) : dc.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: sel ? r.color : dc.border,
                width: sel ? 2 : 1),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(r.icon, color: r.color, size: 20),
            const SizedBox(height: 4),
            Text(r.label, style: TextStyle(
                fontSize: 11, color: r.color,
                fontWeight: sel ? FontWeight.w700 : FontWeight.normal)),
          ]),
        ),
      ),
    );
  }

  Widget _btnFoto({
    required IconData icono, required String titulo, required String subtitulo,
    required Color color, required DispersaludColors dc,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: dc.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: onTap != null ? color.withOpacity(0.4) : dc.border,
            style: BorderStyle.solid,
            width: 1.5,
          ),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icono, color: onTap != null ? color : dc.textHint, size: 22),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(titulo, style: TextStyle(
                color: onTap != null ? color : dc.textHint,
                fontSize: 13, fontWeight: FontWeight.w700)),
            Text(subtitulo, style: TextStyle(color: dc.textHint, fontSize: 10)),
          ]),
        ]),
      ),
    );
  }

  // ── Encabezados de sección ─────────────────────────────────────────────────
  Widget _secTitulo(DispersaludColors dc, String emoji, String titulo) =>
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Row(children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Text(titulo, style: TextStyle(
              color: dc.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
        ]),
      );

  Widget _secTituloOpcional(DispersaludColors dc, String emoji,
      String titulo, String tag) =>
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Row(children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Text(titulo, style: TextStyle(
              color: dc.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(width: 6),
          Text(tag, style: TextStyle(color: dc.textHint, fontSize: 12)),
        ]),
      );

  // ── Diálogo de ayuda ───────────────────────────────────────────────────────
  void _mostrarAyuda() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _dc(context).card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(children: [
          Container(width: 36, height: 36,
            decoration: BoxDecoration(
                color: _kVerde.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.help_outline_rounded, color: _kVerde, size: 20)),
          const SizedBox(width: 10),
          const Text('¿Cómo funciona?', style: TextStyle(fontSize: 16)),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          _ayudaItem('1.', 'Selecciona el tipo de alerta según el grupo de población afectado.'),
          _ayudaItem('2.', 'Elige el nivel de riesgo que mejor describe la situación.'),
          _ayudaItem('3.', 'Describe con detalle los síntomas o la situación observada.'),
          _ayudaItem('4.', 'Adjunta fotos como evidencia opcional (máx. 3).'),
          _ayudaItem('5.', 'Confirma la ubicación y fecha del evento.'),
          _ayudaItem('6.', 'Toca "Reportar alerta" para enviar. Tu información es confidencial.'),
        ]),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
                backgroundColor: _kVerde, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  Widget _ayudaItem(String num, String texto) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(num, style: const TextStyle(color: _kVerde,
          fontWeight: FontWeight.bold, fontSize: 13)),
      const SizedBox(width: 8),
      Expanded(child: Text(texto, style: TextStyle(
          color: _dc(context).textSecondary, fontSize: 13, height: 1.4))),
    ]),
  );
}