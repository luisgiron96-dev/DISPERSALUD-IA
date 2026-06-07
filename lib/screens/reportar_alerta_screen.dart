import 'package:flutter/material.dart';
import '../../core/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PANTALLA: REPORTAR ALERTA  (independiente del módulo de alertas)
// Ubicación sugerida: lib/screens/reportar_alerta_screen.dart
// ─────────────────────────────────────────────────────────────────────────────

const Color _kVerde      = Color(0xFF1D9E75);
const Color _kVerdeOscuro = Color(0xFF0A5240);

class ReportarAlertaScreen extends StatefulWidget {
  const ReportarAlertaScreen({super.key});

  @override
  State<ReportarAlertaScreen> createState() => _ReportarAlertaScreenState();
}

class _ReportarAlertaScreenState extends State<ReportarAlertaScreen> {
  // ── Estado ────────────────────────────────────────────────────────────────
  String _tipoSeleccionado   = 'gestacion';
  String _riesgoSeleccionado = 'bajo';
  final TextEditingController _descripcionCtrl = TextEditingController();

  // ── Tipos de alerta ───────────────────────────────────────────────────────
  static const _tipos = [
    {'id': 'gestacion',   'label': 'Gestación',     'emoji': '🤰', 'color': 0xFF993556},
    {'id': 'vacunacion',  'label': 'Vacunación',    'emoji': '💉', 'color': 0xFFE07B00},
    {'id': 'infancia',    'label': 'Infancia',      'emoji': '🧒', 'color': 0xFF185FA5},
    {'id': 'adolescencia','label': 'Adolescencia',  'emoji': '🧑', 'color': 0xFF534AB7},
    {'id': 'adulto',      'label': 'Adulto mayor',  'emoji': '🧓', 'color': 0xFF3B6D11},
  ];

  // ── Niveles de riesgo ─────────────────────────────────────────────────────
  static const _riesgos = [
    {'id': 'bajo',  'label': 'Bajo',  'icon': Icons.shield_outlined,      'color': 0xFF1D9E75},
    {'id': 'medio', 'label': 'Medio', 'icon': Icons.shield_moon_outlined,  'color': 0xFFE07B00},
    {'id': 'alto',  'label': 'Alto',  'icon': Icons.shield_outlined,       'color': 0xFFE24B4A},
    {'id': 'nose',  'label': 'No sé', 'icon': Icons.help_outline_rounded,  'color': 0xFF888888},
  ];

  @override
  void dispose() {
    _descripcionCtrl.dispose();
    super.dispose();
  }

