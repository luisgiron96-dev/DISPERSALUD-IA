import 'dart:async';
import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../services/connectivity_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MODELO
// ─────────────────────────────────────────────────────────────────────────────
class _PacienteSeg {
  final String nombre, ubicacion, condicion, ultimaVisita, proximoControl;
  final String riesgo, categoria;
  const _PacienteSeg({
    required this.nombre, required this.ubicacion, required this.condicion,
    required this.ultimaVisita, required this.proximoControl,
    required this.riesgo, required this.categoria,
  });
}

const List<_PacienteSeg> _kPacientes = [
  _PacienteSeg(nombre: 'María Fernanda Hernández', ubicacion: 'Timbío - Cauca',
    condicion: 'Gestante (28 semanas)', ultimaVisita: 'Hace 7 días',
    proximoControl: 'Hoy 2:00 p.m.', riesgo: 'alto', categoria: 'gestante'),
  _PacienteSeg(nombre: 'Carlos Alberto Pérez', ubicacion: 'El Palmar - Cauca',
    condicion: 'Hipertensión arterial', ultimaVisita: 'Hace 14 días',
    proximoControl: 'En 2 días', riesgo: 'alto', categoria: 'cronico'),
  _PacienteSeg(nombre: 'Juan David Morales', ubicacion: 'La Esperanza - Cauca',
    condicion: 'Control general', ultimaVisita: 'Hace 21 días',
    proximoControl: 'En 5 días', riesgo: 'medio', categoria: 'nino'),
  _PacienteSeg(nombre: 'María Inés Valencia', ubicacion: 'San Antonio - Cauca',
    condicion: 'Diabetes tipo 2', ultimaVisita: 'Hace 1 mes',
    proximoControl: 'En 12 días', riesgo: 'bajo', categoria: 'adulto_mayor'),
  _PacienteSeg(nombre: 'Luis Ernesto Castro', ubicacion: 'Villa Rica - Cauca',
    condicion: 'Control adulto mayor', ultimaVisita: 'Hace 3 semanas',
    proximoControl: 'En 7 días', riesgo: 'medio', categoria: 'adulto_mayor'),
  _PacienteSeg(nombre: 'Ana Sofía Mosquera', ubicacion: 'Santander de Q.',
    condicion: 'Gestante (35 semanas)', ultimaVisita: 'Hace 5 días',
    proximoControl: 'Mañana', riesgo: 'bajo', categoria: 'gestante'),
];

// ─────────────────────────────────────────────────────────────────────────────
// PANTALLA
// ─────────────────────────────────────────────────────────────────────────────
class SeguimientoScreen extends StatefulWidget {
  const SeguimientoScreen({super.key});
  @override
  State<SeguimientoScreen> createState() => _SeguimientoScreenState();
}

class _SeguimientoScreenState extends State<SeguimientoScreen> {
  bool _online = false;
  StreamSubscription<bool>? _connSub;
  String _filtro = 'todos';

  static const _verde = Color(0xFF1D9E75);
  static const _rojo  = Color(0xFFE24B4A);
  static const _ambar = Color(0xFFEF9F27);
  static const _azul  = Color(0xFF185FA5);

  @override
  void initState() {
    super.initState();
    _initConn();
  }

  @override
  void dispose() { _connSub?.cancel(); super.dispose(); }

  Future<void> _initConn() async {
    _online = await ConnectivityService.instance.verificarAhora();
    if (mounted) setState(() {});
    _connSub = ConnectivityService.instance.cambios.listen((v) {
      if (mounted) setState(() => _online = v);
    });
  }

  List<_PacienteSeg> get _filtrados {
    if (_filtro == 'todos') return _kPacientes;
    return _kPacientes.where((p) => p.categoria == _filtro).toList();
  }

  Color _cRiesgo(String r) =>
      r == 'alto' ? _rojo : r == 'medio' ? _ambar : _verde;

  String _lRiesgo(String r) =>
      r == 'alto' ? 'Alto riesgo' : r == 'medio' ? 'Riesgo medio' : 'Bajo riesgo';

  IconData _iRiesgo(String r) =>
      r == 'alto' ? Icons.warning_rounded
      : r == 'medio' ? Icons.error_outline_rounded
      : Icons.shield_rounded;

  IconData _iCat(String c) {
    switch (c) {
      case 'gestante':     return Icons.favorite_border_rounded;
      case 'cronico':      return Icons.monitor_heart_outlined;
      case 'adulto_mayor': return Icons.accessible_forward_rounded;
      case 'nino':         return Icons.child_friendly_outlined;
      default:             return Icons.person_outline_rounded;
    }
  }

