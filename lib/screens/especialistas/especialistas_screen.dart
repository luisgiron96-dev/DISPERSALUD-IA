import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/app_theme.dart';
import '../../database/database_helper.dart';

// ─── Helper tema ─────────────────────────────────────────────────────────────
DispersaludColors _dc(BuildContext ctx) =>
    Theme.of(ctx).extension<DispersaludColors>() ?? DispersaludColors.dark;

// ─────────────────────────────────────────────────────────────────────────────
// CATEGORÍAS (chips de filtro)
// ─────────────────────────────────────────────────────────────────────────────
const _kTabs = [
  'Todos',
  'Medicina Interna',
  'Pediatría',
  'Ginecología',
  'Gastroenterología',
  'Cardiología',
  'Reumatología',
  'Psiquiatría',
];

// Mapeo nombre-chip → categoria_id guardada en BD
const _kCatMap = {
  'Medicina Interna':    'medicina_interna',
  'Pediatría':          'pediatria',
  'Ginecología':        'ginecologia',
  'Gastroenterología':  'gastroenterologia',
  'Cardiología':        'cardiologia',
  'Reumatología':       'reumatologia',
  'Psiquiatría':        'psiquiatria',
};

// Colores por especialidad
const _kColores = {
  'medicina_interna':   Color(0xFF1D9E75),
  'pediatria':          Color(0xFF0288D1),
  'ginecologia':        Color(0xFF7C4DFF),
  'gastroenterologia':  Color(0xFFE65100),
  'cardiologia':        Color(0xFFE53935),
  'reumatologia':       Color(0xFF00897B),
  'psiquiatria':        Color(0xFF6A1B9A),
};

Color _colorDeCategoria(String? catId) =>
    _kColores[catId] ?? const Color(0xFF1D9E75);

String _inicialesDe(String nombre) {
  final partes = nombre.trim().split(' ')
      .where((p) => p.isNotEmpty && p != 'Dr.' && p != 'Dra.').toList();
  if (partes.length >= 2) return '${partes[0][0]}${partes[1][0]}'.toUpperCase();
  return nombre.isNotEmpty ? nombre[0].toUpperCase() : '??';
}

// ─────────────────────────────────────────────────────────────────────────────
// PANTALLA PRINCIPAL
// ─────────────────────────────────────────────────────────────────────────────
class EspecialistasScreen extends StatefulWidget {
  const EspecialistasScreen({super.key});
  @override
  State<EspecialistasScreen> createState() => _EspecialistasScreenState();
}

class _EspecialistasScreenState extends State<EspecialistasScreen> {
  final _searchCtrl = TextEditingController();
  int    _tabIdx    = 0;
  String _busqueda  = '';
  bool   _cargando  = true;

  List<Map<String, dynamic>> _todos     = [];
  int _totalDisponibles = 0;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  // ── Carga desde SQLite ────────────────────────────────────────────────────
  Future<void> _cargar() async {
    setState(() => _cargando = true);
    final lista = await DatabaseHelper.instance.obtenerEspecialistas();
    if (!mounted) return;
    setState(() {
      _todos            = lista;
      _totalDisponibles = lista.where((e) => e['disponible'] == 1).length;
      _cargando         = false;
    });
  }

  // ── Lista filtrada ────────────────────────────────────────────────────────
  List<Map<String, dynamic>> get _filtrados {
    var r = List<Map<String, dynamic>>.from(_todos);
    if (_busqueda.isNotEmpty) {
      final q = _busqueda.toLowerCase();
      r = r.where((e) =>
        (e['nombre']       as String? ?? '').toLowerCase().contains(q) ||
        (e['especialidad'] as String? ?? '').toLowerCase().contains(q) ||
        (e['ciudad']       as String? ?? '').toLowerCase().contains(q)).toList();
    }
    if (_tabIdx > 0) {
      final catId = _kCatMap[_kTabs[_tabIdx]] ?? '';
      r = r.where((e) => (e['categoria_id'] as String? ?? '') == catId).toList();
    }
    return r;
  }

