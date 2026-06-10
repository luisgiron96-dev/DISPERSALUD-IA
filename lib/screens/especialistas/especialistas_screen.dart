import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/app_theme.dart';

// ════════════════════════════════════════════════════════════════════════════
//  especialistas_screen.dart  —  DISPERSALUD IA
// ════════════════════════════════════════════════════════════════════════════

const Color _kVerde   = Color(0xFF1D9E75);
const Color _kDark    = Color(0xFF0F6E56);
const Color _kNaranja = Color(0xFFEF9F27);
const Color _kAzul    = Color(0xFF185FA5);
const Color _kMorado  = Color(0xFF534AB7);
const Color _kRojo    = Color(0xFFE24B4A);

DispersaludColors _c(BuildContext ctx) =>
    Theme.of(ctx).extension<DispersaludColors>() ?? DispersaludColors.dark;

// ─────────────────────────────────────────────────────────────────────────────
// MODELOS
// ─────────────────────────────────────────────────────────────────────────────
class _Especialista {
  final int id;
  final String nombre, especialidad, ciudad, proximaConsulta, categoriaId;
  final double calificacion;
  final int opiniones, aniosExp;
  final bool disponible;
  const _Especialista({
    required this.id, required this.nombre, required this.especialidad,
    required this.calificacion, required this.opiniones, required this.aniosExp,
    required this.ciudad, required this.proximaConsulta,
    required this.disponible, required this.categoriaId,
  });
}

class _Categoria {
  final String id, nombre;
  final IconData icono;
  const _Categoria({required this.id, required this.nombre, required this.icono});
}

// ─── 7 categorías requeridas ──────────────────────────────────────────────
const List<_Categoria> _kCategorias = [
  _Categoria(id: 'todos',           nombre: 'Todos',              icono: Icons.grid_view_rounded),
  _Categoria(id: 'medicina_interna',nombre: 'Medicina Interna',   icono: Icons.medical_services_outlined),
  _Categoria(id: 'pediatria',       nombre: 'Pediatría',          icono: Icons.child_care_outlined),
  _Categoria(id: 'ginecologia',     nombre: 'Ginecología',        icono: Icons.pregnant_woman_outlined),
  _Categoria(id: 'gastroenterologia',nombre:'Gastroenterología',  icono: Icons.healing_outlined),
  _Categoria(id: 'cardiologia',     nombre: 'Cardiología',        icono: Icons.favorite_outline),
  _Categoria(id: 'reumatologia',    nombre: 'Reumatología',       icono: Icons.accessibility_new_outlined),
  _Categoria(id: 'psiquiatria',     nombre: 'Psiquiatría',        icono: Icons.psychology_outlined),
];

