import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../core/responsive.dart';
import '../database/database_helper.dart';
import 'nuevo_paciente_screen.dart';
import 'historial_screen.dart';
import 'historia_clinica_screen.dart';

const Color _kVerde  = Color(0xFF1D9E75);
DispersaludColors _c(BuildContext ctx) =>
    Theme.of(ctx).extension<DispersaludColors>() ?? DispersaludColors.dark;

class PacientesScreen extends StatefulWidget {
  PacientesScreen({super.key});
  @override
  State<PacientesScreen> createState() => _PacientesScreenState();
}

class _PacientesScreenState extends State<PacientesScreen> {
  final _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _pacientes = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    final lista = await DatabaseHelper.instance.obtenerPacientes();
    setState(() { _pacientes = lista; _cargando = false; });
  }

  Future<void> _buscar(String q) async {
    if (q.trim().isEmpty) { _cargar(); return; }
    final lista = await DatabaseHelper.instance.buscarPacientes(q.trim());
    setState(() => _pacientes = lista);
  }

  Future<void> _eliminar(int id, String nombre) async {
    final conf = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text('Eliminar paciente', style: TextStyle(color: _c(context).textPrimary)),
        content: Text('¿Eliminar a $nombre y todo su historial?',
            style: TextStyle(color: _c(context).textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: Text('Cancelar', style: TextStyle(color: _c(context).textHint))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Eliminar', style: TextStyle(color: _c(context).textPrimary)),
          ),
        ],
      ),
    );
    if (conf == true) {
      await DatabaseHelper.instance.eliminarPaciente(id);
      _cargar();
    }
  }

  String _iniciales(String nombre) {
    final partes = nombre.trim().split(' ');
    if (partes.length >= 2) return '${partes[0][0]}${partes[1][0]}'.toUpperCase();
    return nombre.isNotEmpty ? nombre[0].toUpperCase() : '?';
  }

  Color _colorModulo(String modulo) {
    switch (modulo) {
      case 'Gestación':        return Color(0xFF993556);
      case 'Primera infancia': return Color(0xFF854F0B);
      case 'Infancia':         return Color(0xFF185FA5);
      case 'Adolescencia':     return Color(0xFF534AB7);
      case 'Juventud':         return Color(0xFF3B6D11);
      case 'Adultez':          return Color(0xFF0F6E56);
      case 'Vejez':            return Color(0xFF5F5E5A);
      default:                 return _kVerde;
    }
  }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _c(context).bg,
      body: SafeArea(
        child: ResponsiveCenter(
        child: Column(children: [
          // ── Header ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Pacientes', style: TextStyle(color: _c(context).textPrimary, fontSize: 22, fontWeight: FontWeight.bold)),
                Text('Registros locales · sin internet', style: TextStyle(color: _c(context).textHint, fontSize: 12)),
              ])),
              ElevatedButton.icon(
                onPressed: () async {
                  await Navigator.push(context,
                      MaterialPageRoute(builder: (_) => NuevoPacienteScreen()));
                  _cargar();
                },
                icon: Icon(Icons.person_add_outlined, color: Colors.white, size: 18),
                label: Text('Nuevo', style: TextStyle(color: _c(context).textPrimary, fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kVerde,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),
            ]),
          ),

          // ── Buscador ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _buscar,
              style: TextStyle(color: _c(context).textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Buscar por nombre, vereda o municipio...',
                hintStyle: TextStyle(color: _c(context).textHint, fontSize: 13),
                prefixIcon: Icon(Icons.search, color: _c(context).textHint, size: 20),
                filled: true, fillColor: _c(context).card,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),
          SizedBox(height: 12),

          // ── Lista ─────────────────────────────────────────────────────
          Expanded(
            child: _cargando
                ? Center(child: CircularProgressIndicator(color: Color(0xFF1D9E75)))
                : _pacientes.isEmpty
                    ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.people_outline, color: _c(context).border, size: 56),
                        SizedBox(height: 12),
                        Text('No hay pacientes registrados',
                            style: TextStyle(color: _c(context).textHint, fontSize: 15)),
                        SizedBox(height: 8),
                        TextButton(
                          onPressed: () async {
                            await Navigator.push(context,
                                MaterialPageRoute(builder: (_) => NuevoPacienteScreen()));
                            _cargar();
                          },
                          child: Text('Registrar primer paciente →',
                              style: TextStyle(color: Color(0xFF1D9E75))),
                        ),
                      ]))
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _pacientes.length,
                        separatorBuilder: (_, __) => SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final p = _pacientes[i];
                          final color = _colorModulo(p['modulo'] ?? '');
                          return Dismissible(
                            key: Key('p_${p['id']}'),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(14)),
                              child: Icon(Icons.delete_outline, color: Colors.red),
                            ),
                            confirmDismiss: (_) async {
                              await _eliminar(p['id'], p['nombre']);
                              return false;
                            },
                            child: GestureDetector(
                              onTap: () async {
                                await Navigator.push(context, MaterialPageRoute(
                                    builder: (_) => HistorialScreen(
                                        pacienteId: p['id'], nombre: p['nombre'])));
                                _cargar();
                              },
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: _c(context).card,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: _c(context).border),
                                ),
                                child: Row(children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor: color.withOpacity(0.2),
                                    child: Text(_iniciales(p['nombre'] ?? ''),
                                        style: TextStyle(color: color,
                                            fontWeight: FontWeight.bold, fontSize: 14)),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text(p['nombre'] ?? '',
                                        style: TextStyle(color: _c(context).textPrimary,
                                            fontSize: 14, fontWeight: FontWeight.w600)),
                                    SizedBox(height: 2),
                                    Text('${p['vereda'] ?? ''} · ${p['municipio'] ?? ''}',
                                        style: TextStyle(color: _c(context).textHint, fontSize: 12)),
                                  ])),
                                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                          color: color.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(20)),
                                      child: Text(p['modulo'] ?? '',
                                          style: TextStyle(color: color,
                                              fontSize: 10, fontWeight: FontWeight.w600)),
                                    ),
                                    SizedBox(height: 4),
                                    Row(mainAxisSize: MainAxisSize.min, children: [
                                      // Botón Historia Clínica
                                      GestureDetector(
                                        onTap: () => Navigator.push(context,
                                          MaterialPageRoute(builder: (_) =>
                                            HistoriaClinicaScreen(
                                              pacienteId: p['id'],
                                              nombrePaciente: p['nombre']))),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF534AB7).withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Row(mainAxisSize: MainAxisSize.min,
                                              children: [
                                            Icon(Icons.assignment_rounded,
                                                color: Color(0xFF534AB7), size: 13),
                                            SizedBox(width: 3),
                                            Text('H.C.',
                                                style: TextStyle(
                                                    color: Color(0xFF534AB7),
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w700)),
                                          ]),
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      GestureDetector(
                                        onTap: () async {
                                          await Navigator.push(context, MaterialPageRoute(
                                              builder: (_) => NuevoPacienteScreen(pacienteEditar: p)));
                                          _cargar();
                                        },
                                        child: Icon(Icons.edit_outlined,
                                            color: _c(context).textSecondary, size: 18),
                                      ),
                                      SizedBox(width: 8),
                                      Icon(Icons.chevron_right,
                                          color: _c(context).border, size: 18),
                                    ]),
                                  ]),
                                ]),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ]),
        ),
      ),
    );
  }
}