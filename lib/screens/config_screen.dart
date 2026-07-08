import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../services/excel_service.dart';
import 'package:file_picker/file_picker.dart';
import '../services/backup_downloader_stub.dart'
    if (dart.library.html) '../services/backup_downloader_web.dart'
    if (dart.library.io)   '../services/backup_downloader_mobile.dart';
import 'package:printing/printing.dart';
import 'package:image_picker/image_picker.dart';
import '../core/app_theme.dart';
import '../core/responsive.dart';
import '../database/database_helper.dart';
import '../services/connectivity_service.dart';
import '../services/sync_service.dart';
import '../main.dart' show temaNotifier, temaDesdeString, fontSizeNotifier;
import 'package:supabase_flutter/supabase_flutter.dart';

const Color _kVerde = Color(0xFF1D9E75);

DispersaludColors _c(BuildContext ctx) =>
    Theme.of(ctx).extension<DispersaludColors>() ?? DispersaludColors.dark;

/// Construye el widget de la foto de perfil, ya sea que venga de un archivo
/// local (Android/iOS) o de un string base64 (web). Si el dato guardado
/// está vacío o corrupto, muestra [fallback] en su lugar en vez de fallar.
Widget _fotoPerfilWidget(String fotoPerfil, Widget fallback) {
  if (fotoPerfil.isEmpty) return fallback;
  try {
    if (kIsWeb) {
      final b64 = fotoPerfil.replaceFirst('data:base64,', '');
      return Image.memory(base64Decode(b64), fit: BoxFit.cover);
    } else {
      return Image.file(File(fotoPerfil), fit: BoxFit.cover);
    }
  } catch (_) {
    return fallback;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PANTALLA COMPLETA "Mi Perfil" (nueva — diseño imagen)
// Se navega desde el tile "Mi perfil" de Configuración
// ─────────────────────────────────────────────────────────────────────────────
class MiPerfilScreen extends StatefulWidget {
  const MiPerfilScreen({super.key});
  @override
  State<MiPerfilScreen> createState() => _MiPerfilScreenState();
}

class _MiPerfilScreenState extends State<MiPerfilScreen> {
  // ── datos básicos ──────────────────────────────────────────────────────────
  String _nombre       = '';
  String _vereda       = '';
  String _municipio    = '';
  String _departamento = '';
  String _fotoPerfil   = '';
  bool   _online       = false;
  StreamSubscription<bool>? _connSub;

  // ── datos personales ───────────────────────────────────────────────────────
  String _documento    = '';
  String _fechaNac     = '';
  String _genero       = 'Masculino';
  String _grupoSangre  = 'O+';

  // ── contacto ──────────────────────────────────────────────────────────────
  String _telefono     = '';
  String _correo       = '';

  // ── médica ────────────────────────────────────────────────────────────────
  String _eps              = '';
  String _alergias         = '';
  String _enfermedades     = '';
  String _medicamentos     = '';

  // ── emergencia ────────────────────────────────────────────────────────────
  String _contactoNombre   = '';
  String _contactoTel      = '';
  String _contactoParent   = '';

  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _cargar();
    _connSub = ConnectivityService.instance.cambios
        .listen((v) { if (mounted) setState(() => _online = v); });
    _online = ConnectivityService.instance.tieneInternet;
  }

  @override
  void dispose() { _connSub?.cancel(); super.dispose(); }

  Future<void> _cargar() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _nombre       = p.getString('promotor_nombre')        ?? '';
      _vereda       = p.getString('promotor_vereda')        ?? '';
      _municipio    = p.getString('promotor_municipio')     ?? '';
      _departamento = p.getString('promotor_departamento')  ?? '';
      _fotoPerfil   = p.getString('promotor_foto')          ?? '';
      _documento    = p.getString('promotor_documento')     ?? '';
      _fechaNac     = p.getString('promotor_fecha_nac')     ?? '';
      _genero       = p.getString('promotor_genero')        ?? 'Masculino';
      _grupoSangre  = p.getString('promotor_grupo_sangre')  ?? 'O+';
      _telefono     = p.getString('promotor_telefono')      ?? '';
      _correo       = p.getString('promotor_correo')        ?? '';
      _eps              = p.getString('promotor_eps')            ?? '';
      _alergias         = p.getString('promotor_alergias')       ?? 'Ninguna';
      _enfermedades     = p.getString('promotor_enfermedades')   ?? 'Ninguna';
      _medicamentos     = p.getString('promotor_medicamentos')   ?? 'Ninguno';
      _contactoNombre   = p.getString('promotor_emer_nombre')    ?? '';
      _contactoTel      = p.getString('promotor_emer_tel')       ?? '';
      _contactoParent   = p.getString('promotor_emer_parent')    ?? '';
    });
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    final p = await SharedPreferences.getInstance();
    await p.setString('promotor_nombre',       _nombre);
    await p.setString('promotor_vereda',       _vereda);
    await p.setString('promotor_municipio',    _municipio);
    await p.setString('promotor_departamento', _departamento);
    await p.setString('promotor_foto',         _fotoPerfil);
    await p.setString('promotor_documento',    _documento);
    await p.setString('promotor_fecha_nac',    _fechaNac);
    await p.setString('promotor_genero',       _genero);
    await p.setString('promotor_grupo_sangre', _grupoSangre);
    await p.setString('promotor_telefono',     _telefono);
    await p.setString('promotor_correo',       _correo);
    await p.setString('promotor_eps',          _eps);
    await p.setString('promotor_alergias',     _alergias);
    await p.setString('promotor_enfermedades', _enfermedades);
    await p.setString('promotor_medicamentos', _medicamentos);
    await p.setString('promotor_emer_nombre',  _contactoNombre);
    await p.setString('promotor_emer_tel',     _contactoTel);
    await p.setString('promotor_emer_parent',  _contactoParent);
    if (!mounted) return;
    setState(() => _guardando = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Row(children: [
        Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
        SizedBox(width: 8), Text('Perfil guardado correctamente'),
      ]),
      backgroundColor: _kVerde, behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
    Navigator.pop(context, true); // devuelve true para que ConfigScreen recargue
  }

  Future<void> _seleccionarFoto() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (img != null) {
      if (kIsWeb) {
        // En web no hay sistema de archivos ni File(): guardamos la imagen
        // codificada en base64 dentro de SharedPreferences. Esto permite
        // mostrarla con Image.memory() y que persista aunque se recargue
        // la página (un blob: URL, en cambio, se pierde al recargar).
        final bytes = await img.readAsBytes();
        if (!mounted) return;
        setState(() => _fotoPerfil = 'data:base64,${base64Encode(bytes)}');
      } else {
        final dir = await getApplicationDocumentsDirectory();
        final dest = File('${dir.path}/perfil_foto.jpg');
        await dest.writeAsBytes(await img.readAsBytes());
        if (!mounted) return;
        setState(() => _fotoPerfil = dest.path);
      }
    }
  }

  Future<void> _tomarFoto() async {
    if (kIsWeb) { _seleccionarFoto(); return; } // En web no hay cámara nativa
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.camera, imageQuality: 75);
    if (img != null) {
      final dir = await getApplicationDocumentsDirectory();
      final dest = File('${dir.path}/perfil_foto.jpg');
      await dest.writeAsBytes(await img.readAsBytes());
      if (!mounted) return;
      setState(() => _fotoPerfil = dest.path);
    }
  }

  void _mostrarOpcionesFoto() {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent,
      builder: (_) {
        final dc = _c(context);
        return Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: dc.card, borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: dc.border, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text('Foto de perfil', style: TextStyle(color: dc.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _opcionFoto(Icons.photo_library_rounded, 'Elegir de la galería', _kVerde, _seleccionarFoto),
            const SizedBox(height: 10),
            _opcionFoto(Icons.camera_alt_rounded, 'Tomar una foto', const Color(0xFF185FA5), _tomarFoto),
            if (_fotoPerfil.isNotEmpty) ...[
              const SizedBox(height: 10),
              _opcionFoto(Icons.delete_outline_rounded, 'Eliminar foto', Colors.red, () {
                setState(() => _fotoPerfil = '');
                Navigator.pop(context);
              }),
            ],
            const SizedBox(height: 10),
            SizedBox(width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(side: BorderSide(color: dc.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: Text('Cancelar', style: TextStyle(color: dc.textSecondary)),
              )),
          ]),
        );
      },
    );
  }

  Widget _opcionFoto(IconData icon, String label, Color color, VoidCallback fn) {
    final dc = _c(context);
    return GestureDetector(
      onTap: () { Navigator.pop(context); fn(); },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.25))),
        child: Row(children: [
          Icon(icon, color: color, size: 20), const SizedBox(width: 12),
          Text(label, style: TextStyle(color: dc.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }

  // ── secciones editables ────────────────────────────────────────────────────
  void _editarSeccion(String titulo, IconData icono, List<_CampoEditar> campos) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => _SeccionEditorSheet(
        titulo: titulo, icono: icono, campos: campos,
        onGuardar: (vals) {
          setState(() {
            for (final c in campos) c.onSave(vals[c.key] ?? '');
          });
        },
      ),
    );
  }

  void _editarDatosPersonales() => _editarSeccion(
    'Datos personales', Icons.person_rounded, [
      _CampoEditar(key: 'doc',    label: 'Documento de identidad', value: _documento,   onSave: (v) => _documento    = v),
      _CampoEditar(key: 'fec',    label: 'Fecha de nacimiento (DD/MM/AAAA)', value: _fechaNac,    onSave: (v) => _fechaNac     = v),
      _CampoEditar(key: 'gen',    label: 'Género', value: _genero,     onSave: (v) => _genero       = v,
          opciones: ['Masculino','Femenino','No binario','Prefiero no decir']),
      _CampoEditar(key: 'gsp',    label: 'Grupo sanguíneo', value: _grupoSangre, onSave: (v) => _grupoSangre  = v,
          opciones: ['O+','O-','A+','A-','B+','B-','AB+','AB-']),
    ],
  );

  void _editarContacto() => _editarSeccion(
    'Información de contacto', Icons.phone_rounded, [
      _CampoEditar(key: 'tel',  label: 'Teléfono',               value: _telefono,     onSave: (v) => _telefono     = v, tipo: TextInputType.phone),
      _CampoEditar(key: 'cor',  label: 'Correo electrónico',      value: _correo,       onSave: (v) => _correo       = v, tipo: TextInputType.emailAddress),
      _CampoEditar(key: 've',   label: 'Vereda / Dirección',      value: _vereda,       onSave: (v) => _vereda       = v),
      _CampoEditar(key: 'mu',   label: 'Municipio',               value: _municipio,    onSave: (v) => _municipio    = v),
      _CampoEditar(key: 'dep',  label: 'Departamento',            value: _departamento, onSave: (v) => _departamento = v),
    ],
  );

  void _editarMedica() => _editarSeccion(
  'Información médica', Icons.medical_information_rounded, [
    _CampoEditar(key: 'eps', label: 'EPS', value: _eps, onSave: (v) => _eps = v,
        opciones: [
          // Régimen contributivo
          'Nueva EPS',
          'Sanitas EPS',
          'Sura EPS',
          'Compensar EPS',
          'Famisanar EPS',
          'Salud Total EPS',
          'Coosalud EPS',
          'Aliansalud EPS',
          'Medimás EPS',
          'Comfenalco Valle EPS',
          'Comfacundi EPS',
          'Mutual Ser EPS',
          'Asmet Salud EPS',
          'Emssanar EPS',
          'Capresoca EPS',
          'Barrios Unidos EPS',
          'Coomeva EPS',
          // Régimen subsidiado
          'Pijaos Salud EPSI',
          'Dusakawi EPSI',
          'AIC EPSI',
          'Mallamas EPSI',
          // Especiales
          'Ejército - SISFUERZA',
          'Policía Nacional',
          'Ecopetrol',
          'Magisterio - FOMAG',
          // Sin EPS
          'Sin EPS / No afiliado',
          'Otra',
        ]),
    _CampoEditar(key: 'ale', label: 'Alergias', value: _alergias,
        onSave: (v) => _alergias = v),
    _CampoEditar(key: 'enf', label: 'Enfermedades crónicas', value: _enfermedades,
        onSave: (v) => _enfermedades = v),
    _CampoEditar(key: 'med', label: 'Medicamentos actuales', value: _medicamentos,
        onSave: (v) => _medicamentos = v),
  ],
);

  void _editarEmergencia() => _editarSeccion(
    'Contacto de emergencia', Icons.emergency_rounded, [
      _CampoEditar(key: 'cnm', label: 'Nombre completo',           value: _contactoNombre,  onSave: (v) => _contactoNombre  = v),
      _CampoEditar(key: 'cte', label: 'Teléfono',                  value: _contactoTel,     onSave: (v) => _contactoTel     = v, tipo: TextInputType.phone),
      _CampoEditar(key: 'cpr', label: 'Parentesco',                value: _contactoParent,  onSave: (v) => _contactoParent  = v),
    ],
  );

  void _editarNombreCompleto() => _editarSeccion(
    'Nombre del promotor', Icons.badge_rounded, [
      _CampoEditar(key: 'nom', label: 'Nombre completo', value: _nombre, onSave: (v) => _nombre = v),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final dc = _c(context);
    return Scaffold(
      backgroundColor: dc.bg,
      body: ResponsiveCenter(child: CustomScrollView(
        slivers: [

          // ── APP BAR con header verde degradado ──────────────────────────
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: const Color(0xFF0A5240),
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
              ),
            ),
            title: const Text('Mi Perfil',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0A5240), Color(0xFF0F6E56), Color(0xFF1D9E75)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 56, 20, 16),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [

                      // Avatar / foto de perfil
                      GestureDetector(
                        onTap: _mostrarOpcionesFoto,
                        child: Stack(children: [
                          Container(
                            width: 86, height: 86,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withOpacity(0.4), width: 3),
                              color: Colors.white.withOpacity(0.15),
                            ),
                            child: ClipOval(child: _fotoPerfilWidget(
                              _fotoPerfil,
                              Center(child: Text(
                                  _nombre.isNotEmpty ? _nombre[0].toUpperCase() : 'P',
                                  style: const TextStyle(color: Colors.white, fontSize: 32,
                                      fontWeight: FontWeight.bold))))),
                          ),
                          Positioned(bottom: 0, right: 0,
                            child: Container(
                              width: 28, height: 28,
                              decoration: BoxDecoration(
                                color: _kVerde, shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2)),
                              child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 14),
                            )),
                        ]),
                      ),
                      const SizedBox(width: 14),

                      // Nombre + cargo + ubicación + estado
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min, children: [
                          GestureDetector(
                            onTap: _editarNombreCompleto,
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Flexible(child: Text(
                                _nombre.isNotEmpty ? _nombre : 'Toca para editar',
                                style: const TextStyle(color: Colors.white, fontSize: 20,
                                    fontWeight: FontWeight.bold),
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                              )),
                              const SizedBox(width: 6),
                              Icon(Icons.edit_rounded, color: Colors.white.withOpacity(0.6), size: 14),
                            ]),
                          ),
                          const Text('Promotor de Salud Rural',
                              style: TextStyle(color: Color(0xFF9FE1CB), fontSize: 12)),
                          const SizedBox(height: 2),
                          if (_vereda.isNotEmpty || _municipio.isNotEmpty)
                            Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(Icons.location_on_rounded, color: Colors.white.withOpacity(0.7), size: 12),
                              const SizedBox(width: 3),
                              Flexible(child: Text(
                                [_vereda, _municipio].where((s) => s.isNotEmpty).join(' - '),
                                style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11),
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                              )),
                            ]),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withOpacity(0.3)),
                            ),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Container(width: 7, height: 7, decoration: BoxDecoration(
                                  color: _online ? const Color(0xFF4ADE80) : Colors.orange,
                                  shape: BoxShape.circle)),
                              const SizedBox(width: 5),
                              Text(_online ? 'En línea' : 'Offline',
                                  style: const TextStyle(color: Colors.white, fontSize: 11,
                                      fontWeight: FontWeight.w600)),
                            ]),
                          ),
                        ]),
                      ),
                    ]),
                  ),
                ),
              ),
            ),
          ),

          // ── CONTENIDO ───────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
              child: Column(children: [

                // ── Datos personales ───────────────────────────────────────
                _Seccion(
                  icono: Icons.person_rounded, titulo: 'Datos personales',
                  color: _kVerde, onTap: _editarDatosPersonales,
                  filas: [
                    _Fila(Icons.badge_outlined,       'Documento de identidad', _documento.isEmpty    ? '—' : _documento),
                    _Fila(Icons.calendar_today_rounded,'Fecha de nacimiento',   _fechaNac.isEmpty     ? '—' : _fechaNac),
                    _Fila(Icons.wc_rounded,            'Género',               _genero),
                    _Fila(Icons.water_drop_rounded,    'Grupo sanguíneo',      _grupoSangre),
                  ],
                ),
                const SizedBox(height: 14),

                // ── Información de contacto ────────────────────────────────
                _Seccion(
                  icono: Icons.phone_rounded, titulo: 'Información de contacto',
                  color: const Color(0xFF534AB7), onTap: _editarContacto,
                  filas: [
                    _Fila(Icons.phone_rounded,         'Teléfono',             _telefono.isEmpty     ? '—' : '+57 $_telefono'),
                    _Fila(Icons.email_outlined,        'Correo electrónico',   _correo.isEmpty       ? '—' : _correo),
                    _Fila(Icons.location_on_outlined,  'Dirección',            _vereda.isEmpty       ? '—' : _vereda),
                    _Fila(Icons.apartment_rounded,     'Municipio / Depto.',
                        [_municipio, _departamento].where((s) => s.isNotEmpty).join(' - ').isEmpty
                            ? '—' : [_municipio, _departamento].where((s) => s.isNotEmpty).join(' - ')),
                  ],
                ),
                const SizedBox(height: 14),

                // ── Información médica ─────────────────────────────────────
                _Seccion(
                  icono: Icons.medical_information_rounded, titulo: 'Información médica',
                  color: const Color(0xFFC62828), onTap: _editarMedica,
                  filas: [
                    _Fila(Icons.health_and_safety_rounded, 'EPS',               _eps.isEmpty          ? '—' : _eps),
                    _Fila(Icons.warning_amber_rounded,     'Alergias',          _alergias.isEmpty     ? '—' : _alergias),
                    _Fila(Icons.monitor_heart_rounded,     'Enfermedades crónicas', _enfermedades.isEmpty ? '—' : _enfermedades),
                    _Fila(Icons.medication_rounded,        'Medicamentos actuales', _medicamentos.isEmpty ? '—' : _medicamentos),
                  ],
                ),
                const SizedBox(height: 14),

                // ── Contacto de emergencia ─────────────────────────────────
                _Seccion(
                  icono: Icons.emergency_rounded, titulo: 'Contacto de emergencia',
                  color: const Color(0xFFEF9F27), onTap: _editarEmergencia,
                  filas: [
                    _Fila(Icons.person_outline_rounded,  'Nombre',    _contactoNombre.isEmpty ? '—' : _contactoNombre),
                    _Fila(Icons.phone_outlined,          'Teléfono',  _contactoTel.isEmpty    ? '—' : '+57 $_contactoTel'),
                    _Fila(Icons.family_restroom_rounded, 'Parentesco',_contactoParent.isEmpty ? '—' : _contactoParent),
                  ],
                ),
                const SizedBox(height: 14),

                // ── Seguridad y privacidad ─────────────────────────────────
                _Seccion(
                  icono: Icons.lock_rounded, titulo: 'Seguridad y privacidad',
                  color: const Color(0xFF185FA5), onTap: null,
                  expandido: true,
                  filas: [
                    _Fila(Icons.lock_outline_rounded,  'Cambiar contraseña',     '→'),
                    _Fila(Icons.verified_user_rounded, 'Verificación en dos pasos', ''),
                    _Fila(Icons.devices_rounded,       'Dispositivos autorizados', '1 dispositivo'),
                  ],
                  accionWidget: Column(children: [
                    _FilaAccion(Icons.lock_outline_rounded, 'Cambiar contraseña', dc, () {}),
                    Divider(height: 1, color: dc.border, indent: 52),
                    _FilaAccionBadge(Icons.verified_user_rounded, 'Verificación en dos pasos',
                        'Activado', const Color(0xFF1D9E75), dc, () {}),
                    Divider(height: 1, color: dc.border, indent: 52),
                    _FilaAccion(Icons.devices_rounded, 'Dispositivos autorizados', dc, () {},
                        trailing: '1 dispositivo'),
                  ]),
                ),
                const SizedBox(height: 28),

                // ── Botón Guardar ──────────────────────────────────────────
                SizedBox(
                  width: double.infinity, height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _guardando ? null : _guardar,
                    icon: _guardando
                        ? const SizedBox(width: 18, height: 18,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.save_rounded, color: Colors.white, size: 20),
                    label: Text(_guardando ? 'Guardando...' : 'Guardar cambios',
                        style: const TextStyle(color: Colors.white, fontSize: 15,
                            fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kVerde, elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // ── Botón Eliminar cuenta ──────────────────────────────────
                SizedBox(
                  width: double.infinity, height: 52,
                  child: OutlinedButton.icon(
                    onPressed: _confirmarEliminar,
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                    label: const Text('Eliminar cuenta',
                        style: TextStyle(color: Colors.red, fontSize: 15, fontWeight: FontWeight.w700)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
      ),
    );
  }

  void _confirmarEliminar() {
    final dc = _c(context);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: dc.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('¿Eliminar cuenta?',
            style: TextStyle(color: dc.textPrimary, fontWeight: FontWeight.bold)),
        content: Text(
            'Esta acción borrará todos tus datos, pacientes y consultas. Esta acción es irreversible.',
            style: TextStyle(color: dc.textSecondary, fontSize: 13, height: 1.5)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar', style: TextStyle(color: _kVerde))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              Navigator.pop(context);
              final p = await SharedPreferences.getInstance();
              await p.clear();
              if (mounted) Navigator.of(context).pushNamedAndRemoveUntil('/pin', (r) => false);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ── Helpers de la pantalla de perfil ──────────────────────────────────────────

class _Fila { final IconData icon; final String label, value;
  const _Fila(this.icon, this.label, this.value); }

class _Seccion extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final Color color;
  final VoidCallback? onTap;
  final List<_Fila> filas;
  final bool expandido;
  final Widget? accionWidget;

  const _Seccion({
    required this.icono, required this.titulo, required this.color,
    required this.onTap, this.filas = const [], this.expandido = false,
    this.accionWidget,
  });

  @override
  Widget build(BuildContext context) {
    final dc = _c(context);
    return Container(
      decoration: BoxDecoration(color: dc.card, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: dc.border)),
      child: Column(children: [
        // Título de sección
        InkWell(
          onTap: onTap,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            child: Row(children: [
              Container(width: 34, height: 34,
                decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(9)),
                child: Icon(icono, color: color, size: 18)),
              const SizedBox(width: 12),
              Expanded(child: Text(titulo, style: TextStyle(
                  color: dc.textPrimary, fontSize: 14, fontWeight: FontWeight.w700))),
              if (onTap != null)
                Icon(Icons.chevron_right_rounded, color: dc.textHint, size: 20),
            ]),
          ),
        ),
        Divider(height: 1, color: dc.border),
        // Filas de datos o widget personalizado
        if (accionWidget != null)
          accionWidget!
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(children: filas.map((f) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(children: [
                Icon(f.icon, color: color, size: 16),
                const SizedBox(width: 10),
                Expanded(child: Text(f.label, style: TextStyle(color: dc.textSecondary, fontSize: 13))),
                Flexible(child: Text(f.value, style: TextStyle(
                    color: dc.textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
                    textAlign: TextAlign.end, maxLines: 1, overflow: TextOverflow.ellipsis)),
              ]),
            )).toList()),
          ),
      ]),
    );
  }
}

Widget _FilaAccion(IconData icon, String label, DispersaludColors dc, VoidCallback fn,
    {String? trailing}) =>
  InkWell(
    onTap: fn,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(children: [
        Icon(icon, color: dc.textSecondary, size: 18),
        const SizedBox(width: 14),
        Expanded(child: Text(label, style: TextStyle(color: dc.textPrimary, fontSize: 13))),
        if (trailing != null) Text(trailing, style: TextStyle(color: dc.textHint, fontSize: 12)),
        const SizedBox(width: 4),
        Icon(Icons.chevron_right_rounded, color: dc.textHint, size: 18),
      ]),
    ),
  );

Widget _FilaAccionBadge(IconData icon, String label, String badge, Color badgeColor,
    DispersaludColors dc, VoidCallback fn) =>
  InkWell(
    onTap: fn,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(children: [
        Icon(icon, color: dc.textSecondary, size: 18),
        const SizedBox(width: 14),
        Expanded(child: Text(label, style: TextStyle(color: dc.textPrimary, fontSize: 13))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
          decoration: BoxDecoration(color: badgeColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20)),
          child: Text(badge, style: TextStyle(
              color: badgeColor, fontSize: 11, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(width: 6),
        Icon(Icons.chevron_right_rounded, color: dc.textHint, size: 18),
      ]),
    ),
  );

// ── Editor de sección (bottom sheet) ──────────────────────────────────────────

class _CampoEditar {
  final String key, label, value;
  final Function(String) onSave;
  final List<String>? opciones;
  final TextInputType tipo;
  const _CampoEditar({
    required this.key, required this.label, required this.value,
    required this.onSave, this.opciones, this.tipo = TextInputType.text,
  });
}

class _SeccionEditorSheet extends StatefulWidget {
  final String titulo;
  final IconData icono;
  final List<_CampoEditar> campos;
  final Function(Map<String, String>) onGuardar;
  const _SeccionEditorSheet({
    required this.titulo, required this.icono,
    required this.campos, required this.onGuardar,
  });
  @override
  State<_SeccionEditorSheet> createState() => _SeccionEditorSheetState();
}

class _SeccionEditorSheetState extends State<_SeccionEditorSheet> {
  late final Map<String, TextEditingController> _ctls;
  late final Map<String, String> _drops;

  @override
  void initState() {
    super.initState();
    _ctls  = { for (final c in widget.campos) c.key: TextEditingController(text: c.value) };
    _drops = { for (final c in widget.campos.where((c) => c.opciones != null)) c.key: c.value };
  }

  @override
  void dispose() {
    for (final c in _ctls.values) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dc     = _c(context);
    final bottom = MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: BoxDecoration(color: dc.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      padding: EdgeInsets.fromLTRB(20, 16, 20, bottom < 16 ? 32 : bottom + 16),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: dc.border, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Row(children: [
            Container(width: 38, height: 38,
              decoration: BoxDecoration(color: _kVerde.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
              child: Icon(widget.icono, color: _kVerde, size: 20)),
            const SizedBox(width: 10),
            Text(widget.titulo, style: TextStyle(color: dc.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 20),

          // Campos
          ...widget.campos.map((c) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: c.opciones != null
                ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(c.label, style: TextStyle(color: dc.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(color: dc.bg, borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: dc.border)),
                      child: DropdownButton<String>(
                        value: c.opciones!.contains(_drops[c.key]) ? _drops[c.key] : c.opciones!.first,
                        isExpanded: true, underline: const SizedBox(),
                        dropdownColor: dc.card,
                        style: TextStyle(color: dc.textPrimary, fontSize: 14),
                        items: c.opciones!.map((o) =>
                            DropdownMenuItem(value: o, child: Text(o))).toList(),
                        onChanged: (v) => setState(() => _drops[c.key] = v!),
                      ),
                    ),
                  ])
                : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(c.label, style: TextStyle(color: dc.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 5),
                    TextField(
                      controller: _ctls[c.key],
                      keyboardType: c.tipo,
                      style: TextStyle(color: dc.textPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        filled: true, fillColor: dc.bg,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: dc.border)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: dc.border)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: _kVerde, width: 1.5)),
                      ),
                    ),
                  ]),
          )),

          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 13),
                side: BorderSide(color: dc.border),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: Text('Cancelar', style: TextStyle(color: dc.textSecondary)),
            )),
            const SizedBox(width: 12),
            Expanded(flex: 2, child: ElevatedButton(
              onPressed: () {
                final vals = <String, String>{
                  for (final c in widget.campos)
                    c.key: c.opciones != null
                        ? (_drops[c.key] ?? c.value)
                        : (_ctls[c.key]?.text.trim() ?? ''),
                };
                // Llamar onSave de cada campo
                for (final c in widget.campos) c.onSave(vals[c.key]!);
                widget.onGuardar(vals);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _kVerde, padding: const EdgeInsets.symmetric(vertical: 13),
                elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Guardar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            )),
          ]),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CONFIG SCREEN ORIGINAL (sin cambios — solo se agrega la navegación al perfil)
