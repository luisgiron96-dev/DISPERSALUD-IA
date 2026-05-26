import 'package:flutter/material.dart';
import '../database/database_helper.dart';

const Color _kBg     = Color(0xFF111111);
const Color _kCard   = Color(0xFF1E1E1E);
const Color _kVerde  = Color(0xFF1D9E75);
const Color _kBorder = Color(0xFF2A2A2A);

// ─── Datos SIVIGILA locales por municipio ───────────────────────────────────
// Basados en protocolos reales del INS Colombia
const List<Map<String, dynamic>> _kEventosSivigila = [
  {
    'codigo': 'DEN', 'nombre': 'Dengue', 'emoji': '🦟',
    'descripcion': 'Enfermedad viral transmitida por Aedes aegypti. Vigilancia activa en temporada de lluvias.',
    'prevencion': 'Eliminar criaderos de agua estancada. Usar toldillos y repelente. Reportar casos febriles.',
    'signos_alarma': 'Fiebre alta, dolor detrás de los ojos, sarpullido. EMERGENCIA: sangrado, vómito persistente.',
    'municipios_riesgo': ['Popayán', 'Santander de Quilichao', 'Puerto Tejada', 'Caloto', 'Corinto'],
    'nivel_base': 'vigilancia',
  },
  {
    'codigo': 'EDA', 'nombre': 'Enfermedad Diarreica Aguda', 'emoji': '💧',
    'descripcion': 'Infección gastrointestinal por bacterias, virus o parásitos. Más frecuente en niños menores de 5 años.',
    'prevencion': 'Agua hervida o clorada. Lavado de manos con jabón. Manejo adecuado de alimentos.',
    'signos_alarma': 'Diarrea > 3 veces al día, fiebre, vómito. EMERGENCIA en menores: signos de deshidratación.',
    'municipios_riesgo': ['Toribío', 'Páez', 'La Sierra', 'El Tambo', 'Balboa'],
    'nivel_base': 'normal',
  },
  {
    'codigo': 'IRA', 'nombre': 'Infección Respiratoria Aguda', 'emoji': '🤧',
    'descripcion': 'Incluye resfriado común, faringitis, neumonía. Principal causa de mortalidad infantil evitable.',
    'prevencion': 'Vacunación contra influenza y neumococo. Ventilación de espacios. Cubrirse al toser.',
    'signos_alarma': 'Dificultad para respirar, tiraje subcostal, cianosis. EMERGENCIA: fiebre > 39°C en menores.',
    'municipios_riesgo': ['Silvia', 'Inzá', 'Puracé', 'La Vega', 'Bolívar'],
    'nivel_base': 'vigilancia',
  },
  {
    'codigo': 'MAL', 'nombre': 'Malaria', 'emoji': '🦠',
    'descripcion': 'Parasitosis transmitida por Anopheles. Zonas de riesgo bajo los 1600 msnm en Cauca.',
    'prevencion': 'Toldillos impregnados. Eliminar criaderos. Consulta inmediata ante fiebre en zona endémica.',
    'signos_alarma': 'Fiebre intermitente, escalofríos, sudoración. Gota gruesa ante toda fiebre en zona de riesgo.',
    'municipios_riesgo': ['López de Micay', 'Timbiquí', 'Guapi', 'Olaya Herrera', 'Santa Bárbara'],
    'nivel_base': 'alerta',
  },
  {
    'codigo': 'TBC', 'nombre': 'Tuberculosis', 'emoji': '🫁',
    'descripcion': 'Enfermedad infecciosa causada por Mycobacterium tuberculosis. Transmisión por vía aérea.',
    'prevencion': 'Diagnóstico temprano. Tratamiento DOTS supervisado. Vacuna BCG al nacer.',
    'signos_alarma': 'Tos > 15 días, pérdida de peso, sudoración nocturna, fiebre vespertina.',
    'municipios_riesgo': ['Popayán', 'Santander de Quilichao', 'Miranda', 'Caloto'],
    'nivel_base': 'vigilancia',
  },
  {
    'codigo': 'VIF', 'nombre': 'Violencia y Lesiones', 'emoji': '🚨',
    'descripcion': 'Evento de salud pública que incluye violencia intrafamiliar, sexual y accidentes. Notificación obligatoria.',
    'prevencion': 'Redes de apoyo comunitario. Activar rutas de atención integral. Notificar a autoridades.',
    'signos_alarma': 'Todo caso de violencia es EMERGENCIA. Activar ruta de atención inmediata.',
    'municipios_riesgo': ['Todo el departamento'],
    'nivel_base': 'alerta',
  },
  {
    'codigo': 'DES', 'nombre': 'Desnutrición Aguda', 'emoji': '⚖️',
    'descripcion': 'Emergencia nutricional en menores de 5 años. Indicador trazador de condiciones de vida.',
    'prevencion': 'Monitoreo de peso/talla en menores. Complementación alimentaria. Activar programas ICBF.',
    'signos_alarma': 'Peso/talla < -3 DE, edema en pies, pelo rojizo. EMERGENCIA: hospitalización inmediata.',
    'municipios_riesgo': ['Toribío', 'Páez', 'Jambaló', 'Caldono', 'Silvia'],
    'nivel_base': 'alerta',
  },
  {
    'codigo': 'COV', 'nombre': 'COVID-19 y Virus Respiratorios', 'emoji': '😷',
    'descripcion': 'Vigilancia de virus respiratorios graves. Seguimiento de variantes y brotes estacionales.',
    'prevencion': 'Ventilación de espacios. Higiene de manos. Vacunación con esquema completo.',
    'signos_alarma': 'Fiebre + tos + dificultad respiratoria. Saturación < 94% requiere atención inmediata.',
    'municipios_riesgo': ['Todo el departamento'],
    'nivel_base': 'normal',
  },
];