const List<_Especialista> _kEspecialistas = [
  _Especialista(id:1, nombre:'Dra. Ana Rodríguez',  especialidad:'Ginecología y Obstetricia',
      calificacion:4.9, opiniones:128, aniosExp:12,
      ciudad:'Cali, Valle del Cauca',     proximaConsulta:'3:00 p.m.',  disponible:true,  categoriaId:'ginecologia'),
  _Especialista(id:2, nombre:'Dr. Carlos Pérez',    especialidad:'Cardiología',
      calificacion:4.8, opiniones:98,  aniosExp:15,
      ciudad:'Popayán, Cauca',            proximaConsulta:'5:30 p.m.',  disponible:false, categoriaId:'cardiologia'),
  _Especialista(id:3, nombre:'Dra. María Gómez',    especialidad:'Pediatría',
      calificacion:4.9, opiniones:156, aniosExp:10,
      ciudad:'Palmira, Valle del Cauca',  proximaConsulta:'2:00 p.m.',  disponible:true,  categoriaId:'pediatria'),
  _Especialista(id:4, nombre:'Dr. Luis Herrera',    especialidad:'Medicina Interna',
      calificacion:4.7, opiniones:203, aniosExp:8,
      ciudad:'Cali, Valle del Cauca',     proximaConsulta:'4:00 p.m.',  disponible:true,  categoriaId:'medicina_interna'),
  _Especialista(id:5, nombre:'Dra. Sandra Torres',  especialidad:'Psiquiatría',
      calificacion:4.8, opiniones:74,  aniosExp:18,
      ciudad:'Cali, Valle del Cauca',     proximaConsulta:'Mañana 9:00 a.m.', disponible:false, categoriaId:'psiquiatria'),
  _Especialista(id:6, nombre:'Dr. Jorge Mendoza',   especialidad:'Gastroenterología',
      calificacion:4.6, opiniones:91,  aniosExp:6,
      ciudad:'Buenaventura, Valle del Cauca', proximaConsulta:'6:00 p.m.', disponible:true, categoriaId:'gastroenterologia'),
  _Especialista(id:7, nombre:'Dra. Claudia Ríos',   especialidad:'Reumatología',
      calificacion:4.9, opiniones:312, aniosExp:20,
      ciudad:'Cali, Valle del Cauca',     proximaConsulta:'1:30 p.m.',  disponible:true,  categoriaId:'reumatologia'),
  _Especialista(id:8, nombre:'Dr. Andrés Salcedo',  especialidad:'Medicina Interna',
      calificacion:4.7, opiniones:145, aniosExp:14,
      ciudad:'Cali, Valle del Cauca',     proximaConsulta:'3:30 p.m.',  disponible:true,  categoriaId:'medicina_interna'),
  _Especialista(id:9, nombre:'Dra. Paola Muñoz',    especialidad:'Gastroenterología',
      calificacion:4.8, opiniones:88,  aniosExp:11,
      ciudad:'Tuluá, Valle del Cauca',    proximaConsulta:'11:00 a.m.', disponible:true,  categoriaId:'gastroenterologia'),
  _Especialista(id:10,nombre:'Dr. Iván Castaño',    especialidad:'Psiquiatría',
      calificacion:4.6, opiniones:67,  aniosExp:9,
      ciudad:'Cali, Valle del Cauca',     proximaConsulta:'Mañana 10:00 a.m.', disponible:false, categoriaId:'psiquiatria'),
];

// ─── Eventos de salud pública para el formulario ─────────────────────────
const List<Map<String, String>> _kEventosSalud = [
  {'codigo':'DEN',   'nombre':'Dengue',                   'emoji':'🦟'},
  {'codigo':'CHIK',  'nombre':'Chikunguña',                'emoji':'🦟'},
  {'codigo':'ZIKA',  'nombre':'Zika',                      'emoji':'🦟'},
  {'codigo':'MAL',   'nombre':'Malaria',                   'emoji':'🦠'},
  {'codigo':'TUB',   'nombre':'Tuberculosis',              'emoji':'🫁'},
  {'codigo':'VIH',   'nombre':'VIH/SIDA',                  'emoji':'🔬'},
  {'codigo':'HEP',   'nombre':'Hepatitis',                 'emoji':'🫀'},
  {'codigo':'IRA',   'nombre':'IRA (Infección Respiratoria)', 'emoji':'😷'},
  {'codigo':'EDA',   'nombre':'EDA (Enfermedad Diarreica)','emoji':'💧'},
  {'codigo':'VAR',   'nombre':'Varicela',                  'emoji':'💉'},
  {'codigo':'SAR',   'nombre':'Sarampión',                 'emoji':'💉'},
  {'codigo':'LEP',   'nombre':'Lepra',                     'emoji':'🏥'},
  {'codigo':'COV',   'nombre':'COVID-19',                  'emoji':'🦠'},
  {'codigo':'VIO',   'nombre':'Violencia de género',       'emoji':'🚨'},
  {'codigo':'INT',   'nombre':'Intoxicación',              'emoji':'⚠️'},
  {'codigo':'OTR',   'nombre':'Otro evento',               'emoji':'📋'},
];

// ════════════════════════════════════════════════════════════════════════════
//  WIDGET PRINCIPAL
// ════════════════════════════════════════════════════════════════════════════
class EspecialistasScreen extends StatefulWidget {
  const EspecialistasScreen({super.key});
  @override
  State<EspecialistasScreen> createState() => _EspecialistasScreenState();
}

class _EspecialistasScreenState extends State<EspecialistasScreen> {
  final _searchCtrl = TextEditingController();
  String _categoriaActiva = 'todos';
  String _busqueda = '';
  bool _modoOffline = true;

