import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/app_theme.dart';
import '../../core/responsive.dart';
import '../../database/database_helper.dart';
import '../../services/connectivity_service.dart';

DispersaludColors _dc(BuildContext ctx) =>
    Theme.of(ctx).extension<DispersaludColors>() ?? DispersaludColors.dark;

// ── Chips de filtro ───────────────────────────────────────────────────────────
const _kTabs = [
  'Todos', 'Medicina Interna', 'Pediatría', 'Ginecología',
  'Gastroenterología', 'Cardiología', 'Reumatología', 'Psiquiatría',
];

const _kCatMap = {
  'Medicina Interna':   'medicina_interna',
  'Pediatría':          'pediatria',
  'Ginecología':        'ginecologia',
  'Gastroenterología':  'gastroenterologia',
  'Cardiología':        'cardiologia',
  'Reumatología':       'reumatologia',
  'Psiquiatría':        'psiquiatria',
};

const _kColores = {
  'medicina_interna':  Color(0xFF1D9E75),
  'pediatria':         Color(0xFF0288D1),
  'ginecologia':       Color(0xFF7C4DFF),
  'gastroenterologia': Color(0xFFE65100),
  'cardiologia':       Color(0xFFE53935),
  'reumatologia':      Color(0xFF00897B),
  'psiquiatria':       Color(0xFF6A1B9A),
};

// ── Municipios de Colombia ────────────────────────────────────────────────────
const _kMunicipios = [
  'Cali, Valle del Cauca',        'Buenaventura, Valle del Cauca',
  'Palmira, Valle del Cauca',     'Tuluá, Valle del Cauca',
  'Buga, Valle del Cauca',        'Cartago, Valle del Cauca',
  'Jamundí, Valle del Cauca',     'Yumbo, Valle del Cauca',
  'Florida, Valle del Cauca',     'Pradera, Valle del Cauca',
  'Popayán, Cauca',               'Santander de Quilichao, Cauca',
  'Puerto Tejada, Cauca',         'Patía, Cauca',
  'Bogotá D.C.',                  'Medellín, Antioquia',
  'Barranquilla, Atlántico',      'Cartagena, Bolívar',
  'Cúcuta, Norte de Santander',   'Bucaramanga, Santander',
  'Pereira, Risaralda',           'Manizales, Caldas',
  'Ibagué, Tolima',               'Neiva, Huila',
  'Pasto, Nariño',                'Armenia, Quindío',
  'Montería, Córdoba',            'Sincelejo, Sucre',
  'Valledupar, Cesar',            'Riohacha, Guajira',
  'Villavicencio, Meta',          'Quibdó, Chocó',
  'Otro',
];

Color _colorDeCategoria(String? c) => _kColores[c] ?? const Color(0xFF1D9E75);

String _iniciales(String nombre) {
  final p = nombre.trim().split(' ')
      .where((x) => x.isNotEmpty && x != 'Dr.' && x != 'Dra.').toList();
  if (p.length >= 2) return '${p[0][0]}${p[1][0]}'.toUpperCase();
  return nombre.isNotEmpty ? nombre[0].toUpperCase() : '?';
}

// ═════════════════════════════════════════════════════════════════════════════
// PANTALLA PRINCIPAL
// ═════════════════════════════════════════════════════════════════════════════
class EspecialistasScreen extends StatefulWidget {
  const EspecialistasScreen({super.key});
  @override State<EspecialistasScreen> createState() => _EspecialistasScreenState();
}

class _EspecialistasScreenState extends State<EspecialistasScreen> {
  final _search = TextEditingController();
  int    _tab      = 0;
  String _busqueda = '';
  bool   _cargando      = true;
  bool   _online        = false;
  StreamSubscription<bool>? _connSub;
  List<Map<String, dynamic>> _todos = [];
  int    _disponibles   = 0;
  // Filtros adicionales
  bool   _soloDisponibles = false;
  double _califMin        = 0;   // 0 = sin filtro
  int    _expMin          = 0;   // 0 = sin filtro
  String _ciudadFiltro    = '';  // '' = todas

  @override
  void initState() {
    super.initState();
    _cargar();
    _initConn();
  }

  Future<void> _initConn() async {
    _online = await ConnectivityService.instance.verificarAhora();
    if (mounted) setState(() {});
    _connSub = ConnectivityService.instance.cambios.listen((v) {
      if (mounted) setState(() => _online = v);
    });
  }
  @override
  void dispose() {
    _connSub?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    final lista = await DatabaseHelper.instance.obtenerEspecialistas();
    if (!mounted) return;
    setState(() {
      _todos       = lista;
      _disponibles = lista.where((e) => e['disponible'] == 1).length;
      _cargando    = false;
    });
  }