  Color _cCat(String c) {
    switch (c) {
      case 'gestante':     return const Color(0xFF993556);
      case 'cronico':      return _rojo;
      case 'adulto_mayor': return const Color(0xFF5F5E5A);
      case 'nino':         return _azul;
      default:             return _verde;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dc = DT(context);

    return Scaffold(
      backgroundColor: dc.bg,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: _verde,
        icon: const Icon(Icons.add_circle_outline_rounded,
            color: Colors.white, size: 20),
        label: const Text('Nuevo seguimiento',
            style: TextStyle(color: Colors.white, fontSize: 12,
                fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: Column(children: [
          // ── APP BAR ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Row(children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: dc.card,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: dc.border)),
                child: Icon(Icons.menu, color: dc.textSecondary, size: 18),
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
                    Text('128 pacientes monitoreados',
                        style: TextStyle(color: dc.textHint, fontSize: 10)),
                  ]),
              ),
              // Badge online
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: _online ? _verde.withOpacity(0.12) : dc.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: _online ? _verde : dc.border),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 6, height: 6,
                      decoration: BoxDecoration(
                          color: _online ? _verde : Colors.orange,
                          shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  Text(_online ? 'Online Activo' : 'Offline Activo',
                      style: TextStyle(
                          color: _online ? _verde : Colors.orange,
                          fontSize: 10, fontWeight: FontWeight.w600)),
                ]),
              ),
            ]),
          ),

          // ── CONTENIDO SCROLLEABLE ────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── 4 TARJETAS RIESGO ─────────────────────────────────
                  Row(children: [
                    _RCard(valor: '12', label: 'Alto\nriesgo',
                        color: _rojo, icono: Icons.warning_rounded, dc: dc),
                    const SizedBox(width: 8),
                    _RCard(valor: '25', label: 'Riesgo\nmedio',
                        color: _ambar, icono: Icons.error_outline_rounded, dc: dc),
                    const SizedBox(width: 8),
                    _RCard(valor: '91', label: 'Bajo\nriesgo',
                        color: _verde, icono: Icons.shield_rounded, dc: dc),
                    const SizedBox(width: 8),
                    _RCard(valor: '18', label: 'Controles\nhoy',
                        color: _azul, icono: Icons.calendar_today_rounded, dc: dc),
                  ]),
                  const SizedBox(height: 12),

                  // ── BANNER IA ─────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: dc.card,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: dc.border)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Fila título IA
                        Row(children: [
                          Container(
                            width: 38, height: 38,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                  colors: [Color(0xFF534AB7), Color(0xFF7B61FF)]),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.smart_toy_rounded,
                                color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('IA DISPERSALUD',
                                    style: TextStyle(color: Color(0xFF7B61FF),
                                        fontSize: 13, fontWeight: FontWeight.bold)),
                                Text('Análisis inteligente de seguimiento',
                                    style: TextStyle(
                                        color: dc.textSecondary, fontSize: 10)),
                              ])),
                          GestureDetector(
                            onTap: () {},
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF534AB7).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: const Color(0xFF534AB7).withOpacity(0.3)),
                              ),
                              child: const Row(mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('Ver todas', style: TextStyle(
                                        color: Color(0xFF7B61FF), fontSize: 11,
                                        fontWeight: FontWeight.w600)),
                                    SizedBox(width: 2),
                                    Icon(Icons.chevron_right_rounded,
                                        color: Color(0xFF7B61FF), size: 14),
                                  ]),
                            ),
                          ),
                        ]),
                        const SizedBox(height: 10),
                        // Grid de alertas 2x2
                        Row(children: [
                          Expanded(child: _IaBadge(
                              texto: '5 Gestantes sin control', color: _ambar)),
                          const SizedBox(width: 8),
                          Expanded(child: _IaBadge(
                              texto: '2 Pacientes críticos', color: _rojo)),
                        ]),
                        const SizedBox(height: 6),
                        Row(children: [
                          Expanded(child: _IaBadge(
                              texto: '3 Hipertensos sin visita', color: _rojo)),
                          const SizedBox(width: 8),
                          Expanded(child: _IaBadge(
                              texto: '8 Vacunas pendientes', color: _ambar)),
                        ]),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── FILTROS ───────────────────────────────────────────
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(children: [
                      _Chip(label: 'Todos', icono: Icons.group_rounded,
                          activo: _filtro == 'todos', color: _verde,
                          onTap: () => setState(() => _filtro = 'todos')),
                      const SizedBox(width: 6),
                      _Chip(label: 'Gestantes', icono: Icons.favorite_border_rounded,
                          activo: _filtro == 'gestante',
                          color: const Color(0xFF993556),
                          onTap: () => setState(() => _filtro = 'gestante')),
                      const SizedBox(width: 6),
                      _Chip(label: 'Crónicos', icono: Icons.monitor_heart_outlined,
                          activo: _filtro == 'cronico', color: _rojo,
                          onTap: () => setState(() => _filtro = 'cronico')),
                      const SizedBox(width: 6),
                      _Chip(label: 'Adulto mayor',
                          icono: Icons.accessible_forward_rounded,
                          activo: _filtro == 'adulto_mayor',
                          color: const Color(0xFF5F5E5A),
                          onTap: () => setState(() => _filtro = 'adulto_mayor')),
                      const SizedBox(width: 6),
                      _Chip(label: 'Niños',
                          icono: Icons.child_friendly_outlined,
                          activo: _filtro == 'nino', color: _azul,
                          onTap: () => setState(() => _filtro = 'nino')),
                      const SizedBox(width: 6),
                      _Chip(label: 'Pendientes',
                          icono: Icons.access_time_rounded,
                          activo: _filtro == 'pendiente', color: _ambar,
                          onTap: () => setState(() => _filtro = 'pendiente')),
                    ]),
                  ),
                  const SizedBox(height: 14),

                  // ── HEADER SECCIÓN ────────────────────────────────────
                  Row(children: [
                    Expanded(
                      child: Text('Pacientes con seguimiento pendiente',
                          style: TextStyle(color: dc.textPrimary,
                              fontSize: 14, fontWeight: FontWeight.bold)),
                    ),
                    GestureDetector(
                      onTap: () {},
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.calendar_month_rounded,
                            color: _verde, size: 14),
                        const SizedBox(width: 3),
                        const Text('Ver calendario',
                            style: TextStyle(color: _verde, fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  ]),
                  const SizedBox(height: 12),

                  // ── LISTA DE PACIENTES (columna completa) ─────────────
                  ..._filtrados.map((p) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _PCard(
                      paciente: p, dc: dc,
                      colorR: _cRiesgo(p.riesgo),
                      labelR: _lRiesgo(p.riesgo),
                      iconR:  _iRiesgo(p.riesgo),
                      iconC:  _iCat(p.categoria),
                      colorC: _cCat(p.categoria),
                    ),
                  )),
                  const SizedBox(height: 12),

                  // ── PANEL VISITAS HOY ────────────────────────────────
                  _PanelVisitas(dc: dc),
                  const SizedBox(height: 10),

                  // ── INDICADORES RÁPIDOS ───────────────────────────────
                  _PanelIndicadores(dc: dc),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WIDGETS
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
        const SizedBox(height: 2),
        ClipRRect(borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: 0.6,
                backgroundColor: color.withOpacity(0.12),
                color: color, minHeight: 2)),
        const SizedBox(height: 4),
        Text(label, textAlign: TextAlign.center,
            style: TextStyle(color: dc.textHint, fontSize: 8.5, height: 1.2)),
      ]),
    ),
  );
}

