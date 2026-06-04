import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../core/app_theme.dart';
import '../database/database_helper.dart';
import '../services/connectivity_service.dart';
import '../main.dart' show temaNotifier, temaDesdeString; // ← FIX 1: importa el notifier

const Color _kVerde = Color(0xFF1D9E75);

DispersaludColors _c(BuildContext ctx) =>
    Theme.of(ctx).extension<DispersaludColors>() ?? DispersaludColors.dark;

class ConfigScreen extends StatefulWidget {
  ConfigScreen({super.key});
  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen>
    with WidgetsBindingObserver {
  // Perfil
  String _nombre       = '';
  String _vereda       = '';
  String _municipio    = '';
  String _departamento = '';

  // Preferencias
  bool   _vozActiva = true;
  bool   _alertas   = true;
  String _tema      = 'Sistema';

  // Conectividad
  bool _online = false;
  StreamSubscription<bool>? _connSub;

  // Estado de operaciones
  bool _exportando    = false;
  bool _sincronizando = false;
  bool _creandoCopia  = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cargar();
    _initConectividad();
  }

  // ── FIX 2: conectar al ConnectivityService real ──────────────────────────
  Future<void> _initConectividad() async {
    // Leer estado actual del singleton (ya inicializado en main)
    final actual = ConnectivityService.instance.tieneInternet;
    if (mounted) setState(() => _online = actual);

    // Suscribirse al stream de cambios en tiempo real
    _connSub = ConnectivityService.instance.cambios.listen((v) {
      if (mounted) setState(() => _online = v);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _cargar();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connSub?.cancel();
    super.dispose();
  }

  Future<void> _cargar() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _nombre       = p.getString('promotor_nombre')       ?? '';
      _vereda       = p.getString('promotor_vereda')       ?? '';
      _municipio    = p.getString('promotor_municipio')    ?? '';
      _departamento = p.getString('promotor_departamento') ?? '';
      _vozActiva    = p.getBool('voz_activa')              ?? true;
      _alertas      = p.getBool('alertas_activas')         ?? true;
      _tema         = p.getString('tema_app')              ?? 'Sistema';
    });
  }

  Future<void> _pref(String k, dynamic v) async {
    final p = await SharedPreferences.getInstance();
    if (v is bool)   await p.setBool(k, v);
    if (v is String) await p.setString(k, v);
  }

  void _snack(String msg, {bool error = false, bool info = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(
          error ? Icons.error_outline : info
              ? Icons.info_outline : Icons.check_circle_outline,
          color: Colors.white, size: 18,
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(msg, style: const TextStyle(fontSize: 13))),
      ]),
      backgroundColor: error ? Colors.red : info
          ? const Color(0xFF185FA5) : _kVerde,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 3),
    ));
  }

  Future<void> _verificarConectividad() async {
    _snack('Verificando conexión...', info: true);
    final v = await ConnectivityService.instance.verificarAhora();
    if (mounted) setState(() => _online = v);
    _snack(_online ? '✓ Conexión activa' : 'Sin conexión a internet');
  }

  Future<void> _sincronizar() async {
    if (!_online) {
      _snack('Sin conexión. Los datos se sincronizarán automáticamente al reconectarse.', info: true);
      return;
    }
    if (_sincronizando) return;
    setState(() => _sincronizando = true);
    try {
      final pendientes = await DatabaseHelper.instance.obtenerConsultasPendientesSync();
      if (pendientes.isEmpty) {
        _snack('Todo está sincronizado. Sin registros pendientes.');
        setState(() => _sincronizando = false);
        return;
      }
      int sincronizados = 0;
      for (final consulta in pendientes) {
        await DatabaseHelper.instance.marcarConsultaSincronizada(consulta['id']);
        sincronizados++;
        await Future.delayed(const Duration(milliseconds: 100));
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('ultima_sincronizacion', DateTime.now().toIso8601String());
      _snack('✓ $sincronizados registro${sincronizados == 1 ? '' : 's'} sincronizado${sincronizados == 1 ? '' : 's'}');
    } catch (e) {
      _snack('Error al sincronizar: $e', error: true);
    } finally {
      if (mounted) setState(() => _sincronizando = false);
    }
  }

  Future<void> _exportarPDF() async {
    if (_exportando) return;
    setState(() => _exportando = true);
    _snack('Generando PDF...', info: true);
    try {
      final pacientes = await DatabaseHelper.instance.obtenerPacientes();
      final consultas = await DatabaseHelper.instance.obtenerConsultas();
      final alertas   = await DatabaseHelper.instance.obtenerAlertas(soloActivas: false);
      final resumen   = await DatabaseHelper.instance.resumenGeneral();
      final pdf       = pw.Document();
      final ahora     = DateTime.now();
      final fecha     = '${ahora.day}/${ahora.month}/${ahora.year}';
      final hora      = '${ahora.hour.toString().padLeft(2,'0')}:${ahora.minute.toString().padLeft(2,'0')}';
      final verde     = PdfColor.fromHex('1D9E75');
      final oscuro    = PdfColor.fromHex('0F6E56');
      final gris      = PdfColor.fromHex('6B7280');

      pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (ctx) => pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 12),
          decoration: pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: verde, width: 2))),
          child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text('DISPERSALUD IA', style: pw.TextStyle(color: verde, fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.Text('Informe de registros · Salud rural Colombia', style: pw.TextStyle(color: gris, fontSize: 9)),
            ]),
            pw.Text('$fecha  $hora', style: pw.TextStyle(color: gris, fontSize: 9)),
          ]),
        ),
        footer: (ctx) => pw.Container(
          padding: const pw.EdgeInsets.only(top: 8),
          decoration: pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300))),
          child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            pw.Text('${_nombre.isNotEmpty ? _nombre : "Promotor/a"} · ${_vereda.isNotEmpty ? "$_vereda · " : ""}$_municipio',
                style: pw.TextStyle(color: gris, fontSize: 8)),
            pw.Text('Página ${ctx.pageNumber} de ${ctx.pagesCount}', style: pw.TextStyle(color: gris, fontSize: 8)),
          ]),
        ),
        build: (ctx) => [
          pw.Container(
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(color: verde, borderRadius: pw.BorderRadius.circular(8)),
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text('Informe General de Salud Rural', style: pw.TextStyle(color: PdfColors.white, fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              pw.Text('${_nombre.isNotEmpty ? _nombre : "Promotor/a"}${_vereda.isNotEmpty ? " · $_vereda · $_municipio" : ""}',
                  style: pw.TextStyle(color: PdfColors.white, fontSize: 11)),
              pw.SizedBox(height: 2),
              pw.Text('Generado el $fecha a las $hora', style: pw.TextStyle(color: const PdfColor(1, 1, 1, 0.7), fontSize: 10)),
            ]),
          ),
          pw.SizedBox(height: 24),
          pw.Text('Resumen ejecutivo', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: oscuro)),
          pw.SizedBox(height: 12),
          pw.Row(children: [
            _pdfStatBox('Pacientes', '${resumen['pacientes'] ?? pacientes.length}', verde),
            pw.SizedBox(width: 10),
            _pdfStatBox('Consultas', '${resumen['consultas'] ?? consultas.length}', oscuro),
            pw.SizedBox(width: 10),
            _pdfStatBox('Alertas', '${alertas.length}', PdfColor.fromHex('E24B4A')),
          ]),
          pw.SizedBox(height: 24),
          if (pacientes.isNotEmpty) ...[
            pw.Text('Registro de pacientes', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: oscuro)),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headers: ['Nombre', 'Módulo', 'Vereda', 'Municipio', 'Documento'],
              data: pacientes.take(50).map((p) => [p['nombre']??'', p['modulo']??'', p['vereda']??'', p['municipio']??'', p['documento']??'']).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 9),
              headerDecoration: pw.BoxDecoration(color: verde),
              oddRowDecoration: pw.BoxDecoration(color: PdfColor.fromHex('F0FDF4')),
              cellStyle: pw.TextStyle(fontSize: 9, color: gris),
            ),
            pw.SizedBox(height: 16),
          ],
          if (consultas.isNotEmpty) ...[
            pw.Text('Consultas registradas', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: oscuro)),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headers: ['Paciente', 'Módulo', 'Nivel riesgo', 'Fecha'],
              data: consultas.take(50).map((c) => [c['nombre']??c['paciente_nombre']??'', c['modulo']??'', c['nivel_riesgo']??'Estable', _formatFecha(c['fecha'] as String?)]).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 9),
              headerDecoration: pw.BoxDecoration(color: oscuro),
              oddRowDecoration: pw.BoxDecoration(color: PdfColor.fromHex('F0FDF4')),
              cellStyle: pw.TextStyle(fontSize: 9, color: gris),
            ),
          ],
        ],
      ));

      await Printing.layoutPdf(
        onLayout: (_) async => pdf.save(),
        name: 'DISPERSALUD_IA_${ahora.year}${ahora.month}${ahora.day}.pdf',
      );
      _snack('✓ PDF generado correctamente');
    } catch (e) {
      _snack('Error al generar PDF: $e', error: true);
    } finally {
      if (mounted) setState(() => _exportando = false);
    }
  }

  pw.Widget _pdfStatBox(String label, String valor, PdfColor color) =>
      pw.Expanded(child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: pw.BoxDecoration(color: color, borderRadius: pw.BorderRadius.circular(8)),
        child: pw.Column(children: [
          pw.Text(valor, style: pw.TextStyle(color: PdfColors.white, fontSize: 22, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text(label, style: pw.TextStyle(color: const PdfColor(1, 1, 1, 0.7), fontSize: 10)),
        ]),
      ));

  String _formatFecha(String? iso) {
    if (iso == null) return '';
    try { final dt = DateTime.parse(iso); return '${dt.day}/${dt.month}/${dt.year}'; }
    catch (_) { return iso; }
  }

  Future<void> _crearCopia() async {
    if (_creandoCopia) return;
    setState(() => _creandoCopia = true);
    _snack('Creando copia de seguridad...', info: true);
    try {
      final pacientes = await DatabaseHelper.instance.obtenerPacientes();
      final consultas = await DatabaseHelper.instance.obtenerConsultas();
      final alertas   = await DatabaseHelper.instance.obtenerAlertas(soloActivas: false);
      final prefs     = await SharedPreferences.getInstance();
      final ahora     = DateTime.now();
      final backup = {
        'version': '1.0', 'app': 'DISPERSALUD IA',
        'promotor': _nombre, 'vereda': _vereda, 'municipio': _municipio,
        'fecha_backup': ahora.toIso8601String(),
        'datos': { 'pacientes': pacientes, 'consultas': consultas, 'alertas': alertas,
          'preferencias': { 'voz_activa': prefs.getBool('voz_activa') ?? true,
            'alertas_activas': prefs.getBool('alertas_activas') ?? true,
            'tema_app': prefs.getString('tema_app') ?? 'Sistema' }},
        'resumen': { 'total_pacientes': pacientes.length, 'total_consultas': consultas.length, 'total_alertas': alertas.length },
      };
      final dir    = await getApplicationDocumentsDirectory();
      final nombre = 'dispersalud_backup_${ahora.year}${ahora.month.toString().padLeft(2,'0')}${ahora.day.toString().padLeft(2,'0')}_${ahora.hour.toString().padLeft(2,'0')}${ahora.minute.toString().padLeft(2,'0')}.json';
      final file   = File('${dir.path}/$nombre');
      await file.writeAsString(_mapToJson(backup));
      await prefs.setString('ultima_copia', ahora.toIso8601String());
      _snack('✓ Copia guardada: ${pacientes.length} pacientes, ${consultas.length} consultas');
    } catch (e) {
      _snack('Error al crear copia: $e', error: true);
    } finally {
      if (mounted) setState(() => _creandoCopia = false);
    }
  }

  String _mapToJson(dynamic obj) {
    if (obj == null)   return 'null';
    if (obj is bool)   return obj.toString();
    if (obj is num)    return obj.toString();
    if (obj is String) return '"${obj.replaceAll('\\','\\\\').replaceAll('"','\\"').replaceAll('\n','\\n')}"';
    if (obj is List)   return '[${obj.map(_mapToJson).join(',')}]';
    if (obj is Map)    return '{${obj.entries.map((e) => '"${e.key}":${_mapToJson(e.value)}').join(',')}}';
    return '"$obj"';
  }

  void _abrirPerfil() {
    showModalBottomSheet(
      context: context, isScrollControlled: true, useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PerfilSheet(
        nombre: _nombre, vereda: _vereda, municipio: _municipio, departamento: _departamento,
        onGuardar: (n, v, m, d) async {
          await _pref('promotor_nombre', n); await _pref('promotor_vereda', v);
          await _pref('promotor_municipio', m); await _pref('promotor_departamento', d);
          setState(() { _nombre = n; _vereda = v; _municipio = m; _departamento = d; });
          _snack('Perfil actualizado ✓');
        },
      ),
    );
  }

  void _abrirSeguridad() => _sheet('Seguridad y privacidad', Icons.lock_outline_rounded,
    Column(children: [
      _infoRow(Icons.lock_rounded, Colors.green, 'Cifrado AES-256 activo', 'Todos tus datos están cifrados en el dispositivo'),
      const SizedBox(height: 10),
      _infoRow(Icons.phone_android_outlined, _kVerde, 'Datos solo en tu celular', 'Sin envío a servidores. Cumple Ley 1581 de protección de datos'),
      const SizedBox(height: 10),
      _infoRow(Icons.sync_outlined, Colors.blue, 'Sincronización cifrada', 'Cuando haya internet, los datos se envían con TLS 1.3'),
      const SizedBox(height: 10),
      _infoRow(Icons.verified_user_outlined, const Color(0xFF534AB7), 'Acceso con PIN', 'El acceso está protegido con PIN de seguridad'),
    ]));

  void _abrirDispositivos() => _sheet('Dispositivos conectados', Icons.devices_outlined,
    Column(children: [
      _infoRow(Icons.phone_android_rounded, _kVerde, 'Este dispositivo',
          'Activo ahora · Android · ${_online ? "Sincronizado" : "Offline"}'),
      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.10), borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.orange.withOpacity(0.3)),
        ),
        child: Row(children: [
          const Icon(Icons.info_outline, color: Colors.orange, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Builder(builder: (ctx) => Text('Solo se permite un dispositivo activo por cuenta.',
              style: TextStyle(color: _c(ctx).textSecondary, fontSize: 12)))),
        ]),
      ),
    ]));

  // ── FIX 3: _abrirTema ahora actualiza temaNotifier en tiempo real ─────────
  void _abrirTema() {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent,
      builder: (_) => _BottomSheet(
        titulo: 'Tema de la aplicación', icono: Icons.dark_mode_outlined,
        child: Column(children: [
          ...[
            ('Sistema', Icons.brightness_auto_rounded),
            ('Claro',   Icons.light_mode_rounded),
            ('Oscuro',  Icons.dark_mode_rounded),
          ].map((t) {
            final sel = _tema == t.$1;
            return GestureDetector(
              onTap: () async {
                // 1. Guardar en SharedPreferences
                await _pref('tema_app', t.$1);
                // 2. Actualizar el notifier → MaterialApp cambia al instante
                temaNotifier.value = temaDesdeString(t.$1);
                // 3. Actualizar estado local de la pantalla
                setState(() => _tema = t.$1);
                if (mounted) Navigator.pop(context);
                _snack('Tema ${t.$1.toLowerCase()} aplicado ✓');
              },
              child: Builder(builder: (ctx) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                decoration: BoxDecoration(
                  color: sel ? _kVerde.withOpacity(0.12) : _c(ctx).bg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: sel ? _kVerde : _c(ctx).border, width: sel ? 1.5 : 1),
                ),
                child: Row(children: [
                  Icon(t.$2, color: sel ? _kVerde : _c(ctx).textSecondary, size: 20),
                  const SizedBox(width: 12),
                  Text(t.$1, style: TextStyle(
                      color: sel ? _kVerde : _c(ctx).textPrimary, fontSize: 14,
                      fontWeight: sel ? FontWeight.w700 : FontWeight.normal)),
                  const Spacer(),
                  if (sel) const Icon(Icons.check_circle_rounded, color: _kVerde, size: 20),
                ]),
              )),
            );
          }),
        ]),
      ),
    );
  }

  void _abrirIdioma() => _sheet('Idioma', Icons.language_rounded,
    Column(children: [
      _infoRow(Icons.check_circle_rounded, _kVerde, 'Español (Colombia)', 'Idioma predeterminado de la aplicación'),
      const SizedBox(height: 8),
      Builder(builder: (ctx) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: _kVerde.withOpacity(0.06), borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _kVerde.withOpacity(0.2))),
        child: Text('Actualmente solo está disponible el español colombiano. Próximas versiones incluirán más idiomas.',
            style: TextStyle(color: _c(ctx).textSecondary, fontSize: 12, height: 1.4)),
      )),
    ]));

  void _abrirNotificaciones() {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => _BottomSheet(
          titulo: 'Notificaciones', icono: Icons.notifications_outlined,
          child: Column(children: [
            _switchRow(icono: Icons.notifications_active_rounded, color: const Color(0xFFEF9F27),
              titulo: 'Alertas de pacientes', desc: 'Notificaciones de nivel urgente y alerta',
              valor: _alertas, onChange: (v) { setS(() {}); setState(() => _alertas = v); _pref('alertas_activas', v); }),
            const SizedBox(height: 10),
            _switchRow(icono: Icons.mic_rounded, color: _kVerde,
              titulo: 'Respuesta por voz', desc: 'La IA leerá las respuestas en voz alta',
              valor: _vozActiva, onChange: (v) { setS(() {}); setState(() => _vozActiva = v); _pref('voz_activa', v); }),
          ]),
        ),
      ),
    );
  }

  void _abrirSincronizacion() {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => _BottomSheet(
        titulo: 'Sincronización de datos', icono: Icons.sync_rounded,
        child: Column(children: [
          _infoRow(
            _online ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
            _online ? _kVerde : Colors.orange,
            _online ? 'Conectado a internet' : 'Sin conexión a internet',
            _online ? 'Los datos se sincronizan automáticamente' : 'Los datos se guardan localmente hasta reconectarse',
          ),
          const SizedBox(height: 10),
          _infoRow(Icons.storage_rounded, const Color(0xFF185FA5), 'Base de datos local',
              'SQLite · cifrado AES-256 · sin límite de registros'),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, height: 48,
            child: ElevatedButton.icon(
              onPressed: _sincronizando ? null : () { Navigator.pop(context); _sincronizar(); },
              icon: _sincronizando
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.sync_rounded, size: 18),
              label: Text(_sincronizando ? 'Sincronizando...' : 'Sincronizar ahora'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _online ? _kVerde : Colors.grey,
                foregroundColor: Colors.white, elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(width: double.infinity, height: 48,
            child: OutlinedButton.icon(
              onPressed: () { Navigator.pop(context); _verificarConectividad(); },
              icon: Icon(_online ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                  color: _online ? _kVerde : Colors.orange, size: 18),
              label: Text('Verificar conexión',
                  style: TextStyle(color: _online ? _kVerde : Colors.orange)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: _online ? _kVerde : Colors.orange),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  void _abrirExportar() {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent,
      builder: (_) => _BottomSheet(
        titulo: 'Exportar datos', icono: Icons.download_outlined,
        child: Column(children: [
          GestureDetector(
            onTap: () { Navigator.pop(context); _exportarPDF(); },
            child: Builder(builder: (ctx) => Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFE24B4A).withOpacity(0.08), borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE24B4A).withOpacity(0.25)),
              ),
              child: Row(children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: const Color(0xFFE24B4A).withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                  child: _exportando
                      ? const Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator(color: Color(0xFFE24B4A), strokeWidth: 2))
                      : const Icon(Icons.picture_as_pdf_outlined, color: Color(0xFFE24B4A), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Exportar como PDF', style: TextStyle(color: _c(ctx).textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                  Text('Informe completo de pacientes y consultas', style: TextStyle(color: _c(ctx).textHint, fontSize: 11)),
                ])),
                const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFE24B4A), size: 14),
              ]),
            )),
          ),
          const SizedBox(height: 10),
          Builder(builder: (ctx) => Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: _kVerde.withOpacity(0.06), borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _kVerde.withOpacity(0.2))),
            child: Row(children: [
              const Icon(Icons.check_circle_outline_rounded, color: _kVerde, size: 14),
              const SizedBox(width: 8),
              Expanded(child: Text('El PDF se genera localmente. No requiere internet.',
                  style: TextStyle(color: _c(ctx).textSecondary, fontSize: 11))),
            ]),
          )),
        ]),
      ),
    );
  }

  void _abrirCopias() {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent,
      builder: (_) => _BottomSheet(
        titulo: 'Copias de seguridad', icono: Icons.backup_outlined,
        child: Column(children: [
          _infoRow(Icons.phone_android_rounded, _kVerde, 'Copia local activa', 'Los datos se guardan automáticamente en el dispositivo'),
          const SizedBox(height: 10),
          _infoRow(Icons.folder_open_rounded, const Color(0xFF185FA5), 'Formato JSON', 'Compatible con futuras versiones de DISPERSALUD IA'),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, height: 48,
            child: ElevatedButton.icon(
              onPressed: _creandoCopia ? null : () { Navigator.pop(context); _crearCopia(); },
              icon: _creandoCopia
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.backup_rounded, size: 18),
              label: Text(_creandoCopia ? 'Creando copia...' : 'Crear copia ahora'),
              style: ElevatedButton.styleFrom(backgroundColor: _kVerde, foregroundColor: Colors.white, elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            ),
          ),
        ]),
      ),
    );
  }

  void _abrirAyuda() => _sheet('Centro de ayuda', Icons.help_outline_rounded,
    Column(children: [
      _infoRow(Icons.book_outlined, const Color(0xFF534AB7), '¿Cómo registrar un paciente?', 'Ve a Módulos → selecciona ciclo vital → nuevo paciente'),
      const SizedBox(height: 10),
      _infoRow(Icons.mic_rounded, _kVerde, '¿Cómo usar la IA por voz?', 'En Inicio, toca "Consultar IA" y habla tu consulta'),
      const SizedBox(height: 10),
      _infoRow(Icons.wifi_off_rounded, Colors.orange, '¿Funciona sin internet?', 'Sí, todos los módulos y la IA básica funcionan 100% offline'),
      const SizedBox(height: 10),
      _infoRow(Icons.lock_outline, Colors.green, '¿Mis datos son seguros?', 'Sí, cifrado AES-256 y nunca salen del dispositivo sin tu permiso'),
    ]));

  void _abrirManual() => _sheet('Manual de uso', Icons.menu_book_rounded,
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _manualItem('1. Registro de pacientes', 'Ve a la pestaña Módulos y selecciona el ciclo vital del paciente.'),
      _manualItem('2. Consulta por voz', 'Desde Inicio, toca el botón "Consultar IA" y habla tu consulta clínica.'),
      _manualItem('3. Historia clínica', 'En Pacientes, toca el botón H.C. en la tarjeta del paciente.'),
      _manualItem('4. Alertas', 'Las alertas se generan automáticamente según el nivel de riesgo.'),
      _manualItem('5. Medicamentos', 'Accede desde Inicio → Acciones rápidas → Medicamentos.'),
      _manualItem('6. Modo offline', 'Todo funciona sin internet. Al reconectarte se sincronizan los datos.'),
    ]));

  void _abrirContacto() => _sheet('Contacto soporte', Icons.support_agent_rounded,
    Column(children: [
      _infoRow(Icons.email_outlined, const Color(0xFF185FA5), 'Correo de soporte', 'soporte@dispersalud.co'),
      const SizedBox(height: 10),
      _infoRow(Icons.phone_outlined, _kVerde, 'Línea de atención', 'Lunes a viernes 8am - 5pm'),
      const SizedBox(height: 10),
      _infoRow(Icons.chat_outlined, const Color(0xFF534AB7), 'Chat en línea', 'Disponible cuando hay conexión a internet'),
    ]));

  void _cerrarSesion() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _c(context).card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('¿Cerrar sesión?', style: TextStyle(color: _c(context).textPrimary, fontWeight: FontWeight.bold)),
        content: Text('Tus datos quedarán guardados. Necesitarás tu PIN para volver a ingresar.',
            style: TextStyle(color: _c(context).textSecondary, fontSize: 13, height: 1.5)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: _kVerde))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              Navigator.pop(context);
              final p = await SharedPreferences.getInstance();
              await p.remove('pin_configurado');
              if (mounted) Navigator.of(context).pushNamedAndRemoveUntil('/pin', (r) => false);
            },
            child: const Text('Cerrar sesión', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _sheet(String titulo, IconData icono, Widget child) {
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
        builder: (_) => _BottomSheet(titulo: titulo, icono: icono, child: child));
  }

  @override
  Widget build(BuildContext context) {
    final dc = _c(context);
    return Scaffold(
      backgroundColor: dc.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(children: [
            // APP BAR
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Row(children: [
                GestureDetector(
                  onTap: () => Navigator.maybePop(context),
                  child: Container(width: 36, height: 36,
                    decoration: BoxDecoration(color: dc.card, borderRadius: BorderRadius.circular(10), border: Border.all(color: dc.border)),
                    child: Icon(Icons.arrow_back_rounded, color: dc.textSecondary, size: 18)),
                ),
                const SizedBox(width: 12),
                Icon(Icons.settings_rounded, color: _kVerde, size: 22),
                const SizedBox(width: 8),
                Text('Configuración', style: TextStyle(color: dc.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
              ]),
            ),
            // TARJETA PERFIL
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: GestureDetector(
                onTap: _abrirPerfil,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: dc.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: dc.border)),
                  child: Row(children: [
                    Container(
                      width: 52, height: 52,
                      decoration: BoxDecoration(color: _kVerde.withOpacity(0.15), shape: BoxShape.circle,
                          border: Border.all(color: _kVerde.withOpacity(0.3), width: 2)),
                      child: Center(child: Text(_nombre.isNotEmpty ? _nombre[0].toUpperCase() : 'P',
                          style: const TextStyle(color: _kVerde, fontSize: 22, fontWeight: FontWeight.bold))),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(_nombre.isNotEmpty ? _nombre : 'Promotor/a',
                          style: TextStyle(color: dc.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                      const Text('Promotor de Salud Rural', style: TextStyle(color: Color(0xFF9FE1CB), fontSize: 12)),
                      if (_vereda.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Row(children: [
                          Icon(Icons.location_on_outlined, color: dc.textHint, size: 12),
                          const SizedBox(width: 3),
                          Text('$_vereda - $_municipio', style: TextStyle(color: dc.textHint, fontSize: 11)),
                        ]),
                      ],
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: _verificarConectividad,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _online ? _kVerde.withOpacity(0.15) : Colors.orange.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Container(width: 6, height: 6,
                                decoration: BoxDecoration(color: _online ? _kVerde : Colors.orange, shape: BoxShape.circle)),
                            const SizedBox(width: 5),
                            Text(_online ? 'Online' : 'Offline', style: TextStyle(
                                color: _online ? _kVerde : Colors.orange, fontSize: 11, fontWeight: FontWeight.w600)),
                          ]),
                        ),
                      ),
                    ])),
                    Icon(Icons.chevron_right_rounded, color: dc.textHint, size: 20),
                  ]),
                ),
              ),
            ),
            const SizedBox(height: 4),
            _label('Cuenta'),
            _grupo([
              _tile(Icons.person_outline_rounded, 'Mi perfil', null, dc, onTap: _abrirPerfil),
              _tile(Icons.lock_outline_rounded, 'Seguridad y privacidad', null, dc, onTap: _abrirSeguridad),
              _tile(Icons.devices_outlined, 'Dispositivos conectados', null, dc, onTap: _abrirDispositivos, last: true),
            ], dc),
            const SizedBox(height: 8),
            _label('Aplicación'),
            _grupo([
              _tile(Icons.dark_mode_outlined, 'Tema', _tema, dc, onTap: _abrirTema),
              _tile(Icons.language_rounded, 'Idioma', 'Español', dc, onTap: _abrirIdioma),
              _tile(Icons.notifications_outlined, 'Notificaciones', 'Personalizadas', dc, onTap: _abrirNotificaciones, last: true),
            ], dc),
            const SizedBox(height: 8),
            // TARJETA DISPERSALUD IA
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF0A5240), Color(0xFF0F6E56)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                    child: Stack(alignment: Alignment.center, children: [
                      const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 28),
                      Positioned(top: 5, right: 5, child: Icon(Icons.auto_awesome, color: Colors.white.withOpacity(0.7), size: 10)),
                    ]),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('DISPERSALUD IA', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 0.3)),
                    const Text('Modelo clínico activo  ·  v2.4', style: TextStyle(color: Color(0xFF9FE1CB), fontSize: 11)),
                    const SizedBox(height: 8),
                    const Row(children: [Icon(Icons.check_rounded, color: Color(0xFF9FE1CB), size: 14), SizedBox(width: 4), Text('Protocolos actualizados', style: TextStyle(color: Color(0xFFB8F0DC), fontSize: 11))]),
                    const SizedBox(height: 3),
                    const Row(children: [Icon(Icons.check_rounded, color: Color(0xFF9FE1CB), size: 14), SizedBox(width: 4), Text('Uso sin conexión habilitado', style: TextStyle(color: Color(0xFFB8F0DC), fontSize: 11))]),
                  ])),
                  const Icon(Icons.chevron_right_rounded, color: Colors.white38, size: 20),
                ]),
              ),
            ),
            const SizedBox(height: 8),
            _label('Datos y sincronización'),
            _grupo([
              _tile(Icons.sync_rounded, 'Sincronización de datos', _sincronizando ? 'Sincronizando...' : null,
                  dc, onTap: _abrirSincronizacion, iconColor: _online ? _kVerde : Colors.orange),
              _tile(Icons.download_outlined, 'Exportar datos', _exportando ? 'Generando PDF...' : null, dc, onTap: _abrirExportar),
              _tile(Icons.backup_outlined, 'Copias de seguridad', _creandoCopia ? 'Creando copia...' : null, dc, onTap: _abrirCopias, last: true),
            ], dc),
            const SizedBox(height: 8),
            _label('Soporte'),
            _grupo([
              _tile(Icons.help_outline_rounded, 'Centro de ayuda', null, dc, onTap: _abrirAyuda, iconColor: const Color(0xFFEF9F27)),
              _tile(Icons.menu_book_rounded, 'Manual de uso', null, dc, onTap: _abrirManual, iconColor: const Color(0xFF185FA5)),
              _tile(Icons.support_agent_rounded, 'Contacto soporte', null, dc, onTap: _abrirContacto, iconColor: const Color(0xFF534AB7), last: true),
            ], dc),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              child: SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton.icon(
                  onPressed: _cerrarSesion,
                  icon: const Icon(Icons.exit_to_app_rounded, color: Colors.white, size: 20),
                  label: const Text('Cerrar sesión', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB71C1C), elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// HELPERS DE LAYOUT
Widget _label(String texto) => Padding(
  padding: const EdgeInsets.fromLTRB(20, 4, 16, 6),
  child: Builder(builder: (ctx) => Text(texto, style: TextStyle(color: _c(ctx).textHint, fontSize: 12, fontWeight: FontWeight.w600))),
);

Widget _grupo(List<Widget> items, DispersaludColors dc) => Padding(
  padding: const EdgeInsets.symmetric(horizontal: 16),
  child: Container(
    decoration: BoxDecoration(color: dc.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: dc.border)),
    child: Column(children: items),
  ),
);