// ─────────────────────────────────────────────────────────────────────────────
class ConfigScreen extends StatefulWidget {
  ConfigScreen({super.key});
  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen>
    with WidgetsBindingObserver {
  // Perfil
  String _nombre       = '';
  String _vereda       = '';
  String _municipio    = '';
  String _departamento = '';
  String _fotoPerfil   = '';

  // Preferencias
  bool   _vozActiva = true;
  bool   _alertas   = true;
  String _tema      = 'Sistema';
  double _fuente    = 1.0; // escala de texto

  // Conectividad
  bool _online = false;
  StreamSubscription<bool>? _connSub;

  // Estado de operaciones
  bool _exportando      = false;
  bool _exportandoExcel = false;
  bool _sincronizando = false;
  bool _creandoCopia  = false;
  bool _restaurando   = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cargar();
    _initConectividad();
  }

  Future<void> _initConectividad() async {
    final actual = ConnectivityService.instance.tieneInternet;
    if (mounted) setState(() => _online = actual);
    _connSub = ConnectivityService.instance.cambios.listen((v) {
      if (mounted) setState(() => _online = v);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _cargar();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connSub?.cancel();
    super.dispose();
  }

  Future<void> _cargar() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _nombre       = p.getString('promotor_nombre')       ?? '';
      _vereda       = p.getString('promotor_vereda')       ?? '';
      _municipio    = p.getString('promotor_municipio')    ?? '';
      _departamento = p.getString('promotor_departamento') ?? '';
      _fotoPerfil   = p.getString('promotor_foto')         ?? '';
      _vozActiva    = p.getBool('voz_activa')              ?? true;
      _alertas      = p.getBool('alertas_activas')         ?? true;
      _tema         = p.getString('tema_app')              ?? 'Sistema';
      _fuente       = p.getDouble('fuente_escala')          ?? 1.0;
    });
  }

  Future<void> _pref(String k, dynamic v) async {
    final p = await SharedPreferences.getInstance();
    if (v is bool)   await p.setBool(k, v);
    if (v is String) await p.setString(k, v);
  }

  void _snack(String msg, {bool error = false, bool info = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(error ? Icons.error_outline : info ? Icons.info_outline : Icons.check_circle_outline,
            color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(msg, style: const TextStyle(fontSize: 13))),
      ]),
      backgroundColor: error ? Colors.red : info ? const Color(0xFF185FA5) : _kVerde,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 3),
    ));
  }

  Future<void> _verificarConectividad() async {
    _snack('Verificando conexión...', info: true);
    final v = await ConnectivityService.instance.verificarAhora();
    if (mounted) setState(() => _online = v);
    _snack(_online ? '✓ Conexión activa' : 'Sin conexión a internet');
  }

  Future<void> _sincronizar() async {
    if (!_online) { _snack('Sin conexión. Los datos se sincronizarán automáticamente al reconectarse.', info: true); return; }
    if (_sincronizando) return;
    setState(() => _sincronizando = true);
    try {
      // Usa el nuevo SyncService con Supabase — sincroniza pacientes,
      // consultas, alertas y fichas epidemiológicas en una sola llamada
      final resultado = await SyncService.instance.sincronizar();
      if (resultado.exito) {
        _snack('✓ ${resultado.mensaje}');
      } else {
        _snack(resultado.mensaje, error: resultado.pendientes > 0, info: !resultado.exito && resultado.pendientes == 0);
      }
    } catch (e) {
      _snack('Error al sincronizar: $e', error: true);
    } finally {
      if (mounted) setState(() => _sincronizando = false);
    }
  }

  Future<void> _exportarPDF() async {
    if (_exportando) return;
    setState(() => _exportando = true);
    _snack('Generando PDF...', info: true);
    try {
      final pacientes = await DatabaseHelper.instance.obtenerPacientes();
      final consultas = await DatabaseHelper.instance.obtenerConsultas();
      final alertas   = await DatabaseHelper.instance.obtenerAlertas(soloActivas: false);
      final resumen   = await DatabaseHelper.instance.resumenGeneral();
      final pdf = pw.Document();
      final ahora = DateTime.now();
      final fecha = '${ahora.day}/${ahora.month}/${ahora.year}';
      final hora  = '${ahora.hour.toString().padLeft(2,'0')}:${ahora.minute.toString().padLeft(2,'0')}';
      final verde  = PdfColor.fromHex('1D9E75');
      final oscuro = PdfColor.fromHex('0F6E56');
      final gris   = PdfColor.fromHex('6B7280');
      pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (ctx) => pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 12),
          decoration: pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: verde, width: 2))),
          child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text('DISPERSALUD IA', style: pw.TextStyle(color: verde, fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.Text('Informe de registros · Salud rural Colombia', style: pw.TextStyle(color: gris, fontSize: 9)),
            ]),
            pw.Text('$fecha  $hora', style: pw.TextStyle(color: gris, fontSize: 9)),
          ]),
        ),
        footer: (ctx) => pw.Container(
          padding: const pw.EdgeInsets.only(top: 8),
          decoration: pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300))),
          child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            pw.Text('${_nombre.isNotEmpty ? _nombre : "Promotor/a"} · ${_vereda.isNotEmpty ? "$_vereda · " : ""}$_municipio',
                style: pw.TextStyle(color: gris, fontSize: 8)),
            pw.Text('Página ${ctx.pageNumber} de ${ctx.pagesCount}', style: pw.TextStyle(color: gris, fontSize: 8)),
          ]),
        ),
        build: (ctx) => [
          pw.Container(
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(color: verde, borderRadius: pw.BorderRadius.circular(8)),
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text('Informe General de Salud Rural', style: pw.TextStyle(color: PdfColors.white, fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              pw.Text('${_nombre.isNotEmpty ? _nombre : "Promotor/a"}${_vereda.isNotEmpty ? " · $_vereda · $_municipio" : ""}',
                  style: pw.TextStyle(color: PdfColors.white, fontSize: 11)),
              pw.SizedBox(height: 2),
              pw.Text('Generado el $fecha a las $hora', style: pw.TextStyle(color: const PdfColor(1,1,1,0.7), fontSize: 10)),
            ]),
          ),
          pw.SizedBox(height: 24),
          pw.Text('Resumen ejecutivo', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: oscuro)),
          pw.SizedBox(height: 12),
          pw.Row(children: [
            _pdfStatBox('Pacientes', '${resumen['pacientes'] ?? pacientes.length}', verde),
            pw.SizedBox(width: 10),
            _pdfStatBox('Consultas', '${resumen['consultas'] ?? consultas.length}', oscuro),
            pw.SizedBox(width: 10),
            _pdfStatBox('Alertas', '${alertas.length}', PdfColor.fromHex('E24B4A')),
          ]),
          pw.SizedBox(height: 24),
          if (pacientes.isNotEmpty) ...[
            pw.Text('Registro de pacientes', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: oscuro)),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headers: ['Nombre','Módulo','Vereda','Municipio','Documento'],
              data: pacientes.take(50).map((p) => [p['nombre']??'',p['modulo']??'',p['vereda']??'',p['municipio']??'',p['documento']??'']).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 9),
              headerDecoration: pw.BoxDecoration(color: verde),
              oddRowDecoration: pw.BoxDecoration(color: PdfColor.fromHex('F0FDF4')),
              cellStyle: pw.TextStyle(fontSize: 9, color: gris),
            ),
            pw.SizedBox(height: 16),
          ],
          if (consultas.isNotEmpty) ...[
            pw.Text('Consultas registradas', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: oscuro)),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headers: ['Paciente','Módulo','Nivel riesgo','Fecha'],
              data: consultas.take(50).map((c) => [c['nombre']??c['paciente_nombre']??'',c['modulo']??'',c['nivel_riesgo']??'Estable',_formatFecha(c['fecha'] as String?)]).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 9),
              headerDecoration: pw.BoxDecoration(color: oscuro),
              oddRowDecoration: pw.BoxDecoration(color: PdfColor.fromHex('F0FDF4')),
              cellStyle: pw.TextStyle(fontSize: 9, color: gris),
            ),
          ],
        ],
      ));
      await Printing.layoutPdf(
        onLayout: (_) async => pdf.save(),
        name: 'DISPERSALUD_IA_${ahora.year}${ahora.month}${ahora.day}.pdf',
      );
      _snack('✓ PDF generado correctamente');
    } catch (e) { _snack('Error al generar PDF: $e', error: true); }
    finally { if (mounted) setState(() => _exportando = false); }
  }

  pw.Widget _pdfStatBox(String label, String valor, PdfColor color) =>
      pw.Expanded(child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: pw.BoxDecoration(color: color, borderRadius: pw.BorderRadius.circular(8)),
        child: pw.Column(children: [
          pw.Text(valor, style: pw.TextStyle(color: PdfColors.white, fontSize: 22, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text(label, style: pw.TextStyle(color: const PdfColor(1,1,1,0.7), fontSize: 10)),
        ]),
      ));

  String _formatFecha(String? iso) {
    if (iso == null) return '';
    try { final dt = DateTime.parse(iso); return '${dt.day}/${dt.month}/${dt.year}'; }
    catch (_) { return iso; }
  }

  Future<void> _crearCopia() async {
    if (_creandoCopia) return;
    setState(() => _creandoCopia = true);
    _snack('Creando copia de seguridad...', info: true);
    try {
      final pacientes = await DatabaseHelper.instance.obtenerPacientes();
      final consultas = await DatabaseHelper.instance.obtenerConsultas();
      final alertas   = await DatabaseHelper.instance.obtenerAlertas(soloActivas: false);
      final prefs     = await SharedPreferences.getInstance();
      final ahora = DateTime.now();
      final backup = {
        'version': '1.0', 'app': 'DISPERSALUD IA',
        'promotor': _nombre, 'vereda': _vereda, 'municipio': _municipio,
        'fecha_backup': ahora.toIso8601String(),
        'datos': { 'pacientes': pacientes, 'consultas': consultas, 'alertas': alertas,
          'preferencias': { 'voz_activa': prefs.getBool('voz_activa') ?? true,
            'alertas_activas': prefs.getBool('alertas_activas') ?? true,
            'tema_app': prefs.getString('tema_app') ?? 'Sistema' }},
        'resumen': { 'total_pacientes': pacientes.length, 'total_consultas': consultas.length, 'total_alertas': alertas.length },
      };
      final mm  = ahora.month.toString().padLeft(2, '0');
      final dd  = ahora.day.toString().padLeft(2, '0');
      final hh  = ahora.hour.toString().padLeft(2, '0');
      final min = ahora.minute.toString().padLeft(2, '0');
      final nombre = 'dispersalud_backup_${ahora.year}${mm}${dd}_${hh}${min}.json';
      // NOTA: antes esto tenía `if (!kIsWeb) { ...guardar archivo... }`,
      // lo cual significaba que en web NUNCA se guardaba ningún archivo
      // real — el mensaje decía "Copia guardada" pero era falso. Ahora,
      // en web se descarga el .json al navegador (carpeta Descargas del
      // usuario) usando el mismo mecanismo que ya usa la exportación a
      // Excel; en Android/iOS se sigue guardando en la carpeta de
      // documentos de la app, exactamente como antes.
      await descargarBackup(_mapToJson(backup), nombre);
      await prefs.setString('ultima_copia', ahora.toIso8601String());
      _snack('✓ Copia guardada: ${pacientes.length} pacientes, ${consultas.length} consultas');
    } catch (e) { _snack('Error al crear copia: $e', error: true); }
    finally { if (mounted) setState(() => _creandoCopia = false); }
  }

  // ── Restaurar una copia de seguridad desde un archivo .json ──────────────
  Future<void> _restaurarCopia() async {
    if (_restaurando) return;

    // Confirmación previa: importar puede duplicar o sobrescribir datos.
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _c(context).card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('¿Restaurar copia de seguridad?',
            style: TextStyle(color: _c(context).textPrimary, fontWeight: FontWeight.bold)),
        content: Text(
          'Se agregarán los pacientes, consultas y alertas del archivo que elijas. '
          'Si un registro ya existe (mismo ID), se actualizará con los datos de la copia. '
          'Esta acción no se puede deshacer.',
          style: TextStyle(color: _c(context).textSecondary, fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar', style: TextStyle(color: _kVerde))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _kVerde,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Elegir archivo', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmar != true) return;

    setState(() => _restaurando = true);
    try {
      // withData: true es obligatorio en web (ahí no existe una ruta de
      // archivo real; solo se puede acceder a los bytes en memoria).
      final resultado = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );
      if (resultado == null || resultado.files.single.bytes == null) {
        setState(() => _restaurando = false);
        return; // el usuario canceló el selector
      }

      _snack('Restaurando copia de seguridad...', info: true);
      final contenido = utf8.decode(resultado.files.single.bytes!);
      final Map<String, dynamic> backup = jsonDecode(contenido);

      if (backup['datos'] == null) {
        throw const FormatException('El archivo no tiene el formato esperado de DISPERSALUD IA');
      }
      final datos = backup['datos'] as Map<String, dynamic>;
      final pacientes = (datos['pacientes'] as List?) ?? [];
      final consultas = (datos['consultas'] as List?) ?? [];
      final alertas   = (datos['alertas']   as List?) ?? [];

      int okPacientes = 0, okConsultas = 0, okAlertas = 0;
      for (final p in pacientes) {
        try { await DatabaseHelper.instance.insertarPaciente(Map<String, dynamic>.from(p)); okPacientes++; } catch (_) {}
      }
      for (final c in consultas) {
        try { await DatabaseHelper.instance.insertarConsulta(Map<String, dynamic>.from(c)); okConsultas++; } catch (_) {}
      }
      for (final a in alertas) {
        try { await DatabaseHelper.instance.insertarAlerta(Map<String, dynamic>.from(a)); okAlertas++; } catch (_) {}
      }

      _snack('✓ Copia restaurada: $okPacientes pacientes, $okConsultas consultas, $okAlertas alertas');
    } on FormatException catch (e) {
      _snack('Archivo inválido: ${e.message}', error: true);
    } catch (e) {
      _snack('Error al restaurar la copia: $e', error: true);
    } finally {
      if (mounted) setState(() => _restaurando = false);
    }
  }

  String _mapToJson(dynamic obj) {
    if (obj == null)   return 'null';
    if (obj is bool)   return obj.toString();
    if (obj is num)    return obj.toString();
    if (obj is String) return '"${obj.replaceAll('\\','\\\\').replaceAll('"','\\"').replaceAll('\n','\\n')}"';
    if (obj is List)   return '[${obj.map(_mapToJson).join(',')}]';
    if (obj is Map)    return '{${obj.entries.map((e) => '"${e.key}":${_mapToJson(e.value)}').join(',')}}';
    return '"$obj"';
  }

  // ── AHORA abre la pantalla completa MiPerfilScreen ──────────────────────
  void _abrirPerfil() {
    Navigator.push(context,
      MaterialPageRoute(builder: (_) => const MiPerfilScreen()),
    ).then((recargado) {
      if (recargado == true) _cargar(); // recargar nombre/vereda en la tarjeta
    });
  }

  void _abrirSeguridad() => _sheet('Seguridad y privacidad', Icons.lock_outline_rounded,
    Column(children: [
      _infoRow(Icons.lock_rounded, Colors.green, 'Cifrado AES-256 activo', 'Todos tus datos están cifrados en el dispositivo'),
      const SizedBox(height: 10),
      _infoRow(Icons.phone_android_outlined, _kVerde, 'Datos solo en tu celular', 'Sin envío a servidores. Cumple Ley 1581 de protección de datos'),
      const SizedBox(height: 10),
      _infoRow(Icons.sync_outlined, Colors.blue, 'Sincronización cifrada', 'Cuando haya internet, los datos se envían con TLS 1.3'),
      const SizedBox(height: 10),
      _infoRow(Icons.verified_user_outlined, const Color(0xFF534AB7), 'Acceso con PIN', 'El acceso está protegido con PIN de seguridad'),
    ]));

  void _abrirDispositivos() => _sheet('Dispositivos conectados', Icons.devices_outlined,
    Column(children: [
      _infoRow(Icons.phone_android_rounded, _kVerde, 'Este dispositivo',
          'Activo ahora · Android · ${_online ? "Sincronizado" : "Offline"}'),
      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.orange.withOpacity(0.10), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.orange.withOpacity(0.3))),
        child: Row(children: [
          const Icon(Icons.info_outline, color: Colors.orange, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Builder(builder: (ctx) => Text('Solo se permite un dispositivo activo por cuenta.',
              style: TextStyle(color: _c(ctx).textSecondary, fontSize: 12)))),
        ]),
      ),
    ]));

  void _abrirTema() {
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent, builder: (_) =>
      _BottomSheet(titulo: 'Tema de la aplicación', icono: Icons.dark_mode_outlined,
        child: Column(children: [
          ...[ ('Sistema', Icons.brightness_auto_rounded), ('Claro', Icons.light_mode_rounded), ('Oscuro', Icons.dark_mode_rounded) ].map((t) {
            final sel = _tema == t.$1;
            return GestureDetector(
              onTap: () async {
                await _pref('tema_app', t.$1);
                temaNotifier.value = temaDesdeString(t.$1);
                setState(() => _tema = t.$1);

                // FIX: forzar actualización inmediata de la barra de estado
                // El AnnotatedRegion solo funciona en algunos dispositivos;
                // SystemChrome garantiza el cambio en TODOS los Android.
                final esClaro = t.$1 == 'Claro' ||
                    (t.$1 == 'Sistema' &&
                        (WidgetsBinding.instance.platformDispatcher
                                .platformBrightness ==
                            Brightness.light));
                const kVerdeApp = Color(0xFF1D9E75);
                SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
                  statusBarColor:          esClaro ? kVerdeApp : const Color(0xFF0A0A0A),
                  statusBarIconBrightness: Brightness.light,
                  statusBarBrightness:     Brightness.dark,
                  systemNavigationBarColor:          esClaro ? Colors.white : const Color(0xFF101010),
                  systemNavigationBarIconBrightness: esClaro ? Brightness.dark : Brightness.light,
                  systemNavigationBarDividerColor:   Colors.transparent,
                ));

                if (mounted) Navigator.pop(context);
                _snack('Tema ${t.$1.toLowerCase()} aplicado ✓');
              },
              child: Builder(builder: (ctx) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                decoration: BoxDecoration(
                  color: sel ? _kVerde.withOpacity(0.12) : _c(ctx).bg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: sel ? _kVerde : _c(ctx).border, width: sel ? 1.5 : 1),
                ),
                child: Row(children: [
                  Icon(t.$2, color: sel ? _kVerde : _c(ctx).textSecondary, size: 20),
                  const SizedBox(width: 12),
                  Text(t.$1, style: TextStyle(color: sel ? _kVerde : _c(ctx).textPrimary, fontSize: 14,
                      fontWeight: sel ? FontWeight.w700 : FontWeight.normal)),
                  const Spacer(),
                  if (sel) const Icon(Icons.check_circle_rounded, color: _kVerde, size: 20),
                ]),
              )),
            );
          }),
        ]),
      ),
    );
  }

  // ── Tamaño de fuente ────────────────────────────────────────────────────
  void _abrirFuente() {
    // Opciones predefinidas: etiqueta, escala, descripción
    const opciones = [
      ('Pequeña',  0.85, 'Cabe más contenido en pantalla'),
      ('Normal',   1.0,  'Tamaño predeterminado de la app'),
      ('Grande',   1.15, 'Más fácil de leer'),
      ('Muy grande',1.3, 'Accesibilidad máxima'),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (ctx, ss) {
          final dc = _c(ctx);
          return Container(
            decoration: BoxDecoration(
              color: dc.card,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              // Handle
              Center(child: Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: dc.border,
                      borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),

              // Título
              Row(children: [
                Container(width: 38, height: 38,
                  decoration: BoxDecoration(color: _kVerde.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.text_fields_rounded, color: _kVerde, size: 20)),
                const SizedBox(width: 10),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Tamaño de fuente', style: TextStyle(
                      color: dc.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                  Text('Ajusta el texto de toda la aplicación',
                      style: TextStyle(color: dc.textHint, fontSize: 11)),
                ]),
              ]),
              const SizedBox(height: 20),

              // Vista previa del texto
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: dc.bg, borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: dc.border)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Vista previa',
                      style: TextStyle(color: dc.textHint, fontSize: 11)),
                  const SizedBox(height: 6),
                  Text('DISPERSALUD IA',
                      style: TextStyle(color: _kVerde,
                          fontSize: 14 * _fuente,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text('Salud rural sin internet · Cauca, Colombia',
                      style: TextStyle(color: dc.textSecondary,
                          fontSize: 12 * _fuente)),
                ]),
              ),
              const SizedBox(height: 16),

              // Opciones de tamaño
              ...opciones.map((op) {
                final sel = (_fuente - op.$2).abs() < 0.01;
                return GestureDetector(
                  onTap: () async {
                    ss(() {});
                    setState(() => _fuente = op.$2);
                    fontSizeNotifier.value = op.$2;
                    final p = await SharedPreferences.getInstance();
                    await p.setDouble('fuente_escala', op.$2);
                    _snack('Fuente ${op.$1.toLowerCase()} aplicada ✓');
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: sel ? _kVerde.withOpacity(0.10) : dc.bg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: sel ? _kVerde : dc.border,
                          width: sel ? 1.5 : 1)),
                    child: Row(children: [
                      // Preview "A" con el tamaño correspondiente
                      SizedBox(
                        width: 40,
                        child: Text('A',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: sel ? _kVerde : dc.textSecondary,
                                fontSize: 12 + (op.$2 - 0.85) * 20,
                                fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(op.$1, style: TextStyle(
                            color: sel ? _kVerde : dc.textPrimary,
                            fontSize: 14,
                            fontWeight: sel ? FontWeight.bold : FontWeight.w500)),
                        Text(op.$3, style: TextStyle(
                            color: dc.textHint, fontSize: 11)),
                      ])),
                      // Badge seleccionado
                      if (sel)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                              color: _kVerde.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20)),
                          child: const Text('Activo',
                              style: TextStyle(color: _kVerde,
                                  fontSize: 11, fontWeight: FontWeight.bold)),
                        )
                      else
                        Icon(Icons.radio_button_unchecked,
                            color: dc.border, size: 18),
                    ]),
                  ),
                );
              }),

              const SizedBox(height: 8),
              SizedBox(width: double.infinity, height: 48,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                      side: BorderSide(color: dc.border),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  child: Text('Cerrar',
                      style: TextStyle(color: dc.textSecondary,
                          fontWeight: FontWeight.w600)),
                )),
            ]),
          );
        },
      ),
    );
  }

  void _abrirIdioma() => _sheet('Idioma', Icons.language_rounded,
    Column(children: [
      _infoRow(Icons.check_circle_rounded, _kVerde, 'Español (Colombia)', 'Idioma predeterminado de la aplicación'),
      const SizedBox(height: 8),
      Builder(builder: (ctx) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: _kVerde.withOpacity(0.06), borderRadius: BorderRadius.circular(10), border: Border.all(color: _kVerde.withOpacity(0.2))),
        child: Text('Actualmente solo está disponible el español colombiano. Próximas versiones incluirán más idiomas.',
            style: TextStyle(color: _c(ctx).textSecondary, fontSize: 12, height: 1.4)),
      )),
    ]));

  void _abrirNotificaciones() {
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(builder: (ctx, setS) => _BottomSheet(
        titulo: 'Notificaciones', icono: Icons.notifications_outlined,
        child: Column(children: [
          _switchRow(icono: Icons.notifications_active_rounded, color: const Color(0xFFEF9F27),
            titulo: 'Alertas de pacientes', desc: 'Notificaciones de nivel urgente y alerta',
            valor: _alertas, onChange: (v) { setS(() {}); setState(() => _alertas = v); _pref('alertas_activas', v); }),
          const SizedBox(height: 10),
          _switchRow(icono: Icons.mic_rounded, color: _kVerde,
            titulo: 'Respuesta por voz', desc: 'La IA leerá las respuestas en voz alta',
            valor: _vozActiva, onChange: (v) { setS(() {}); setState(() => _vozActiva = v); _pref('voz_activa', v); }),
        ]),
      )),
    );
  }

  void _abrirSincronizacion() {
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => _BottomSheet(titulo: 'Sincronización de datos', icono: Icons.sync_rounded,
        child: Column(children: [
          _infoRow(_online ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
              _online ? _kVerde : Colors.orange,
              _online ? 'Conectado a internet' : 'Sin conexión a internet',
              _online ? 'Los datos se sincronizan automáticamente' : 'Los datos se guardan localmente hasta reconectarse'),
          const SizedBox(height: 10),
          _infoRow(Icons.storage_rounded, const Color(0xFF185FA5), 'Base de datos local', 'SQLite · cifrado AES-256 · sin límite de registros'),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, height: 48,
            child: ElevatedButton.icon(
              onPressed: _sincronizando ? null : () { Navigator.pop(context); _sincronizar(); },
              icon: _sincronizando ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.sync_rounded, size: 18),
              label: Text(_sincronizando ? 'Sincronizando...' : 'Sincronizar ahora'),
              style: ElevatedButton.styleFrom(backgroundColor: _online ? _kVerde : Colors.grey, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(width: double.infinity, height: 48,
            child: OutlinedButton.icon(
              onPressed: () { Navigator.pop(context); _verificarConectividad(); },
              icon: Icon(_online ? Icons.wifi_rounded : Icons.wifi_off_rounded, color: _online ? _kVerde : Colors.orange, size: 18),
              label: Text('Verificar conexión', style: TextStyle(color: _online ? _kVerde : Colors.orange)),
              style: OutlinedButton.styleFrom(side: BorderSide(color: _online ? _kVerde : Colors.orange), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            ),
          ),
        ]),
      ),
    );
  }

  Future<void> _exportarExcel() async {
    if (_exportandoExcel) return;
    setState(() => _exportandoExcel = true);
    _snack('Generando Excel...', info: true);
    try {
      final ruta = await ExcelService.instance.exportarTodo();
      _snack('Excel guardado: $ruta');
    } catch (e) {
      _snack('Error al generar Excel: $e', error: true);
    } finally {
      if (mounted) setState(() => _exportandoExcel = false);
    }
  }

  void _abrirExportar() {
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent,
      builder: (_) => _BottomSheet(titulo: 'Exportar datos', icono: Icons.download_outlined,
        child: Column(children: [
          GestureDetector(
            onTap: () { Navigator.pop(context); _exportarPDF(); },
            child: Builder(builder: (ctx) => Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: const Color(0xFFE24B4A).withOpacity(0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE24B4A).withOpacity(0.25))),
              child: Row(children: [
                Container(width: 40, height: 40, decoration: BoxDecoration(color: const Color(0xFFE24B4A).withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                  child: _exportando ? const Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator(color: Color(0xFFE24B4A), strokeWidth: 2)) : const Icon(Icons.picture_as_pdf_outlined, color: Color(0xFFE24B4A), size: 20)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Exportar como PDF', style: TextStyle(color: _c(ctx).textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                  Text('Informe completo de pacientes y consultas', style: TextStyle(color: _c(ctx).textHint, fontSize: 11)),
                ])),
                const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFE24B4A), size: 14),
              ]),
            )),
          ),
          const SizedBox(height: 10),
          Builder(builder: (ctx) => Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: _kVerde.withOpacity(0.06), borderRadius: BorderRadius.circular(10), border: Border.all(color: _kVerde.withOpacity(0.2))),
            child: Row(children: [
              const Icon(Icons.check_circle_outline_rounded, color: _kVerde, size: 14),
              const SizedBox(width: 8),
              Expanded(child: Text('El PDF se genera localmente. No requiere internet.', style: TextStyle(color: _c(ctx).textSecondary, fontSize: 11))),
            ]),
          )),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () { Navigator.pop(context); _exportarExcel(); },
            child: Builder(builder: (ctx) => Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1D7A3A).withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF1D7A3A).withOpacity(0.25)),
              ),
              child: Row(children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1D7A3A).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _exportandoExcel
                    ? const Padding(padding: EdgeInsets.all(10),
                        child: CircularProgressIndicator(color: Color(0xFF1D7A3A), strokeWidth: 2))
                    : const Icon(Icons.table_chart_outlined, color: Color(0xFF1D7A3A), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Exportar como Excel', style: TextStyle(
                      color: _c(ctx).textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                  Text('Pacientes, consultas, signos vitales, alertas, especialistas y medicamentos',
                      style: TextStyle(color: _c(ctx).textHint, fontSize: 11)),
                ])),
                const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF1D7A3A), size: 14),
              ]),
            )),
          ),
        ]),
      ),
    );
  }

  void _abrirCopias() {
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent,
      builder: (_) => _BottomSheet(titulo: 'Copias de seguridad', icono: Icons.backup_outlined,
        child: Column(children: [
          _infoRow(Icons.phone_android_rounded, _kVerde, 'Copia local activa', 'Los datos se guardan automáticamente en el dispositivo'),
          const SizedBox(height: 10),
          _infoRow(Icons.folder_open_rounded, const Color(0xFF185FA5), 'Formato JSON', 'Compatible con futuras versiones de DISPERSALUD IA'),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, height: 48,
            child: ElevatedButton.icon(
              onPressed: _creandoCopia ? null : () { Navigator.pop(context); _crearCopia(); },
              icon: _creandoCopia ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.backup_rounded, size: 18),
              label: Text(_creandoCopia ? 'Creando copia...' : 'Crear copia ahora'),
              style: ElevatedButton.styleFrom(backgroundColor: _kVerde, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(width: double.infinity, height: 48,
            child: OutlinedButton.icon(
              onPressed: _restaurando ? null : () { Navigator.pop(context); _restaurarCopia(); },
              icon: _restaurando ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Color(0xFF185FA5), strokeWidth: 2)) : const Icon(Icons.restore_rounded, size: 18, color: Color(0xFF185FA5)),
              label: Text(_restaurando ? 'Restaurando...' : 'Restaurar desde archivo', style: const TextStyle(color: Color(0xFF185FA5))),
              style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFF185FA5)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            ),
          ),
        ]),
      ),
    );
  }

  void _abrirAyuda() => _sheet('Centro de ayuda', Icons.help_outline_rounded,
    Column(children: [
      _infoRow(Icons.book_outlined, const Color(0xFF534AB7), '¿Cómo registrar un paciente?', 'Ve a Módulos → selecciona ciclo vital → nuevo paciente'),
      const SizedBox(height: 10),
      _infoRow(Icons.mic_rounded, _kVerde, '¿Cómo usar la IA por voz?', 'En Inicio, toca "Consultar IA" y habla tu consulta'),
      const SizedBox(height: 10),
      _infoRow(Icons.wifi_off_rounded, Colors.orange, '¿Funciona sin internet?', 'Sí, todos los módulos y la IA básica funcionan 100% offline'),
      const SizedBox(height: 10),
      _infoRow(Icons.lock_outline, Colors.green, '¿Mis datos son seguros?', 'Sí, cifrado AES-256 y nunca salen del dispositivo sin tu permiso'),
    ]));

  void _abrirManual() => _sheet('Manual de uso', Icons.menu_book_rounded,
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _manualItem('1. Registro de pacientes', 'Ve a la pestaña Módulos y selecciona el ciclo vital del paciente.'),
      _manualItem('2. Consulta por voz', 'Desde Inicio, toca el botón "Consultar IA" y habla tu consulta clínica.'),
      _manualItem('3. Historia clínica', 'En Pacientes, toca el botón H.C. en la tarjeta del paciente.'),
      _manualItem('4. Alertas', 'Las alertas se generan automáticamente según el nivel de riesgo.'),
      _manualItem('5. Medicamentos', 'Accede desde Inicio → Acciones rápidas → Medicamentos.'),
      _manualItem('6. Modo offline', 'Todo funciona sin internet. Al reconectarte se sincronizan los datos.'),
    ]));

  void _abrirContacto() => _sheet('Contacto soporte', Icons.support_agent_rounded,
    Column(children: [
      _infoRow(Icons.email_outlined, const Color(0xFF185FA5), 'Correo de soporte', 'soporte@dispersalud.co'),
      const SizedBox(height: 10),
      _infoRow(Icons.phone_outlined, _kVerde, 'Línea de atención', 'Lunes a viernes 8am - 5pm'),
      const SizedBox(height: 10),
      _infoRow(Icons.chat_outlined, const Color(0xFF534AB7), 'Chat en línea', 'Disponible cuando hay conexión a internet'),
    ]));

  void _cerrarSesion() {
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: _c(context).card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('¿Cerrar sesión?', style: TextStyle(color: _c(context).textPrimary, fontWeight: FontWeight.bold)),
      content: Text(
        'Tu sesión se cerrará completamente. Los datos del dispositivo permanecerán guardados.',
        style: TextStyle(color: _c(context).textSecondary, fontSize: 13, height: 1.5),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar', style: TextStyle(color: _kVerde)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () async {
            Navigator.pop(context);
            // 1. Cerrar sesión en Supabase (invalida el token en servidor)
            try {
              await Supabase.instance.client.auth.signOut();
            } catch (_) {
              // Sin internet: se cerrará solo localmente
            }
            // Solo se cierra la sesión — el perfil y los datos quedan intactos
            // Para borrar todo usar "Eliminar cuenta" en Mi Perfil
            if (mounted) {
              Navigator.of(context).pushNamedAndRemoveUntil('/auth', (r) => false);
            }
          },
          child: const Text('Cerrar sesión', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        ),
      ],
    ));
  }

  void _sheet(String titulo, IconData icono, Widget child) {
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
        builder: (_) => _BottomSheet(titulo: titulo, icono: icono, child: child));
  }

  @override
  Widget build(BuildContext context) {
    final dc = _c(context);
    return Scaffold(
      backgroundColor: dc.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(children: [
            // APP BAR
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Row(children: [
                const SizedBox(width: 4),
                Icon(Icons.settings_rounded, color: _kVerde, size: 22),
                const SizedBox(width: 8),
                Text('Configuración', style: TextStyle(color: dc.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
              ]),
            ),

            // TARJETA PERFIL — ahora abre MiPerfilScreen
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: GestureDetector(
                onTap: _abrirPerfil,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: dc.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: dc.border)),
                  child: Row(children: [
                    // Avatar con foto si existe
                    Container(
                      width: 52, height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: _kVerde.withOpacity(0.3), width: 2),
                        color: _kVerde.withOpacity(0.15),
                      ),
                      child: ClipOval(child: _fotoPerfilWidget(
                        _fotoPerfil,
                        Center(child: Text(
                            _nombre.isNotEmpty ? _nombre[0].toUpperCase() : 'P',
                            style: const TextStyle(color: _kVerde, fontSize: 22, fontWeight: FontWeight.bold))),
                      )),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(_nombre.isNotEmpty ? _nombre : 'Promotor/a',
                          style: TextStyle(color: dc.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                      const Text('Promotor de Salud Rural', style: TextStyle(color: Color(0xFF9FE1CB), fontSize: 12)),
                      if (_vereda.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Row(children: [
                          Icon(Icons.location_on_outlined, color: dc.textHint, size: 12),
                          const SizedBox(width: 3),
                          Text('$_vereda - $_municipio', style: TextStyle(color: dc.textHint, fontSize: 11)),
                        ]),
                      ],
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: _verificarConectividad,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _online ? _kVerde.withOpacity(0.15) : Colors.orange.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Container(width: 6, height: 6, decoration: BoxDecoration(
                                color: _online ? _kVerde : Colors.orange, shape: BoxShape.circle)),
                            const SizedBox(width: 5),
                            Text(_online ? 'Online' : 'Offline', style: TextStyle(
                                color: _online ? _kVerde : Colors.orange, fontSize: 11, fontWeight: FontWeight.w600)),
                          ]),
                        ),
                      ),
                    ])),
                    Icon(Icons.chevron_right_rounded, color: dc.textHint, size: 20),
                  ]),
                ),
              ),
            ),

            const SizedBox(height: 4),
            _label('Cuenta'),
            _grupo([
              _tile(Icons.person_outline_rounded, 'Mi perfil', null, dc, onTap: _abrirPerfil),
              _tile(Icons.lock_outline_rounded, 'Seguridad y privacidad', null, dc, onTap: _abrirSeguridad),
              _tile(Icons.devices_outlined, 'Dispositivos conectados', null, dc, onTap: _abrirDispositivos, last: true),
            ], dc),
            const SizedBox(height: 8),
            _label('Aplicación'),
            _grupo([
              _tile(Icons.dark_mode_outlined, 'Tema', _tema, dc, onTap: _abrirTema),
              _tile(Icons.text_fields_rounded, 'Tamaño de fuente',
                  _fuente == 0.85 ? 'Pequeña'
                  : _fuente == 1.0 ? 'Normal'
                  : _fuente == 1.15 ? 'Grande'
                  : 'Muy grande',
                  dc, onTap: _abrirFuente, iconColor: const Color(0xFF534AB7)),
              _tile(Icons.language_rounded, 'Idioma', 'Español', dc, onTap: _abrirIdioma),
              _tile(Icons.notifications_outlined, 'Notificaciones', 'Personalizadas', dc, onTap: _abrirNotificaciones, last: true),
            ], dc),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF0A5240), Color(0xFF0F6E56)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(width: 48, height: 48, decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                    child: Stack(alignment: Alignment.center, children: [
                      const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 28),
                      Positioned(top: 5, right: 5, child: Icon(Icons.auto_awesome, color: Colors.white.withOpacity(0.7), size: 10)),
                    ])),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('DISPERSALUD IA', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 0.3)),
                    const Text('Modelo clínico activo  ·  v2.4', style: TextStyle(color: Color(0xFF9FE1CB), fontSize: 11)),
                    const SizedBox(height: 8),
                    const Row(children: [Icon(Icons.check_rounded, color: Color(0xFF9FE1CB), size: 14), SizedBox(width: 4), Text('Protocolos actualizados', style: TextStyle(color: Color(0xFFB8F0DC), fontSize: 11))]),
                    const SizedBox(height: 3),
                    const Row(children: [Icon(Icons.check_rounded, color: Color(0xFF9FE1CB), size: 14), SizedBox(width: 4), Text('Uso sin conexión habilitado', style: TextStyle(color: Color(0xFFB8F0DC), fontSize: 11))]),
                  ])),
                  const Icon(Icons.chevron_right_rounded, color: Colors.white38, size: 20),
                ]),
              ),
            ),
            const SizedBox(height: 8),
            _label('Datos y sincronización'),
            _grupo([
              _tile(Icons.sync_rounded, 'Sincronización de datos', _sincronizando ? 'Sincronizando...' : null,
                  dc, onTap: _abrirSincronizacion, iconColor: _online ? _kVerde : Colors.orange),
              _tile(Icons.download_outlined, 'Exportar datos', _exportando ? 'Generando PDF...' : null, dc, onTap: _abrirExportar),
              _tile(Icons.backup_outlined, 'Copias de seguridad',
                  _creandoCopia ? 'Creando copia...' : _restaurando ? 'Restaurando...' : null,
                  dc, onTap: _abrirCopias, last: true),
            ], dc),
            const SizedBox(height: 8),
            _label('Soporte'),
            _grupo([
              _tile(Icons.help_outline_rounded, 'Centro de ayuda', null, dc, onTap: _abrirAyuda, iconColor: const Color(0xFFEF9F27)),
              _tile(Icons.menu_book_rounded, 'Manual de uso', null, dc, onTap: _abrirManual, iconColor: const Color(0xFF185FA5)),
              _tile(Icons.support_agent_rounded, 'Contacto soporte', null, dc, onTap: _abrirContacto, iconColor: const Color(0xFF534AB7), last: true),
            ], dc),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              child: SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton.icon(
                  onPressed: _cerrarSesion,
                  icon: const Icon(Icons.exit_to_app_rounded, color: Colors.white, size: 20),
                  label: const Text('Cerrar sesión', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB71C1C), elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ─── HELPERS DE LAYOUT (sin cambios) ─────────────────────────────────────────
Widget _label(String texto) => Padding(
  padding: const EdgeInsets.fromLTRB(20, 4, 16, 6),
  child: Builder(builder: (ctx) => Text(texto, style: TextStyle(color: _c(ctx).textHint, fontSize: 12, fontWeight: FontWeight.w600))),
);

Widget _grupo(List<Widget> items, DispersaludColors dc) => Padding(
  padding: const EdgeInsets.symmetric(horizontal: 16),
  child: Container(
    decoration: BoxDecoration(color: dc.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: dc.border)),
    child: Column(children: items),
  ),
);

