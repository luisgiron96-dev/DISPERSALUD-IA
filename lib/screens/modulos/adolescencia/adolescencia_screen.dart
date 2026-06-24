import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/app_theme.dart';
import '../../../database/database_helper.dart';
import '../../../services/sivigila_service.dart';

const Color _kColor = Color(0xFF534AB7);

class AdolescenciaScreen extends StatefulWidget {
  final int?    pacienteId;
  final String? pacienteNombre;
  const AdolescenciaScreen({super.key, this.pacienteId, this.pacienteNombre});
  @override
  State<AdolescenciaScreen> createState() => _AdolescenciaScreenState();
}

class _AdolescenciaScreenState extends State<AdolescenciaScreen> {
  final _nombreCtrl  = TextEditingController(text: '');
  final _edadCtrl    = TextEditingController(text: '15 años');
  final _pesoCtrl    = TextEditingController(text: '52');
  final _tallaCtrl   = TextEditingController(text: '160');
  final _presionCtrl = TextEditingController(text: '110/70');
  final _tempCtrl    = TextEditingController(text: '36.7');

  bool _vph1              = true;
  bool _vph2              = false;
  bool _tamizajeITS       = false;
  bool _sinViolencia      = true;
  bool _redApoyo          = true;
  bool _tabacoOSustancias = false;
  bool _anticoncepcion    = false;

  String _diagnostico = '';
  // ignore: unused_field
  String _nivelRiesgo = '';
  Color  _colorDx     = Colors.green;
  bool   _guardando   = false;

  int?    _pacienteId;
  String  _pacienteNombre = 'Sin paciente seleccionado';
  List<Map<String, dynamic>> _listaPacientes = [];

  @override
  void initState() {
    super.initState();
    _pacienteId     = widget.pacienteId;
    _pacienteNombre = widget.pacienteNombre ?? 'Sin paciente seleccionado';
    _cargarPacientes();
  }

  Future<void> _cargarPacientes() async {
    final lista = await DatabaseHelper.instance.obtenerPacientes();
    setState(() => _listaPacientes = lista);
  }

