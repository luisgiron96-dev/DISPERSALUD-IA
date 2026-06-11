import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/app_theme.dart';
import '../database/database_helper.dart';
import '../services/connectivity_service.dart';

// ════════════════════════════════════════════════════════════════════════════
//  partera_screen.dart  —  DISPERSALUD IA
//  Datos reales desde BD (tabla especialistas, categoría ginecología/obstetricia)
//  Llamar → marcador del celular  |  Chat → WhatsApp  |  Agendar → horario
// ════════════════════════════════════════════════════════════════════════════

const Color _kVerde   = Color(0xFF1D9E75);
const Color _kMorado  = Color(0xFF534AB7);
const Color _kRosa    = Color(0xFF993556);
const Color _kAzul    = Color(0xFF185FA5);
const Color _kNaranja = Color(0xFFEF9F27);
const Color _kRojo    = Color(0xFFE24B4A);

DispersaludColors _dc(BuildContext ctx) =>
    Theme.of(ctx).extension<DispersaludColors>() ?? DispersaludColors.dark;

// ─── Servicios fijos que ofrece toda partera ─────────────────────────────────
const List<Map<String, dynamic>> _kServicios = [
  {'icono': Icons.favorite_border_rounded,    'titulo': 'Control prenatal',          'desc': 'Seguimiento completo del embarazo y desarrollo del bebé.'},
  {'icono': Icons.self_improvement_rounded,   'titulo': 'Preparación para el parto', 'desc': 'Clases y acompañamiento para un parto consciente y seguro.'},
  {'icono': Icons.people_outline_rounded,     'titulo': 'Acompañamiento en el parto','desc': 'Apoyo profesional y humanizado durante el trabajo de parto.'},
  {'icono': Icons.child_care_outlined,        'titulo': 'Cuidados posparto',         'desc': 'Atención y recuperación para ti y tu bebé después del parto.'},
  {'icono': Icons.water_drop_outlined,        'titulo': 'Lactancia materna',         'desc': 'Asesoría y acompañamiento para una lactancia exitosa.'},
  {'icono': Icons.calendar_month_outlined,    'titulo': 'Planificación familiar',    'desc': 'Asesoría en métodos anticonceptivos y salud reproductiva.'},
];

const List<Map<String, String>> _kHorarios = [
  {'dia': 'Lunes a Viernes', 'hora': '8:00 AM – 6:00 PM'},
  {'dia': 'Sábado',          'hora': '8:00 AM – 1:00 PM'},
  {'dia': 'Domingo',         'hora': 'Cerrado'},
];

// ════════════════════════════════════════════════════════════════════════════
//  ACCIONES REALES
// ════════════════════════════════════════════════════════════════════════════

/// Limpia el teléfono a solo dígitos + "+" para la URL
String _limpiarTel(String tel) =>
    tel.replaceAll(RegExp(r'[\s\-\(\)]'), '');

Future<void> _llamar(BuildContext ctx, String telefono) async {
  final tel = _limpiarTel(telefono);
  if (tel.isEmpty) {
    _snack(ctx, 'No hay número de teléfono registrado', color: _kRojo);
    return;
  }
  final uri = Uri.parse('tel:$tel');
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  } else {
    _snack(ctx, 'No se pudo abrir el marcador', color: _kRojo);
  }
}

Future<void> _abrirWhatsApp(BuildContext ctx, String telefono, String nombre) async {
  // WhatsApp necesita número sin "+" ni espacios, solo dígitos
  String num = telefono.replaceAll(RegExp(r'[^\d]'), '');
  // Si empieza con 0, quitar el 0 (Colombia: 57 + número)
  if (num.startsWith('0')) num = num.substring(1);
  // Si no tiene código de país y tiene 10 dígitos, agregar 57
  if (num.length == 10) num = '57$num';

  if (num.isEmpty) {
    _snack(ctx, 'No hay número de WhatsApp registrado', color: _kRojo);
    return;
  }

  final msg = Uri.encodeComponent('Hola $nombre, me comunico a través de DISPERSALUD IA.');
  final uri = Uri.parse('https://wa.me/$num?text=$msg');
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } else {
    _snack(ctx, 'No se pudo abrir WhatsApp', color: _kRojo);
  }
}