// ─── Alertas activas simuladas (se mezclan con las de SQLite) ──────────────
final List<Map<String, dynamic>> _kAlertasActivas = [
  {
    'codigo': 'DEN', 'nivel': 'urgente', 'fecha': DateTime.now().subtract(const Duration(hours: 2)),
    'municipio': 'Santander de Quilichao',
    'mensaje': 'Incremento de casos en últimas 2 semanas. Se activa alerta epidemiológica.',
    'casos': 18,
  },
  {
    'codigo': 'MAL', 'nivel': 'alerta', 'fecha': DateTime.now().subtract(const Duration(days: 1)),
    'municipio': 'López de Micay',
    'mensaje': 'Casos confirmados de P. falciparum. Reforzar búsqueda activa con gota gruesa.',
    'casos': 5,
  },
  {
    'codigo': 'DES', 'nivel': 'alerta', 'fecha': DateTime.now().subtract(const Duration(days: 3)),
    'municipio': 'Toribío',
    'mensaje': 'Tres niños menores de 2 años con desnutrición aguda severa. Activar ICBF.',
    'casos': 3,
  },
];

class AlertasScreen extends StatefulWidget {
  const AlertasScreen({super.key});
  @override
  State<AlertasScreen> createState() => _AlertasScreenState();
}

class _AlertasScreenState extends State<AlertasScreen> {
  List<Map<String, dynamic>> _alertasSqlite = [];
  String _filtro = 'todas';
  bool _cargando = true;

