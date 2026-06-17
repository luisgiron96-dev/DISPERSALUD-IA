import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../database/database_helper.dart';
import '../services/connectivity_service.dart';
import '../widgets/firma_panel.dart';

// ════════════════════════════════════════════════════════════════════════════
//  seguimiento_screen.dart  —  DISPERSALUD IA  (datos reales BD)
// ════════════════════════════════════════════════════════════════════════════

const Color _verde  = Color(0xFF1D9E75);
const Color _rojo   = Color(0xFFE24B4A);
const Color _ambar  = Color(0xFFEF9F27);
const Color _azul   = Color(0xFF185FA5);
const Color _morado = Color(0xFF534AB7);

// ─────────────────────────────────────────────────────────────────────────────
// PANTALLA PRINCIPAL
// ─────────────────────────────────────────────────────────────────────────────
class SeguimientoScreen extends StatefulWidget {
  const SeguimientoScreen({super.key});
  @override
  State<SeguimientoScreen> createState() => _SeguimientoScreenState();
}

class _SeguimientoScreenState extends State<SeguimientoScreen> {
  // ── Estado ────────────────────────────────────────────────────────────────
  bool _online    = false;
  bool _cargando  = true;
  StreamSubscription<bool>? _connSub;

  // Datos de BD
  List<Map<String, dynamic>> _pacientes        = [];
  List<Map<String, dynamic>> _pacientesFiltrados = [];

  // Métricas reales
  int _totalPacientes      = 0;
  int _altoRiesgo          = 0;
  int _medioRiesgo         = 0;
  int _bajoRiesgo          = 0;
  int _consultasHoy        = 0;