class _IaBadge extends StatelessWidget {
  final String texto;
  final Color color;
  const _IaBadge({required this.texto, required this.color});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(width: 7, height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 5),
      Flexible(child: Text(texto,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: color, fontSize: 10,
              fontWeight: FontWeight.w500))),
    ],
  );
}

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

class _PCard extends StatelessWidget {
  final _PacienteSeg paciente;
  final DispersaludColors dc;
  final Color colorR, colorC;
  final String labelR;
  final IconData iconR, iconC;

  const _PCard({required this.paciente, required this.dc,
      required this.colorR, required this.labelR, required this.iconR,
      required this.iconC, required this.colorC});

  static const _verde = Color(0xFF1D9E75);
  static const _morado = Color(0xFF534AB7);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: dc.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: dc.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // Fila: avatar + info + badge
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Avatar
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
                color: colorC.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(iconC, color: colorC, size: 24),
          ),
          const SizedBox(width: 10),
          // Nombre + ubicación + condición
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(paciente.nombre,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: dc.textPrimary, fontSize: 13,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Row(children: [
              Icon(Icons.location_on_outlined, color: dc.textHint, size: 10),
              const SizedBox(width: 2),
              Expanded(child: Text(paciente.ubicacion,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: dc.textHint, fontSize: 10))),
            ]),
            const SizedBox(height: 3),
            Row(children: [
              Icon(iconC, color: colorC, size: 10),
              const SizedBox(width: 3),
              Expanded(child: Text(paciente.condicion,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: colorC, fontSize: 11,
                      fontWeight: FontWeight.w600))),
            ]),
          ])),
          const SizedBox(width: 6),
          // Badge riesgo
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

        // Última visita + próximo control + botón Registrar
        Row(children: [
          // Última visita
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Row(children: [
              Icon(Icons.access_time_rounded, color: dc.textHint, size: 10),
              const SizedBox(width: 2),
              Text('Última visita',
                  style: TextStyle(color: dc.textHint, fontSize: 9)),
            ]),
            Text(paciente.ultimaVisita,
                style: TextStyle(color: dc.textSecondary, fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ])),
          // Próximo control
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Row(children: [
              Icon(Icons.calendar_today_rounded, color: dc.textHint, size: 10),
              const SizedBox(width: 2),
              Text('Próximo control',
                  style: TextStyle(color: dc.textHint, fontSize: 9)),
            ]),
            Text(paciente.proximoControl,
                style: TextStyle(color: dc.textSecondary, fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ])),
          // Botón registrar
          GestureDetector(
            onTap: () {},
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
        const SizedBox(height: 10),
        Divider(color: dc.border, height: 1),
        const SizedBox(height: 8),

        // Acciones
        Row(children: [
          _Accion(icono: Icons.phone_outlined, label: 'Llamar',
              color: _verde, onTap: () {}),
          const SizedBox(width: 6),
          _Accion(icono: Icons.home_outlined, label: 'Visita',
              color: _verde, onTap: () {}),
          const SizedBox(width: 6),
          _Accion(icono: Icons.smart_toy_outlined, label: 'IA',
              color: _morado, onTap: () {}),
          const Spacer(),
          Icon(Icons.chevron_right_rounded, color: dc.textHint, size: 18),
        ]),
      ]),
    );
  }
}