Widget _tile(IconData icono, String titulo, String? valor, DispersaludColors dc,
    {VoidCallback? onTap, Color iconColor = _kVerde, bool last = false}) =>
  Column(children: [
    InkWell(
      onTap: onTap, borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(children: [
          Container(width: 34, height: 34,
            decoration: BoxDecoration(color: iconColor.withOpacity(0.12), borderRadius: BorderRadius.circular(9)),
            child: Icon(icono, color: iconColor, size: 18)),
          const SizedBox(width: 12),
          Expanded(child: Text(titulo, style: TextStyle(color: dc.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))),
          if (valor != null) ...[Text(valor, style: TextStyle(color: dc.textHint, fontSize: 12)), const SizedBox(width: 4)],
          Icon(Icons.chevron_right_rounded, color: dc.textHint, size: 18),
        ]),
      ),
    ),
    if (!last) Padding(padding: const EdgeInsets.only(left: 60), child: Divider(height: 1, color: dc.border)),
  ]);

Widget _infoRow(IconData icono, Color color, String titulo, String desc) =>
  Builder(builder: (ctx) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: color.withOpacity(0.06), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.2))),
    child: Row(children: [
      Container(width: 36, height: 36, decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(9)),
          child: Icon(icono, color: color, size: 18)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(titulo, style: TextStyle(color: _c(ctx).textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(desc, style: TextStyle(color: _c(ctx).textHint, fontSize: 11, height: 1.3)),
      ])),
    ]),
  ));