  List<Map<String, dynamic>> get _filtrados {
    var r = List<Map<String, dynamic>>.from(_todos);
    // Búsqueda por texto
    if (_busqueda.isNotEmpty) {
      final q = _busqueda.toLowerCase();
      r = r.where((e) =>
        (e['nombre']       as String? ?? '').toLowerCase().contains(q) ||
        (e['especialidad'] as String? ?? '').toLowerCase().contains(q) ||
        (e['ciudad']       as String? ?? '').toLowerCase().contains(q)).toList();
    }
    // Filtro por categoría (chips superiores)
    if (_tab > 0) {
      final catId = _kCatMap[_kTabs[_tab]] ?? '';
      r = r.where((e) => (e['categoria_id'] as String? ?? '') == catId).toList();
    }
    // Filtro solo disponibles
    if (_soloDisponibles) {
      r = r.where((e) => e['disponible'] == 1).toList();
    }
    // Filtro calificación mínima
    if (_califMin > 0) {
      r = r.where((e) => (e['calificacion'] as num? ?? 0) >= _califMin).toList();
    }
    // Filtro experiencia mínima
    if (_expMin > 0) {
      r = r.where((e) => (e['anios_experiencia'] as int? ?? 0) >= _expMin).toList();
    }
    // Filtro por ciudad
    if (_ciudadFiltro.isNotEmpty) {
      r = r.where((e) =>
          (e['ciudad'] as String? ?? '').toLowerCase().contains(_ciudadFiltro.toLowerCase())).toList();
    }
    return r;
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? const Color(0xFFE24B4A) : const Color(0xFF1D9E75),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _abrirFormulario([Map<String, dynamic>? editar]) {
    final messenger = ScaffoldMessenger.of(context);
    final dc        = _dc(context);
    final verde     = Theme.of(context).colorScheme.primary;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _Formulario(
        dc: dc, verde: verde, datos: editar,
        onGuardar: (data) async {
          try {
            // Remover foto_path si la columna no existe aún en BD antigua
            final dataSafe = Map<String, dynamic>.from(data);
            if (editar != null) {
              await DatabaseHelper.instance.actualizarEspecialista(editar['id'] as int, dataSafe);
              messenger.showSnackBar(SnackBar(
                content: Text('Especialista "${dataSafe['nombre']}" actualizado'),
                backgroundColor: verde, behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ));
            } else {
              await DatabaseHelper.instance.insertarEspecialista(dataSafe);
              messenger.showSnackBar(SnackBar(
                content: Text('Especialista "${dataSafe['nombre']}" agregado'),
                backgroundColor: verde, behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ));
            }
            _cargar();
          } catch (e) {
            // Si falla por foto_path, intentar sin esa columna
            try {
              final dataSinFoto = Map<String, dynamic>.from(data)..remove('foto_path');
              if (editar != null) {
                await DatabaseHelper.instance.actualizarEspecialista(editar['id'] as int, dataSinFoto);
              } else {
                await DatabaseHelper.instance.insertarEspecialista(dataSinFoto);
              }
              messenger.showSnackBar(SnackBar(
                content: Text('Especialista "${data['nombre']}" guardado'),
                backgroundColor: verde, behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ));
              _cargar();
            } catch (e2) {
              messenger.showSnackBar(SnackBar(
                content: Text('Error al guardar: $e2'),
                backgroundColor: const Color(0xFFE24B4A), behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ));
            }
          }
        },
      ),
    );
  }