void _mostrarHorario(BuildContext ctx, Map<String, dynamic> partera) {
  final dc      = _dc(ctx);
  final horario = partera['proximo_horario'] as String? ?? '';
  showModalBottomSheet(
    context: ctx,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: dc.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
      child: Column(mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 40, height: 4,
            decoration: BoxDecoration(color: dc.border,
                borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 16),
        Row(children: [
          const Icon(Icons.event_available_outlined, color: _kMorado, size: 20),
          const SizedBox(width: 8),
          Text('Agendar cita con',
              style: TextStyle(color: dc.textPrimary, fontSize: 15,
                  fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 4),
        Text(partera['nombre'] as String? ?? '',
            style: const TextStyle(color: _kRosa, fontSize: 13,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        if (horario.isNotEmpty) ...[
          Text('Próxima disponibilidad',
              style: TextStyle(color: dc.textHint, fontSize: 11)),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: _kMorado.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _kMorado.withOpacity(0.3))),
            child: Text(horario,
                style: const TextStyle(color: _kMorado, fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 14),
        ],
        Text('Horario de atención',
            style: TextStyle(color: dc.textHint, fontSize: 11)),
        const SizedBox(height: 8),
        for (final h in _kHorarios)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              Expanded(child: Text(h['dia']!,
                  style: TextStyle(color: dc.textSecondary, fontSize: 12))),
              Text(h['hora']!,
                  style: TextStyle(color: dc.textPrimary, fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ]),
          ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _llamar(ctx, partera['telefono'] as String? ?? '');
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: _kMorado,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14)),
            icon: const Icon(Icons.phone_rounded, size: 16),
            label: const Text('Llamar para confirmar cita',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ]),
    ),
  );
}

void _snack(BuildContext ctx, String msg, {Color? color}) {
  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
    content: Text(msg),
    backgroundColor: color ?? _kVerde,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    duration: const Duration(seconds: 2),
  ));
}

// ════════════════════════════════════════════════════════════════════════════
//  PANTALLA LISTA
// ════════════════════════════════════════════════════════════════════════════
class ParteraScreen extends StatefulWidget {
  const ParteraScreen({super.key});
  @override
  State<ParteraScreen> createState() => _ParteraScreenState();
}

class _ParteraScreenState extends State<ParteraScreen> {
  bool   _online   = false;
  bool   _cargando = true;
  StreamSubscription<bool>? _connSub;

  List<Map<String, dynamic>> _parteras  = [];
  List<Map<String, dynamic>> _filtradas = [];
  String _busqueda = '';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initConectividad();
    _cargar();
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

  Future<void> _cargar() async {
    if (!mounted) return;
    setState(() => _cargando = true);

    final todos = await DatabaseHelper.instance.obtenerEspecialistas();
    // Filtrar por categoría ginecología u obstetricia, o especialidad que
    // contenga partera / matrona / ginec / obste
    final lista = todos.where((e) {
      final cat = (e['categoria_id'] as String? ?? '').toLowerCase();
      final esp = (e['especialidad']  as String? ?? '').toLowerCase();
      return cat.contains('ginec') ||
             cat.contains('obste') ||
             esp.contains('parter') ||
             esp.contains('matrona') ||
             esp.contains('ginec') ||
             esp.contains('obste');
    }).toList();

    if (!mounted) return;
    setState(() {
      _parteras  = lista;
      _cargando  = false;
    });
    _filtrar();
  }

  void _filtrar() {
    if (_busqueda.isEmpty) {
      setState(() => _filtradas = List.from(_parteras));
      return;
    }
    final q = _busqueda.toLowerCase();
    setState(() => _filtradas = _parteras.where((p) {
      final n = (p['nombre']       as String? ?? '').toLowerCase();
      final e = (p['especialidad'] as String? ?? '').toLowerCase();
      final c = (p['ciudad']       as String? ?? '').toLowerCase();
      return n.contains(q) || e.contains(q) || c.contains(q);
    }).toList());
  }

  void _abrirPerfil(Map<String, dynamic> partera) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => _PerfilScreen(partera: partera, online: _online),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final dc = _dc(context);