class _Accion extends StatelessWidget {
  final IconData icono;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _Accion({required this.icono, required this.label,
      required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.2))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icono, color: color, size: 12),
          const SizedBox(width: 3),
          Text(label, style: TextStyle(color: color, fontSize: 11,
              fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

class _PanelVisitas extends StatelessWidget {
  final DispersaludColors dc;
  const _PanelVisitas({required this.dc});
  static const _verde = Color(0xFF1D9E75);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: dc.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: dc.border)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.calendar_month_rounded, color: _verde, size: 16),
        const SizedBox(width: 6),
        Text('Próximas visitas hoy',
            style: TextStyle(color: dc.textPrimary, fontSize: 13,
                fontWeight: FontWeight.bold)),
      ]),
      const SizedBox(height: 10),
      _VRow(hora: '08:00 AM', cantidad: 3, dc: dc),
      const SizedBox(height: 8),
      _VRow(hora: '10:00 AM', cantidad: 2, dc: dc),
      const SizedBox(height: 8),
      _VRow(hora: '02:00 PM', cantidad: 4, dc: dc),
      const SizedBox(height: 10),
      Row(children: [
        Text('Ver agenda completa',
            style: TextStyle(color: dc.textSecondary, fontSize: 11)),
        const SizedBox(width: 2),
        Icon(Icons.chevron_right_rounded, color: dc.textHint, size: 14),
      ]),
    ]),
  );
}

class _VRow extends StatelessWidget {
  final String hora;
  final int cantidad;
  final DispersaludColors dc;
  const _VRow({required this.hora, required this.cantidad, required this.dc});
  static const _verde = Color(0xFF1D9E75);

  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        children: [
      Text(hora, style: TextStyle(color: dc.textPrimary, fontSize: 12,
          fontWeight: FontWeight.w600)),
      Text('Visitas programadas',
          style: TextStyle(color: dc.textHint, fontSize: 10)),
    ])),
    Container(width: 28, height: 28,
        decoration: const BoxDecoration(color: _verde, shape: BoxShape.circle),
        child: Center(child: Text('$cantidad',
            style: const TextStyle(color: Colors.white, fontSize: 12,
                fontWeight: FontWeight.bold)))),
  ]);
}

class _PanelIndicadores extends StatelessWidget {
  final DispersaludColors dc;
  const _PanelIndicadores({required this.dc});
  static const _verde = Color(0xFF1D9E75);
  static const _ambar = Color(0xFFEF9F27);
  static const _azul  = Color(0xFF185FA5);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: dc.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: dc.border)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Indicadores rápidos',
          style: TextStyle(color: dc.textPrimary, fontSize: 13,
              fontWeight: FontWeight.bold)),
      const SizedBox(height: 10),
      _IRow(label: 'Visitas realizadas (mes)', valor: '48',
          color: _verde, dc: dc),
      const SizedBox(height: 8),
      _IRow(label: 'Controles pendientes', valor: '27',
          color: _ambar, dc: dc),
      const SizedBox(height: 8),
      _IRow(label: 'Pacientes activos', valor: '128',
          color: _azul, dc: dc),
      const SizedBox(height: 8),
      _IRow(label: 'Cobertura del mes', valor: '76%',
          color: _verde, dc: dc),
    ]),
  );
}

class _IRow extends StatelessWidget {
  final String label, valor;
  final Color color;
  final DispersaludColors dc;
  const _IRow({required this.label, required this.valor,
      required this.color, required this.dc});

  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(child: Text(label,
        style: TextStyle(color: dc.textSecondary, fontSize: 11))),
    Text(valor, style: TextStyle(color: color, fontSize: 14,
        fontWeight: FontWeight.bold)),
  ]);
}