  void _eliminar(Map<String, dynamic> esp) {
    final dc = _dc(context);
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: dc.card,
      title: Text('Eliminar especialista',
          style: TextStyle(color: dc.textPrimary, fontWeight: FontWeight.bold)),
      content: Text('¿Eliminar a "${esp['nombre']}"? Esta acción no se puede deshacer.',
          style: TextStyle(color: dc.textSecondary, fontSize: 13)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: TextStyle(color: dc.textHint))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE24B4A)),
          onPressed: () async {
            Navigator.pop(context);
            await DatabaseHelper.instance.eliminarEspecialista(esp['id'] as int);
            _snack('Especialista eliminado');
            _cargar();
          },
          child: const Text('Eliminar', style: TextStyle(color: Colors.white))),
      ],
    ));
  }

  Future<void> _llamar(String? tel, String nombre) async {
    if (tel == null || tel.trim().isEmpty) {
      _snack('$nombre no tiene teléfono registrado', error: true); return;
    }
    final uri = Uri(scheme: 'tel', path: tel.trim().replaceAll(RegExp(r'[\s\-\(\)]'), ''));
    try { await launchUrl(uri, mode: LaunchMode.externalApplication); }
    catch (_) { _snack('No se pudo abrir la app de llamadas', error: true); }
  }

  // Indica si hay algún filtro adicional activo
  bool get _filtrosActivos =>
      _soloDisponibles || _califMin > 0 || _expMin > 0 || _ciudadFiltro.isNotEmpty;

  void _limpiarFiltros() => setState(() {
    _soloDisponibles = false;
    _califMin        = 0;
    _expMin          = 0;
    _ciudadFiltro    = '';
  });

  void _abrirFiltros() {
    final dc    = _dc(context);
    final verde = Theme.of(context).colorScheme.primary;

    // Variables locales del sheet (se aplican al cerrar con "Aplicar")
    bool   localDisp  = _soloDisponibles;
    double localCalif = _califMin;
    int    localExp   = _expMin;
    String localCiud  = _ciudadFiltro;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, ss) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: BoxDecoration(
              color: dc.card,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              // Handle
              Center(child: Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: dc.border, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),

              // Título
              Row(children: [
                Icon(Icons.tune_rounded, color: verde, size: 20),
                const SizedBox(width: 8),
                Text('Filtros', style: TextStyle(color: dc.textPrimary,
                    fontSize: 17, fontWeight: FontWeight.bold)),
                const Spacer(),
                GestureDetector(
                  onTap: () { ss(() { localDisp = false; localCalif = 0; localExp = 0; localCiud = ''; }); },
                  child: Text('Limpiar todo', style: TextStyle(color: verde, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ]),
              const SizedBox(height: 20),

              // ── Solo disponibles ─────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: dc.bg, borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: dc.border)),
                child: Row(children: [
                  Icon(Icons.circle, color: localDisp ? const Color(0xFF4CAF50) : dc.textHint, size: 14),
                  const SizedBox(width: 10),
                  Expanded(child: Text('Solo especialistas disponibles ahora',
                      style: TextStyle(color: dc.textPrimary, fontSize: 13))),
                  Switch(value: localDisp, activeColor: verde,
                      onChanged: (v) => ss(() => localDisp = v)),
                ]),
              ),
              const SizedBox(height: 14),

              // ── Calificación mínima ──────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: dc.bg, borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: dc.border)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Icon(Icons.star_rounded, color: const Color(0xFFFFB300), size: 16),
                    const SizedBox(width: 8),
                    Text('Calificación mínima',
                        style: TextStyle(color: dc.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Text(localCalif == 0 ? 'Todas' : '${localCalif.toStringAsFixed(1)}★',
                        style: TextStyle(color: verde, fontSize: 12, fontWeight: FontWeight.bold)),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: List.generate(5, (i) {
                    final estrella = (i + 1).toDouble();
                    return GestureDetector(
                      onTap: () => ss(() => localCalif = localCalif == estrella ? 0 : estrella),
                      child: Padding(padding: const EdgeInsets.only(right: 8),
                        child: Icon(
                          i < localCalif ? Icons.star_rounded : Icons.star_border_rounded,
                          color: const Color(0xFFFFB300), size: 32)),
                    );
                  })),
                ]),
              ),
              const SizedBox(height: 14),

              // ── Experiencia mínima ───────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: dc.bg, borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: dc.border)),
                child: Row(children: [
                  Icon(Icons.workspace_premium_rounded, color: dc.textSecondary, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Experiencia mínima',
                      style: TextStyle(color: dc.textPrimary, fontSize: 13, fontWeight: FontWeight.w600))),
                  GestureDetector(
                    onTap: () { if (localExp > 0) ss(() => localExp -= 5); },
                    child: Container(width: 32, height: 32,
                        decoration: BoxDecoration(color: dc.card, borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: dc.border)),
                        child: Icon(Icons.remove_rounded, color: dc.textSecondary, size: 16)),
                  ),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Text(localExp == 0 ? 'Todos' : '$localExp+ años',
                          style: TextStyle(color: dc.textPrimary, fontSize: 13, fontWeight: FontWeight.bold))),
                  GestureDetector(
                    onTap: () => ss(() => localExp = (localExp + 5).clamp(0, 30)),
                    child: Container(width: 32, height: 32,
                        decoration: BoxDecoration(color: dc.card, borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: dc.border)),
                        child: Icon(Icons.add_rounded, color: verde, size: 16)),
                  ),
                ]),
              ),
              const SizedBox(height: 14),

              // ── Ciudad ───────────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(color: dc.bg, borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: dc.border)),
                child: TextField(
                  controller: TextEditingController(text: localCiud),
                  onChanged: (v) => localCiud = v,
                  style: TextStyle(color: dc.textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Filtrar por ciudad (ej: Cali, Popayán...)',
                    hintStyle: TextStyle(color: dc.textHint, fontSize: 12),
                    prefixIcon: Icon(Icons.location_on_outlined, color: dc.textHint, size: 18),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 22),

              // ── Botón aplicar ────────────────────────────────────────────
              SizedBox(width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _soloDisponibles = localDisp;
                      _califMin        = localCalif;
                      _expMin          = localExp;
                      _ciudadFiltro    = localCiud.trim();
                    });
                    Navigator.pop(ctx);
                  },
                  icon: const Icon(Icons.check_rounded, color: Colors.white, size: 18),
                  label: const Text('Aplicar filtros',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: verde,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Future<void> _whatsapp(String? tel, String nombre) async {
    if (tel == null || tel.trim().isEmpty) {
      _snack('$nombre no tiene teléfono registrado', error: true); return;
    }
    final num = tel.trim().replaceAll(RegExp(r'[\s\-\(\)]'), '');
    final uri = Uri.parse('https://wa.me/${num.startsWith('+') ? num : '+57$num'}');
    try { await launchUrl(uri, mode: LaunchMode.externalApplication); }
    catch (_) { _snack('No se pudo abrir WhatsApp', error: true); }
  }

  Future<void> _agendar(Map<String, dynamic> esp) async {
    final uri = Uri.parse(
      'https://calendar.google.com/calendar/render?action=TEMPLATE'
      '&text=Consulta+con+${esp['nombre'] ?? ''}'
      '&details=Especialidad:+${esp['especialidad'] ?? ''}');
    try { await launchUrl(uri, mode: LaunchMode.externalApplication); }
    catch (_) { _snack('Agendando con ${esp['nombre']}'); }
  }

  @override
  Widget build(BuildContext context) {
    final dc    = _dc(context);
    final verde = Theme.of(context).colorScheme.primary;
    final lista = _filtrados;

    return Scaffold(
      backgroundColor: dc.bg,
      body: ResponsiveCenter(child: CustomScrollView(slivers: [
        SliverToBoxAdapter(child: _header(dc)),
        SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(16,16,16,0), child: _stats(dc, verde))),
        SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(16,14,16,0), child: _buscador(dc, verde))),
        SliverToBoxAdapter(child: _chips(dc, verde)),
        SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(16,16,16,0), child: _bannerIA(dc))),
        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.fromLTRB(16,22,16,10),
          child: Row(children: [
            Text('Especialistas registrados', style: TextStyle(color: dc.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
            const Spacer(),
            Text('${lista.length} encontrados', style: TextStyle(color: dc.textHint, fontSize: 12)),
          ]),
        )),
        if (_cargando)
          SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator(color: verde))))
        else if (lista.isEmpty)
          SliverToBoxAdapter(child: _vacio(dc))
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(delegate: SliverChildBuilderDelegate(
              (_, i) => Padding(padding: const EdgeInsets.only(bottom: 12), child: _card(lista[i], dc, verde)),
              childCount: lista.length,
            )),
          ),
        SliverToBoxAdapter(child: SafeArea(top: false, child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: _botonAgregar(dc, verde),
        ))),
      ]), ),
    );
  }

  // ── Widgets internos ─────────────────────────────────────────────────────
  Widget _header(DispersaludColors dc) => Container(
    decoration: const BoxDecoration(gradient: LinearGradient(
        colors: [Color(0xFF0A5240), Color(0xFF1D9E75)],
        begin: Alignment.topLeft, end: Alignment.bottomRight)),
    child: SafeArea(bottom: false, child: Padding(
      padding: const EdgeInsets.fromLTRB(16,12,16,18),
      child: Row(children: [
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Especialistas', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          Text('Conecta con expertos en salud', style: TextStyle(color: Color(0xFF9FE1CB), fontSize: 12)),
        ])),
        // Indicador Online / Offline dinámico (igual al resto de la app)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: _online
                ? Colors.green.withOpacity(0.25)
                : Colors.orange.withOpacity(0.25),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _online
                  ? Colors.greenAccent.withOpacity(0.7)
                  : Colors.orange.withOpacity(0.7),
            ),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 7, height: 7,
              decoration: BoxDecoration(
                color: _online ? Colors.greenAccent : Colors.orange,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              _online ? 'Online' : 'Offline',
              style: TextStyle(
                color: _online ? Colors.greenAccent : Colors.orange,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ]),
        ),
      ]),
    )),
  );

  Widget _stats(DispersaludColors dc, Color verde) {
    final items = [
      (Icons.people_alt_rounded,     '${_todos.length}',     'Especialistas\nActivos',  verde),
      (Icons.circle,                 '$_disponibles',        'Disponibles\nAhora',      const Color(0xFF4CAF50)),
      (Icons.calendar_today_rounded, '${_filtrados.length}', 'Filtrados\nActual',       const Color(0xFF2196F3)),
      (Icons.star_rounded,           '4.8',                  'Calificación\nPromedio',  const Color(0xFF7C4DFF)),
    ];
    return Row(children: List.generate(items.length, (i) => Expanded(
      child: Padding(padding: EdgeInsets.only(right: i < items.length - 1 ? 8 : 0),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          decoration: BoxDecoration(color: dc.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: dc.border)),
          child: Column(children: [
            Icon(items[i].$1, color: items[i].$4, size: 18),
            const SizedBox(height: 5),
            Text(items[i].$2, style: TextStyle(color: items[i].$4, fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(items[i].$3, textAlign: TextAlign.center, style: TextStyle(color: dc.textHint, fontSize: 9, height: 1.3)),
          ]),
        ),
      ),
    )));
  }

  Widget _buscador(DispersaludColors dc, Color verde) => Row(children: [
    Expanded(child: Container(
      height: 46,
      decoration: BoxDecoration(color: dc.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: dc.border)),
      child: TextField(
        controller: _search, onChanged: (v) => setState(() => _busqueda = v),
        style: TextStyle(color: dc.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Buscar especialista o especialidad...',
          hintStyle: TextStyle(color: dc.textHint, fontSize: 13),
          prefixIcon: Icon(Icons.search_rounded, color: dc.textHint, size: 20),
          suffixIcon: _busqueda.isNotEmpty
              ? GestureDetector(onTap: () { _search.clear(); setState(() => _busqueda = ''); },
                  child: Icon(Icons.close, color: dc.textHint, size: 18)) : null,
          border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(vertical: 13),
        ),
      ),
    )),
    const SizedBox(width: 10),
    GestureDetector(
      onTap: _abrirFiltros,
      child: Container(height: 46, padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: _filtrosActivos ? verde.withOpacity(0.12) : dc.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _filtrosActivos ? verde : dc.border,
            width: _filtrosActivos ? 1.5 : 1.0,
          ),
        ),
        child: Row(children: [
          Icon(Icons.tune_rounded,
              color: _filtrosActivos ? verde : dc.textSecondary, size: 18),
          const SizedBox(width: 6),
          Text('Filtros',
              style: TextStyle(
                color: _filtrosActivos ? verde : dc.textSecondary,
                fontSize: 13, fontWeight: FontWeight.w600)),
          if (_filtrosActivos) ...[
            const SizedBox(width: 5),
            Container(width: 7, height: 7,
                decoration: BoxDecoration(color: verde, shape: BoxShape.circle)),
          ],
        ]),
      ),
    ),
  ]);

  Widget _chips(DispersaludColors dc, Color verde) => SizedBox(height: 48,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      itemCount: _kTabs.length,
      separatorBuilder: (_, __) => const SizedBox(width: 8),
      itemBuilder: (_, i) {
        final sel = i == _tab;
        return GestureDetector(
          onTap: () => setState(() => _tab = i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: sel ? verde : dc.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: sel ? verde : dc.border, width: 1.2),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (i == 0) ...[Icon(Icons.grid_view_rounded, color: sel ? Colors.white : dc.textSecondary, size: 14), const SizedBox(width: 4)],
              Text(_kTabs[i], style: TextStyle(color: sel ? Colors.white : dc.textSecondary, fontSize: 12, fontWeight: sel ? FontWeight.w700 : FontWeight.w500)),
            ]),
          ),
        );
      },
    ),
  );

  Widget _bannerIA(DispersaludColors dc) => Container(
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [Color(0xFF0D1B2A), Color(0xFF1A2A1E)], begin: Alignment.topLeft, end: Alignment.bottomRight),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFF1D9E75).withOpacity(0.4)),
    ),
    padding: const EdgeInsets.all(16),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 60, height: 60,
        decoration: BoxDecoration(color: const Color(0xFF1D9E75).withOpacity(0.15),
            borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFF1D9E75).withOpacity(0.3))),
        child: const Icon(Icons.smart_toy_rounded, color: Color(0xFF1D9E75), size: 32)),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('IA DISPERSALUD', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
        const Text('Análisis inteligente de especialistas', style: TextStyle(color: Color(0xFF9FE1CB), fontSize: 11)),
        const SizedBox(height: 8),
        Text('La IA ha identificado especialistas recomendados para tus pacientes.',
            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11, height: 1.4)),
        const SizedBox(height: 10),
        Row(children: [
          _chipIA(Icons.people_rounded,        '${_todos.length}',   'Registrados', const Color(0xFF7C4DFF)),
          const SizedBox(width: 8),
          _chipIA(Icons.priority_high_rounded, '$_disponibles',      'Disponibles', const Color(0xFFEF9F27)),
          const SizedBox(width: 8),
          _chipIA(Icons.person_search_rounded, '${_filtrados.length}','Filtrados',  const Color(0xFF2196F3)),
        ]),
      ])),
    ]),
  );

  Widget _chipIA(IconData ico, String val, String lbl, Color c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(color: c.withOpacity(0.12), borderRadius: BorderRadius.circular(9), border: Border.all(color: c.withOpacity(0.25))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(ico, color: c, size: 13), const SizedBox(width: 4),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(val, style: TextStyle(color: c, fontSize: 13, fontWeight: FontWeight.bold, height: 1)),
        Text(lbl, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 8, height: 1.2)),
      ]),
    ]),
  );

  Widget _card(Map<String, dynamic> e, DispersaludColors dc, Color verde) {
    final disponible = (e['disponible'] as int? ?? 1) == 1;
    final dispColor  = disponible ? const Color(0xFF1D9E75) : const Color(0xFFEF9F27);
    final color      = _colorDeCategoria(e['categoria_id'] as String?);
    final fotoPath   = e['foto_path'] as String? ?? '';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: dc.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: dc.border)),
      child: Column(children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Avatar con foto real si existe
          Stack(children: [
            Container(
              width: 50, height: 50,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2), shape: BoxShape.circle,
                border: Border.all(color: color.withOpacity(0.4), width: 2),
                image: fotoPath.isNotEmpty
                    ? DecorationImage(image: (!kIsWeb && fotoPath.isNotEmpty) ? FileImage(File(fotoPath)) as ImageProvider : const AssetImage('assets/logo_dispersalud.png'), fit: BoxFit.cover)
                    : null,
              ),
              child: fotoPath.isEmpty
                  ? Center(child: Text(_iniciales(e['nombre'] as String? ?? ''),
                      style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.bold)))
                  : null,
            ),
            Positioned(right: 2, bottom: 2, child: Container(
              width: 11, height: 11,
              decoration: BoxDecoration(color: dispColor, shape: BoxShape.circle, border: Border.all(color: dc.card, width: 2)))),
          ]),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(e['nombre'] as String? ?? '',
                  style: TextStyle(color: dc.textPrimary, fontSize: 14, fontWeight: FontWeight.bold))),
              const Icon(Icons.verified_rounded, color: Color(0xFF2196F3), size: 15),
            ]),
            const SizedBox(height: 2),
            Text(e['especialidad'] as String? ?? '', style: TextStyle(color: dc.textSecondary, fontSize: 12)),
            const SizedBox(height: 5),
            Row(children: [
              const Icon(Icons.star_rounded, color: Color(0xFFFFB300), size: 13),
              const SizedBox(width: 3),
              Text('${(e['calificacion'] as num? ?? 4.5).toStringAsFixed(1)}',
                  style: TextStyle(color: dc.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
              Container(width: 1, height: 11, margin: const EdgeInsets.symmetric(horizontal: 7), color: dc.border),
              Text('${e['anios_exp'] ?? 1} años exp.', style: TextStyle(color: dc.textHint, fontSize: 11)),
            ]),
            if ((e['ciudad'] as String? ?? '').isNotEmpty) ...[
              const SizedBox(height: 3),
              Row(children: [
                Icon(Icons.location_on_rounded, color: dc.textHint, size: 11),
                const SizedBox(width: 3),
                Expanded(child: Text(e['ciudad'] as String? ?? '',
                    style: TextStyle(color: dc.textHint, fontSize: 11), overflow: TextOverflow.ellipsis)),
              ]),
            ],
          ])),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(color: dispColor.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
              child: Text(disponible ? 'Disponible' : 'Ocupado',
                  style: TextStyle(color: dispColor, fontSize: 10, fontWeight: FontWeight.w700))),
            const SizedBox(height: 5),
            if ((e['proximo_horario'] as String? ?? '').isNotEmpty) ...[
              Text('Próxima consulta', style: TextStyle(color: dc.textHint, fontSize: 9)),
              Text(e['proximo_horario'] as String? ?? '',
                  style: TextStyle(color: dc.textSecondary, fontSize: 10, fontWeight: FontWeight.w600)),
            ],
            const SizedBox(height: 4),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert_rounded, color: dc.textHint, size: 18),
              color: dc.card,
              onSelected: (v) {
                if (v == 'editar')   _abrirFormulario(e);
                if (v == 'eliminar') _eliminar(e);
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'editar', child: Row(children: [
                  Icon(Icons.edit_outlined, color: verde, size: 16), const SizedBox(width: 8),
                  Text('Editar', style: TextStyle(color: dc.textPrimary, fontSize: 13))])),
                PopupMenuItem(value: 'eliminar', child: Row(children: [
                  const Icon(Icons.delete_outline_rounded, color: Color(0xFFE24B4A), size: 16), const SizedBox(width: 8),
                  Text('Eliminar', style: TextStyle(color: dc.textPrimary, fontSize: 13))])),
              ],
            ),
          ]),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          _btn(Icons.phone_rounded,          'Llamar',   const Color(0xFF1D9E75),
              () => _llamar(e['telefono'] as String?, e['nombre'] as String? ?? '')),
          const SizedBox(width: 8),
          _btn(Icons.chat_rounded,           'WhatsApp', const Color(0xFF25D366),
              () => _whatsapp(e['telefono'] as String?, e['nombre'] as String? ?? '')),
          const SizedBox(width: 8),
          _btn(Icons.calendar_month_rounded, 'Agendar',  const Color(0xFF7C4DFF),
              () => _agendar(e)),
        ]),
      ]),
    );
  }

  Widget _btn(IconData ico, String lbl, Color c, VoidCallback fn) =>
    Expanded(child: GestureDetector(onTap: fn,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(color: c.withOpacity(0.12), borderRadius: BorderRadius.circular(10), border: Border.all(color: c.withOpacity(0.25))),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(ico, color: c, size: 15), const SizedBox(width: 5),
          Text(lbl, style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
      ),
    ));

  Widget _vacio(DispersaludColors dc) => Padding(
    padding: const EdgeInsets.all(40),
    child: Column(children: [
      Icon(Icons.people_outline_rounded, color: dc.border, size: 56),
      const SizedBox(height: 16),
      Text(_busqueda.isNotEmpty || _tab > 0 ? 'No se encontraron especialistas' : 'Aún no hay especialistas registrados',
          style: TextStyle(color: dc.textSecondary, fontSize: 15, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      Text(_busqueda.isNotEmpty || _tab > 0 ? 'Intenta con otra búsqueda o categoría' : 'Toca el botón de abajo para agregar el primero',
          textAlign: TextAlign.center, style: TextStyle(color: dc.textHint, fontSize: 12)),
    ]),
  );

  Widget _botonAgregar(DispersaludColors dc, Color verde) => GestureDetector(
    onTap: () => _abrirFormulario(),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF0A5240), Color(0xFF1D9E75)], begin: Alignment.centerLeft, end: Alignment.centerRight),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(children: [
        Container(width: 42, height: 42,
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
          child: const Icon(Icons.person_add_rounded, color: Colors.white, size: 20)),
        const SizedBox(width: 12),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Agregar nuevo especialista', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          SizedBox(height: 2),
          Text('Registra un especialista real en la base de datos', style: TextStyle(color: Color(0xFFB8F0DC), fontSize: 11)),
        ])),
        const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 15),
      ]),
    ),
  );
}