Widget _tile(IconData icono, String titulo, String? valor, DispersaludColors dc,
    {VoidCallback? onTap, Color iconColor = _kVerde, bool last = false}) =>
  Column(children: [
    InkWell(
      onTap: onTap, borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(children: [
          Container(width: 34, height: 34,
            decoration: BoxDecoration(color: iconColor.withOpacity(0.12), borderRadius: BorderRadius.circular(9)),
            child: Icon(icono, color: iconColor, size: 18)),
          const SizedBox(width: 12),
          Expanded(child: Text(titulo, style: TextStyle(color: dc.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))),
          if (valor != null) ...[Text(valor, style: TextStyle(color: dc.textHint, fontSize: 12)), const SizedBox(width: 4)],
          Icon(Icons.chevron_right_rounded, color: dc.textHint, size: 18),
        ]),
      ),
    ),
    if (!last) Padding(padding: const EdgeInsets.only(left: 60), child: Divider(height: 1, color: dc.border)),
  ]);

Widget _infoRow(IconData icono, Color color, String titulo, String desc) =>
  Builder(builder: (ctx) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: color.withOpacity(0.06), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.2))),
    child: Row(children: [
      Container(width: 36, height: 36, decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(9)),
          child: Icon(icono, color: color, size: 18)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(titulo, style: TextStyle(color: _c(ctx).textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(desc, style: TextStyle(color: _c(ctx).textHint, fontSize: 11, height: 1.3)),
      ])),
    ]),
  ));