  // ── Acciones reales ───────────────────────────────────────────────────────
  Future<void> _llamar(String? telefono, String nombre) async {
    if (telefono == null || telefono.trim().isEmpty) {
      _snack('$nombre no tiene teléfono registrado', error: true); return;
    }
    final numero = telefono.trim().replaceAll(RegExp(r'[\s\-\(\)]'), '');
    final uri = Uri(scheme: 'tel', path: numero);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      _snack('No se pudo abrir la app de llamadas', error: true);
    }
  }

  Future<void> _whatsapp(String? telefono, String nombre) async {
    if (telefono == null || telefono.trim().isEmpty) {
      _snack('$nombre no tiene teléfono registrado', error: true); return;
    }
    // Limpia el número: quita espacios, guiones, paréntesis
    final numero = telefono.trim().replaceAll(RegExp(r'[\s\-\(\)]'), '');
    // Si no empieza con código de país, asume Colombia +57
    final completo = numero.startsWith('+') ? numero : '+57$numero';
    final uri = Uri.parse('https://wa.me/$completo');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _snack('No se pudo abrir WhatsApp', error: true);
    }
  }

  Future<void> _agendar(Map<String, dynamic> esp) async {
    // Intenta abrir Google Calendar para crear un evento
    final nombre = esp['nombre'] as String? ?? 'Especialista';
    final uri = Uri.parse(
      'https://calendar.google.com/calendar/render?action=TEMPLATE'
      '&text=Consulta+con+$nombre'
      '&details=Especialidad:+${esp['especialidad'] ?? ''}'
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _snack('Agendando consulta con $nombre', error: false);
    }
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

  // ── Abrir formulario agregar ──────────────────────────────────────────────
  void _abrirFormulario([Map<String, dynamic>? editar]) {
    final messenger = ScaffoldMessenger.of(context);
    final dc        = _dc(context);
    final verde     = Theme.of(context).colorScheme.primary;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FormularioEspecialista(
        dc: dc, verde: verde,
        datos: editar,
        onGuardar: (data) async {
          if (editar != null) {
            await DatabaseHelper.instance.actualizarEspecialista(editar['id'] as int, data);
            messenger.showSnackBar(SnackBar(
              content: Text('Especialista "${data['nombre']}" actualizado'),
              backgroundColor: verde, behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ));
          } else {
            await DatabaseHelper.instance.insertarEspecialista(data);
            messenger.showSnackBar(SnackBar(
              content: Text('Especialista "${data['nombre']}" agregado correctamente'),
              backgroundColor: verde, behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ));
          }
          _cargar();
        },
      ),
    );
  }

  // ── Eliminar con confirmación ─────────────────────────────────────────────
  void _confirmarEliminar(Map<String, dynamic> esp) {
    final dc = _dc(context);
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: dc.card,
      title: Text('Eliminar especialista', style: TextStyle(color: dc.textPrimary, fontWeight: FontWeight.bold)),
      content: Text('¿Seguro que deseas eliminar a "${esp['nombre']}"? Esta acción no se puede deshacer.',
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

  @override
  Widget build(BuildContext context) {
    final dc    = _dc(context);
    final verde = Theme.of(context).colorScheme.primary;
    final lista = _filtrados;

    return Scaffold(
      backgroundColor: dc.bg,
      body: CustomScrollView(slivers: [

        // ── Header ─────────────────────────────────────────────────────────
        SliverToBoxAdapter(child: _buildHeader(dc)),

        // ── Stats ──────────────────────────────────────────────────────────
        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: _buildStats(dc, verde),
        )),

        // ── Buscador ───────────────────────────────────────────────────────
        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: _buildBuscador(dc),
        )),

        // ── Chips especialidades ────────────────────────────────────────────
        SliverToBoxAdapter(child: SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            itemCount: _kTabs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final sel = i == _tabIdx;
              return GestureDetector(
                onTap: () => setState(() => _tabIdx = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: sel ? verde : dc.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: sel ? verde : dc.border, width: 1.2),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    if (i == 0) ...[
                      Icon(Icons.grid_view_rounded, color: sel ? Colors.white : dc.textSecondary, size: 14),
                      const SizedBox(width: 4),
                    ],
                    Text(_kTabs[i], style: TextStyle(
                        color: sel ? Colors.white : dc.textSecondary,
                        fontSize: 12,
                        fontWeight: sel ? FontWeight.w700 : FontWeight.w500)),
                  ]),
                ),
              );
            },
          ),
        )),

        // ── Banner IA ──────────────────────────────────────────────────────
        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: _buildBannerIA(dc),
        )),

        // ── Título lista ───────────────────────────────────────────────────
        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 22, 16, 10),
          child: Row(children: [
            Text('Especialistas registrados', style: TextStyle(
                color: dc.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
            const Spacer(),
            Text('${lista.length} encontrados', style: TextStyle(color: dc.textHint, fontSize: 12)),
          ]),
        )),

        // ── Lista / vacío / cargando ────────────────────────────────────────
        if (_cargando)
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.all(40),
            child: Center(child: CircularProgressIndicator(color: verde)),
          ))
        else if (lista.isEmpty)
          SliverToBoxAdapter(child: _buildVacio(dc))
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(delegate: SliverChildBuilderDelegate(
              (_, i) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildCard(lista[i], dc, verde),
              ),
              childCount: lista.length,
            )),
          ),

        // ── Botón agregar ─────────────────────────────────────────────────
        SliverToBoxAdapter(child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: _buildBotonAgregar(dc, verde),
          ),
        )),
      ]),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BUILDERS
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildHeader(DispersaludColors dc) => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFF0A5240), Color(0xFF1D9E75)],
        begin: Alignment.topLeft, end: Alignment.bottomRight,
      ),
    ),
    child: SafeArea(bottom: false, child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
      child: Row(children: [
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Especialistas', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          Text('Conecta con expertos en salud', style: TextStyle(color: Color(0xFF9FE1CB), fontSize: 12)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.wifi_off_rounded, color: Colors.white, size: 13),
            SizedBox(width: 4),
            Text('Modo Offline', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
          ]),
        ),
        const SizedBox(width: 10),
        Stack(children: [
          Container(width: 36, height: 36,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
            child: const Icon(Icons.notifications_outlined, color: Colors.white, size: 18)),
          Positioned(right: 0, top: 0, child: Container(
            width: 15, height: 15,
            decoration: const BoxDecoration(color: Color(0xFFE24B4A), shape: BoxShape.circle),
            child: const Center(child: Text('3', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold))))),
        ]),
      ]),
    )),
  );

  Widget _buildStats(DispersaludColors dc, Color verde) {
    final items = [
      (Icons.people_alt_rounded,     '${_todos.length}',     'Especialistas\nActivos',  verde),
      (Icons.circle,                 '$_totalDisponibles',   'Disponibles\nAhora',      const Color(0xFF4CAF50)),
      (Icons.calendar_today_rounded, '${_filtrados.length}', 'Filtrados\nActual',       const Color(0xFF2196F3)),
      (Icons.star_rounded,           '4.8',                  'Calificación\nPromedio',  const Color(0xFF7C4DFF)),
    ];
    return Row(children: List.generate(items.length, (i) => Expanded(
      child: Padding(
        padding: EdgeInsets.only(right: i < items.length - 1 ? 8 : 0),
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

  Widget _buildBuscador(DispersaludColors dc) => Row(children: [
    Expanded(child: Container(
      height: 46,
      decoration: BoxDecoration(color: dc.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: dc.border)),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => setState(() => _busqueda = v),
        style: TextStyle(color: dc.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Buscar especialista o especialidad...',
          hintStyle: TextStyle(color: dc.textHint, fontSize: 13),
          prefixIcon: Icon(Icons.search_rounded, color: dc.textHint, size: 20),
          suffixIcon: _busqueda.isNotEmpty
              ? GestureDetector(
                  onTap: () { _searchCtrl.clear(); setState(() => _busqueda = ''); },
                  child: Icon(Icons.close, color: dc.textHint, size: 18))
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 13),
        ),
      ),
    )),
    const SizedBox(width: 10),
    Container(
      height: 46, padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(color: dc.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: dc.border)),
      child: Row(children: [
        Icon(Icons.tune_rounded, color: dc.textSecondary, size: 18),
        const SizedBox(width: 6),
        Text('Filtros', style: TextStyle(color: dc.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
      ]),
    ),
  ]);

  Widget _buildBannerIA(DispersaludColors dc) => Container(
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [Color(0xFF0D1B2A), Color(0xFF1A2A1E)], begin: Alignment.topLeft, end: Alignment.bottomRight),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFF1D9E75).withOpacity(0.4)),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 60, height: 60,
          decoration: BoxDecoration(
            color: const Color(0xFF1D9E75).withOpacity(0.15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF1D9E75).withOpacity(0.3)),
          ),
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
            _chipIA(Icons.people_rounded,        '${_todos.length}',   'Registrados',  const Color(0xFF7C4DFF)),
            const SizedBox(width: 8),
            _chipIA(Icons.priority_high_rounded, '$_totalDisponibles', 'Disponibles',  const Color(0xFFEF9F27)),
            const SizedBox(width: 8),
            _chipIA(Icons.person_search_rounded, '${_filtrados.length}','Filtrados',   const Color(0xFF2196F3)),
          ]),
        ])),
      ]),
    ),
  );

  Widget _chipIA(IconData icono, String valor, String label, Color color) =>
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(9),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icono, color: color, size: 13),
        const SizedBox(width: 4),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(valor, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold, height: 1)),
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 8, height: 1.2)),
        ]),
      ]),
    );

  Widget _buildCard(Map<String, dynamic> e, DispersaludColors dc, Color verde) {
    final disponible = (e['disponible'] as int? ?? 1) == 1;
    final dispColor  = disponible ? const Color(0xFF1D9E75) : const Color(0xFFEF9F27);
    final color      = _colorDeCategoria(e['categoria_id'] as String?);
    final iniciales  = _inicialesDe(e['nombre'] as String? ?? '');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: dc.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: dc.border)),
      child: Column(children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Avatar
          Stack(children: [
            Container(
              width: 50, height: 50,
              decoration: BoxDecoration(color: color.withOpacity(0.2), shape: BoxShape.circle, border: Border.all(color: color.withOpacity(0.4), width: 2)),
              child: Center(child: Text(iniciales, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.bold))),
            ),
            Positioned(right: 2, bottom: 2, child: Container(
              width: 11, height: 11,
              decoration: BoxDecoration(color: dispColor, shape: BoxShape.circle, border: Border.all(color: dc.card, width: 2)))),
          ]),
          const SizedBox(width: 12),
          // Info
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(e['nombre'] as String? ?? '', style: TextStyle(color: dc.textPrimary, fontSize: 14, fontWeight: FontWeight.bold))),
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
              Text('${e['anios_exp'] ?? 1} años exp.',
                  style: TextStyle(color: dc.textHint, fontSize: 11)),
            ]),
            const SizedBox(height: 3),
            if ((e['ciudad'] as String? ?? '').isNotEmpty)
              Row(children: [
                Icon(Icons.location_on_rounded, color: dc.textHint, size: 11),
                const SizedBox(width: 3),
                Expanded(child: Text(e['ciudad'] as String? ?? '',
                    style: TextStyle(color: dc.textHint, fontSize: 11), overflow: TextOverflow.ellipsis)),
              ]),
          ])),
          const SizedBox(width: 8),
          // Estado + menú
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
            // Menú editar/eliminar
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert_rounded, color: dc.textHint, size: 18),
              color: dc.card,
              onSelected: (v) {
                if (v == 'editar')   _abrirFormulario(e);
                if (v == 'eliminar') _confirmarEliminar(e);
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'editar',
                  child: Row(children: [Icon(Icons.edit_outlined, color: verde, size: 16), const SizedBox(width: 8), Text('Editar', style: TextStyle(color: dc.textPrimary, fontSize: 13))])),
                PopupMenuItem(value: 'eliminar',
                  child: Row(children: [const Icon(Icons.delete_outline_rounded, color: Color(0xFFE24B4A), size: 16), const SizedBox(width: 8), Text('Eliminar', style: TextStyle(color: dc.textPrimary, fontSize: 13))])),
              ],
            ),
          ]),
        ]),
        const SizedBox(height: 12),
        // Botones acción reales
        Row(children: [
          _btnAccion(Icons.phone_rounded,         'Llamar',    const Color(0xFF1D9E75),
              () => _llamar(e['telefono'] as String?, e['nombre'] as String? ?? '')),
          const SizedBox(width: 8),
          _btnAccion(Icons.chat_rounded,          'WhatsApp',  const Color(0xFF25D366),
              () => _whatsapp(e['telefono'] as String?, e['nombre'] as String? ?? '')),
          const SizedBox(width: 8),
          _btnAccion(Icons.calendar_month_rounded,'Agendar',   const Color(0xFF7C4DFF),
              () => _agendar(e)),
        ]),
      ]),
    );
  }

  Widget _btnAccion(IconData ico, String lbl, Color c, VoidCallback fn) =>
    Expanded(child: GestureDetector(
      onTap: fn,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(color: c.withOpacity(0.12), borderRadius: BorderRadius.circular(10), border: Border.all(color: c.withOpacity(0.25))),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(ico, color: c, size: 15),
          const SizedBox(width: 5),
          Text(lbl, style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
      ),
    ));

  Widget _buildVacio(DispersaludColors dc) => Padding(
    padding: const EdgeInsets.all(40),
    child: Column(children: [
      Icon(Icons.people_outline_rounded, color: dc.border, size: 56),
      const SizedBox(height: 16),
      Text(_busqueda.isNotEmpty || _tabIdx > 0
            ? 'No se encontraron especialistas'
            : 'Aún no hay especialistas registrados',
          style: TextStyle(color: dc.textSecondary, fontSize: 15, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      Text(_busqueda.isNotEmpty || _tabIdx > 0
            ? 'Intenta con otra búsqueda o categoría'
            : 'Toca el botón de abajo para agregar el primero',
          textAlign: TextAlign.center,
          style: TextStyle(color: dc.textHint, fontSize: 12)),
    ]),
  );

  Widget _buildBotonAgregar(DispersaludColors dc, Color verde) =>
    GestureDetector(
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

// ─────────────────────────────────────────────────────────────────────────────
// FORMULARIO — crea o edita un especialista real en SQLite
// ─────────────────────────────────────────────────────────────────────────────
class _FormularioEspecialista extends StatefulWidget {
  final DispersaludColors dc;
  final Color verde;
  final Map<String, dynamic>? datos;         // null = nuevo, no-null = edición
  final Future<void> Function(Map<String, dynamic>) onGuardar;

  const _FormularioEspecialista({
    required this.dc, required this.verde,
    required this.onGuardar, this.datos,
  });

  @override
  State<_FormularioEspecialista> createState() => _FormularioEspecialistaState();
}

class _FormularioEspecialistaState extends State<_FormularioEspecialista> {
  final _nombreCtrl   = TextEditingController();
  final _ciudadCtrl   = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _horarioCtrl  = TextEditingController();

  String _categoriaId  = 'medicina_interna';
  double _calificacion = 4.5;
  int    _anios        = 1;
  bool   _disponible   = true;
  bool   _guardando    = false;

  static const _especialidades = [
    ('medicina_interna',   'Medicina Interna'),
    ('pediatria',          'Pediatría'),
    ('ginecologia',        'Ginecología'),
    ('gastroenterologia',  'Gastroenterología'),
    ('cardiologia',        'Cardiología'),
    ('reumatologia',       'Reumatología'),
    ('psiquiatria',        'Psiquiatría'),
  ];

  // Mapa categoriaId → nombre especialidad para el guardado
  static const _catNombre = {
    'medicina_interna':  'Medicina Interna',
    'pediatria':         'Pediatría',
    'ginecologia':       'Ginecología',
    'gastroenterologia': 'Gastroenterología',
    'cardiologia':       'Cardiología',
    'reumatologia':      'Reumatología',
    'psiquiatria':       'Psiquiatría',
  };

  @override
  void initState() {
    super.initState();
    // Si viene con datos = modo edición
    final d = widget.datos;
    if (d != null) {
      _nombreCtrl.text   = d['nombre']          as String? ?? '';
      _ciudadCtrl.text   = d['ciudad']          as String? ?? '';
      _telefonoCtrl.text = d['telefono']        as String? ?? '';
      _horarioCtrl.text  = d['proximo_horario'] as String? ?? '';
      _categoriaId       = d['categoria_id']    as String? ?? 'medicina_interna';
      _calificacion      = (d['calificacion']   as num? ?? 4.5).toDouble();
      _anios             = d['anios_exp']        as int? ?? 1;
      _disponible        = (d['disponible']      as int? ?? 1) == 1;
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose(); _ciudadCtrl.dispose();
    _telefonoCtrl.dispose(); _horarioCtrl.dispose();
    super.dispose();
  }

  DispersaludColors get dc    => widget.dc;
  Color             get verde => widget.verde;

  Future<void> _guardar() async {
    final nombre = _nombreCtrl.text.trim();
    if (nombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('El nombre es obligatorio'),
        backgroundColor: const Color(0xFFE24B4A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      return;
    }

    setState(() => _guardando = true);

    final data = {
      'nombre':          nombre,
      'especialidad':    _catNombre[_categoriaId] ?? 'Medicina Interna',
      'ciudad':          _ciudadCtrl.text.trim(),
      'telefono':        _telefonoCtrl.text.trim(),
      'proximo_horario': _horarioCtrl.text.trim(),
      'categoria_id':    _categoriaId,
      'calificacion':    _calificacion,
      'anios_exp':       _anios,
      'disponible':      _disponible ? 1 : 0,
    };

    Navigator.of(context).pop();
    await widget.onGuardar(data);
  }

  @override
  Widget build(BuildContext context) {
    final esEdicion = widget.datos != null;
    return Container(
      decoration: BoxDecoration(color: dc.bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom + 32),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [

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
          const SizedBox(height: 20),

          // Nombre *
          _label('Nombre completo *'),
          _campo(_nombreCtrl, 'Ej: Dr. Juan García', Icons.person_outline_rounded),
          const SizedBox(height: 12),

          // Ciudad
          _label('Ciudad'),
          _campo(_ciudadCtrl, 'Ej: Cali, Valle del Cauca', Icons.location_on_outlined),
          const SizedBox(height: 12),

          // Teléfono
          _label('Teléfono de contacto'),
          _campo(_telefonoCtrl, 'Ej: 3001234567', Icons.phone_outlined, teclado: TextInputType.phone),
          const SizedBox(height: 12),

          // Horario
          _label('Próxima disponibilidad'),
          _campo(_horarioCtrl, 'Ej: 3:00 p.m. o Lunes 8am', Icons.access_time_outlined),
          const SizedBox(height: 20),

          // Especialidad chips
          _label('Especialidad médica *'),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8,
            children: _especialidades.map((esp) {
              final sel = esp.$1 == _categoriaId;
              return GestureDetector(
                onTap: () => setState(() => _categoriaId = esp.$1),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: sel ? verde.withOpacity(0.12) : dc.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: sel ? verde : dc.border, width: 1.2),
                  ),
                  child: Text(esp.$2, style: TextStyle(
                      color: sel ? verde : dc.textSecondary, fontSize: 12,
                      fontWeight: sel ? FontWeight.w700 : FontWeight.w500)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Calificación
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Calificación: ${_calificacion.toStringAsFixed(1)}',
                style: TextStyle(color: dc.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
            Row(children: List.generate(5, (i) {
              final llena = i < _calificacion.round();
              return GestureDetector(
                onTap: () => setState(() => _calificacion = (i + 1).toDouble()),
                child: Icon(llena ? Icons.star_rounded : Icons.star_border_rounded,
                    color: const Color(0xFFFFB300), size: 28));
            })),
          ]),
          const SizedBox(height: 20),

          // Años
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

          // Disponible
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Disponible ahora', style: TextStyle(color: dc.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
            Switch(value: _disponible, activeColor: verde, onChanged: (v) => setState(() => _disponible = v)),
          ]),
          const SizedBox(height: 24),

          // Botón guardar
          SizedBox(width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: verde, foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              icon: _guardando
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Icon(esEdicion ? Icons.save_rounded : Icons.person_add_rounded, size: 20),
              label: Text(esEdicion ? 'Guardar cambios' : 'Agregar especialista',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              onPressed: _guardando ? null : _guardar,
            )),
        ]),
      ),
    );
  }

  Widget _label(String texto) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(texto, style: TextStyle(color: dc.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)));

  Widget _campo(TextEditingController ctrl, String hint, IconData ico,
      {TextInputType teclado = TextInputType.text}) =>
    Container(
      height: 50,
      decoration: BoxDecoration(color: dc.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: dc.border)),
      child: TextField(
        controller: ctrl, keyboardType: teclado,
        style: TextStyle(color: dc.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint, hintStyle: TextStyle(color: dc.textHint, fontSize: 13),
          prefixIcon: Icon(ico, color: dc.textHint, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
}