  @override
  void initState() { super.initState(); _cargar(); }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    // Cargar alertas manuales del promotor
    final lista = await DatabaseHelper.instance.obtenerAlertas();
    // Generar alertas automáticas desde consultas urgentes
    final consultasUrgentes = await DatabaseHelper.instance.consultasUrgentesRecientes();
    for (final c in consultasUrgentes) {
      // Solo insertar si no existe ya una alerta igual en las últimas 24h
      final existe = lista.any((a) =>
        a['paciente'] == c['nombre'] &&
        a['modulo'] == c['modulo']);
      if (!existe && (c['nivel_riesgo'] == 'urgente' || c['nivel_riesgo'] == 'alerta')) {
        await DatabaseHelper.instance.insertarAlerta({
          'modulo':   c['modulo'] ?? '',
          'paciente': c['nombre'] ?? 'Paciente',
          'mensaje':  c['diagnostico'] ?? 'Consulta con nivel de riesgo elevado',
          'nivel':    c['nivel_riesgo'] ?? 'alerta',
          'resuelta': 0,
        });
      }
    }
    final listaFinal = await DatabaseHelper.instance.obtenerAlertas();
    setState(() { _alertasSqlite = listaFinal; _cargando = false; });
  }

  Future<void> _resolverAlerta(int id) async {
    await DatabaseHelper.instance.resolverAlerta(id);
    _cargar();
  }

  Color _nivelColor(String nivel) {
    switch (nivel) {
      case 'urgente': return Colors.red;
      case 'alerta':  return Colors.orange;
      default:        return _kVerde;
    }
  }

  String _nivelLabel(String nivel) {
    switch (nivel) {
      case 'urgente': return '🚨 URGENTE';
      case 'alerta':  return '⚠️ ALERTA';
      default:        return '✅ VIGILANCIA';
    }
  }

  String _tiempoRelativo(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 60) return 'hace ${d.inMinutes} min';
    if (d.inHours < 24)   return 'hace ${d.inHours}h';
    return 'hace ${d.inDays}d';
  }

  Map<String, dynamic>? _eventoBase(String codigo) {
    try { return _kEventosSivigila.firstWhere((e) => e['codigo'] == codigo); }
    catch (_) { return null; }
  }

  void _verDetalle(Map<String, dynamic> evento) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _kCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6, maxChildSize: 0.92, minChildSize: 0.4,
        expand: false,
        builder: (_, ctrl) => SingleChildScrollView(
          controller: ctrl,
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Row(children: [
              Text(evento['emoji'] ?? '🦠', style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(evento['nombre'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                Text('Código: ${evento['codigo'] ?? ''}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ])),
            ]),
            const SizedBox(height: 16),
            _SeccionDetalle(titulo: '📋 Descripción', contenido: evento['descripcion'] ?? ''),
            _SeccionDetalle(titulo: '🛡️ Prevención', contenido: evento['prevencion'] ?? ''),
            _SeccionDetalle(titulo: '⚠️ Signos de alarma', contenido: evento['signos_alarma'] ?? ''),
            const SizedBox(height: 12),
            Container(
              width: double.infinity, padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('📍 Municipios en riesgo', style: TextStyle(color: Colors.blue, fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(spacing: 6, runSpacing: 6,
                  children: (evento['municipios_riesgo'] as List<String>).map((m) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.blue.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                    child: Text(m, style: const TextStyle(color: Colors.blue, fontSize: 12)),
                  )).toList(),
                ),
              ]),
            ),
            const SizedBox(height: 24),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final urgentes = _kAlertasActivas.where((a) => a['nivel'] == 'urgente').length;

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _cargar,
          color: _kVerde,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              // ── Header ────────────────────────────────────────────────
              Row(children: [
                const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Alertas SIVIGILA', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  Text('Eventos de salud pública · Colombia', style: TextStyle(color: Colors.white54, fontSize: 12)),
                ])),
                if (urgentes > 0) Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: Colors.red.withOpacity(0.2), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.red.withOpacity(0.5))),
                  child: Text('$urgentes urgente${urgentes > 1 ? 's' : ''}', style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ]),
              const SizedBox(height: 16),

              // ── Alertas activas ───────────────────────────────────────
              const Text('Alertas activas en tu zona', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),

              ..._kAlertasActivas.map((a) {
                final ev = _eventoBase(a['codigo']);
                final color = _nivelColor(a['nivel']);
                return GestureDetector(
                  onTap: ev != null ? () => _verDetalle(ev) : null,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _kCard, borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: color.withOpacity(0.5)),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Text(ev?['emoji'] ?? '🦠', style: const TextStyle(fontSize: 24)),
                        const SizedBox(width: 10),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(ev?['nombre'] ?? a['codigo'], style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                          Text('${a['municipio']} · ${_tiempoRelativo(a['fecha'])}', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                        ])),
                        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                            child: Text(_nivelLabel(a['nivel']), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                          if ((a['casos'] as int) > 0) ...[
                            const SizedBox(height: 4),
                            Text('${a['casos']} casos', style: TextStyle(color: color.withOpacity(0.8), fontSize: 11)),
                          ],
                        ]),
                      ]),
                      const SizedBox(height: 8),
                      Text(a['mensaje'], style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4)),
                      const SizedBox(height: 6),
                      Text('Toca para ver protocolo de actuación →', style: TextStyle(color: color, fontSize: 11)),
                    ]),
                  ),
                );
              }),

              const SizedBox(height: 20),

              // ── Alertas registradas por el promotor ───────────────────
              Row(children: [
                const Expanded(child: Text('Alertas registradas por ti', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600))),
                TextButton(
                  onPressed: () => _mostrarFormularioAlerta(),
                  child: const Text('+ Registrar alerta', style: TextStyle(color: _kVerde, fontSize: 12)),
                ),
              ]),
              const SizedBox(height: 10),

              if (_cargando)
                const Center(child: CircularProgressIndicator(color: _kVerde))
              else if (_alertasSqlite.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: _kCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: _kBorder)),
                  child: const Column(children: [
                    Icon(Icons.notifications_off_outlined, color: Colors.white24, size: 36),
                    SizedBox(height: 10),
                    Text('Sin alertas registradas', style: TextStyle(color: Colors.white54, fontSize: 14)),
                    SizedBox(height: 4),
                    Text('Registra eventos inusuales que observes en tu comunidad.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white38, fontSize: 12)),
                  ]),
                )
              else
                ..._alertasSqlite.map((a) {
                  final color = _nivelColor(a['nivel'] ?? 'normal');
                  final resuelta = (a['resuelta'] as int? ?? 0) == 1;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _kCard, borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: resuelta ? Colors.white12 : color.withOpacity(0.4)),
                    ),
                    child: Row(children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(a['mensaje'] ?? '', style: TextStyle(color: resuelta ? Colors.white38 : Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        Text('${a['modulo'] ?? ''} · ${a['paciente'] ?? ''} · ${a['fecha'] ?? ''}', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                      ])),
                      if (!resuelta) GestureDetector(
                        onTap: () => _resolverAlerta(a['id']),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(color: _kVerde.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                          child: const Text('Resolver', style: TextStyle(color: _kVerde, fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                      ) else const Icon(Icons.check_circle_outline, color: Colors.white24, size: 20),
                    ]),
                  );
                }),

              const SizedBox(height: 20),

              // ── Todos los eventos SIVIGILA ────────────────────────────
              const Text('Guía de eventos SIVIGILA', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),

              ..._kEventosSivigila.map((ev) {
                final color = _nivelColor(ev['nivel_base']);
                return GestureDetector(
                  onTap: () => _verDetalle(ev),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: _kCard, borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Row(children: [
                      Text(ev['emoji'], style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(ev['nombre'], style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                        Text(ev['descripcion'], maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                      ])),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                        child: Text(ev['nivel_base'].toString().toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.chevron_right, color: Colors.white24, size: 16),
                    ]),
                  ),
                );
              }),

              const SizedBox(height: 24),
            ]),
          ),
        ),
      ),
    );
  }

  // ── Formulario para registrar nueva alerta ──────────────────────────────
  void _mostrarFormularioAlerta() {
    final _msgCtrl = TextEditingController();
    String _nivel  = 'alerta';
    String _modulo = 'General';

    showModalBottomSheet(
      context: context,
      backgroundColor: _kCard,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SingleChildScrollView(
        child: Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20,
            MediaQuery.of(ctx).viewInsets.bottom +
            (MediaQuery.of(ctx).padding.bottom < 16 ? 48 : MediaQuery.of(ctx).padding.bottom + 24)),
        child: StatefulBuilder(builder: (_, setS) => Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Registrar alerta', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const Text('Descripción del evento', style: TextStyle(color: Colors.white54, fontSize: 11)),
          const SizedBox(height: 4),
          TextField(
            controller: _msgCtrl,
            maxLines: 3,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Ej: Tres casos de fiebre con sarpullido en vereda La Esperanza...',
              hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
              filled: true, fillColor: const Color(0xFF2A2A2A),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Nivel', style: TextStyle(color: Colors.white54, fontSize: 11)),
              const SizedBox(height: 4),
              Container(padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(color: const Color(0xFF2A2A2A), borderRadius: BorderRadius.circular(10)),
                child: DropdownButton<String>(value: _nivel, isExpanded: true, underline: const SizedBox(), dropdownColor: _kCard,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  items: const [
                    DropdownMenuItem(value: 'urgente', child: Text('🚨 Urgente')),
                    DropdownMenuItem(value: 'alerta',  child: Text('⚠️ Alerta')),
                    DropdownMenuItem(value: 'normal',  child: Text('✅ Vigilancia')),
                  ],
                  onChanged: (v) => setS(() => _nivel = v!),
                ),
              ),
            ])),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Módulo', style: TextStyle(color: Colors.white54, fontSize: 11)),
              const SizedBox(height: 4),
              Container(padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(color: const Color(0xFF2A2A2A), borderRadius: BorderRadius.circular(10)),
                child: DropdownButton<String>(value: _modulo, isExpanded: true, underline: const SizedBox(), dropdownColor: _kCard,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  items: ['General','Gestación','Primera infancia','Infancia','Adolescencia','Juventud','Adultez','Vejez']
                      .map((m) => DropdownMenuItem(value: m, child: Text(m, overflow: TextOverflow.ellipsis))).toList(),
                  onChanged: (v) => setS(() => _modulo = v!),
                ),
              ),
            ])),
          ]),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, height: 48,
            child: ElevatedButton(
              onPressed: () async {
                if (_msgCtrl.text.trim().isEmpty) return;
                await DatabaseHelper.instance.insertarAlerta({
                  'modulo':   _modulo,
                  'paciente': '',
                  'mensaje':  _msgCtrl.text.trim(),
                  'nivel':    _nivel,
                  'resuelta': 0,
                });
                Navigator.pop(ctx);
                _cargar();
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: const Text('Alerta registrada correctamente'),
                  backgroundColor: _kVerde, behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ));
              },
              style: ElevatedButton.styleFrom(backgroundColor: _kVerde, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Guardar alerta', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 20),
        ]))),
      ),
    );
  }
}

class _SeccionDetalle extends StatelessWidget {
  final String titulo, contenido;
  const _SeccionDetalle({required this.titulo, required this.contenido});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: const Color(0xFF111111), borderRadius: BorderRadius.circular(12)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(titulo, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
      const SizedBox(height: 6),
      Text(contenido, style: const TextStyle(color: Colors.white60, fontSize: 13, height: 1.5)),
    ]),
  );
}