  void _enviarAlerta() {
    if (_descripcionCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Por favor describe la situación antes de enviar.'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    // ── Aquí puedes guardar en base de datos o enviar al servidor ──────────
    // Ejemplo: DatabaseHelper.instance.insertarAlerta({ ... });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('¡Alerta enviada! El equipo de salud revisará tu reporte.'),
        backgroundColor: _kVerde,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    Navigator.pop(context);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final dc = Theme.of(context).extension<DispersaludColors>() ??
        DispersaludColors.dark;

    return Scaffold(
      backgroundColor: dc.bg,
      // ── APP BAR ──────────────────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: dc.card,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: dc.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reportar alerta',
              style: TextStyle(
                color: dc.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Cuéntanos qué está sucediendo',
              style: TextStyle(color: dc.textHint, fontSize: 12),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: OutlinedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('¿Cómo funciona?'),
                    content: const Text(
                      'Completa los 6 pasos para reportar una situación de salud '
                      'en tu comunidad. Tu información es confidencial y será '
                      'revisada por el equipo de salud.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Entendido',
                            style: TextStyle(color: _kVerde)),
                      ),
                    ],
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: _kVerde, width: 1.5),
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(4),
                minimumSize: Size.zero,
              ),
              child: const Text('i',
                  style: TextStyle(
                      color: _kVerde,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.bold)),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: dc.border),
        ),
      ),

      // ── CUERPO ───────────────────────────────────────────────────────────
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          children: [

            // ── PASO 1: TIPO DE ALERTA ────────────────────────────────────
            _Seccion(
              numero: 1,
              titulo: 'Tipo de alerta',
              dc: dc,
              child: Row(
                children: _tipos.map((t) {
                  final activo = _tipoSeleccionado == t['id'];
                  return Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _tipoSeleccionado = t['id'] as String),
                      child: Container(
                        margin: EdgeInsets.only(
                            right: t == _tipos.last ? 0 : 6),
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 4),
                        decoration: BoxDecoration(
                          color: dc.card,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: activo
                                ? _kVerde
                                : dc.border,
                            width: activo ? 2 : 1,
                          ),
                        ),
                        child: Stack(
                          alignment: Alignment.topRight,
                          children: [
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(t['emoji'] as String,
                                    style: const TextStyle(fontSize: 22)),
                                const SizedBox(height: 5),
                                Text(
                                  t['label'] as String,
                                  style: TextStyle(
                                      fontSize: 9.5,
                                      color: dc.textHint,
                                      height: 1.2),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                            if (activo)
                              Container(
                                width: 15, height: 15,
                                margin: const EdgeInsets.only(right: 2, top: 2),
                                decoration: const BoxDecoration(
                                  color: _kVerde,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.check,
                                    color: Colors.white, size: 10),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // ── PASO 2: NIVEL DE RIESGO ───────────────────────────────────
            _Seccion(
              numero: 2,
              titulo: 'Nivel de riesgo',
              dc: dc,
              child: Row(
                children: _riesgos.map((r) {
                  final activo = _riesgoSeleccionado == r['id'];
                  final color  = Color(r['color'] as int);
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(
                          () => _riesgoSeleccionado = r['id'] as String),
                      child: Container(
                        margin: EdgeInsets.only(
                            right: r == _riesgos.last ? 0 : 6),
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 4),
                        decoration: BoxDecoration(
                          color: activo
                              ? color.withOpacity(0.08)
                              : dc.card,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: activo ? color : dc.border,
                            width: activo ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(r['icon'] as IconData,
                                color: color, size: 18),
                            const SizedBox(height: 4),
                            Text(
                              r['label'] as String,
                              style: TextStyle(
                                fontSize: 11,
                                color: color,
                                fontWeight: activo
                                    ? FontWeight.w700
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // ── PASO 3: DESCRIBE LA SITUACIÓN ─────────────────────────────
            _Seccion(
              numero: 3,
              titulo: 'Describe la situación',
              dc: dc,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  TextField(
                    controller: _descripcionCtrl,
                    maxLength: 500,
                    maxLines: 4,
                    onChanged: (_) => setState(() {}),
                    style: TextStyle(color: dc.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Escribe aquí la situación o los síntomas...',
                      hintStyle:
                          TextStyle(color: dc.textHint, fontSize: 13),
                      counterText: '',
                      filled: true,
                      fillColor: dc.bg,
                      contentPadding: const EdgeInsets.all(14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: dc.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: dc.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: _kVerde, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_descripcionCtrl.text.length}/500',
                    style:
                        TextStyle(color: dc.textHint, fontSize: 11),
                  ),
                ],
              ),
            ),

            // ── PASO 4: INFORMACIÓN ADICIONAL ─────────────────────────────
            _Seccion(
              numero: 4,
              titulo: 'Información adicional',
              opcional: true,
              dc: dc,
              child: _FilaInfo(
                icono: Icons.camera_alt_outlined,
                titulo: 'Agregar foto',
                subtitulo: 'Máx. 3 fotos',
                dc: dc,
                onTap: () {
                  // TODO: abrir selector de imágenes
                  // ImagePicker().pickImage(source: ImageSource.gallery);
                },
              ),
            ),

            // ── PASO 5: UBICACIÓN ──────────────────────────────────────────
            _Seccion(
              numero: 5,
              titulo: 'Ubicación',
              dc: dc,
              child: _FilaInfo(
                icono: Icons.location_on_outlined,
                titulo: 'Vereda El Palmar - Cauca',
                dc: dc,
                onTap: () {
                  // TODO: abrir selector de ubicación
                },
              ),
            ),

            // ── PASO 6: FECHA Y HORA ───────────────────────────────────────
            _Seccion(
              numero: 6,
              titulo: 'Fecha y hora',
              dc: dc,
              child: _FilaInfo(
                icono: Icons.calendar_today_outlined,
                titulo: _fechaFormateada(),
                dc: dc,
                onTap: () async {
                  // TODO: abrir DateTimePicker
                },
              ),
            ),

            // ── BOTÓN ENVIAR ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _enviarAlerta,
                  icon: const Icon(Icons.send_rounded,
                      color: Colors.white, size: 20),
                  label: const Text(
                    'Enviar alerta',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kVerdeOscuro,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                ),
              ),
            ),

            // ── NOTA DE PRIVACIDAD ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline_rounded,
                      size: 12,
                      color: Theme.of(context)
                          .extension<DispersaludColors>()!
                          .textHint),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      'Tu información está segura y será revisada por el equipo de salud.',
                      style: TextStyle(
                          color: Theme.of(context)
                              .extension<DispersaludColors>()!
                              .textHint,
                          fontSize: 11),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fechaFormateada() {
    final now = DateTime.now();
    const meses = [
      '', 'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    final h  = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final m  = now.minute.toString().padLeft(2, '0');
    final ap = now.hour < 12 ? 'a. m.' : 'p. m.';
    return '${now.day} ${meses[now.month]} ${now.year} - $h:$m $ap';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WIDGET: Sección numerada
// ─────────────────────────────────────────────────────────────────────────────
class _Seccion extends StatelessWidget {
  final int    numero;
  final String titulo;
  final bool   opcional;
  final Widget child;
  final DispersaludColors dc;

  const _Seccion({
    required this.numero,
    required this.titulo,
    required this.child,
    required this.dc,
    this.opcional = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: dc.card,
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26, height: 26,
                decoration: const BoxDecoration(
                  color: _kVerde, shape: BoxShape.circle),
                child: Center(
                  child: Text('$numero',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 10),
              Text(titulo,
                  style: TextStyle(
                      color: dc.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
              if (opcional) ...[
                const SizedBox(width: 6),
                Text('(opcional)',
                    style:
                        TextStyle(color: dc.textHint, fontSize: 12)),
              ],
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WIDGET: Fila de información (foto, ubicación, fecha)
// ─────────────────────────────────────────────────────────────────────────────
class _FilaInfo extends StatelessWidget {
  final IconData icono;
  final String   titulo;
  final String?  subtitulo;
  final VoidCallback onTap;
  final DispersaludColors dc;

  const _FilaInfo({
    required this.icono,
    required this.titulo,
    required this.onTap,
    required this.dc,
    this.subtitulo,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: dc.border),
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: _kVerde.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icono, color: _kVerde, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo,
                      style: TextStyle(
                          color: dc.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500)),
                  if (subtitulo != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitulo!,
                        style: TextStyle(
                            color: dc.textHint, fontSize: 12)),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: dc.textHint, size: 20),
          ],
        ),
      ),
    );
  }
}