Widget _switchRow({required IconData icono, required Color color, required String titulo, required String desc,
    required bool valor, required ValueChanged<bool> onChange}) =>
  Builder(builder: (ctx) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(color: _c(ctx).bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: _c(ctx).border)),
    child: Row(children: [
      Container(width: 36, height: 36, decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(9)),
          child: Icon(icono, color: color, size: 18)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(titulo, style: TextStyle(color: _c(ctx).textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
        Text(desc, style: TextStyle(color: _c(ctx).textHint, fontSize: 11)),
      ])),
      Switch(value: valor, activeColor: _kVerde, onChanged: onChange),
    ]),
  ));

Widget _manualItem(String titulo, String desc) =>
  Builder(builder: (ctx) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 6, height: 6, margin: const EdgeInsets.only(top: 5),
          decoration: const BoxDecoration(color: _kVerde, shape: BoxShape.circle)),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(titulo, style: TextStyle(color: _c(ctx).textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(desc, style: TextStyle(color: _c(ctx).textHint, fontSize: 11, height: 1.4)),
      ])),
    ]),
  ));

// BOTTOM SHEET GENÉRICO
class _BottomSheet extends StatelessWidget {
  final String titulo;
  final IconData icono;
  final Widget child;
  const _BottomSheet({required this.titulo, required this.icono, required this.child});