    return Scaffold(
      backgroundColor: dc.bg,
      body: SafeArea(
        child: Column(children: [

          // HEADER
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Row(children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                    color: _kRosa.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _kRosa.withOpacity(0.3))),
                child: const Icon(Icons.favorite_border_rounded,
                    color: _kRosa, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Partera', style: TextStyle(color: dc.textPrimary,
                    fontSize: 20, fontWeight: FontWeight.bold)),
                Text('Cuidados expertos para ti y tu bebé',
                    style: TextStyle(color: dc.textHint, fontSize: 11)),
              ])),
              _BadgeOnline(online: _online),
            ]),
          ),

          // BÚSQUEDA
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                  color: dc.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: dc.border)),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) { _busqueda = v; _filtrar(); },
                style: TextStyle(color: dc.textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Buscar partera, ciudad...',
                  hintStyle: TextStyle(color: dc.textHint, fontSize: 12),
                  prefixIcon: Icon(Icons.search_rounded,
                      color: dc.textHint, size: 18),
                  suffixIcon: _busqueda.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            _searchCtrl.clear();
                            _busqueda = '';
                            _filtrar();
                          },
                          child: Icon(Icons.close_rounded,
                              color: dc.textHint, size: 16))
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),

          // LISTA
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator(color: _kRosa))
                : RefreshIndicator(
                    color: _kRosa,
                    onRefresh: _cargar,
                    child: _filtradas.isEmpty
                        ? _EmptyState(dc: dc,
                              sinRegistros: _parteras.isEmpty)
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                            itemCount: _filtradas.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (_, i) => _CardPartera(
                              p:     _filtradas[i],
                              dc:    dc,
                              onTap: () => _abrirPerfil(_filtradas[i]),
                            ),
                          ),
                  ),
          ),
        ]),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  TARJETA LISTA
