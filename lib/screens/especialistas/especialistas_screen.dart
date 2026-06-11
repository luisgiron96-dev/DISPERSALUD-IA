import 'package:flutter/material.dart';
import '../../core/app_theme.dart';

// ─── Helper tema ──────────────────────────────────────────────────────────────
DispersaludColors _dc(BuildContext ctx) =>
    Theme.of(ctx).extension<DispersaludColors>() ?? DispersaludColors.dark;

// ─────────────────────────────────────────────────────────────────────────────
// MODELO
// ─────────────────────────────────────────────────────────────────────────────
class _Especialista {
  final String nombre, especialidad, ubicacion, proximaConsulta, iniciales;
  final double calificacion;
  final int opiniones, aniosExp;
  final bool disponible;
  final Color color;

  const _Especialista({
    required this.nombre, required this.especialidad,
    required this.ubicacion, required this.proximaConsulta,
    required this.iniciales, required this.calificacion,
    required this.opiniones, required this.aniosExp,
    required this.disponible, required this.color,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// PANTALLA
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

  // Lista mutable para poder agregar especialistas
  final List<_Especialista> _lista = [
    const _Especialista(nombre: 'Dra. Ana Rodríguez', especialidad: 'Ginecología y Obstetricia',
      calificacion: 4.9, opiniones: 128, aniosExp: 12, ubicacion: 'Cali, Valle del Cauca',
      disponible: true,  proximaConsulta: '3:00 p.m.',        iniciales: 'AR', color: Color(0xFF7C4DFF)),
    const _Especialista(nombre: 'Dr. Carlos Pérez',   especialidad: 'Cardiología',
      calificacion: 4.8, opiniones: 98,  aniosExp: 15, ubicacion: 'Popayán, Cauca',
      disponible: false, proximaConsulta: '5:30 p.m.',        iniciales: 'CP', color: Color(0xFF1D9E75)),
    const _Especialista(nombre: 'Dra. María Gómez',   especialidad: 'Pediatría',
      calificacion: 4.9, opiniones: 156, aniosExp: 10, ubicacion: 'Palmira, Valle del Cauca',
      disponible: true,  proximaConsulta: '2:00 p.m.',        iniciales: 'MG', color: Color(0xFF0288D1)),
    const _Especialista(nombre: 'Dr. Jorge Morales',  especialidad: 'Medicina General',
      calificacion: 4.7, opiniones: 204, aniosExp: 8,  ubicacion: 'Santander de Q., Cauca',
      disponible: true,  proximaConsulta: '1:00 p.m.',        iniciales: 'JM', color: Color(0xFFE65100)),
    const _Especialista(nombre: 'Dra. Lucía Vargas',  especialidad: 'Salud Mental / Psiquiatría',
      calificacion: 4.8, opiniones: 87,  aniosExp: 9,  ubicacion: 'Bogotá D.C.',
      disponible: false, proximaConsulta: 'Mañana 9:00 a.m.', iniciales: 'LV', color: Color(0xFF6A1B9A)),
  ];

  static const _tabs = [
    'Todos', 'Medicina General', 'Ginecología',
    'Pediatría', 'Cardiología', 'Salud Mental',
  ];

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  List<_Especialista> get _filtrados {
    var r = List<_Especialista>.from(_lista);
    if (_busqueda.isNotEmpty) {
      final q = _busqueda.toLowerCase();
      r = r.where((e) =>
        e.nombre.toLowerCase().contains(q) ||
        e.especialidad.toLowerCase().contains(q)).toList();
    }
    if (_tabIdx > 0) {
      final t = _tabs[_tabIdx].toLowerCase();
      r = r.where((e) => e.especialidad.toLowerCase().contains(t)).toList();
    }
    return r;
  }

  // ── Abrir formulario ── ¡LA CLAVE DEL FIX!
  // Usamos un GlobalKey para mostrar el snackbar sin depender del context
  // del modal, que ya fue destruido cuando llamamos Navigator.pop().
  void _abrirFormulario() {
    // 1. Capturamos ScaffoldMessenger ANTES de abrir el modal
    //    El messenger es del Scaffold principal — sobrevive al pop del sheet
    final messenger = ScaffoldMessenger.of(context);

    // 2. Capturamos los colores ANTES de abrir el modal
    final dc    = _dc(context);
    final verde = Theme.of(context).colorScheme.primary;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      // 3. El builder usa SOLO los valores capturados, nunca 'context' del padre
      builder: (sheetCtx) => _Formulario(
        dc:      dc,
        verde:   verde,
        // 4. El callback recibe el nombre y usa el messenger capturado
        //    — ya no depende de ningún context del modal
        onGuardar: (nombre) {
          messenger.showSnackBar(SnackBar(
            content: Text('Especialista "$nombre" agregado correctamente'),
            backgroundColor: verde,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ));
          // Actualizar la lista en el state padre
          setState(() {
            _lista.add(_Especialista(
              nombre: nombre, especialidad: 'Medicina General',
              calificacion: 4.5, opiniones: 0, aniosExp: 1,
              ubicacion: 'Cauca', disponible: true,
              proximaConsulta: 'Por definir',
              iniciales: nombre.isNotEmpty
                  ? nombre.trim().split(' ').map((p) => p[0]).take(2).join().toUpperCase()
                  : 'NN',
              color: const Color(0xFF1D9E75),
            ));
          });
        },
      ),
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final dc    = _dc(context);
    final verde = Theme.of(context).colorScheme.primary;
    final lista = _filtrados;

    return Scaffold(
      backgroundColor: dc.bg,
      body: CustomScrollView(
        slivers: [

          // ── Header ───────────────────────────────────────────────────────
          SliverToBoxAdapter(child: _buildHeader(dc)),

          // ── Stats ────────────────────────────────────────────────────────
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _buildStats(dc, verde),
          )),

          // ── Buscador ─────────────────────────────────────────────────────
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: _buildBuscador(dc),
          )),

          // ── Chips especialidades ──────────────────────────────────────────
          SliverToBoxAdapter(child: SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              itemCount: _tabs.length,
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
                      border: Border.all(
                          color: sel ? verde : dc.border, width: 1.2),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      if (i == 0) ...[
                        Icon(Icons.grid_view_rounded,
                            color: sel ? Colors.white : dc.textSecondary, size: 14),
                        const SizedBox(width: 4),
                      ],
                      Text(_tabs[i], style: TextStyle(
                          color: sel ? Colors.white : dc.textSecondary,
                          fontSize: 12,
                          fontWeight: sel ? FontWeight.w700 : FontWeight.w500)),
                    ]),
                  ),
                );
              },
            ),
          )),

          // ── Banner IA ─────────────────────────────────────────────────────
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _buildBannerIA(dc),
          )),

          // ── Título lista ──────────────────────────────────────────────────
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 22, 16, 10),
            child: Text('Especialistas disponibles',
                style: TextStyle(color: dc.textPrimary,
                    fontSize: 16, fontWeight: FontWeight.bold)),
          )),

          // ── Lista ─────────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: lista.isEmpty
                ? SliverToBoxAdapter(child: _buildVacio(dc))
                : SliverList(delegate: SliverChildBuilderDelegate(
                    (_, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildCard(lista[i], dc, verde),
                    ),
                    childCount: lista.length,
                  )),
          ),

          // ── Botón solicitar ───────────────────────────────────────────────
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
            child: _buildBotonSolicitar(dc, verde),
          )),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BUILDERS INTERNOS — todos reciben dc y verde como parámetros
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildHeader(DispersaludColors dc) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0A5240), Color(0xFF1D9E75)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(bottom: false, child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
        child: Row(children: [
          const SizedBox(width: 4),
          const Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Especialistas', style: TextStyle(
                  color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              Text('Conecta con expertos en salud',
                  style: TextStyle(color: Color(0xFF9FE1CB), fontSize: 12)),
            ],
          )),
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
              Text('Modo Offline', style: TextStyle(
                  color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
            ]),
          ),
          const SizedBox(width: 10),
          Stack(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
              child: const Icon(Icons.notifications_outlined,
                  color: Colors.white, size: 18),
            ),
            Positioned(right: 0, top: 0, child: Container(
              width: 15, height: 15,
              decoration: const BoxDecoration(
                  color: Color(0xFFE24B4A), shape: BoxShape.circle),
              child: const Center(child: Text('3',
                  style: TextStyle(color: Colors.white,
                      fontSize: 8, fontWeight: FontWeight.bold))),
            )),
          ]),
        ]),
      )),
    );
  }

  Widget _buildStats(DispersaludColors dc, Color verde) {
    final items = [
      (Icons.people_alt_rounded,     '${_lista.length}', 'Especialistas\nActivos',  verde),
      (Icons.circle,                 '${_lista.where((e) => e.disponible).length}', 'Disponibles\nAhora', const Color(0xFF4CAF50)),
      (Icons.calendar_today_rounded, '12',  'Consultas\nHoy',         const Color(0xFF2196F3)),
      (Icons.star_rounded,           '4.8', 'Calificación\nPromedio', const Color(0xFF7C4DFF)),
    ];
    return Row(
      children: List.generate(items.length, (i) => Expanded(
        child: Padding(
          padding: EdgeInsets.only(right: i < items.length - 1 ? 8 : 0),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            decoration: BoxDecoration(
              color: dc.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: dc.border),
            ),
            child: Column(children: [
              Icon(items[i].$1, color: items[i].$4, size: 18),
              const SizedBox(height: 5),
              Text(items[i].$2, style: TextStyle(
                  color: items[i].$4, fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(items[i].$3, textAlign: TextAlign.center,
                  style: TextStyle(color: dc.textHint, fontSize: 9, height: 1.3)),
            ]),
          ),
        ),
      )),
    );
  }

  Widget _buildBuscador(DispersaludColors dc) {
    return Row(children: [
      Expanded(child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: dc.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: dc.border),
        ),
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
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: dc.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: dc.border),
        ),
        child: Row(children: [
          Icon(Icons.tune_rounded, color: dc.textSecondary, size: 18),
          const SizedBox(width: 6),
          Text('Filtros', style: TextStyle(
              color: dc.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
        ]),
      ),
    ]);
  }

  Widget _buildBannerIA(DispersaludColors dc) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D1B2A), Color(0xFF1A2A1E)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
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
              border: Border.all(
                  color: const Color(0xFF1D9E75).withOpacity(0.3)),
            ),
            child: const Icon(Icons.smart_toy_rounded,
                color: Color(0xFF1D9E75), size: 32),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('IA DISPERSALUD', style: TextStyle(
                  color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
              const Text('Análisis inteligente de especialistas',
                  style: TextStyle(color: Color(0xFF9FE1CB), fontSize: 11)),
              const SizedBox(height: 8),
              Text('La IA ha identificado especialistas recomendados para tus pacientes.',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.7), fontSize: 11, height: 1.4)),
              const SizedBox(height: 10),
              Row(children: [
                _chipIA(Icons.people_rounded,       '3', 'Remisiones',   const Color(0xFF7C4DFF)),
                const SizedBox(width: 8),
                _chipIA(Icons.priority_high_rounded,'2', 'Urgentes',     const Color(0xFFEF9F27)),
                const SizedBox(width: 8),
                _chipIA(Icons.person_search_rounded,'5', 'Seguimientos', const Color(0xFF2196F3)),
              ]),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1D9E75),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Text('Ver recomendaciones', style: TextStyle(
                      color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                  SizedBox(width: 6),
                  Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 11),
                ]),
              ),
            ],
          )),
        ]),
      ),
    );
  }

  Widget _chipIA(IconData icono, String valor, String label, Color color) =>
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icono, color: color, size: 13),
        const SizedBox(width: 4),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(valor, style: TextStyle(
              color: color, fontSize: 13, fontWeight: FontWeight.bold, height: 1)),
          Text(label, style: TextStyle(
              color: Colors.white.withOpacity(0.6), fontSize: 8, height: 1.2)),
        ]),
      ]),
    );

  Widget _buildCard(_Especialista e, DispersaludColors dc, Color verde) {
    final dispColor = e.disponible
        ? const Color(0xFF1D9E75) : const Color(0xFFEF9F27);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: dc.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: dc.border),
      ),
      child: Column(children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Avatar
          Stack(children: [
            Container(
              width: 50, height: 50,
              decoration: BoxDecoration(
                color: e.color.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(color: e.color.withOpacity(0.4), width: 2),
              ),
              child: Center(child: Text(e.iniciales, style: TextStyle(
                  color: e.color, fontSize: 15, fontWeight: FontWeight.bold))),
            ),
            Positioned(right: 2, bottom: 2, child: Container(
              width: 11, height: 11,
              decoration: BoxDecoration(
                color: dispColor,
                shape: BoxShape.circle,
                border: Border.all(color: dc.card, width: 2),
              ),
            )),
          ]),
          const SizedBox(width: 12),
          // Info
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(e.nombre, style: TextStyle(
                  color: dc.textPrimary, fontSize: 14, fontWeight: FontWeight.bold))),
              const Icon(Icons.verified_rounded, color: Color(0xFF2196F3), size: 15),
            ]),
            const SizedBox(height: 2),
            Text(e.especialidad,
                style: TextStyle(color: dc.textSecondary, fontSize: 12)),
            const SizedBox(height: 5),
            Row(children: [
              const Icon(Icons.star_rounded, color: Color(0xFFFFB300), size: 13),
              const SizedBox(width: 3),
              Text('${e.calificacion}', style: TextStyle(
                  color: dc.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
              Text(' (${e.opiniones})',
                  style: TextStyle(color: dc.textHint, fontSize: 11)),
              Container(width: 1, height: 11,
                  margin: const EdgeInsets.symmetric(horizontal: 7), color: dc.border),
              Text('${e.aniosExp} años',
                  style: TextStyle(color: dc.textHint, fontSize: 11)),
            ]),
            const SizedBox(height: 3),
            Row(children: [
              Icon(Icons.location_on_rounded, color: dc.textHint, size: 11),
              const SizedBox(width: 3),
              Expanded(child: Text(e.ubicacion,
                  style: TextStyle(color: dc.textHint, fontSize: 11),
                  overflow: TextOverflow.ellipsis)),
            ]),
          ])),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                color: dispColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(e.disponible ? 'Disponible' : 'Ocupado',
                  style: TextStyle(color: dispColor,
                      fontSize: 10, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 5),
            Text('Próxima consulta',
                style: TextStyle(color: dc.textHint, fontSize: 9)),
            Text(e.proximaConsulta, style: TextStyle(
                color: dc.textSecondary, fontSize: 10, fontWeight: FontWeight.w600)),
          ]),
        ]),
        const SizedBox(height: 12),
        // Botones acción — usan _snack del State, que sí tiene context válido
        Row(children: [
          _btnAccion(Icons.phone_rounded,        'Llamar',  const Color(0xFF1D9E75),
              () => _snack('Llamando a ${e.nombre}…')),
          const SizedBox(width: 8),
          _btnAccion(Icons.chat_bubble_rounded,  'Chat',    const Color(0xFF2196F3),
              () => _snack('Chat con ${e.nombre}…')),
          const SizedBox(width: 8),
          _btnAccion(Icons.calendar_month_rounded,'Agendar',const Color(0xFF7C4DFF),
              () => _snack('Agendando con ${e.nombre}…')),
        ]),
      ]),
    );
  }

  Widget _btnAccion(IconData ico, String lbl, Color c, VoidCallback fn) =>
    Expanded(child: GestureDetector(
      onTap: fn,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: c.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: c.withOpacity(0.25)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(ico, color: c, size: 15),
          const SizedBox(width: 5),
          Text(lbl, style: TextStyle(
              color: c, fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
      ),
    ));

  Widget _buildVacio(DispersaludColors dc) => Container(
    padding: const EdgeInsets.all(32),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.search_off_rounded, color: dc.border, size: 48),
      const SizedBox(height: 12),
      Text('No se encontraron especialistas',
          style: TextStyle(color: dc.textHint, fontSize: 15)),
    ]),
  );

  Widget _buildBotonSolicitar(DispersaludColors dc, Color verde) =>
    GestureDetector(
      onTap: _abrirFormulario,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0A5240), Color(0xFF1D9E75)],
            begin: Alignment.centerLeft, end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
            child: const Icon(Icons.person_add_rounded,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Solicitar nuevo especialista', style: TextStyle(
                color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
            SizedBox(height: 2),
            Text('¿No encuentras el especialista que necesitas?',
                style: TextStyle(color: Color(0xFFB8F0DC), fontSize: 11)),
          ])),
          const Icon(Icons.arrow_forward_ios_rounded,
              color: Colors.white, size: 15),
        ]),
      ),
    );
}