  // Filtros y búsqueda
  String _filtroModulo = 'todos';
  String _busqueda     = '';
  final _searchCtrl    = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initConectividad();
    _cargarDatos();
  }

  @override
  void dispose() {
    _connSub?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _initConectividad() async {
    _online = await ConnectivityService.instance.verificarAhora();
    if (mounted) setState(() {});
    _connSub = ConnectivityService.instance.cambios.listen((v) {
      if (mounted) setState(() => _online = v);
    });
  }

  Future<void> _cargarDatos() async {
    if (!mounted) return;
    setState(() => _cargando = true);

    final db   = DatabaseHelper.instance;
    final pacs = await db.obtenerPacientes();

    // Para cada paciente obtenemos la última consulta
    final List<Map<String, dynamic>> enriquecidos = [];
    for (final p in pacs) {
      final consultas = await db.consultasDePaciente(p['id'] as int);
      final ultima    = consultas.isNotEmpty ? consultas.first : null;
      enriquecidos.add({
        ...p,
        'ultima_consulta':  ultima,
        'total_consultas':  consultas.length,
      });
    }

    // Métricas
    final hoy = DateTime.now().toIso8601String().substring(0, 10);
    int alto = 0, medio = 0, bajo = 0, hoyCount = 0;
    for (final p in enriquecidos) {
      final uc = p['ultima_consulta'] as Map<String, dynamic>?;
      final nivel = (uc?['nivel_riesgo'] as String? ?? 'estable').toLowerCase();
      if (nivel == 'urgente' || nivel == 'alerta') alto++;
      else if (nivel == 'moderado') medio++;
      else bajo++;

      final fecha = uc?['fecha'] as String? ?? '';
      if (fecha.startsWith(hoy)) hoyCount++;
    }

    if (!mounted) return;
    setState(() {
      _pacientes        = enriquecidos;
      _totalPacientes   = enriquecidos.length;
      _altoRiesgo       = alto;
      _medioRiesgo      = medio;
      _bajoRiesgo       = bajo;
      _consultasHoy     = hoyCount;
      _cargando         = false;
    });
    _aplicarFiltros();
  }

  void _aplicarFiltros() {
    var lista = List<Map<String, dynamic>>.from(_pacientes);

    // Filtro por módulo
    if (_filtroModulo != 'todos') {
      lista = lista.where((p) {
        final mod = (p['modulo'] as String? ?? '').toLowerCase();
        return mod.contains(_filtroModulo);
      }).toList();
    }

    // Búsqueda por nombre / vereda
    if (_busqueda.isNotEmpty) {
      final q = _busqueda.toLowerCase();
      lista = lista.where((p) {
        final nombre = (p['nombre'] as String? ?? '').toLowerCase();
        final vereda = (p['vereda'] as String? ?? '').toLowerCase();
        final mun    = (p['municipio'] as String? ?? '').toLowerCase();
        return nombre.contains(q) || vereda.contains(q) || mun.contains(q);
      }).toList();
    }

    // Ordenar: alto riesgo primero
    lista.sort((a, b) {
      int _orden(Map<String, dynamic> p) {
        final uc    = p['ultima_consulta'] as Map<String, dynamic>?;
        final nivel = (uc?['nivel_riesgo'] as String? ?? '').toLowerCase();
        if (nivel == 'urgente' || nivel == 'alerta') return 0;
        if (nivel == 'moderado') return 1;
        return 2;
      }
      return _orden(a).compareTo(_orden(b));
    });

    setState(() => _pacientesFiltrados = lista);
  }

  // ── Helpers de riesgo ────────────────────────────────────────────────────
  Color _colorRiesgo(String? nivel) {
    final n = (nivel ?? '').toLowerCase();
    if (n == 'urgente' || n == 'alerta') return _rojo;
    if (n == 'moderado') return _ambar;
    return _verde;
  }

  String _labelRiesgo(String? nivel) {
    final n = (nivel ?? '').toLowerCase();
    if (n == 'urgente') return 'Urgente';
    if (n == 'alerta')  return 'Alerta';
    if (n == 'moderado') return 'Moderado';
    return 'Estable';
  }

  IconData _iconoRiesgo(String? nivel) {
    final n = (nivel ?? '').toLowerCase();
    if (n == 'urgente' || n == 'alerta') return Icons.warning_rounded;
    if (n == 'moderado') return Icons.error_outline_rounded;
    return Icons.shield_rounded;
  }

  // ── Helpers de módulo ────────────────────────────────────────────────────
  IconData _iconoModulo(String? modulo) {
    final m = (modulo ?? '').toLowerCase();
    if (m.contains('gestac'))    return Icons.favorite_border_rounded;
    if (m.contains('infancia') || m.contains('niñ')) return Icons.child_friendly_outlined;
    if (m.contains('vejez') || m.contains('mayor')) return Icons.accessible_forward_rounded;
    if (m.contains('adultez') || m.contains('crón')) return Icons.monitor_heart_outlined;
    return Icons.person_outline_rounded;
  }

  Color _colorModulo(String? modulo) {
    final m = (modulo ?? '').toLowerCase();
    if (m.contains('gestac'))  return const Color(0xFF993556);
    if (m.contains('infancia')) return _azul;
    if (m.contains('vejez'))   return const Color(0xFF5F5E5A);
    if (m.contains('adultez')) return _rojo;
    return _verde;
  }

  // ── Tiempo transcurrido ──────────────────────────────────────────────────
  String _tiempoTranscurrido(String? fechaStr) {
    if (fechaStr == null || fechaStr.isEmpty) return 'Sin consultas';
    try {
      final fecha = DateTime.parse(fechaStr);
      final diff  = DateTime.now().difference(fecha);
      if (diff.inDays == 0)  return 'Hoy';
      if (diff.inDays == 1)  return 'Ayer';
      if (diff.inDays < 7)   return 'Hace ${diff.inDays} días';
      if (diff.inDays < 30)  return 'Hace ${(diff.inDays / 7).floor()} sem.';
      if (diff.inDays < 365) return 'Hace ${(diff.inDays / 30).floor()} mes.';
      return 'Hace más de 1 año';
    } catch (_) {
      return 'Desconocido';
    }
  }

  // ── Diálogo registrar visita / nota ──────────────────────────────────────
  Future<void> _mostrarRegistroVisita(Map<String, dynamic> paciente) async {
    final notaCtrl   = TextEditingController();
    final pesoCtrl   = TextEditingController();
    final presCtrl   = TextEditingController();
    String nivelSel  = 'estable';
    Uint8List? firmaBytes;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final dc = DT(ctx);
        return StatefulBuilder(builder: (ctx2, setSt) {
          return Container(
            padding: EdgeInsets.fromLTRB(
                16, 16, 16,
                MediaQuery.of(ctx2).viewInsets.bottom +
                MediaQuery.of(ctx2).padding.bottom + 16),
            decoration: BoxDecoration(
                color: dc.bg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
            child: SingleChildScrollView(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Handle
                Center(child: Container(width: 40, height: 4,
                    decoration: BoxDecoration(
                        color: dc.border,
                        borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 16),
                // Título
                Row(children: [
                  Container(width: 36, height: 36,
                      decoration: BoxDecoration(
                          color: _verde.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.assignment_add, color: _verde, size: 18)),
                  const SizedBox(width: 8),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    const Text('Registrar visita',
                        style: TextStyle(color: _verde, fontSize: 14,
                            fontWeight: FontWeight.bold)),
                    Text(paciente['nombre'] as String? ?? '',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: dc.textSecondary, fontSize: 11)),
                  ])),
                ]),
                const SizedBox(height: 16),

                // Nivel de riesgo
                Text('Nivel de riesgo',
                    style: TextStyle(color: dc.textPrimary, fontSize: 12,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: [
                    for (final n in ['estable', 'moderado', 'alerta', 'urgente'])
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: GestureDetector(
                          onTap: () => setSt(() => nivelSel = n),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: nivelSel == n
                                  ? _colorRiesgo(n).withOpacity(0.18)
                                  : dc.card,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: nivelSel == n
                                      ? _colorRiesgo(n)
                                      : dc.border,
                                  width: nivelSel == n ? 1.5 : 1),
                            ),
                            child: Text(n[0].toUpperCase() + n.substring(1),
                                style: TextStyle(
                                    color: nivelSel == n
                                        ? _colorRiesgo(n)
                                        : dc.textSecondary,
                                    fontSize: 11,
                                    fontWeight: nivelSel == n
                                        ? FontWeight.bold
                                        : FontWeight.normal)),
                          ),
                        ),
                      ),
                  ]),
                ),
                const SizedBox(height: 14),

                // Signos vitales opcionales
                Text('Signos vitales (opcional)',
                    style: TextStyle(color: dc.textPrimary, fontSize: 12,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: _Campo(ctrl: pesoCtrl, label: 'Peso (kg)',
                      icono: Icons.monitor_weight_outlined, dc: dc)),
                  const SizedBox(width: 8),
                  Expanded(child: _Campo(ctrl: presCtrl, label: 'Presión',
                      icono: Icons.favorite_outline, dc: dc)),
                ]),
                const SizedBox(height: 14),

                // Nota / observación
                Text('Nota de visita',
                    style: TextStyle(color: dc.textPrimary, fontSize: 12,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                      color: dc.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: dc.border)),
                  child: TextField(
                    controller: notaCtrl,
                    maxLines: 3,
                    style: TextStyle(color: dc.textPrimary, fontSize: 12),
                    decoration: InputDecoration(
                      hintText: 'Observaciones de la visita...',
                      hintStyle:
                          TextStyle(color: dc.textHint, fontSize: 12),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Firma del profesional
                Text('Firma del profesional',
                    style: TextStyle(color: dc.textPrimary, fontSize: 12,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final bytes = await mostrarDialogoFirma(
                      context: ctx2,
                      titulo: 'Firma del profesional',
                    );
                    if (bytes != null) {
                      setSt(() => firmaBytes = bytes);
                    }
                  },
                  child: firmaBytes == null
                      ? Container(
                          height: 56,
                          decoration: BoxDecoration(
                              color: dc.card,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: dc.border)),
                          child: Row(children: [
                            const SizedBox(width: 14),
                            Icon(Icons.draw_outlined, color: dc.textHint, size: 18),
                            const SizedBox(width: 10),
                            Text('Tocar para firmar',
                                style: TextStyle(color: dc.textHint, fontSize: 12.5)),
                          ]),
                        )
                      : Container(
                          height: 70,
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _verde, width: 1.4)),
                          child: Row(children: [
                            Expanded(child: Image.memory(firmaBytes!, fit: BoxFit.contain)),
                            const SizedBox(width: 6),
                            Icon(Icons.check_circle_rounded, color: _verde, size: 18),
                          ]),
                        ),
                ),
                const SizedBox(height: 16),

                // Botón guardar
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(ctx2);
                      await _guardarVisita(
                        paciente: paciente,
                        nota: notaCtrl.text.trim(),
                        peso: pesoCtrl.text.trim(),
                        presion: presCtrl.text.trim(),
                        nivelRiesgo: nivelSel,
                        firmaBytes: firmaBytes,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: _verde,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14)),
                    icon: const Icon(Icons.save_outlined, size: 16),
                    label: const Text('Guardar visita',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ]),
            ),
          );
        });
      },
    );
    notaCtrl.dispose();
    pesoCtrl.dispose();
    presCtrl.dispose();
  }

  Future<void> _guardarVisita({
    required Map<String, dynamic> paciente,
    required String nota,
    required String peso,
    required String presion,
    required String nivelRiesgo,
    Uint8List? firmaBytes,
  }) async {
    await DatabaseHelper.instance.insertarConsulta({
      'paciente_id':  paciente['id'],
      'nombre':       paciente['nombre'],
      'modulo':       paciente['modulo'] ?? 'Seguimiento',
      'observaciones': nota.isNotEmpty ? nota : 'Visita de seguimiento registrada',
      'peso':         peso,
      'presion':      presion,
      'nivel_riesgo': nivelRiesgo,
      'diagnostico':  'Visita de seguimiento',
      if (firmaBytes != null) 'firma_png': base64Encode(firmaBytes),
      if (firmaBytes != null) 'firma_fecha': DateTime.now().toIso8601String(),
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('✓ Visita registrada correctamente'),
        backgroundColor: _verde,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      await _cargarDatos();
    }
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final dc = DT(context);

    return Scaffold(
      backgroundColor: dc.bg,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _cargarDatos,
        backgroundColor: _verde,
        icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
        label: const Text('Actualizar',
            style: TextStyle(color: Colors.white, fontSize: 12,
                fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: Column(children: [

          // ── APP BAR ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(color: dc.card,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: dc.border)),
                  child: Icon(Icons.arrow_back_ios_new_rounded,
                      color: dc.textSecondary, size: 16),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                    color: _verde.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.assignment_rounded,
                    color: _verde, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('Seguimiento', style: TextStyle(
                      color: dc.textPrimary, fontSize: 18,
                      fontWeight: FontWeight.bold)),
                  Text('$_totalPacientes pacientes en seguimiento',
                      style: TextStyle(color: dc.textHint, fontSize: 10)),
                ]),
              ),
              // Badge online
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: _online ? _verde.withOpacity(0.12) : dc.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _online ? _verde : dc.border),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 6, height: 6,
                      decoration: BoxDecoration(
                          color: _online ? _verde : Colors.orange,
                          shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  Text(_online ? 'Online' : 'Offline',
                      style: TextStyle(
                          color: _online ? _verde : Colors.orange,
                          fontSize: 10, fontWeight: FontWeight.w600)),
                ]),
              ),
            ]),
          ),

          // ── BARRA DE BÚSQUEDA ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Container(
              height: 40,
              decoration: BoxDecoration(color: dc.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: dc.border)),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) {
                  _busqueda = v;
                  _aplicarFiltros();
                },
                style: TextStyle(color: dc.textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Buscar paciente, vereda...',
                  hintStyle: TextStyle(color: dc.textHint, fontSize: 12),
                  prefixIcon: Icon(Icons.search_rounded,
                      color: dc.textHint, size: 18),
                  suffixIcon: _busqueda.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            _searchCtrl.clear();
                            _busqueda = '';
                            _aplicarFiltros();
                          },
                          child: Icon(Icons.close_rounded,
                              color: dc.textHint, size: 16))
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),

          // ── CONTENIDO SCROLLEABLE ──────────────────────────────────────
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator(color: _verde))
                : RefreshIndicator(
                    color: _verde,
                    onRefresh: _cargarDatos,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(12),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                        // ── 4 TARJETAS MÉTRICAS REALES ─────────────────
                        Row(children: [
                          _RCard(valor: '$_altoRiesgo', label: 'Alto\nriesgo',
                              color: _rojo, icono: Icons.warning_rounded, dc: dc),
                          const SizedBox(width: 8),
                          _RCard(valor: '$_medioRiesgo', label: 'Riesgo\nmedio',
                              color: _ambar, icono: Icons.error_outline_rounded, dc: dc),
                          const SizedBox(width: 8),
                          _RCard(valor: '$_bajoRiesgo', label: 'Bajo\nriesgo',
                              color: _verde, icono: Icons.shield_rounded, dc: dc),
                          const SizedBox(width: 8),
                          _RCard(valor: '$_consultasHoy', label: 'Controles\nhoy',
                              color: _azul, icono: Icons.calendar_today_rounded, dc: dc),
                        ]),
                        const SizedBox(height: 12),

                        // ── FILTROS POR MÓDULO ──────────────────────────
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(children: [
                            _Chip(label: 'Todos', icono: Icons.group_rounded,
                                activo: _filtroModulo == 'todos', color: _verde,
                                onTap: () {
                                  _filtroModulo = 'todos';
                                  _aplicarFiltros();
                                }),
                            const SizedBox(width: 6),
                            _Chip(label: 'Gestantes',
                                icono: Icons.favorite_border_rounded,
                                activo: _filtroModulo == 'gestac',
                                color: const Color(0xFF993556),
                                onTap: () {
                                  _filtroModulo = 'gestac';
                                  _aplicarFiltros();
                                }),
                            const SizedBox(width: 6),
                            _Chip(label: 'Infancia',
                                icono: Icons.child_friendly_outlined,
                                activo: _filtroModulo == 'infancia', color: _azul,
                                onTap: () {
                                  _filtroModulo = 'infancia';
                                  _aplicarFiltros();
                                }),
                            const SizedBox(width: 6),
                            _Chip(label: 'Adultos',
                                icono: Icons.person_outlined,
                                activo: _filtroModulo == 'adultez', color: _rojo,
                                onTap: () {
                                  _filtroModulo = 'adultez';
                                  _aplicarFiltros();
                                }),
                            const SizedBox(width: 6),
                            _Chip(label: 'Vejez',
                                icono: Icons.accessible_forward_rounded,
                                activo: _filtroModulo == 'vejez',
                                color: const Color(0xFF5F5E5A),
                                onTap: () {
                                  _filtroModulo = 'vejez';
                                  _aplicarFiltros();
                                }),
                          ]),
                        ),
                        const SizedBox(height: 14),

                        // ── HEADER LISTA ────────────────────────────────
                        Row(children: [
                          Expanded(
                            child: Text(
                              _pacientesFiltrados.isEmpty
                                  ? 'Sin pacientes registrados'
                                  : '${_pacientesFiltrados.length} pacientes',
                              style: TextStyle(color: dc.textPrimary,
                                  fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ),
                          if (_pacientesFiltrados.isNotEmpty)
                            Text(
                              'Ordenados por riesgo',
                              style: TextStyle(color: dc.textHint, fontSize: 10),
                            ),
                        ]),
                        const SizedBox(height: 12),

                        // ── LISTA REAL DE PACIENTES ────────────────────
                        if (_pacientesFiltrados.isEmpty)
                          _EmptyState(dc: dc,
                              sinBD: _pacientes.isEmpty)
                        else
                          ..._pacientesFiltrados.map((p) {
                            final uc    = p['ultima_consulta']
                                as Map<String, dynamic>?;
                            final nivel = uc?['nivel_riesgo'] as String?;
                            final modulo = p['modulo'] as String?;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _PCard(
                                paciente: p,
                                dc:       dc,
                                colorR:   _colorRiesgo(nivel),
                                labelR:   _labelRiesgo(nivel),
                                iconR:    _iconoRiesgo(nivel),
                                iconC:    _iconoModulo(modulo),
                                colorC:   _colorModulo(modulo),
                                ultimaVisita: _tiempoTranscurrido(
                                    uc?['fecha'] as String?),
                                totalConsultas: p['total_consultas'] as int? ?? 0,
                                onRegistrar: () => _mostrarRegistroVisita(p),
                              ),
                            );
                          }),

                        const SizedBox(height: 80),
                      ]),
                    ),
                  ),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CAMPO DE TEXTO AUXILIAR