Widget _switchRow({required IconData icono, required Color color, required String titulo,
    required String desc, required bool valor, required ValueChanged<bool> onChange}) =>
  Builder(builder: (ctx) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(color: _c(ctx).bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: _c(ctx).border)),
    child: Row(children: [
      Container(width: 36, height: 36, decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(9)),
          child: Icon(icono, color: color, size: 18)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(titulo, style: TextStyle(color: _c(ctx).textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
        Text(desc, style: TextStyle(color: _c(ctx).textHint, fontSize: 11)),
      ])),
      Switch(value: valor, activeColor: _kVerde, onChanged: onChange),
    ]),
  ));

Widget _manualItem(String titulo, String desc) =>
  Builder(builder: (ctx) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 6, height: 6, margin: const EdgeInsets.only(top: 5),
          decoration: const BoxDecoration(color: _kVerde, shape: BoxShape.circle)),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(titulo, style: TextStyle(color: _c(ctx).textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(desc, style: TextStyle(color: _c(ctx).textHint, fontSize: 11, height: 1.4)),
      ])),
    ]),
  ));

// BOTTOM SHEET GENÉRICO (sin cambios)
class _BottomSheet extends StatelessWidget {
  final String titulo;
  final IconData icono;
  final Widget child;
  const _BottomSheet({required this.titulo, required this.icono, required this.child});

  @override
  Widget build(BuildContext context) {
    final dc     = _c(context);
    final bottom = MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: BoxDecoration(color: dc.card, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      padding: EdgeInsets.fromLTRB(20, 16, 20, bottom < 16 ? 32 : bottom + 16),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: dc.border, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Row(children: [
            Container(width: 38, height: 38,
              decoration: BoxDecoration(color: _kVerde.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
              child: Icon(icono, color: _kVerde, size: 20)),
            const SizedBox(width: 10),
            Text(titulo, style: TextStyle(color: dc.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 20),
          child,
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, height: 48,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(side: BorderSide(color: dc.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: Text('Cerrar', style: TextStyle(color: dc.textSecondary, fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
      ),
    );
  }
}