// ════════════════════════════════════════════════════════════════════════════
class _CardPartera extends StatelessWidget {
  final Map<String, dynamic> p;
  final DispersaludColors dc;
  final VoidCallback onTap;
  const _CardPartera({required this.p, required this.dc, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final disponible = (p['disponible'] as int?) == 1;
    final cal        = (p['calificacion'] as num?)?.toDouble() ?? 0.0;
    final anios      = (p['anios_exp']    as int?) ?? 0;
    final inicial    = (p['nombre'] as String? ?? 'P')
        .split(' ').last[0].toUpperCase();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: dc.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: dc.border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Avatar con gradiente
            Container(
              width: 54, height: 54,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_kRosa, _kMorado],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(child: Text(inicial,
                  style: const TextStyle(color: Colors.white, fontSize: 22,
                      fontWeight: FontWeight.bold))),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(p['nombre'] as String? ?? '',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: dc.textPrimary, fontSize: 14,
                        fontWeight: FontWeight.bold))),
                const Icon(Icons.verified_rounded, color: _kVerde, size: 15),
              ]),
              const SizedBox(height: 2),
              Text(p['especialidad'] as String? ?? '',
                  style: const TextStyle(color: _kRosa, fontSize: 11,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.star_rounded, color: _kNaranja, size: 13),
                const SizedBox(width: 3),
                Text(cal.toStringAsFixed(1),
                    style: TextStyle(color: dc.textSecondary, fontSize: 11,
                        fontWeight: FontWeight.w600)),
                Text('  •  $anios años exp.',
                    style: TextStyle(color: dc.textHint, fontSize: 11)),
              ]),
              const SizedBox(height: 3),
              Row(children: [
                Icon(Icons.location_on_outlined, color: dc.textHint, size: 11),
                const SizedBox(width: 2),
                Expanded(child: Text(p['ciudad'] as String? ?? '',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: dc.textHint, fontSize: 11))),
              ]),
            ])),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                  color: disponible
                      ? _kVerde.withOpacity(0.12)
                      : _kRojo.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: disponible ? _kVerde : _kRojo)),
              child: Text(disponible ? 'Disponible' : 'No disp.',
                  style: TextStyle(
                      color: disponible ? _kVerde : _kRojo,
                      fontSize: 9, fontWeight: FontWeight.bold)),
            ),
          ]),

          const SizedBox(height: 12),
          Divider(color: dc.border, height: 1),
          const SizedBox(height: 10),

          Row(children: [
            _MiniStat(valor: p['telefono'] as String? ?? 'Sin tel.',
                label: 'Teléfono',
                icono: Icons.phone_outlined, color: _kVerde),
            const Spacer(),
            GestureDetector(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                    color: _kRosa.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _kRosa.withOpacity(0.4))),
                child: const Text('Ver perfil',
                    style: TextStyle(color: _kRosa, fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  PANTALLA PERFIL COMPLETO
// ════════════════════════════════════════════════════════════════════════════
class _PerfilScreen extends StatelessWidget {
  final Map<String, dynamic> partera;
  final bool online;
  const _PerfilScreen({required this.partera, required this.online});

  String get _nombre     => partera['nombre']        as String? ?? '';
  String get _esp        => partera['especialidad']  as String? ?? 'Partera';
  String get _ciudad     => partera['ciudad']        as String? ?? '';
  String get _telefono   => partera['telefono']      as String? ?? '';
  double get _cal        => (partera['calificacion'] as num?)?.toDouble() ?? 0.0;
  int    get _anios      => (partera['anios_exp']    as int?) ?? 0;
  bool   get _disponible => (partera['disponible']   as int?) == 1;
  String get _inicial    => _nombre.split(' ').last[0].toUpperCase();

  @override
  Widget build(BuildContext context) {
    final dc = _dc(context);

    return Scaffold(
      backgroundColor: dc.bg,
      body: CustomScrollView(slivers: [

        // APP BAR con gradiente
        SliverAppBar(
          expandedHeight: 210,
          pinned: true,
          backgroundColor: dc.bg,
          automaticallyImplyLeading: false,
          leading: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 16),
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: _BadgeOnline(online: online),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1A0A2E), _kRosa, _kMorado],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(children: [
                // Corazón decorativo
                Positioned(
                  right: 20, top: 40,
                  child: Opacity(opacity: 0.15,
                      child: const Icon(Icons.favorite_rounded,
                          size: 110, color: Colors.white)),
                ),
                // Contenido
                Positioned(
                  left: 16, bottom: 20, right: 80,
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Container(
                      width: 68, height: 68,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_kRosa, _kMorado],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white30, width: 2),
                      ),
                      child: Center(child: Text(_inicial,
                          style: const TextStyle(color: Colors.white,
                              fontSize: 28, fontWeight: FontWeight.bold))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min, children: [
                      Row(children: [
                        Expanded(child: Text(_nombre,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white,
                                fontSize: 16, fontWeight: FontWeight.bold))),
                        const Icon(Icons.verified_rounded,
                            color: _kVerde, size: 16),
                      ]),
                      const SizedBox(height: 2),
                      Text(_esp, style: const TextStyle(
                          color: Color(0xFFDDB0C4), fontSize: 12)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _disponible
                              ? _kVerde.withOpacity(0.25)
                              : Colors.grey.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: _disponible ? _kVerde : Colors.grey),
                        ),
                        child: Text(
                          _disponible ? 'Disponible' : 'No disponible',
                          style: TextStyle(
                              color: _disponible ? _kVerde : Colors.grey,
                              fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ])),
                  ]),
                ),
              ]),
            ),
          ),
        ),

        // CONTENIDO
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 40),
          sliver: SliverList(delegate: SliverChildListDelegate([

            const SizedBox(height: 14),

            // Info: especialidad + rating + ubicación + año inicio
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: dc.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: dc.border)),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Atención prenatal, parto y posparto',
                    style: TextStyle(color: _kRosa, fontSize: 12,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(children: [
                  const Icon(Icons.star_rounded, color: _kNaranja, size: 15),
                  const SizedBox(width: 4),
                  Text('${ _cal.toStringAsFixed(1)} opiniones',
                      style: TextStyle(color: dc.textSecondary, fontSize: 12)),
                  const SizedBox(width: 8),
                  Container(width: 1, height: 12, color: dc.border),
                  const SizedBox(width: 8),
                  Text('$_anios años exp.',
                      style: TextStyle(color: dc.textSecondary, fontSize: 12)),
                ]),
                const SizedBox(height: 6),
                if (_ciudad.isNotEmpty) Row(children: [
                  Icon(Icons.location_on_outlined, color: dc.textHint, size: 13),
                  const SizedBox(width: 4),
                  Text(_ciudad,
                      style: TextStyle(color: dc.textHint, fontSize: 12)),
                ]),
                const SizedBox(height: 4),
                Row(children: [
                  Icon(Icons.calendar_month_outlined,
                      color: dc.textHint, size: 13),
                  const SizedBox(width: 4),
                  Text('Atiende desde ${DateTime.now().year - _anios}',
                      style: TextStyle(color: dc.textHint, fontSize: 12)),
                ]),
              ]),
            ),

            const SizedBox(height: 12),

            // BOTONES DE ACCIÓN REALES
            Row(children: [
              Expanded(child: _BtnAccion(
                label: 'Llamar',
                icono: Icons.phone_rounded,
                color: _kVerde,
                onTap: () => _llamar(context, _telefono),
              )),
              const SizedBox(width: 8),
              Expanded(child: _BtnAccion(
                label: 'Chat',
                icono: Icons.chat_bubble_outline_rounded,
                color: _kAzul,
                onTap: () => _abrirWhatsApp(context, _telefono, _nombre),
              )),
              const SizedBox(width: 8),
              Expanded(child: _BtnAccion(
                label: 'Agendar',
                icono: Icons.event_available_outlined,
                color: _kMorado,
                onTap: () => _mostrarHorario(context, partera),
              )),
            ]),

            const SizedBox(height: 14),

            // MÉTRICAS
            Row(children: [
              _MetCard(valor: '—',  label: 'Embarazos\nAcompañados',
                  icono: Icons.pregnant_woman_outlined, color: _kRosa, dc: dc),
              const SizedBox(width: 8),
              _MetCard(valor: '—',  label: 'Partos\nAsistidos',
                  icono: Icons.child_care_outlined, color: _kMorado, dc: dc),
              const SizedBox(width: 8),
              _MetCard(valor: '98%', label: 'Pacientes\nSatisfechas',
                  icono: Icons.favorite_rounded, color: _kRojo, dc: dc),
              const SizedBox(width: 8),
              _MetCard(valor: '$_anios', label: 'Años de\nExperiencia',
                  icono: Icons.shield_outlined, color: _kAzul, dc: dc),
            ]),

            const SizedBox(height: 16),

            // SERVICIOS
            Text('Servicios que ofrece',
                style: TextStyle(color: dc.textPrimary, fontSize: 14,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.78,
              children: _kServicios.map((s) => _ServicioCard(
                titulo: s['titulo'] as String,
                desc:   s['desc']   as String,
                icono:  s['icono']  as IconData,
                dc:     dc,
              )).toList(),
            ),

            const SizedBox(height: 16),

            // HORARIO + EPS
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: _HorarioCard(dc: dc)),
              const SizedBox(width: 10),
              Expanded(child: _EpsCard(dc: dc)),
            ]),

            const SizedBox(height: 16),

            // OPINIONES
            Row(children: [
              Expanded(child: Text('Opiniones de pacientes',
                  style: TextStyle(color: dc.textPrimary, fontSize: 14,
                      fontWeight: FontWeight.bold))),
              Text('Ver todas',
                  style: const TextStyle(color: _kMorado, fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _OpinionCard(
                nombre: 'María Camila R.', estrellas: 5,
                texto: 'Me acompañó en todo el embarazo y parto. Me sentí muy segura y en confianza.',
                tiempo: 'Hace 2 semanas', dc: dc,
              )),
              const SizedBox(width: 10),
              Expanded(child: _OpinionCard(
                nombre: 'Valentina S.', estrellas: 4,
                texto: 'Su apoyo fue fundamental en mi posparto y lactancia. 100% recomendada.',
                tiempo: 'Hace 1 mes', dc: dc,
              )),
            ]),

            const SizedBox(height: 20),
          ])),
        ),
      ]),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  WIDGETS REUTILIZABLES