  List<_Especialista> get _filtrados {
    return _kEspecialistas.where((e) {
      final matchCat = _categoriaActiva == 'todos' || e.categoriaId == _categoriaActiva;
      final q = _busqueda.toLowerCase();
      final matchQ = q.isEmpty ||
          e.nombre.toLowerCase().contains(q) ||
          e.especialidad.toLowerCase().contains(q) ||
          e.ciudad.toLowerCase().contains(q);
      return matchCat && matchQ;
    }).toList();
  }

  int get _disponibles => _kEspecialistas.where((e) => e.disponible).length;

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg), backgroundColor: _kVerde,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _c(context).bg,
      body: SafeArea(
        child: Column(children: [
          _buildHeader(),
          Expanded(
            child: RefreshIndicator(
              color: _kVerde,
              onRefresh: () async => await Future.delayed(const Duration(seconds: 1)),
              child: ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  _buildMetricas(),
                  _buildBuscador(),
                  _buildCategorias(),
                  _buildBannerIA(),
                  _buildBotonFormulario(),
                  _buildSeccionEspecialistas(),
                  _buildSolicitarEspecialista(),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Especialistas', style: TextStyle(color: _c(context).textPrimary, fontSize: 22, fontWeight: FontWeight.bold)),
          Text('Conecta con expertos en salud', style: TextStyle(color: _c(context).textHint, fontSize: 12)),
        ])),
        GestureDetector(
          onTap: () => setState(() => _modoOffline = !_modoOffline),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _modoOffline ? _kVerde.withValues(alpha:0.15) : _kAzul.withValues(alpha:0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _modoOffline ? _kVerde : _kAzul),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(_modoOffline ? Icons.wifi : Icons.wifi_off, size: 14, color: _modoOffline ? _kVerde : _kAzul),
              const SizedBox(width: 4),
              Text(_modoOffline ? 'Modo Offline' : 'En línea',
                  style: TextStyle(color: _modoOffline ? _kVerde : _kAzul, fontSize: 11, fontWeight: FontWeight.w600)),
            ]),
          ),
        ),
        const SizedBox(width: 8),
        Stack(children: [
          IconButton(icon: Icon(Icons.notifications_outlined, color: _c(context).textPrimary),
              onPressed: () => _snack('Sin notificaciones nuevas')),
          Positioned(right: 6, top: 6,
            child: Container(width: 16, height: 16,
              decoration: const BoxDecoration(color: _kRojo, shape: BoxShape.circle),
              child: const Center(child: Text('3', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold))))),
        ]),
      ]),
    );
  }

  // ── Métricas ──────────────────────────────────────────────────────────────
  Widget _buildMetricas() {
    final stats = [
      {'icon': Icons.groups_rounded,   'valor': '${_kEspecialistas.length}', 'label': 'Especialistas\nActivos',  'color': _kVerde},
      {'icon': Icons.circle,           'valor': '$_disponibles',             'label': 'Disponibles\nEn línea',   'color': _kVerde},
      {'icon': Icons.calendar_month,   'valor': '12',                        'label': 'Consultas\nHoy',          'color': _kAzul},
      {'icon': Icons.star_rounded,     'valor': '4.8',                       'label': 'Calificación\nPromedio',  'color': _kNaranja},
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Row(children: stats.map((s) => Expanded(child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(color: _c(context).card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _c(context).border)),
        child: Column(children: [
          Icon(s['icon'] as IconData, color: s['color'] as Color, size: 18),
          const SizedBox(height: 4),
          Text(s['valor'] as String, style: TextStyle(color: _c(context).textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
          Text(s['label'] as String, textAlign: TextAlign.center, style: TextStyle(color: _c(context).textHint, fontSize: 9)),
        ]),
      ))).toList()..last),
    );
  }

  // ── Buscador ──────────────────────────────────────────────────────────────
  Widget _buildBuscador() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(children: [
        Expanded(child: Container(
          height: 44,
          decoration: BoxDecoration(color: _c(context).card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _c(context).border)),
          child: TextField(
            controller: _searchCtrl,
            style: TextStyle(color: _c(context).textPrimary, fontSize: 14),
            onChanged: (v) => setState(() => _busqueda = v),
            decoration: InputDecoration(
              hintText: 'Buscar especialista o especialidad...',
              hintStyle: TextStyle(color: _c(context).textHint, fontSize: 13),
              prefixIcon: Icon(Icons.search, color: _c(context).textHint, size: 20),
              suffixIcon: _busqueda.isNotEmpty
                  ? IconButton(icon: Icon(Icons.close, color: _c(context).textHint, size: 18),
                      onPressed: () { _searchCtrl.clear(); setState(() => _busqueda = ''); })
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
        )),
        const SizedBox(width: 8),
        Container(
          height: 44, padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(color: _c(context).card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _c(context).border)),
          child: Row(children: [
            Icon(Icons.tune_rounded, color: _c(context).textSecondary, size: 18),
            const SizedBox(width: 6),
            Text('Filtros', style: TextStyle(color: _c(context).textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
          ]),
        ),
      ]),
    );
  }

  // ── Chips categorías ──────────────────────────────────────────────────────
  Widget _buildCategorias() {
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        itemCount: _kCategorias.length,
        itemBuilder: (_, i) {
          final cat = _kCategorias[i];
          final activo = cat.id == _categoriaActiva;
          return GestureDetector(
            onTap: () => setState(() => _categoriaActiva = cat.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: activo ? _kVerde : _c(context).card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: activo ? _kVerde : _c(context).border),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(cat.icono, size: 14, color: activo ? Colors.white : _c(context).textSecondary),
                const SizedBox(width: 5),
                Text(cat.nombre, style: TextStyle(
                    color: activo ? Colors.white : _c(context).textSecondary,
                    fontSize: 12, fontWeight: activo ? FontWeight.w600 : FontWeight.normal)),
              ]),
            ),
          );
        },
      ),
    );
  }

  // ── Banner IA ─────────────────────────────────────────────────────────────
  Widget _buildBannerIA() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_kDark.withValues(alpha:0.9), const Color(0xFF1A1040)],
            begin: Alignment.centerLeft, end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kVerde.withValues(alpha:0.4)),
        ),
        child: Row(children: [
          Container(width: 56, height: 56,
            decoration: BoxDecoration(color: _kVerde.withValues(alpha:0.2),
                shape: BoxShape.circle, border: Border.all(color: _kVerde.withValues(alpha:0.5), width: 2)),
            child: const Icon(Icons.smart_toy_rounded, color: _kVerde, size: 28)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('IA DISPERSALUD', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
            const Text('Análisis inteligente de especialistas', style: TextStyle(color: Color(0xFFCCCCCC), fontSize: 11)),
            const SizedBox(height: 6),
            Row(children: [
              _iaChip(Icons.person_add_outlined, '3 Remisiones', _kMorado),
              const SizedBox(width: 8),
              _iaChip(Icons.warning_amber_rounded, '2 Urgentes', _kNaranja),
              const SizedBox(width: 8),
              _iaChip(Icons.track_changes_rounded, '5 Seguim.', _kAzul),
            ]),
          ])),
          const SizedBox(width: 8),
          Icon(Icons.psychology_rounded, color: _kMorado.withValues(alpha:0.7), size: 36),
        ]),
      ),
    );
  }

  Widget _iaChip(IconData icon, String texto, Color color) => Row(
    mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: color, size: 12),
      const SizedBox(width: 3),
      Text(texto, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
    ]);

  // ── Botón formulario eventos salud pública ────────────────────────────────
  Widget _buildBotonFormulario() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: GestureDetector(
        onTap: _mostrarFormularioEvento,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _kAzul.withValues(alpha:0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _kAzul.withValues(alpha:0.5)),
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: _kAzul.withValues(alpha:0.15), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.assignment_outlined, color: _kAzul, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Registrar evento de salud pública',
                  style: TextStyle(color: _kAzul, fontWeight: FontWeight.bold, fontSize: 14)),
              Text('Formulario de reporte para especialistas', style: TextStyle(color: _c(context).textHint, fontSize: 11)),
            ])),
            const Icon(Icons.chevron_right_rounded, color: _kAzul, size: 24),
          ]),
        ),
      ),
    );
  }

  // ── Sección lista especialistas ───────────────────────────────────────────
  Widget _buildSeccionEspecialistas() {
    final lista = _filtrados;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('Especialistas disponibles', style: TextStyle(color: _c(context).textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
          const Spacer(),
          Text('${lista.length} encontrados', style: TextStyle(color: _c(context).textHint, fontSize: 12)),
        ]),
        const SizedBox(height: 12),
        if (lista.isEmpty) _buildVacio()
        else ...lista.map((e) => _buildTarjeta(e)),
      ]),
    );
  }

  Widget _buildVacio() => Container(
    width: double.infinity, padding: const EdgeInsets.all(32),
    child: Column(children: [
      Icon(Icons.search_off_rounded, color: _c(context).textHint, size: 48),
      const SizedBox(height: 12),
      Text('No se encontraron especialistas', style: TextStyle(color: _c(context).textSecondary, fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      Text('Intenta con otra búsqueda o categoría', style: TextStyle(color: _c(context).textHint, fontSize: 12)),
    ]),
  );

  Widget _buildTarjeta(_Especialista esp) {
    return GestureDetector(
      onTap: () => _mostrarDetalle(esp),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: _c(context).card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _c(context).border)),
        child: Row(children: [
          Stack(children: [
            CircleAvatar(radius: 28,
              backgroundColor: _kVerde.withValues(alpha:0.15),
              child: Text(_iniciales(esp.nombre),
                  style: const TextStyle(color: _kVerde, fontWeight: FontWeight.bold, fontSize: 16))),
            Positioned(right: 0, bottom: 0,
              child: Container(width: 14, height: 14,
                decoration: BoxDecoration(
                    color: esp.disponible ? _kVerde : _kNaranja,
                    shape: BoxShape.circle,
                    border: Border.all(color: _c(context).card, width: 2)))),
          ]),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(esp.nombre,
                  style: TextStyle(color: _c(context).textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
              const Icon(Icons.verified_rounded, color: _kVerde, size: 16),
            ]),
            const SizedBox(height: 2),
            Text(esp.especialidad, style: TextStyle(color: _c(context).textHint, fontSize: 11)),
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.star_rounded, color: _kNaranja, size: 13),
              const SizedBox(width: 2),
              Text('${esp.calificacion} (${esp.opiniones})', style: TextStyle(color: _c(context).textSecondary, fontSize: 11)),
              const SizedBox(width: 8),
              Text('${esp.aniosExp} años', style: TextStyle(color: _c(context).textHint, fontSize: 11)),
            ]),
            const SizedBox(height: 3),
            Row(children: [
              Icon(Icons.location_on_outlined, color: _c(context).textHint, size: 12),
              const SizedBox(width: 2),
              Expanded(child: Text(esp.ciudad, style: TextStyle(color: _c(context).textHint, fontSize: 11),
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
            ]),
          ])),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                  color: esp.disponible ? _kVerde.withValues(alpha:0.15) : _kNaranja.withValues(alpha:0.15),
                  borderRadius: BorderRadius.circular(8)),
              child: Text(esp.disponible ? 'Disponible' : 'Ocupado',
                  style: TextStyle(color: esp.disponible ? _kVerde : _kNaranja, fontSize: 10, fontWeight: FontWeight.w600))),
            const SizedBox(height: 4),
            Text('Próx. ${esp.proximaConsulta}', style: TextStyle(color: _c(context).textHint, fontSize: 9)),
            const SizedBox(height: 6),
            Row(children: [
              _btnAccion(Icons.phone_rounded,              _kVerde,  () => _snack('Llamando a ${esp.nombre}...')),
              const SizedBox(width: 6),
              _btnAccion(Icons.chat_bubble_outline_rounded,_kAzul,   () => _snack('Chat con ${esp.nombre}')),
              const SizedBox(width: 6),
              _btnAccion(Icons.calendar_month_rounded,     _kMorado, () => _snack('Agendando con ${esp.nombre}')),
            ]),
          ]),
        ]),
      ),
    );
  }

  Widget _btnAccion(IconData icon, Color color, VoidCallback onTap) =>
    GestureDetector(onTap: onTap,
      child: Container(width: 30, height: 30,
        decoration: BoxDecoration(color: color.withValues(alpha:0.15), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: color, size: 15)));

  // ── Solicitar especialista ─────────────────────────────────────────────────
  Widget _buildSolicitarEspecialista() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: GestureDetector(
        onTap: _mostrarSolicitudDialog,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_kVerde, _kDark],
                begin: Alignment.centerLeft, end: Alignment.centerRight),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(children: [
            Container(padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha:0.2), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.person_add_rounded, color: Colors.white, size: 22)),
            const SizedBox(width: 12),
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Solicitar nuevo especialista', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              Text('¿No encuentras el especialista que necesitas?', style: TextStyle(color: Colors.white70, fontSize: 11)),
            ])),
            const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 24),
          ]),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  //  FORMULARIO EVENTOS SALUD PÚBLICA
  // ════════════════════════════════════════════════════════════════════════
  void _mostrarFormularioEvento() {
    String eventoSel     = '';
    String especialidadSel = 'Medicina Interna';
    String nivelSel      = 'alerta';
    String municipioSel  = 'Cali';
    final descCtrl       = TextEditingController();
    final pacienteCtrl   = TextEditingController();
    final edadCtrl       = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 32),
        child: SingleChildScrollView(child: StatefulBuilder(
          builder: (_, ss) => Container(
            decoration: BoxDecoration(color: _c(context).card, borderRadius: BorderRadius.circular(20)),
            padding: const EdgeInsets.all(20),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              // ── Asa ──
              Center(child: Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: _c(context).border, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              // ── Título ──
              Row(children: [
                Container(padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: _kAzul.withValues(alpha:0.15), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.assignment_outlined, color: _kAzul, size: 20)),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Evento de Salud Pública', style: TextStyle(color: _c(context).textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                  Text('Formulario de reporte SIVIGILA', style: TextStyle(color: _c(context).textHint, fontSize: 11)),
                ])),
              ]),
              const SizedBox(height: 20),

              // ── Evento ──
              _label('Evento notificable *'),
              _dropdown<String>(
                value: eventoSel.isEmpty ? null : eventoSel,
                hint: 'Seleccionar evento',
                items: [
                  const DropdownMenuItem(value: '', child: Text('— Seleccione —')),
                  ..._kEventosSalud.map((e) => DropdownMenuItem(
                      value: e['codigo'],
                      child: Text('${e['emoji']} ${e['nombre']}', overflow: TextOverflow.ellipsis))),
                ],
                onChanged: (v) => ss(() => eventoSel = v ?? ''),
              ),
              const SizedBox(height: 12),

              // ── Especialidad relacionada ──
              _label('Especialidad relacionada *'),
              _dropdown<String>(
                value: especialidadSel,
                hint: 'Seleccionar especialidad',
                items: [
                  'Medicina Interna', 'Pediatría', 'Ginecología',
                  'Gastroenterología', 'Cardiología', 'Reumatología', 'Psiquiatría',
                ].map((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis))).toList(),
                onChanged: (v) => ss(() => especialidadSel = v ?? 'Medicina Interna'),
              ),
              const SizedBox(height: 12),

              // ── Paciente + Edad ──
              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _label('Nombre del paciente'),
                  _textField(pacienteCtrl, 'Nombre completo'),
                ])),
                const SizedBox(width: 12),
                SizedBox(width: 80, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _label('Edad'),
                  _textField(edadCtrl, 'Años', keyboardType: TextInputType.number),
                ])),
              ]),
              const SizedBox(height: 12),

              // ── Municipio ──
              _label('Municipio de ocurrencia *'),
              _dropdown<String>(
                value: municipioSel,
                hint: 'Municipio',
                items: [
                  'Cali', 'Buenaventura', 'Palmira', 'Tuluá', 'Buga',
                  'Cartago', 'Jamundí', 'Popayán', 'Santander de Quilichao',
                  'Puerto Tejada', 'Otro',
                ].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                onChanged: (v) => ss(() => municipioSel = v ?? 'Cali'),
              ),
              const SizedBox(height: 12),

              // ── Nivel de alerta ──
              _label('Nivel de prioridad *'),
              Row(children: [
                _chipNivel(ss, nivelSel, 'urgente', '🚨 Urgente',    _kRojo),
                const SizedBox(width: 8),
                _chipNivel(ss, nivelSel, 'alerta',  '⚠️ Alerta',     _kNaranja),
                const SizedBox(width: 8),
                _chipNivel(ss, nivelSel, 'normal',  '✅ Vigilancia', _kVerde),
              ].map((w) => Expanded(child: GestureDetector(
                onTap: () {
                  final nivel = w is _NivelChip ? w.nivel : '';
                  if (nivel.isNotEmpty) ss(() => nivelSel = nivel);
                },
                child: w,
              ))).toList()),
              const SizedBox(height: 12),

              // ── Descripción ──
              _label('Descripción del evento *'),
              TextField(
                controller: descCtrl, maxLines: 3,
                style: TextStyle(color: _c(context).textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Describe los hallazgos clínicos, síntomas y contexto epidemiológico...',
                  hintStyle: TextStyle(color: _c(context).textHint, fontSize: 12),
                  filled: true, fillColor: _c(context).bg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _c(context).border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _c(context).border)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _kAzul, width: 1.5)),
                ),
              ),
              const SizedBox(height: 20),

              // ── Botones ──
              Row(children: [
                Expanded(child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                      side: BorderSide(color: _c(context).border),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Cancelar', style: TextStyle(color: _c(context).textSecondary)),
                )),
                const SizedBox(width: 12),
                Expanded(child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: _kAzul,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                  label: const Text('Reportar evento', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    if (eventoSel.isEmpty || descCtrl.text.trim().isEmpty) {
                      _snack('Completa los campos obligatorios (*)');
                      return;
                    }
                    Navigator.pop(ctx);
                    _snack('✓ Evento de salud pública registrado correctamente');
                  },
                )),
              ]),
            ]),
          ),
        )),
      ),
    );
  }

  Widget _label(String texto) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(texto, style: TextStyle(color: _c(context).textSecondary, fontSize: 12, fontWeight: FontWeight.w600)));

  Widget _dropdown<T>({required T? value, required String hint, required List<DropdownMenuItem<T>> items, required ValueChanged<T?> onChanged}) =>
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: _c(context).bg, borderRadius: BorderRadius.circular(10), border: Border.all(color: _c(context).border)),
      child: DropdownButton<T>(
        value: value, isExpanded: true, underline: const SizedBox(),
        dropdownColor: _c(context).card,
        hint: Text(hint, style: TextStyle(color: _c(context).textHint, fontSize: 13)),
        style: TextStyle(color: _c(context).textPrimary, fontSize: 13),
        items: items, onChanged: onChanged,
      ),
    );

  Widget _textField(TextEditingController ctrl, String hint, {TextInputType? keyboardType}) =>
    TextField(
      controller: ctrl, keyboardType: keyboardType,
      style: TextStyle(color: _c(context).textPrimary, fontSize: 13),
      decoration: InputDecoration(
        hintText: hint, hintStyle: TextStyle(color: _c(context).textHint, fontSize: 12),
        filled: true, fillColor: _c(context).bg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _c(context).border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _c(context).border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _kAzul, width: 1.5)),
      ),
    );

  Widget _chipNivel(StateSetter ss, String actual, String valor, String etiqueta, Color color) =>
    _NivelChip(nivel: valor, etiqueta: etiqueta, color: color, activo: actual == valor,
        onTap: () => ss(() {}));

  // ── Detalle especialista ──────────────────────────────────────────────────
  void _mostrarDetalle(_Especialista esp) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _DetalleSheet(esp: esp),
    );
  }

  // ── Solicitud ─────────────────────────────────────────────────────────────
  void _mostrarSolicitudDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _c(context).card,
        title: Text('Solicitar especialista', style: TextStyle(color: _c(context).textPrimary, fontWeight: FontWeight.bold)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Describe qué tipo de especialista necesitas para tu comunidad:', style: TextStyle(color: _c(context).textSecondary, fontSize: 13)),
          const SizedBox(height: 12),
          TextField(controller: ctrl, maxLines: 3,
            style: TextStyle(color: _c(context).textPrimary),
            decoration: InputDecoration(
              hintText: 'Ej: Especialista en salud mental para Buenaventura...',
              hintStyle: TextStyle(color: _c(context).textHint, fontSize: 12),
              filled: true, fillColor: _c(context).bg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _c(context).border)),
            )),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancelar', style: TextStyle(color: _c(context).textHint))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _kVerde),
            onPressed: () { Navigator.pop(context); _snack('Solicitud enviada correctamente ✓'); },
            child: const Text('Enviar', style: TextStyle(color: Colors.white))),
        ],
      ),
    );
  }

  String _iniciales(String nombre) {
    final partes = nombre.replaceAll('Dr. ', '').replaceAll('Dra. ', '').trim().split(' ');
    if (partes.length >= 2) return '${partes[0][0]}${partes[1][0]}'.toUpperCase();
    return nombre.isNotEmpty ? nombre[0].toUpperCase() : '?';
  }
}

