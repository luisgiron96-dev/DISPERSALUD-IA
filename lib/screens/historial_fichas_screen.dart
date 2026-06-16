// lib/screens/historial_fichas_screen.dart
//
// Historial de Fichas Epidemiológicas — DISPERSALUD IA
// Vista cronológica con filtros por estado y evento. Complementa a
// fichas_reportes_screen.dart (que lista todas las fichas guardadas).

import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../database/database_helper.dart';
import 'ficha_formulario_screen.dart';

DispersaludColors _c(BuildContext ctx) =>
    Theme.of(ctx).extension<DispersaludColors>() ?? DispersaludColors.dark;

const _kVerde   = Color(0xFF1D9E75);
const _kRojo    = Color(0xFFE24B4A);
const _kNaranja = Color(0xFFEF9F27);
const _kAzul    = Color(0xFF185FA5);

class HistorialFichasScreen extends StatefulWidget {
  const HistorialFichasScreen({super.key});

  @override
  State<HistorialFichasScreen> createState() => _HistorialFichasScreenState();
}

class _HistorialFichasScreenState extends State<HistorialFichasScreen> {
  List<Map<String, dynamic>> _fichas    = [];
  List<Map<String, dynamic>> _filtradas = [];
  bool   _cargando = true;
  String _filtroEstado = 'todas';   // todas / completa / borrador
  final  _searchCtrl   = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    final lista = await DatabaseHelper.instance.obtenerFichas();
    if (mounted) {
      setState(() {
        _fichas    = lista;
        _filtradas = _aplicarFiltros(lista);
        _cargando  = false;
      });
    }
  }

  List<Map<String, dynamic>> _aplicarFiltros(List<Map<String, dynamic>> src) {
    var r = src;
    if (_filtroEstado != 'todas') {
      r = r.where((f) => (f['estado'] as String? ?? 'borrador') == _filtroEstado).toList();
    }
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      r = r.where((f) {
        final nombre   = (f['nombre_evento']   as String? ?? '').toLowerCase();
        final paciente = (f['nombre_paciente'] as String? ?? '').toLowerCase();
        final codigo   = (f['codigo_evento']   as String? ?? '').toLowerCase();
        final municipio = (f['municipio']      as String? ?? '').toLowerCase();
        return nombre.contains(q) || paciente.contains(q) ||
               codigo.contains(q)  || municipio.contains(q);
      }).toList();
    }
    return r;
  }

  void _onBuscar(String _) =>
      setState(() => _filtradas = _aplicarFiltros(_fichas));

  void _onFiltro(String estado) {
    setState(() {
      _filtroEstado = estado;
      _filtradas    = _aplicarFiltros(_fichas);
    });
  }

  Future<void> _eliminar(int id) async {
    final dc = _c(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: dc.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('¿Eliminar ficha?',
            style: TextStyle(color: dc.textPrimary, fontWeight: FontWeight.bold)),
        content: Text('Esta acción no se puede deshacer.',
            style: TextStyle(color: dc.textSecondary, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar', style: TextStyle(color: dc.textHint))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _kRojo),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white))),
        ],
      ),
    );
    if (ok == true) {
      await DatabaseHelper.instance.eliminarFicha(id);
      _cargar();
    }
  }

  String _formatFecha(String? raw) {
    if (raw == null || raw.length < 10) return '—';
    try {
      final dt = DateTime.parse(raw);
      return '${dt.day.toString().padLeft(2,'0')}/${dt.month.toString().padLeft(2,'0')}/${dt.year}';
    } catch (_) {
      return raw.substring(0, 10);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dc = _c(context);
    final totalCompletas = _fichas.where((f) => (f['estado'] as String?) == 'completa').length;
    final totalBorradores = _fichas.length - totalCompletas;

    return Scaffold(
      backgroundColor: dc.bg,
      appBar: AppBar(
        backgroundColor: dc.card,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: dc.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Historial de fichas',
              style: TextStyle(color: dc.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
          Text('${_fichas.length} fichas guardadas',
              style: TextStyle(color: dc.textHint, fontSize: 11)),
        ]),
      ),
      body: Column(children: [
        // ── Buscador ───────────────────────────────────────────────────
        Container(
          color: dc.card,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: TextField(
            controller: _searchCtrl,
            onChanged: _onBuscar,
            style: TextStyle(color: dc.textPrimary, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Buscar por evento, paciente o municipio…',
              hintStyle: TextStyle(color: dc.textHint, fontSize: 12),
              prefixIcon: Icon(Icons.search, color: dc.textHint, size: 18),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.close, color: dc.textHint, size: 16),
                      onPressed: () {
                        _searchCtrl.clear();
                        _onBuscar('');
                      })
                  : null,
              filled: true, fillColor: dc.bg,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
            ),
          ),
        ),

        // ── Chips de filtro por estado ──────────────────────────────────
        Container(
          color: dc.card,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Row(children: [
            _ChipFiltro(label: '🗂️ Todas (${_fichas.length})',
                activo: _filtroEstado == 'todas', color: _kAzul,
                onTap: () => _onFiltro('todas')),
            const SizedBox(width: 8),
            _ChipFiltro(label: '✅ Completas ($totalCompletas)',
                activo: _filtroEstado == 'completa', color: _kVerde,
                onTap: () => _onFiltro('completa')),
            const SizedBox(width: 8),
            _ChipFiltro(label: '⏳ Borradores ($totalBorradores)',
                activo: _filtroEstado == 'borrador', color: _kNaranja,
                onTap: () => _onFiltro('borrador')),
          ]),
        ),

        Divider(height: 1, color: dc.border),

        // ── Lista ────────────────────────────────────────────────────
        Expanded(
          child: _cargando
              ? const Center(child: CircularProgressIndicator(color: _kVerde))
              : _filtradas.isEmpty
                  ? _buildVacio(dc)
                  : RefreshIndicator(
                      color: _kVerde,
                      onRefresh: _cargar,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filtradas.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => _buildTarjeta(_filtradas[i], dc),
                      ),
                    ),
        ),
      ]),
    );
  }

  Widget _buildVacio(DispersaludColors dc) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.history_rounded, color: dc.textHint, size: 52),
      const SizedBox(height: 12),
      Text(
        _fichas.isEmpty
            ? 'Aún no has guardado ninguna ficha'
            : 'Sin resultados para esta búsqueda',
        style: TextStyle(color: dc.textPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
      const SizedBox(height: 6),
      Text(
        _fichas.isEmpty
            ? 'Llena un formulario desde el catálogo de fichas epidemiológicas.'
            : 'Intenta con otro término o filtro.',
        style: TextStyle(color: dc.textHint, fontSize: 12),
        textAlign: TextAlign.center),
    ]),
  );

  Widget _buildTarjeta(Map<String, dynamic> f, DispersaludColors dc) {
    final id        = f['id'] as int;
    final codigo    = f['codigo_evento']   as String? ?? '';
    final nombre    = f['nombre_evento']   as String? ?? 'Sin nombre';
    final paciente  = f['nombre_paciente'] as String? ?? 'Sin paciente';
    final municipio = f['municipio']       as String? ?? '';
    final estado    = f['estado']          as String? ?? 'borrador';
    final urgencia  = f['nivel_urgencia']  as String? ?? 'normal';
    final fecha     = _formatFecha(f['created_at'] as String?);
    final completa  = estado == 'completa';

    return Container(
      decoration: BoxDecoration(
          color: dc.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: urgencia == 'urgente' ? _kRojo.withOpacity(0.4) : dc.border)),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () async {
            final ok = await Navigator.push<bool>(context, MaterialPageRoute(
              builder: (_) => FichaFormularioScreen(
                codigoFicha: codigo,
                nombreFicha: nombre,
                colorFicha: completa ? _kVerde : _kNaranja,
                emojiFicha: '📋',
                fichaId: id,
              ),
            ));
            if (ok == true) _cargar();
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              Container(
                width: 46, height: 46,
                decoration: BoxDecoration(
                    color: (completa ? _kVerde : _kNaranja).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(
                    completa ? Icons.task_alt_rounded : Icons.edit_note_rounded,
                    color: completa ? _kVerde : _kNaranja, size: 22)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(nombre,
                      style: TextStyle(color: dc.textPrimary,
                          fontSize: 13, fontWeight: FontWeight.bold),
                      maxLines: 1, overflow: TextOverflow.ellipsis)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                        color: _kAzul.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(6)),
                    child: Text(codigo,
                        style: const TextStyle(color: _kAzul,
                            fontSize: 9, fontWeight: FontWeight.bold))),
                ]),
                const SizedBox(height: 3),
                Text('👤 $paciente',
                    style: TextStyle(color: dc.textSecondary, fontSize: 11),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Row(children: [
                  if (municipio.isNotEmpty) ...[
                    Icon(Icons.location_on_outlined, size: 11, color: dc.textHint),
                    const SizedBox(width: 2),
                    Text(municipio, style: TextStyle(color: dc.textHint, fontSize: 10)),
                    const SizedBox(width: 8),
                  ],
                  Icon(Icons.calendar_today_rounded, size: 10, color: dc.textHint),
                  const SizedBox(width: 2),
                  Text(fecha, style: TextStyle(color: dc.textHint, fontSize: 10)),
                ]),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                      color: (completa ? _kVerde : _kNaranja).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6)),
                  child: Text(completa ? '✓ Completa' : '⏳ Borrador',
                      style: TextStyle(
                          color: completa ? _kVerde : _kNaranja,
                          fontSize: 9, fontWeight: FontWeight.bold)),
                ),
              ])),
              const SizedBox(width: 4),
              PopupMenuButton<String>(
                color: dc.card,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                icon: Icon(Icons.more_vert_rounded, color: dc.textHint, size: 18),
                onSelected: (v) {
                  if (v == 'eliminar') _eliminar(id);
                },
                itemBuilder: (_) => [
                  PopupMenuItem(value: 'eliminar', child: Row(children: [
                    const Icon(Icons.delete_rounded, color: _kRojo, size: 16),
                    const SizedBox(width: 8),
                    Text('Eliminar', style: TextStyle(color: dc.textPrimary, fontSize: 13)),
                  ])),
                ],
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

// ─── Chip de filtro ──────────────────────────────────────────────────────────
class _ChipFiltro extends StatelessWidget {
  final String label;
  final bool   activo;
  final Color  color;
  final VoidCallback onTap;
  const _ChipFiltro({required this.label, required this.activo,
      required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final dc = _c(context);
    return Expanded(child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: activo ? color.withOpacity(0.14) : dc.bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: activo ? color : dc.border,
              width: activo ? 1.5 : 1),
        ),
        child: Center(child: Text(label,
            style: TextStyle(
                color: activo ? color : dc.textHint,
                fontSize: 10.5,
                fontWeight: activo ? FontWeight.bold : FontWeight.normal),
            textAlign: TextAlign.center)),
      ),
    ));
  }
}