// ════════════════════════════════════════════════════════════════════════════

class _BadgeOnline extends StatelessWidget {
  final bool online;
  const _BadgeOnline({required this.online});
  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 300),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: online ? _kVerde.withOpacity(0.12) : Colors.orange.withOpacity(0.12),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: online ? _kVerde : Colors.orange),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(online ? Icons.wifi_rounded : Icons.wifi_off_rounded,
          color: online ? _kVerde : Colors.orange, size: 13),
      const SizedBox(width: 4),
      Text(online ? 'Modo Online' : 'Modo Offline',
          style: TextStyle(
              color: online ? _kVerde : Colors.orange,
              fontSize: 11, fontWeight: FontWeight.bold)),
    ]),
  );
}

class _MiniStat extends StatelessWidget {
  final String valor, label;
  final IconData icono;
  final Color color;
  const _MiniStat({required this.valor, required this.label,
      required this.icono, required this.color});
  @override
  Widget build(BuildContext context) {
    final dc = _dc(context);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 26, height: 26,
          decoration: BoxDecoration(
              color: color.withOpacity(0.12), shape: BoxShape.circle),
          child: Icon(icono, color: color, size: 13)),
      const SizedBox(width: 5),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(valor, style: TextStyle(color: dc.textPrimary,
            fontSize: 11, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis),
        Text(label, style: TextStyle(color: dc.textHint, fontSize: 9)),
      ]),
    ]);
  }
}