// ═════════════════════════════════════════════════════════════════════════════
// FORMULARIO
// ═════════════════════════════════════════════════════════════════════════════
class _Formulario extends StatefulWidget {
  final DispersaludColors dc;
  final Color verde;
  final Map<String, dynamic>? datos;
  final Future<void> Function(Map<String, dynamic>) onGuardar;
  const _Formulario({required this.dc, required this.verde, required this.onGuardar, this.datos});
  @override State<_Formulario> createState() => _FormularioState();
}

class _FormularioState extends State<_Formulario> {
  final _nombreCtrl    = TextEditingController();
  final _apellidoCtrl  = TextEditingController();
  final _telefonoCtrl  = TextEditingController();

  String   _catId       = 'medicina_interna';
  double   _calif       = 4.5;
  int      _anios       = 1;
  bool     _disponible  = true;
  String?  _ciudad;
  DateTime? _fecha;
  TimeOfDay? _hora;
  String?  _fotoPath;

  static const _especialidades = [
    ('medicina_interna',  'Medicina Interna'),
    ('pediatria',         'Pediatría'),
    ('ginecologia',       'Ginecología'),
    ('gastroenterologia', 'Gastroenterología'),
    ('cardiologia',       'Cardiología'),
    ('reumatologia',      'Reumatología'),
    ('psiquiatria',       'Psiquiatría'),
  ];