  @override
  Widget build(BuildContext context) {
    final dc     = _c(context);
    final bottom = MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: BoxDecoration(color: dc.card, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      padding: EdgeInsets.fromLTRB(20, 16, 20, bottom < 16 ? 32 : bottom + 16),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: dc.border, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Row(children: [
            Container(width: 38, height: 38,
              decoration: BoxDecoration(color: _kVerde.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
              child: Icon(icono, color: _kVerde, size: 20)),
            const SizedBox(width: 10),
            Text(titulo, style: TextStyle(color: dc.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 20),
          child,
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, height: 48,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(side: BorderSide(color: dc.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: Text('Cerrar', style: TextStyle(color: dc.textSecondary, fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
      ),
    );
  }
}

// SHEET DE PERFIL
class _PerfilSheet extends StatefulWidget {
  final String nombre, vereda, municipio, departamento;
  final Function(String, String, String, String) onGuardar;
  const _PerfilSheet({required this.nombre, required this.vereda, required this.municipio,
      required this.departamento, required this.onGuardar});
  @override
  State<_PerfilSheet> createState() => _PerfilSheetState();
}

class _PerfilSheetState extends State<_PerfilSheet> {
  late final TextEditingController _n, _v, _m, _d;

  @override
  void initState() {
    super.initState();
    _n = TextEditingController(text: widget.nombre);
    _v = TextEditingController(text: widget.vereda);
    _m = TextEditingController(text: widget.municipio);
    _d = TextEditingController(text: widget.departamento);
  }

  @override
  void dispose() { _n.dispose(); _v.dispose(); _m.dispose(); _d.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final dc     = _c(context);
    final bottom = MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: BoxDecoration(color: dc.card, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      padding: EdgeInsets.fromLTRB(20, 16, 20, bottom < 16 ? 32 : bottom + 16),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: dc.border, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Row(children: [
            Container(width: 38, height: 38,
              decoration: BoxDecoration(color: _kVerde.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.person_outline_rounded, color: _kVerde, size: 20)),
            const SizedBox(width: 10),
            Text('Mi perfil', style: TextStyle(color: dc.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 20),
          _campo('Nombre completo', _n, dc),
          _campo('Vereda', _v, dc),
          Row(children: [
            Expanded(child: _campo('Municipio', _m, dc)),
            const SizedBox(width: 12),
            Expanded(child: _campo('Departamento', _d, dc)),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 13),
                  side: BorderSide(color: dc.border), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: Text('Cancelar', style: TextStyle(color: dc.textSecondary)),
            )),
            const SizedBox(width: 12),
            Expanded(flex: 2, child: ElevatedButton(
              onPressed: () { widget.onGuardar(_n.text.trim(), _v.text.trim(), _m.text.trim(), _d.text.trim()); Navigator.pop(context); },
              style: ElevatedButton.styleFrom(backgroundColor: _kVerde, padding: const EdgeInsets.symmetric(vertical: 13),
                  elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Guardar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            )),
          ]),
        ]),
      ),
    );
  }

  Widget _campo(String label, TextEditingController ctrl, DispersaludColors dc) =>
    Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(color: dc.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 5),
        TextField(
          controller: ctrl,
          style: TextStyle(color: dc.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            filled: true, fillColor: dc.bg,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: dc.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: dc.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _kVerde, width: 1.5)),
          ),
        ),
      ]),
    );
}