class _MetCard extends StatelessWidget {
  final String valor, label;
  final IconData icono;
  final Color color;
  final DispersaludColors dc;
  const _MetCard({required this.valor, required this.label,
      required this.icono, required this.color, required this.dc});
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(
          color: dc.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: dc.border)),
      child: Column(children: [
        Container(width: 30, height: 30,
            decoration: BoxDecoration(
                color: color.withOpacity(0.13), shape: BoxShape.circle),
            child: Icon(icono, color: color, size: 15)),
        const SizedBox(height: 5),
        Text(valor, style: TextStyle(color: color, fontSize: 15,
            fontWeight: FontWeight.bold)),
        const SizedBox(height: 3),
        Text(label, textAlign: TextAlign.center,
            style: TextStyle(color: dc.textHint, fontSize: 8, height: 1.2)),
      ]),
    ),
  );
}

class _BtnAccion extends StatelessWidget {
  final String label;
  final IconData icono;
  final Color color;
  final VoidCallback onTap;
  const _BtnAccion({required this.label, required this.icono,
      required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
          color: color, borderRadius: BorderRadius.circular(12)),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icono, color: Colors.white, size: 16),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: Colors.white,
            fontSize: 12, fontWeight: FontWeight.bold)),
      ]),
    ),
  );
}

class _ServicioCard extends StatelessWidget {
  final String titulo, desc;
  final IconData icono;
  final DispersaludColors dc;
  const _ServicioCard({required this.titulo, required this.desc,
      required this.icono, required this.dc});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
        color: dc.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: dc.border)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 32, height: 32,
          decoration: BoxDecoration(
              color: _kMorado.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8)),
          child: Icon(icono, color: _kMorado, size: 16)),
      const SizedBox(height: 7),
      Text(titulo, style: TextStyle(color: dc.textPrimary, fontSize: 10,
          fontWeight: FontWeight.bold, height: 1.2)),
      const SizedBox(height: 4),
      Expanded(child: Text(desc, style: TextStyle(color: dc.textHint,
          fontSize: 8.5, height: 1.3),
          maxLines: 3, overflow: TextOverflow.ellipsis)),
      const Icon(Icons.arrow_forward_ios_rounded, color: _kVerde, size: 10),
    ]),
  );
}