  static const _catNombre = {
    'medicina_interna':  'Medicina Interna',
    'pediatria':         'Pediatría',
    'ginecologia':       'Ginecología',
    'gastroenterologia': 'Gastroenterología',
    'cardiologia':       'Cardiología',
    'reumatologia':      'Reumatología',
    'psiquiatria':       'Psiquiatría',
  };

  String get _horarioTexto {
    if (_fecha == null && _hora == null) return '';
    final dias   = ['Lun','Mar','Mié','Jue','Vie','Sáb','Dom'];
    final meses  = ['ene','feb','mar','abr','may','jun','jul','ago','sep','oct','nov','dic'];
    final parte1 = _fecha != null ? '${dias[_fecha!.weekday-1]} ${_fecha!.day} ${meses[_fecha!.month-1]}' : '';
    final parte2 = _hora  != null ? _hora!.format(context) : '';
    return [parte1, parte2].where((s) => s.isNotEmpty).join(' · ');
  }

  @override
  void initState() {
    super.initState();
    final d = widget.datos;
    if (d != null) {
      final partes = (d['nombre'] as String? ?? '').trim().split(' ');
      _nombreCtrl.text   = partes.isNotEmpty ? partes.first : '';
      _apellidoCtrl.text = partes.length > 1 ? partes.sublist(1).join(' ') : '';
      _telefonoCtrl.text = d['telefono']    as String? ?? '';
      _ciudad            = d['ciudad']      as String?;
      _catId             = d['categoria_id'] as String? ?? 'medicina_interna';
      _calif             = (d['calificacion'] as num? ?? 4.5).toDouble();
      _anios             = d['anios_exp']   as int? ?? 1;
      _disponible        = (d['disponible'] as int? ?? 1) == 1;
      _fotoPath          = d['foto_path']   as String?;
    }
  }

