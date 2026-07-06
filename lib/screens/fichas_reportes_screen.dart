// lib/screens/fichas_reportes_screen.dart
// Lista de fichas epidemiológicas guardadas — DISPERSALUD IA

import 'dart:convert';
import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../core/responsive.dart';
import '../database/database_helper.dart';
import 'ficha_formulario_screen.dart';

DispersaludColors _dc(BuildContext ctx) =>
    Theme.of(ctx).extension<DispersaludColors>() ?? DispersaludColors.dark;

const _kVerde  = Color(0xFF1D9E75);
const _kRojo   = Color(0xFFE24B4A);
const _kNaranja= Color(0xFFEF9F27);
const _kAzul   = Color(0xFF185FA5);

class FichasReportesScreen extends StatefulWidget {
  const FichasReportesScreen({super.key});
  @override
  State<FichasReportesScreen> createState() => _FichasReportesScreenState();
}

class _FichasReportesScreenState extends State<FichasReportesScreen> {
  List<Map<String, dynamic>> _fichas = [];
  bool _cargando = true;

  @override
  void initState() { super.initState(); _cargar(); }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    final lista = await DatabaseHelper.instance.obtenerFichas();
    if (mounted) setState(() { _fichas = lista; _cargando = false; });
  }

  Future<void> _eliminar(int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _dc(context).card,
        title: Text('¿Eliminar ficha?',
            style: TextStyle(color: _dc(context).textPrimary)),
        content: Text('Esta acción no se puede deshacer.',
            style: TextStyle(color: _dc(context).textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: Text('Cancelar', style: TextStyle(color: _dc(context).textHint))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _kRojo),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await DatabaseHelper.instance.eliminarFicha(id);
      _cargar();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dc = _dc(context);
    return Scaffold(
      backgroundColor: dc.bg,
      appBar: AppBar(
        backgroundColor: dc.bg, elevation: 0,
        iconTheme: IconThemeData(color: dc.textPrimary),
        title: Text('Fichas guardadas',
            style: TextStyle(color: dc.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      body: ResponsiveCenter(child: _cargando
          ? const Center(child: CircularProgressIndicator(color: _kVerde))
          : _fichas.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.folder_open_rounded, color: dc.textHint, size: 56),
                  const SizedBox(height: 12),
                  Text('No hay fichas guardadas aún',
                      style: TextStyle(color: dc.textSecondary, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text('Llena una ficha desde el catálogo de fichas epidemiológicas.',
                      style: TextStyle(color: dc.textHint, fontSize: 12), textAlign: TextAlign.center),
                ]))
              : RefreshIndicator(
                  color: _kVerde,
                  onRefresh: _cargar,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _fichas.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final f = _fichas[i];
                      final id = f['id'] as int;
                      final codigo = f['codigo_evento'] as String? ?? '';
                      final nombre = f['nombre_evento'] as String? ?? '';
                      final paciente = f['nombre_paciente'] as String? ?? 'Sin nombre';
                      final municipio= f['municipio'] as String? ?? '';
                      final fecha   = (f['created_at'] as String? ?? '').substring(0, 10);
                      final estado  = f['estado'] as String? ?? 'borrador';
                      final exportado = (f['exportado'] as int? ?? 0) == 1;

                      return Container(
                        decoration: BoxDecoration(
                          color: dc.card,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: dc.border),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          leading: Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(
                                color: _kVerde.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10)),
                            child: const Center(child: Icon(Icons.assignment_rounded,
                                color: _kVerde, size: 22)),
                          ),
                          title: Text(nombre,
                              style: TextStyle(color: dc.textPrimary,
                                  fontSize: 13, fontWeight: FontWeight.bold)),
                          subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const SizedBox(height: 2),
                            Text('👤 $paciente',
                                style: TextStyle(color: dc.textSecondary, fontSize: 11)),
                            if (municipio.isNotEmpty)
                              Text('📍 $municipio  •  📅 $fecha',
                                  style: TextStyle(color: dc.textHint, fontSize: 10)),
                            const SizedBox(height: 4),
                            Row(children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                    color: estado == 'completa'
                                        ? _kVerde.withOpacity(0.12)
                                        : _kNaranja.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(6)),
                                child: Text(
                                    estado == 'completa' ? '✓ Completa' : '⏳ Borrador',
                                    style: TextStyle(
                                        color: estado == 'completa' ? _kVerde : _kNaranja,
                                        fontSize: 9, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                    color: _kAzul.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6)),
                                child: Text('# $codigo',
                                    style: const TextStyle(color: _kAzul,
                                        fontSize: 9, fontWeight: FontWeight.bold)),
                              ),
                            ]),
                          ]),
                          trailing: PopupMenuButton<String>(
                            color: dc.card,
                            onSelected: (v) async {
                              if (v == 'editar') {
                                final ok = await Navigator.push<bool>(context, MaterialPageRoute(
                                  builder: (_) => FichaFormularioScreen(
                                    codigoFicha: codigo,
                                    nombreFicha: nombre,
                                    colorFicha: _kVerde,
                                    emojiFicha: '📋',
                                    fichaId: id,
                                  ),
                                ));
                                if (ok == true) _cargar();
                              } else if (v == 'eliminar') {
                                await _eliminar(id);
                              }
                            },
                            itemBuilder: (_) => [
                              PopupMenuItem(value: 'editar',
                                child: Row(children: [
                                  Icon(Icons.edit_rounded, color: _kAzul, size: 16),
                                  const SizedBox(width: 8),
                                  Text('Editar', style: TextStyle(color: _dc(context).textPrimary)),
                                ])),
                              PopupMenuItem(value: 'eliminar',
                                child: Row(children: [
                                  const Icon(Icons.delete_rounded, color: _kRojo, size: 16),
                                  const SizedBox(width: 8),
                                  Text('Eliminar', style: TextStyle(color: _dc(context).textPrimary)),
                                ])),
                            ],
                            child: Icon(Icons.more_vert_rounded, color: dc.textHint),
                          ),
                        ),
                      );
                    },
                  ),
                ),
      ),
    );
  }
}