class _HorarioCard extends StatelessWidget {
  final DispersaludColors dc;
  const _HorarioCard({required this.dc});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
        color: dc.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: dc.border)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(Icons.access_time_rounded, color: dc.textHint, size: 14),
        const SizedBox(width: 6),
        Text('Horario de atención',
            style: TextStyle(color: dc.textPrimary, fontSize: 11,
                fontWeight: FontWeight.bold)),
      ]),
      const SizedBox(height: 10),
      for (final h in _kHorarios) ...[
        Row(children: [
          Expanded(child: Text(h['dia']!,
              style: TextStyle(color: dc.textSecondary, fontSize: 10))),
          Text(h['hora']!,
              style: TextStyle(color: dc.textPrimary, fontSize: 10,
                  fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 5),
      ],
      const SizedBox(height: 4),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
            color: _kVerde.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _kVerde.withOpacity(0.3))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.home_outlined, color: _kVerde, size: 12),
          const SizedBox(width: 4),
          const Text('Atención domiciliaria',
              style: TextStyle(color: _kVerde, fontSize: 9,
                  fontWeight: FontWeight.bold)),
        ]),
      ),
    ]),
  );
}

class _EpsCard extends StatelessWidget {
  final DispersaludColors dc;
  const _EpsCard({required this.dc});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
        color: dc.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: dc.border)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(Icons.shield_outlined, color: dc.textHint, size: 14),
        const SizedBox(width: 6),
        Text('Aseguradoras',
            style: TextStyle(color: dc.textPrimary, fontSize: 11,
                fontWeight: FontWeight.bold)),
      ]),
      const SizedBox(height: 10),
      for (final eps in ['Sura', 'Nueva EPS', 'Sanitas', 'Coomeva'])
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
                color: dc.bg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: dc.border)),
            child: Row(children: [
              const Icon(Icons.check_circle_outline_rounded,
                  color: _kVerde, size: 11),
              const SizedBox(width: 5),
              Text(eps, style: TextStyle(color: dc.textSecondary, fontSize: 10)),
            ]),
          ),
        ),
      GestureDetector(
        onTap: () {},
        child: const Row(children: [
          Text('Ver todos los planes',
              style: TextStyle(color: _kMorado, fontSize: 10,
                  fontWeight: FontWeight.w600)),
          SizedBox(width: 2),
          Icon(Icons.arrow_forward_ios_rounded, color: _kMorado, size: 10),
        ]),
      ),
    ]),
  );
}

class _OpinionCard extends StatelessWidget {
  final String nombre, texto, tiempo;
  final int estrellas;
  final DispersaludColors dc;
  const _OpinionCard({required this.nombre, required this.texto,
      required this.tiempo, required this.estrellas, required this.dc});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
        color: dc.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: dc.border)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 28, height: 28,
            decoration: BoxDecoration(
                color: _kRosa.withOpacity(0.15), shape: BoxShape.circle),
            child: Center(child: Text(nombre[0],
                style: const TextStyle(color: _kRosa, fontSize: 13,
                    fontWeight: FontWeight.bold)))),
        const SizedBox(width: 7),
        Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(nombre, overflow: TextOverflow.ellipsis,
              style: TextStyle(color: dc.textPrimary, fontSize: 10,
                  fontWeight: FontWeight.bold)),
          Row(children: [
            for (int i = 1; i <= 5; i++)
              Icon(i <= estrellas
                  ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: _kNaranja, size: 10),
          ]),
        ])),
        const Icon(Icons.format_quote_rounded, color: _kMorado, size: 18),
      ]),
      const SizedBox(height: 8),
      Text(texto, style: TextStyle(color: dc.textSecondary,
          fontSize: 10, height: 1.4)),
      const SizedBox(height: 6),
      Text(tiempo, style: TextStyle(color: dc.textHint, fontSize: 9)),
    ]),
  );
}

class _EmptyState extends StatelessWidget {
  final DispersaludColors dc;
  final bool sinRegistros;
  const _EmptyState({required this.dc, required this.sinRegistros});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.favorite_border_rounded, color: dc.textHint, size: 52),
        const SizedBox(height: 12),
        Text(
          sinRegistros
              ? 'No hay parteras registradas'
              : 'Sin resultados para esa búsqueda',
          textAlign: TextAlign.center,
          style: TextStyle(color: dc.textSecondary, fontSize: 14,
              fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (sinRegistros)
          Text(
            'Ve a la sección "Especialistas", agrega una con categoría Ginecología u Obstetricia y aparecerá aquí automáticamente.',
            textAlign: TextAlign.center,
            style: TextStyle(color: dc.textHint, fontSize: 12, height: 1.5),
          ),
      ]),
    ),
  );
}