  @override
  void dispose() { _nombreCtrl.dispose(); _apellidoCtrl.dispose(); _telefonoCtrl.dispose(); super.dispose(); }

  DispersaludColors get dc    => widget.dc;
  Color             get verde => widget.verde;

  // ── Seleccionar foto ──────────────────────────────────────────────────────
  void _seleccionarFoto() {
    final picker = ImagePicker();
    showModalBottomSheet(
      context: context,
      backgroundColor: dc.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(
          leading: Icon(Icons.camera_alt_rounded, color: verde),
          title: Text('Tomar foto', style: TextStyle(color: dc.textPrimary)),
          onTap: () async {
            Navigator.pop(context);
            final f = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
            if (f != null && mounted) setState(() => _fotoPath = f.path);
          },
        ),
        ListTile(
          leading: Icon(Icons.photo_library_rounded, color: verde),
          title: Text('Elegir de galería', style: TextStyle(color: dc.textPrimary)),
          onTap: () async {
            Navigator.pop(context);
            final f = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
            if (f != null && mounted) setState(() => _fotoPath = f.path);
          },
        ),
        if (_fotoPath != null && _fotoPath!.isNotEmpty)
          ListTile(
            leading: const Icon(Icons.delete_outline_rounded, color: Color(0xFFE24B4A)),
            title: const Text('Eliminar foto', style: TextStyle(color: Color(0xFFE24B4A))),
            onTap: () { Navigator.pop(context); setState(() => _fotoPath = null); },
          ),
      ])),
    );
  }

  // ── Selector de ciudad ────────────────────────────────────────────────────
  void _seleccionarCiudad() {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: dc.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        List<String> filtrados = List.from(_kMunicipios);
        return StatefulBuilder(builder: (_, ss) => Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(ctx).viewInsets.bottom + MediaQuery.of(ctx).padding.bottom + 16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 40, height: 4,
                decoration: BoxDecoration(color: dc.border, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 12),
            Text('Seleccionar ciudad', style: TextStyle(color: dc.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            // Buscador interno
            Container(
              height: 44,
              decoration: BoxDecoration(color: dc.bg, borderRadius: BorderRadius.circular(10), border: Border.all(color: dc.border)),
              child: TextField(
                controller: ctrl, autofocus: true,
                style: TextStyle(color: dc.textPrimary, fontSize: 13),
                onChanged: (v) => ss(() {
                  filtrados = _kMunicipios.where((m) => m.toLowerCase().contains(v.toLowerCase())).toList();
                }),
                decoration: InputDecoration(
                  hintText: 'Buscar ciudad...', hintStyle: TextStyle(color: dc.textHint, fontSize: 12),
                  prefixIcon: Icon(Icons.search_rounded, color: dc.textHint, size: 18),
                  border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(height: 280, child: ListView.builder(
              itemCount: filtrados.length,
              itemBuilder: (_, i) {
                final ciudad = filtrados[i];
                final sel = ciudad == _ciudad;
                return ListTile(
                  dense: true,
                  leading: Icon(sel ? Icons.check_circle_rounded : Icons.location_city_outlined,
                      color: sel ? verde : dc.textHint, size: 18),
                  title: Text(ciudad, style: TextStyle(color: sel ? verde : dc.textPrimary, fontSize: 13,
                      fontWeight: sel ? FontWeight.w600 : FontWeight.normal)),
                  onTap: () { setState(() => _ciudad = ciudad); Navigator.pop(ctx); },
                );
              },
            )),
          ]),
        ));
      },
    );
  }

  // ── Seleccionar fecha ─────────────────────────────────────────────────────
  Future<void> _seleccionarFecha() async {
    final hoy = DateTime.now();
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fecha ?? hoy,
      firstDate: hoy,
      lastDate: hoy.add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(colorScheme: ColorScheme.dark(
            primary: verde, surface: dc.card, onSurface: dc.textPrimary)),
        child: child!,
      ),
    );
    if (fecha != null && mounted) setState(() => _fecha = fecha);
  }

  // ── Seleccionar hora ──────────────────────────────────────────────────────
  Future<void> _seleccionarHora() async {
    final hora = await showTimePicker(
      context: context,
      initialTime: _hora ?? TimeOfDay.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(colorScheme: ColorScheme.dark(
            primary: verde, surface: dc.card, onSurface: dc.textPrimary)),
        child: child!,
      ),
    );
    if (hora != null && mounted) setState(() => _hora = hora);
  }

  // ── Guardar ───────────────────────────────────────────────────────────────
  Future<void> _guardar() async {
    final nombre = _nombreCtrl.text.trim();
    if (nombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('El nombre es obligatorio'),
        backgroundColor: const Color(0xFFE24B4A), behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      return;
    }
    final apellido      = _apellidoCtrl.text.trim();
    final nombreCompleto = apellido.isNotEmpty ? '$nombre $apellido' : nombre;
    final data = {
      'nombre':          nombreCompleto,
      'especialidad':    _catNombre[_catId] ?? 'Medicina Interna',
      'ciudad':          _ciudad ?? '',
      'telefono':        _telefonoCtrl.text.trim(),
      'proximo_horario': _horarioTexto,
      'categoria_id':    _catId,
      'calificacion':    _calif,
      'anios_exp':       _anios,
      'disponible':      _disponible ? 1 : 0,
      'foto_path':       _fotoPath ?? '',
    };
    // ⚠️ Capturar referencias ANTES del pop
    final callback  = widget.onGuardar;
    final navigator = Navigator.of(context);
    navigator.pop();
    await callback(data);
  }

  @override
  Widget build(BuildContext context) {
    final esEdicion = widget.datos != null;
    return Container(
      decoration: BoxDecoration(color: dc.bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      padding: EdgeInsets.fromLTRB(20, 16, 20,
          MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom + 32),
      child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [

        // Handle
        Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(color: dc.border, borderRadius: BorderRadius.circular(2)))),

        // Título
        Row(children: [
          Container(width: 36, height: 36,
            decoration: BoxDecoration(color: verde.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(esEdicion ? Icons.edit_rounded : Icons.person_add_rounded, color: verde, size: 20)),
          const SizedBox(width: 12),
          Text(esEdicion ? 'Editar especialista' : 'Nuevo especialista',
              style: TextStyle(color: verde, fontSize: 18, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 24),

        // ── Foto de perfil ────────────────────────────────────────────────
        Center(child: GestureDetector(
          onTap: _seleccionarFoto,
          child: Stack(children: [
            Container(
              width: 90, height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: verde.withOpacity(0.12),
                border: Border.all(color: verde.withOpacity(0.4), width: 2),
                image: (_fotoPath != null && _fotoPath!.isNotEmpty)
                    ? DecorationImage(image: (!kIsWeb && (_fotoPath?.isNotEmpty ?? false)) ? FileImage(File(_fotoPath!)) as ImageProvider : const AssetImage('assets/logo_dispersalud.png'), fit: BoxFit.cover)
                    : null,
              ),
              child: (_fotoPath == null || _fotoPath!.isEmpty)
                  ? Icon(Icons.person_rounded, color: verde.withOpacity(0.5), size: 44) : null,
            ),
            Positioned(right: 0, bottom: 0, child: Container(
              width: 28, height: 28,
              decoration: BoxDecoration(color: verde, shape: BoxShape.circle, border: Border.all(color: dc.bg, width: 2)),
              child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 14))),
          ]),
        )),
        const SizedBox(height: 6),
        Center(child: Text('Toca para agregar foto', style: TextStyle(color: dc.textHint, fontSize: 11))),
        const SizedBox(height: 20),

        // ── Nombre ───────────────────────────────────────────────────────
        _lbl('Nombre *'),
        _campo(_nombreCtrl, 'Ej: Juan o Dr. Juan', Icons.person_outline_rounded),
        const SizedBox(height: 12),

        // ── Apellidos ─────────────────────────────────────────────────────
        _lbl('Apellidos *'),
        _campo(_apellidoCtrl, 'Ej: García López', Icons.person_outline_rounded),
        const SizedBox(height: 12),

        // ── Ciudad selector ───────────────────────────────────────────────
        _lbl('Ciudad / Municipio'),
        GestureDetector(
          onTap: _seleccionarCiudad,
          child: Container(
            height: 50,
            decoration: BoxDecoration(color: dc.card, borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _ciudad != null ? verde : dc.border, width: _ciudad != null ? 1.5 : 1)),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(children: [
              Icon(Icons.location_on_outlined, color: _ciudad != null ? verde : dc.textHint, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(_ciudad ?? 'Seleccionar ciudad o municipio',
                  style: TextStyle(color: _ciudad != null ? dc.textPrimary : dc.textHint, fontSize: 13))),
              Icon(Icons.arrow_drop_down_rounded, color: dc.textHint, size: 24),
            ]),
          ),
        ),
        const SizedBox(height: 12),

        // ── Teléfono ──────────────────────────────────────────────────────
        _lbl('Teléfono de contacto'),
        _campo(_telefonoCtrl, 'Ej: 3001234567', Icons.phone_outlined, teclado: TextInputType.phone),
        const SizedBox(height: 12),

        // ── Próxima disponibilidad ────────────────────────────────────────
        _lbl('Próxima disponibilidad'),
        Row(children: [
          // Botón fecha
          Expanded(child: GestureDetector(
            onTap: _seleccionarFecha,
            child: Container(
              height: 50,
              decoration: BoxDecoration(color: dc.card, borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _fecha != null ? verde : dc.border, width: _fecha != null ? 1.5 : 1)),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(children: [
                Icon(Icons.calendar_today_rounded, color: _fecha != null ? verde : dc.textHint, size: 18),
                const SizedBox(width: 8),
                Text(_fecha != null ? '${_fecha!.day}/${_fecha!.month}/${_fecha!.year}' : 'Fecha',
                    style: TextStyle(color: _fecha != null ? dc.textPrimary : dc.textHint, fontSize: 12)),
              ]),
            ),
          )),
          const SizedBox(width: 10),
          // Botón hora
          Expanded(child: GestureDetector(
            onTap: _seleccionarHora,
            child: Container(
              height: 50,
              decoration: BoxDecoration(color: dc.card, borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _hora != null ? verde : dc.border, width: _hora != null ? 1.5 : 1)),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(children: [
                Icon(Icons.access_time_rounded, color: _hora != null ? verde : dc.textHint, size: 18),
                const SizedBox(width: 8),
                Text(_hora != null ? _hora!.format(context) : 'Hora',
                    style: TextStyle(color: _hora != null ? dc.textPrimary : dc.textHint, fontSize: 12)),
              ]),
            ),
          )),
        ]),
        if (_horarioTexto.isNotEmpty) ...[
          const SizedBox(height: 6),
          Row(children: [
            Icon(Icons.check_circle_outline_rounded, color: verde, size: 14),
            const SizedBox(width: 4),
            Text(_horarioTexto, style: TextStyle(color: verde, fontSize: 11, fontWeight: FontWeight.w600)),
          ]),
        ],
        const SizedBox(height: 20),

        // ── Especialidad ──────────────────────────────────────────────────
        _lbl('Especialidad médica *'),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: _especialidades.map((esp) {
          final sel = esp.$1 == _catId;
          return GestureDetector(
            onTap: () => setState(() => _catId = esp.$1),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: sel ? verde.withOpacity(0.12) : dc.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: sel ? verde : dc.border, width: 1.2),
              ),
              child: Text(esp.$2, style: TextStyle(color: sel ? verde : dc.textSecondary, fontSize: 12,
                  fontWeight: sel ? FontWeight.w700 : FontWeight.w500)),
            ),
          );
        }).toList()),
        const SizedBox(height: 20),

        // ── Calificación ──────────────────────────────────────────────────
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Calificación: ${_calif.toStringAsFixed(1)}',
              style: TextStyle(color: dc.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
          Row(children: List.generate(5, (i) => GestureDetector(
            onTap: () => setState(() => _calif = (i + 1).toDouble()),
            child: Icon(i < _calif.round() ? Icons.star_rounded : Icons.star_border_rounded,
                color: const Color(0xFFFFB300), size: 28)))),
        ]),
        const SizedBox(height: 20),

        // ── Años de experiencia ───────────────────────────────────────────
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Años de experiencia: $_anios',
              style: TextStyle(color: dc.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
          Row(children: [
            GestureDetector(onTap: () { if (_anios > 1) setState(() => _anios--); },
                child: Icon(Icons.remove_circle_outline_rounded, color: dc.textSecondary, size: 28)),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('$_anios', style: TextStyle(color: dc.textPrimary, fontSize: 16, fontWeight: FontWeight.bold))),
            GestureDetector(onTap: () => setState(() => _anios++),
                child: Icon(Icons.add_circle_outline_rounded, color: verde, size: 28)),
          ]),
        ]),
        const SizedBox(height: 20),

        // ── Disponible ────────────────────────────────────────────────────
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Disponible ahora', style: TextStyle(color: dc.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
          Switch(value: _disponible, activeColor: verde, onChanged: (v) => setState(() => _disponible = v)),
        ]),
        const SizedBox(height: 24),

        // ── Botón guardar ─────────────────────────────────────────────────
        SizedBox(width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: verde, foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            icon: Icon(esEdicion ? Icons.save_rounded : Icons.person_add_rounded, size: 20),
            label: Text(esEdicion ? 'Guardar cambios' : 'Agregar especialista',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            onPressed: _guardar,
          )),
      ])),
    );
  }

  Widget _lbl(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(t, style: TextStyle(color: dc.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)));

  Widget _campo(TextEditingController ctrl, String hint, IconData ico, {TextInputType teclado = TextInputType.text}) =>
    Container(
      height: 50,
      decoration: BoxDecoration(color: dc.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: dc.border)),
      child: TextField(
        controller: ctrl, keyboardType: teclado,
        style: TextStyle(color: dc.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint, hintStyle: TextStyle(color: dc.textHint, fontSize: 13),
          prefixIcon: Icon(ico, color: dc.textHint, size: 20),
          border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
}