// ─────────────────────────────────────────────────────────────────────────────
// FORMULARIO — widget 100% independiente del context del padre
// Recibe DispersaludColors y Color directamente, y usa un callback
// onGuardar para comunicarse con el padre SIN necesitar context
// ─────────────────────────────────────────────────────────────────────────────
class _Formulario extends StatefulWidget {
  final DispersaludColors dc;
  final Color verde;
  final void Function(String nombre) onGuardar;

  const _Formulario({
    required this.dc,
    required this.verde,
    required this.onGuardar,
  });

  @override
  State<_Formulario> createState() => _FormularioState();
}

class _FormularioState extends State<_Formulario> {
  final _nombreCtrl   = TextEditingController();
  final _ciudadCtrl   = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _horarioCtrl  = TextEditingController();

  int    _espIdx       = 0;
  double _calificacion = 4.5;
  int    _anios        = 1;
  bool   _disponible   = false;

  static const _especialidades = [
    'Medicina General', 'Ginecología', 'Pediatría',
    'Cardiología', 'Salud Mental', 'Otra',
  ];

  @override
  void dispose() {
    _nombreCtrl.dispose(); _ciudadCtrl.dispose();
    _telefonoCtrl.dispose(); _horarioCtrl.dispose();
    super.dispose();
  }