// ─────────────────────────────────────────────────────────────────────────────
class _Campo extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final IconData icono;
  final DispersaludColors dc;
  const _Campo({required this.ctrl, required this.label,
      required this.icono, required this.dc});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(color: dc.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: dc.border)),
    child: TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      style: TextStyle(color: dc.textPrimary, fontSize: 12),
      decoration: InputDecoration(
        hintText: label,
        hintStyle: TextStyle(color: dc.textHint, fontSize: 11),
        prefixIcon: Icon(icono, color: dc.textHint, size: 14),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// TARJETA MÉTRICA
// ─────────────────────────────────────────────────────────────────────────────
class _RCard extends StatelessWidget {
  final String valor, label;
  final Color color;
  final IconData icono;
  final DispersaludColors dc;
  const _RCard({required this.valor, required this.label,
      required this.color, required this.icono, required this.dc});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(color: dc.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: dc.border)),
      child: Column(children: [
        Container(width: 32, height: 32,
            decoration: BoxDecoration(
                color: color.withOpacity(0.13), shape: BoxShape.circle),
            child: Icon(icono, color: color, size: 16)),
        const SizedBox(height: 5),
        Text(valor, style: TextStyle(color: color, fontSize: 20,
            fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, textAlign: TextAlign.center,
            style: TextStyle(color: dc.textHint, fontSize: 8.5, height: 1.2)),
      ]),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// CHIP FILTRO
// ─────────────────────────────────────────────────────────────────────────────
class _Chip extends StatelessWidget {
  final String label;
  final IconData icono;
  final bool activo;
  final Color color;
  final VoidCallback onTap;
  const _Chip({required this.label, required this.icono,
      required this.activo, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final dc = DT(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: activo ? color.withOpacity(0.14) : dc.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: activo ? color : dc.border,
              width: activo ? 1.5 : 1),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icono, color: activo ? color : dc.textHint, size: 13),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(
              color: activo ? color : dc.textSecondary,
              fontSize: 11,
              fontWeight: activo ? FontWeight.w700 : FontWeight.normal)),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TARJETA PACIENTE
// ─────────────────────────────────────────────────────────────────────────────
class _PCard extends StatelessWidget {
  final Map<String, dynamic> paciente;
  final DispersaludColors dc;
  final Color colorR, colorC;
  final String labelR, ultimaVisita;
  final IconData iconR, iconC;
  final int totalConsultas;
  final VoidCallback onRegistrar;

  const _PCard({
    required this.paciente,   required this.dc,
    required this.colorR,     required this.labelR,
    required this.iconR,      required this.iconC,
    required this.colorC,     required this.ultimaVisita,
    required this.totalConsultas, required this.onRegistrar,
  });

  @override
  Widget build(BuildContext context) {
    final nombre  = paciente['nombre']   as String? ?? 'Sin nombre';
    final vereda  = paciente['vereda']   as String? ?? '';
    final mun     = paciente['municipio'] as String? ?? '';
    final modulo  = paciente['modulo']   as String? ?? 'General';
    final ubicacion = [vereda, mun].where((s) => s.isNotEmpty).join(' - ');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: dc.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: dc.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // Fila: avatar + info + badge riesgo
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 46, height: 46,
              decoration: BoxDecoration(
                  color: colorC.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(iconC, color: colorC, size: 24)),
          const SizedBox(width: 10),
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(nombre, overflow: TextOverflow.ellipsis,
                style: TextStyle(color: dc.textPrimary, fontSize: 13,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            if (ubicacion.isNotEmpty)
              Row(children: [
                Icon(Icons.location_on_outlined, color: dc.textHint, size: 10),
                const SizedBox(width: 2),
                Expanded(child: Text(ubicacion, overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: dc.textHint, fontSize: 10))),
              ]),
            const SizedBox(height: 3),
            Row(children: [
              Icon(iconC, color: colorC, size: 10),
              const SizedBox(width: 3),
              Expanded(child: Text(modulo, overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: colorC, fontSize: 11,
                      fontWeight: FontWeight.w600))),
            ]),
          ])),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
            decoration: BoxDecoration(
                color: colorR.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colorR.withOpacity(0.3))),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(iconR, color: colorR, size: 11),
              const SizedBox(width: 3),
              Text(labelR, style: TextStyle(color: colorR, fontSize: 10,
                  fontWeight: FontWeight.bold)),
            ]),
          ),
        ]),
        const SizedBox(height: 10),

        // Última visita + total consultas + botón registrar
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Row(children: [
              Icon(Icons.access_time_rounded, color: dc.textHint, size: 10),
              const SizedBox(width: 2),
              Text('Última consulta',
                  style: TextStyle(color: dc.textHint, fontSize: 9)),
            ]),
            Text(ultimaVisita,
                style: TextStyle(color: dc.textSecondary, fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ])),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Row(children: [
              Icon(Icons.history_rounded, color: dc.textHint, size: 10),
              const SizedBox(width: 2),
              Text('Total consultas',
                  style: TextStyle(color: dc.textHint, fontSize: 9)),
            ]),
            Text('$totalConsultas registros',
                style: TextStyle(color: dc.textSecondary, fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ])),
          GestureDetector(
            onTap: onRegistrar,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                  color: _verde.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _verde.withOpacity(0.4))),
              child: const Text('Registrar visita',
                  style: TextStyle(color: _verde, fontSize: 10,
                      fontWeight: FontWeight.bold)),
            ),
          ),
        ]),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ESTADO VACÍO
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final DispersaludColors dc;
  final bool sinBD;
  const _EmptyState({required this.dc, required this.sinBD});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(children: [
        Icon(Icons.assignment_outlined, color: dc.textHint, size: 48),
        const SizedBox(height: 12),
        Text(
          sinBD
              ? 'No hay pacientes registrados'
              : 'No se encontraron pacientes\ncon ese filtro',
          textAlign: TextAlign.center,
          style: TextStyle(color: dc.textSecondary, fontSize: 13),
        ),
        if (sinBD) ...[
          const SizedBox(height: 8),
          Text('Registra pacientes en la sección\n"Pacientes" para verlos aquí.',
              textAlign: TextAlign.center,
              style: TextStyle(color: dc.textHint, fontSize: 11)),
        ],
      ]),
    ),
  );
}