// ─── Chip nivel (clase auxiliar) ─────────────────────────────────────────
class _NivelChip extends StatelessWidget {
  final String nivel, etiqueta;
  final Color color;
  final bool activo;
  final VoidCallback onTap;
  const _NivelChip({required this.nivel, required this.etiqueta,
      required this.color, required this.activo, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: activo ? color.withValues(alpha:0.2) : _c(context).bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: activo ? color : _c(context).border, width: activo ? 1.5 : 1),
      ),
      child: Center(child: Text(etiqueta, style: TextStyle(color: activo ? color : _c(context).textHint, fontSize: 11, fontWeight: activo ? FontWeight.bold : FontWeight.normal))),
    ),
  );
}

// ════════════════════════════════════════════════════════════════════════════
//  SHEET: Detalle Especialista
// ════════════════════════════════════════════════════════════════════════════
class _DetalleSheet extends StatelessWidget {
  final _Especialista esp;
  const _DetalleSheet({required this.esp});

  @override
  Widget build(BuildContext context) {
    final dc = _c(context);
    return Container(
      decoration: BoxDecoration(color: dc.card, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
      padding: const EdgeInsets.all(20),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4, decoration: BoxDecoration(color: dc.border, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 20),
        CircleAvatar(radius: 36, backgroundColor: _kVerde.withValues(alpha:0.15),
          child: Text(esp.nombre.split(' ').where((p) => p != 'Dr.' && p != 'Dra.').take(2).map((p) => p[0]).join().toUpperCase(),
              style: const TextStyle(color: _kVerde, fontWeight: FontWeight.bold, fontSize: 22))),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(esp.nombre, style: TextStyle(color: dc.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(width: 6),
          const Icon(Icons.verified_rounded, color: _kVerde, size: 18),
        ]),
        Text(esp.especialidad, style: TextStyle(color: dc.textHint, fontSize: 13)),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _stat(context, '${esp.calificacion}', 'Calificación', Icons.star_rounded, _kNaranja),
          _stat(context, '${esp.opiniones}',    'Opiniones',    Icons.chat_bubble_outline_rounded, _kAzul),
          _stat(context, '${esp.aniosExp} años','Experiencia',  Icons.workspace_premium_rounded, _kMorado),
        ]),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.location_on_outlined, color: dc.textHint, size: 16),
          Text(esp.ciudad, style: TextStyle(color: dc.textHint, fontSize: 13)),
        ]),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: esp.disponible ? _kVerde.withValues(alpha:0.1) : _kNaranja.withValues(alpha:0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: esp.disponible ? _kVerde : _kNaranja),
          ),
          child: Text(
            esp.disponible ? '✓ Disponible · Próxima consulta: ${esp.proximaConsulta}' : '⏳ Ocupado · Próxima disponibilidad: ${esp.proximaConsulta}',
            style: TextStyle(color: esp.disponible ? _kVerde : _kNaranja, fontWeight: FontWeight.w600, fontSize: 12))),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: OutlinedButton.icon(
            icon: const Icon(Icons.phone_rounded, color: _kVerde, size: 18),
            label: const Text('Llamar', style: TextStyle(color: _kVerde)),
            style: OutlinedButton.styleFrom(side: const BorderSide(color: _kVerde),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () { Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Llamando a ${esp.nombre}...'), backgroundColor: _kVerde, behavior: SnackBarBehavior.floating)); })),
          const SizedBox(width: 8),
          Expanded(child: ElevatedButton.icon(
            icon: const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 18),
            label: const Text('Agendar', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: _kVerde,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () { Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Agendando con ${esp.nombre}'), backgroundColor: _kVerde, behavior: SnackBarBehavior.floating)); })),
        ]),
        const SizedBox(height: 8),
      ]),
    );
  }

  Widget _stat(BuildContext context, String valor, String label, IconData icon, Color color) =>
    Column(children: [
      Icon(icon, color: color, size: 20),
      const SizedBox(height: 4),
      Text(valor, style: TextStyle(color: _c(context).textPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
      Text(label, style: TextStyle(color: _c(context).textHint, fontSize: 11)),
    ]);
}