  Future<void> _seleccionarPaciente() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: DT(context).card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        final dc = DT(ctx);
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.55,
          maxChildSize: 0.90,
          minChildSize: 0.35,
          builder: (_, scrollCtrl) => Column(children: [
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              width: 36, height: 4,
              decoration: BoxDecoration(
                  color: dc.border, borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text('Seleccionar paciente',
                  style: TextStyle(
                      color: dc.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: _listaPacientes.isEmpty
                  ? Center(
                      child: Text(
                        'No hay pacientes.\nRegistra uno en la pestaña Pacientes.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: dc.textHint),
                      ))
                  : ListView.builder(
                      controller: scrollCtrl,
                      itemCount: _listaPacientes.length,
                      itemBuilder: (_, i) {
                        final p = _listaPacientes[i];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _kColor.withValues(alpha: 0.2),
                            child: Text(
                              (p['nombre'] as String)[0].toUpperCase(),
                              style: const TextStyle(
                                  color: _kColor,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(p['nombre'] ?? '',
                              style: TextStyle(color: dc.textPrimary)),
                          subtitle: Text(
                            '${p['vereda'] ?? ''} · ${p['municipio'] ?? ''}',
                            style:
                                TextStyle(color: dc.textHint, fontSize: 12),
                          ),
                          onTap: () {
                            setState(() {
                              _pacienteId     = p['id'];
                              _pacienteNombre = p['nombre'];
                            });
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
            ),
          ]),
        );
      },
    );
  }

  Future<void> _analizarYGuardar() async {
    final presionSis = int.tryParse(_presionCtrl.text.split('/').first) ?? 0;
    final presionDia = int.tryParse(_presionCtrl.text.split('/').last)  ?? 0;
    final peso       = double.tryParse(_pesoCtrl.text)  ?? 0;
    final talla      = double.tryParse(_tallaCtrl.text) ?? 1;
    final temp       = double.tryParse(_tempCtrl.text)  ?? 0;
    final imc        = talla > 0 ? peso / ((talla / 100) * (talla / 100)) : 0;

    // Reglas clínicas — Protocolo MINSALUD Adolescencia 10–17 años
    String dx; String nivel; Color color;

    if (!_sinViolencia) {
      dx    = '🚨 URGENTE: Reporte de violencia. Activar ruta integral, notificar a ICBF y comisaría. No enviar a casa sin verificar seguridad.';
      nivel = 'urgente'; color = Colors.red;
    } else if (temp >= 38.5) {
      dx    = '🌡️ Fiebre alta (${temp}°C). Descartar dengue, malaria o ITS. Hemograma urgente. Hidratación oral.';
      nivel = 'urgente'; color = Colors.red;
    } else if (presionSis >= 140 || presionDia >= 90) {
      dx    = '⚠️ HTA en adolescente ($_presionCtrl.text mmHg). Descartar causa secundaria (renal, endocrina). Remisión médica prioritaria.';
      nivel = 'urgente'; color = Colors.red;
    } else if (imc < 16.0) {
      dx    = '🚨 Desnutrición severa (IMC ${imc.toStringAsFixed(1)}). Riesgo vital. Remisión urgente a nutrición y psicología. Evaluar trastorno alimentario.';
      nivel = 'urgente'; color = Colors.red;
    } else if (_tabacoOSustancias) {
      dx    = '🚭 Consumo de SPA reportado. Activar ruta salud mental. Orientar a programa CAMAD. Involucrar familia.';
      nivel = 'alerta'; color = Colors.orange;
    } else if (presionSis >= 120 || presionDia >= 80) {
      dx    = '⚠️ Presión limítrofe (${_presionCtrl.text} mmHg). Repetir en 2 semanas. Reducir sal y aumentar actividad física.';
      nivel = 'alerta'; color = Colors.orange;
    } else if (imc < 18.5) {
      dx    = '⚖️ Bajo peso (IMC ${imc.toStringAsFixed(1)}). Consejería nutricional. Control en 1 mes.';
      nivel = 'alerta'; color = Colors.orange;
    } else if (imc >= 30.0) {
      dx    = '⚖️ Obesidad (IMC ${imc.toStringAsFixed(1)}). Riesgo síndrome metabólico. Plan nutricional + actividad física + apoyo psicosocial.';
      nivel = 'alerta'; color = Colors.orange;
    } else if (!_vph1 || !_vph2) {
      dx    = '💉 Esquema VPH incompleto. Completar según PAI. Previene cáncer de cuello uterino.';
      nivel = 'alerta'; color = Colors.orange;
    } else if (!_redApoyo) {
      dx    = '🤝 Sin red de apoyo familiar. Riesgo psicosocial. Remitir a trabajo social y salud mental.';
      nivel = 'alerta'; color = Colors.orange;
    } else if (!_tamizajeITS) {
      dx    = '🔬 Tamizaje ITS/VIH pendiente. Solicitar prueba VIH, sífilis y hepatitis B según protocolo MINSALUD.';
      nivel = 'alerta'; color = Colors.orange;
    } else {
      dx    = '✅ Adolescente saludable. Reforzar proyecto de vida y salud sexual responsable. Próximo control en 6 meses.';
      nivel = 'normal'; color = Colors.green;
    }

    setState(() {
      _diagnostico = dx;
      _nivelRiesgo = nivel;
      _colorDx     = color;
    });

    if (_pacienteId != null) {
      setState(() => _guardando = true);
      final datos = {
        'nombre':           _nombreCtrl.text,
        'edad':             _edadCtrl.text,
        'peso':             _pesoCtrl.text,
        'talla':            _tallaCtrl.text,
        'presion':          _presionCtrl.text,
        'temp':             _tempCtrl.text,
        'vph1':             _vph1,
        'vph2':             _vph2,
        'tamizajeITS':      _tamizajeITS,
        'sinViolencia':     _sinViolencia,
        'redApoyo':         _redApoyo,
        'tabacoOSustancias':_tabacoOSustancias,
        'anticoncepcion':   _anticoncepcion,
      };
      await DatabaseHelper.instance.insertarConsulta({
        'paciente_id':  _pacienteId,
        'modulo':       'Adolescencia',
        'fecha':        DateTime.now().toIso8601String(),
        'datos_json':   jsonEncode(datos),
        'diagnostico':  dx,
        'nivel_riesgo': nivel,
      });
      // ── SIVIGILA: detectar enfermedades de notificación obligatoria ──
      await SivigilaService.instance.evaluarDiagnostico(
        diagnostico: dx,
        paciente:    _pacienteNombre,
        modulo:      'Adolescencia',
      );
      setState(() => _guardando = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Consulta guardada para $_pacienteNombre ✓'),
          backgroundColor: _kColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('⚠️ Selecciona un paciente para guardar la consulta'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  @override
  void dispose() {
    for (final c in [_nombreCtrl, _edadCtrl, _pesoCtrl,
                     _tallaCtrl, _presionCtrl, _tempCtrl]) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dt = DT(context);
    return Scaffold(
      backgroundColor: dt.bg,
      appBar: AppBar(
        backgroundColor: _kColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Adolescencia',
              style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
          Text('12–17 años · Salud sexual y mental · DISPERSALUD IA',
              style: TextStyle(color: Colors.white70, fontSize: 11)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(children: [

          // ── Selector paciente ──────────────────────────────────────
          GestureDetector(
            onTap: _seleccionarPaciente,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _pacienteId != null
                    ? _kColor.withValues(alpha: 0.15)
                    : dt.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: _pacienteId != null ? _kColor : dt.border),
              ),
              child: Row(children: [
                Icon(
                  _pacienteId != null
                      ? Icons.person_rounded
                      : Icons.person_add_outlined,
                  color: _pacienteId != null ? _kColor : dt.textHint,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(
                    _pacienteId != null
                        ? 'Paciente seleccionado'
                        : 'Seleccionar paciente',
                    style: TextStyle(
                        color: _pacienteId != null
                            ? _kColor
                            : dt.textSecondary,
                        fontSize: 11),
                  ),
                  Text(
                    _pacienteNombre,
                    style: TextStyle(
                        color: _pacienteId != null
                            ? dt.textPrimary
                            : dt.textHint,
                        fontSize: 14,
                        fontWeight: FontWeight.w600),
                  ),
                ])),
                Icon(Icons.chevron_right,
                    color: _pacienteId != null ? _kColor : dt.textHint,
                    size: 20),
              ]),
            ),
          ),
          const SizedBox(height: 14),

          // ── Datos del paciente ─────────────────────────────────────
          _Card(titulo: 'Datos del paciente', child: Column(children: [
            Row(children: [
              Expanded(child: _Campo(label: 'Nombre completo', controller: _nombreCtrl)),
              const SizedBox(width: 12),
              Expanded(child: _Campo(label: 'Edad', controller: _edadCtrl)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _Campo(label: 'Peso (kg)', controller: _pesoCtrl)),
              const SizedBox(width: 12),
              Expanded(child: _Campo(label: 'Talla (cm)', controller: _tallaCtrl)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _Campo(label: 'Presión arterial', controller: _presionCtrl)),
              const SizedBox(width: 12),
              Expanded(child: _Campo(label: 'Temperatura (°C)', controller: _tempCtrl)),
            ]),
          ])),
          const SizedBox(height: 14),

          // ── Lista de chequeo ───────────────────────────────────────
          _Card(titulo: 'Lista de chequeo', child: Column(children: [
            _CheckItem(texto: 'VPH 1.ª dosis aplicada',               activo: _vph1,              color: Colors.green,  onChanged: (v) => setState(() => _vph1 = v)),
            _CheckItem(texto: 'VPH 2.ª dosis aplicada',               activo: _vph2,              color: Colors.orange, onChanged: (v) => setState(() => _vph2 = v)),
            _CheckItem(texto: 'Tamizaje ITS / VIH realizado',          activo: _tamizajeITS,       color: Colors.orange, onChanged: (v) => setState(() => _tamizajeITS = v)),
            _CheckItem(texto: 'Sin reporte de violencia',              activo: _sinViolencia,      color: Colors.green,  onChanged: (v) => setState(() => _sinViolencia = v)),
            _CheckItem(texto: 'Cuenta con red de apoyo familiar',      activo: _redApoyo,          color: Colors.green,  onChanged: (v) => setState(() => _redApoyo = v)),
            _CheckItem(texto: 'Consumo de tabaco o sustancias',        activo: _tabacoOSustancias, color: Colors.red,    onChanged: (v) => setState(() => _tabacoOSustancias = v)),
            _CheckItem(texto: 'Asesoría en anticoncepción brindada',   activo: _anticoncepcion,    color: Colors.blue,   onChanged: (v) => setState(() => _anticoncepcion = v)),
          ])),

          // ── Diagnóstico IA ─────────────────────────────────────────
          if (_diagnostico.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _colorDx.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _colorDx.withValues(alpha: 0.5)),
              ),
              child: Text(_diagnostico,
                  style: TextStyle(
                      color: _colorDx,
                      fontSize: 14,
                      fontWeight: FontWeight.w500)),
            ),
          ],
          const SizedBox(height: 20),

          // ── Botones ────────────────────────────────────────────────
          SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton.icon(
              onPressed: _guardando ? null : _analizarYGuardar,
              icon: _guardando
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.psychology_outlined, color: Colors.white),
              label: Text(
                _guardando ? 'Guardando...' : 'Analizar y guardar',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity, height: 52,
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: Icon(Icons.local_hospital_outlined,
                  color: dt.textSecondary),
              label: Text('Remitir a salud mental',
                  style: TextStyle(color: dt.textSecondary, fontSize: 15)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: dt.border),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }
}

// ── Widgets auxiliares — cada uno llama DT(context) en su propio build ────────

class _Card extends StatelessWidget {
  final String titulo;
  final Widget child;
  const _Card({required this.titulo, required this.child});

  @override
  Widget build(BuildContext context) {
    final dt = DT(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dt.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: dt.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(titulo,
            style: TextStyle(
                color: dt.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 14),
        child,
      ]),
    );
  }
}

class _Campo extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  const _Campo({required this.label, required this.controller});

  @override
  Widget build(BuildContext context) {
    final dt = DT(context); // ← aquí estaba el error: usaba dc sin definirlo
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: dt.textHint, fontSize: 11)),
      const SizedBox(height: 4),
      TextField(
        controller: controller,
        style: TextStyle(
            color: dt.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          filled: true,
          fillColor: dt.border.withValues(alpha: 0.4),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none),
        ),
      ),
    ]);
  }
}

class _CheckItem extends StatelessWidget {
  final String texto;
  final bool activo;
  final Color color;
  final ValueChanged<bool> onChanged;
  const _CheckItem({
    required this.texto,
    required this.activo,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final dt = DT(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => onChanged(!activo),
        child: Row(children: [
          Icon(
            activo
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            color: activo ? color : dt.border,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(texto,
                style: TextStyle(
                    color: activo ? dt.textPrimary : dt.textHint,
                    fontSize: 13)),
          ),
        ]),
      ),
    );
  }
}