  // Accesos directos — NUNCA usan context heredado
  DispersaludColors get dc    => widget.dc;
  Color             get verde => widget.verde;

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: dc.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, bottomPad + 24),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Handle
          Center(child: Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
                color: dc.border, borderRadius: BorderRadius.circular(2)),
          )),

          // Título
          Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                  color: verde.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.person_add_rounded, color: verde, size: 20),
            ),
            const SizedBox(width: 12),
            Text('Nuevo especialista', style: TextStyle(
                color: verde, fontSize: 18, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 20),

          // Campos
          _campo(_nombreCtrl,   'Nombre completo',        Icons.person_outline_rounded),
          const SizedBox(height: 10),
          _campo(_ciudadCtrl,   'Ciudad',                 Icons.location_on_outlined),
          const SizedBox(height: 10),
          _campo(_telefonoCtrl, 'Teléfono',               Icons.phone_outlined,
              teclado: TextInputType.phone),
          const SizedBox(height: 10),
          _campo(_horarioCtrl,  'Próxima disponibilidad', Icons.access_time_outlined),
          const SizedBox(height: 20),

          // Especialidad chips
          Text('Especialidad médica', style: TextStyle(
              color: dc.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8,
            children: List.generate(_especialidades.length, (i) {
              final sel = i == _espIdx;
              return GestureDetector(
                onTap: () => setState(() => _espIdx = i),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: sel ? verde.withOpacity(0.12) : dc.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: sel ? verde : dc.border, width: 1.2),
                  ),
                  child: Text(_especialidades[i], style: TextStyle(
                      color: sel ? verde : dc.textSecondary,
                      fontSize: 12,
                      fontWeight: sel ? FontWeight.w700 : FontWeight.w500)),
                ),
              );
            }),
          ),
          const SizedBox(height: 20),

          // Calificación
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Calificación: ${_calificacion.toStringAsFixed(1)}',
                style: TextStyle(color: dc.textPrimary,
                    fontSize: 13, fontWeight: FontWeight.w600)),
            Row(children: List.generate(5, (i) {
              final llena = i < _calificacion.round();
              return GestureDetector(
                onTap: () => setState(() => _calificacion = (i + 1).toDouble()),
                child: Icon(
                  llena ? Icons.star_rounded : Icons.star_border_rounded,
                  color: const Color(0xFFFFB300), size: 28),
              );
            })),
          ]),
          const SizedBox(height: 20),

          // Años experiencia
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Años de experiencia: $_anios', style: TextStyle(
                color: dc.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
            Row(children: [
              GestureDetector(
                onTap: () { if (_anios > 1) setState(() => _anios--); },
                child: Icon(Icons.remove_circle_outline_rounded,
                    color: dc.textSecondary, size: 28)),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('$_anios', style: TextStyle(
                    color: dc.textPrimary, fontSize: 16, fontWeight: FontWeight.bold))),
              GestureDetector(
                onTap: () => setState(() => _anios++),
                child: Icon(Icons.add_circle_outline_rounded, color: verde, size: 28)),
            ]),
          ]),
          const SizedBox(height: 20),

          // Toggle disponible
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Disponible ahora', style: TextStyle(
                color: dc.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
            Switch(
              value: _disponible, activeColor: verde,
              onChanged: (v) => setState(() => _disponible = v)),
          ]),
          const SizedBox(height: 24),

          // ── BOTÓN GUARDAR ─────────────────────────────────────────────────
          // USA Navigator.pop() con el context LOCAL del sheet (válido)
          // y llama al callback onGuardar — que usa el messenger del padre
          SizedBox(width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: verde,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              icon: const Icon(Icons.save_rounded, size: 20),
              label: const Text('Agregar especialista',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              onPressed: () {
                final nombre = _nombreCtrl.text.trim().isEmpty
                    ? 'Nuevo especialista'
                    : _nombreCtrl.text.trim();

                // 1. Primero cerrar el modal con el context LOCAL del sheet
                Navigator.of(context).pop();

                // 2. Luego notificar al padre (el padre usa su propio messenger)
                widget.onGuardar(nombre);
              },
            )),
        ]),
      ),
    );
  }

  Widget _campo(TextEditingController ctrl, String hint, IconData ico,
      {TextInputType teclado = TextInputType.text}) =>
    Container(
      height: 50,
      decoration: BoxDecoration(
        color: dc.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: dc.border),
      ),
      child: TextField(
        controller: ctrl,
        keyboardType: teclado,
        style: TextStyle(color: dc.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: dc.textHint, fontSize: 13),
          prefixIcon: Icon(ico, color: dc.textHint, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
}