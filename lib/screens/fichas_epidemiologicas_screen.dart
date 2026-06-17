// lib/screens/fichas_epidemiologicas_screen.dart
//
// Pantalla de Fichas Epidemiológicas — DISPERSALUD IA
// Muestra el catálogo de protocolos del INS, permite buscar y filtrar,
// y abre cada PDF desde los assets con open_filex.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import 'ficha_formulario_screen.dart';
import 'fichas_reportes_screen.dart';
import 'historial_fichas_screen.dart';
import '../database/database_helper.dart';

// ── Acceso al tema ─────────────────────────────────────────────────────────
DispersaludColors _c(BuildContext ctx) =>
    Theme.of(ctx).extension<DispersaludColors>() ?? DispersaludColors.dark;

// ── Colores constantes ─────────────────────────────────────────────────────
const _kVerde   = Color(0xFF1D9E75);
const _kRojo    = Color(0xFFE24B4A);
const _kNaranja = Color(0xFFEF9F27);
const _kAzul    = Color(0xFF185FA5);
const _kMorado  = Color(0xFF534AB7);

// ═══════════════════════════════════════════════════════════════════════════
//  MODELO DE FICHA
// ═══════════════════════════════════════════════════════════════════════════
class _Ficha {
  final String codigo;
  final String nombre;
  final String categoria;
  final String emoji;
  final Color  color;
  final String descripcionCorta;
  final String notificacion;
  final bool   esUrgente;

  const _Ficha({
    required this.codigo,
    required this.nombre,
    required this.categoria,
    required this.emoji,
    required this.color,
    required this.descripcionCorta,
    required this.notificacion,
    this.esUrgente = false,
  });
}

// ─── Categorías ────────────────────────────────────────────────────────────
class _Cat {
  final String id, nombre, emoji;
  final Color color;
  const _Cat({required this.id, required this.nombre,
      required this.emoji, required this.color});
}

const List<_Cat> _kCategorias = [
  _Cat(id: 'todas',      nombre: 'Todas',              emoji: '🗂️', color: _kVerde),
  _Cat(id: 'vectores',   nombre: 'Vectores',            emoji: '🦟', color: Color(0xFF3B6D11)),
  _Cat(id: 'respira',    nombre: 'Respiratorias',       emoji: '🫁', color: _kMorado),
  _Cat(id: 'inmuno',     nombre: 'Inmunoprevenibles',   emoji: '💉', color: _kAzul),
  _Cat(id: 'its',        nombre: 'ITS/VIH',             emoji: '🔬', color: Color(0xFF993556)),
  _Cat(id: 'alimentos',  nombre: 'Alimentos/Agua',      emoji: '💧', color: Color(0xFF0F6E56)),
  _Cat(id: 'zoonosis',   nombre: 'Zoonosis',            emoji: '🐾', color: Color(0xFF854F0B)),
  _Cat(id: 'materna',    nombre: 'Materna',             emoji: '🤰', color: Color(0xFF993556)),
  _Cat(id: 'lesiones',   nombre: 'Lesiones/Violencia',  emoji: '⚕️', color: _kRojo),
  _Cat(id: 'cronicas',   nombre: 'Crónicas/Otras',      emoji: '🏥', color: Color(0xFF5F5E5A)),
];

// ─── Catálogo completo de fichas ──────────────────────────────────────────
const List<_Ficha> _kFichas = [
  // ── VECTORES ─────────────────────────────────────────────────────────────
  _Ficha(
    codigo: 'DEN', nombre: 'Dengue / Dengue grave',
    categoria: 'vectores', emoji: '🦟', color: Color(0xFF3B6D11),
    descripcionCorta: 'Enfermedad viral por Aedes aegypti. Notificación inmediata.',
    notificacion: 'Inmediata', esUrgente: true,
  ),
  _Ficha(
    codigo: 'CHIK', nombre: 'Chikunguña',
    categoria: 'vectores', emoji: '🦟', color: Color(0xFF3B6D11),
    descripcionCorta: 'Arbovirus. Artralgia severa característica.',
    notificacion: '24 horas',
  ),
  _Ficha(
    codigo: 'ZIKA', nombre: 'Zika',
    categoria: 'vectores', emoji: '🦟', color: Color(0xFF3B6D11),
    descripcionCorta: 'Riesgo de microcefalia en embarazadas. Notificación urgente.',
    notificacion: 'Inmediata', esUrgente: true,
  ),
  _Ficha(
    codigo: 'MAL', nombre: 'Malaria',
    categoria: 'vectores', emoji: '🦠', color: Color(0xFF3B6D11),
    descripcionCorta: 'Parasitosis por Plasmodium. Alta mortalidad en forma grave.',
    notificacion: 'Inmediata', esUrgente: true,
  ),
  _Ficha(
    codigo: 'LEISH', nombre: 'Leishmaniasis',
    categoria: 'vectores', emoji: '🦠', color: Color(0xFF3B6D11),
    descripcionCorta: 'Transmitida por flebótomos. Endémica en zonas selváticas.',
    notificacion: '24 horas',
  ),
  _Ficha(
    codigo: 'FIAM', nombre: 'Fiebre amarilla',
    categoria: 'vectores', emoji: '🟡', color: Color(0xFF3B6D11),
    descripcionCorta: 'Arbovirus. Caso único es emergencia de salud pública.',
    notificacion: 'Inmediata', esUrgente: true,
  ),
  _Ficha(
    codigo: 'CHAG', nombre: 'Enfermedad de Chagas',
    categoria: 'vectores', emoji: '🐜', color: Color(0xFF3B6D11),
    descripcionCorta: 'Tripanosomiasis americana. Transmitida por pito/chipo.',
    notificacion: '24 horas',
  ),
  _Ficha(
    codigo: 'ENCEF', nombre: 'Encefalitis equina',
    categoria: 'vectores', emoji: '🐴', color: Color(0xFF3B6D11),
    descripcionCorta: 'Arbovirus transmitido por mosquitos. Vigilancia en equinos.',
    notificacion: 'Inmediata', esUrgente: true,
  ),

  // ── RESPIRATORIAS ─────────────────────────────────────────────────────────
  _Ficha(
    codigo: 'IRA', nombre: 'IRA — Infección Respiratoria Aguda',
    categoria: 'respira', emoji: '🫁', color: _kMorado,
    descripcionCorta: 'Principal causa de mortalidad infantil en menores de 5 años.',
    notificacion: 'Semanal',
  ),
  _Ficha(
    codigo: 'TUB', nombre: 'Tuberculosis',
    categoria: 'respira', emoji: '🦠', color: _kMorado,
    descripcionCorta: 'Notificación individual obligatoria. Búsqueda activa de sintomáticos.',
    notificacion: '24 horas',
  ),
  _Ficha(
    codigo: 'TUBFR', nombre: 'Tuberculosis farmacorresistente',
    categoria: 'respira', emoji: '⚠️', color: _kMorado,
    descripcionCorta: 'TB-MDR y TB-XDR. Protocolo especial de manejo.',
    notificacion: 'Inmediata', esUrgente: true,
  ),
  _Ficha(
    codigo: 'COVID', nombre: 'COVID-19',
    categoria: 'respira', emoji: '😷', color: _kMorado,
    descripcionCorta: 'Vigilancia centinela y IRAG. Protocolo INS actualizado.',
    notificacion: '24 horas',
  ),
  _Ficha(
    codigo: 'TOS', nombre: 'Tos ferina (Pertussis)',
    categoria: 'respira', emoji: '😮', color: _kMorado,
    descripcionCorta: 'Alta mortalidad en menores de 1 año no vacunados.',
    notificacion: 'Inmediata', esUrgente: true,
  ),
  _Ficha(
    codigo: 'DIFT', nombre: 'Difteria',
    categoria: 'respira', emoji: '🤒', color: _kMorado,
    descripcionCorta: 'Inmunoprevenible. Cualquier caso es emergencia epidemiológica.',
    notificacion: 'Inmediata', esUrgente: true,
  ),
  _Ficha(
    codigo: 'MPOX', nombre: 'Mpox (Viruela del mono)',
    categoria: 'respira', emoji: '🔴', color: _kMorado,
    descripcionCorta: 'Vigilancia de casos sospechosos. Aislamiento de contactos.',
    notificacion: 'Inmediata', esUrgente: true,
  ),

  // ── INMUNOPREVENIBLES ─────────────────────────────────────────────────────
  _Ficha(
    codigo: 'VAR', nombre: 'Varicela',
    categoria: 'inmuno', emoji: '💉', color: _kAzul,
    descripcionCorta: 'Vigilancia de brotes. Notificación de casos hospitalizados.',
    notificacion: '24 horas',
  ),
  _Ficha(
    codigo: 'RUBE', nombre: 'Rubéola / Síndrome rubéola congénita',
    categoria: 'inmuno', emoji: '🔴', color: _kAzul,
    descripcionCorta: 'Meta de eliminación en Colombia. Cualquier caso: notificación inmediata.',
    notificacion: 'Inmediata', esUrgente: true,
  ),
  _Ficha(
    codigo: 'PAROT', nombre: 'Parotiditis',
    categoria: 'inmuno', emoji: '🤒', color: _kAzul,
    descripcionCorta: 'Vigilancia de brotes en instituciones educativas y comunidades.',
    notificacion: '24 horas',
  ),
  _Ficha(
    codigo: 'EAPV', nombre: 'Eventos Adversos Post-Vacunación (EAPV)',
    categoria: 'inmuno', emoji: '⚕️', color: _kAzul,
    descripcionCorta: 'Reacciones adversas a biológicos del PAI. Notificación obligatoria.',
    notificacion: '24 horas',
  ),

  // ── ITS / VIH ─────────────────────────────────────────────────────────────
  _Ficha(
    codigo: 'VIH', nombre: 'VIH/SIDA',
    categoria: 'its', emoji: '🔬', color: Color(0xFF993556),
    descripcionCorta: 'Notificación individual. Diagnóstico, tratamiento y adherencia.',
    notificacion: '24 horas',
  ),
  _Ficha(
    codigo: 'HEPATB', nombre: 'Hepatitis B y C',
    categoria: 'its', emoji: '🫀', color: Color(0xFF993556),
    descripcionCorta: 'Vigilancia de hepatitis virales. Énfasis en gestantes y recién nacidos.',
    notificacion: '24 horas',
  ),
  _Ficha(
    codigo: 'HEPA', nombre: 'Hepatitis A',
    categoria: 'its', emoji: '🫀', color: Color(0xFF993556),
    descripcionCorta: 'Transmisión feco-oral. Vigilancia de brotes por agua y alimentos.',
    notificacion: '24 horas',
  ),
  _Ficha(
    codigo: 'SFILIS', nombre: 'Sífilis gestacional y congénita',
    categoria: 'its', emoji: '🤰', color: Color(0xFF993556),
    descripcionCorta: 'Caso de sífilis congénita: notificación inmediata. Meta eliminación.',
    notificacion: 'Inmediata', esUrgente: true,
  ),

  // ── ALIMENTOS / AGUA ──────────────────────────────────────────────────────
  _Ficha(
    codigo: 'EDA', nombre: 'EDA — Enfermedad Diarreica Aguda',
    categoria: 'alimentos', emoji: '💧', color: Color(0xFF0F6E56),
    descripcionCorta: 'Principal causa de consulta infantil. Vigilancia de brotes.',
    notificacion: 'Semanal',
  ),
  _Ficha(
    codigo: 'ETA', nombre: 'ETA — Enfermedades Transmitidas por Alimentos',
    categoria: 'alimentos', emoji: '🍽️', color: Color(0xFF0F6E56),
    descripcionCorta: 'Brotes por consumo de alimentos contaminados. Notificación de brotes.',
    notificacion: 'Inmediata', esUrgente: true,
  ),
  _Ficha(
    codigo: 'FIT', nombre: 'Fiebre tifoidea y paratifoidea',
    categoria: 'alimentos', emoji: '🌡️', color: Color(0xFF0F6E56),
    descripcionCorta: 'Salmonella typhi. Fuente hídrica o alimentaria. Notificación obligatoria.',
    notificacion: '24 horas',
  ),
  _Ficha(
    codigo: 'LEPR', nombre: 'Lepra',
    categoria: 'alimentos', emoji: '🦠', color: Color(0xFF0F6E56),
    descripcionCorta: 'Mycobacterium leprae. Vigilancia activa. Tratamiento multidroga.',
    notificacion: '24 horas',
  ),

  // ── ZOONOSIS ──────────────────────────────────────────────────────────────
  _Ficha(
    codigo: 'RABIA', nombre: 'Rabia humana y animal',
    categoria: 'zoonosis', emoji: '🐾', color: Color(0xFF854F0B),
    descripcionCorta: '100% letal sin tratamiento. Todo accidente ofídico: notificación inmediata.',
    notificacion: 'Inmediata', esUrgente: true,
  ),
  _Ficha(
    codigo: 'LEPT', nombre: 'Leptospirosis',
    categoria: 'zoonosis', emoji: '🐀', color: Color(0xFF854F0B),
    descripcionCorta: 'Transmitida por orina de roedores. Alta mortalidad en forma ictérica.',
    notificacion: '24 horas',
  ),
  _Ficha(
    codigo: 'OFID', nombre: 'Accidente ofídico / Animales venenosos',
    categoria: 'zoonosis', emoji: '🐍', color: Color(0xFF854F0B),
    descripcionCorta: 'Envenenamiento por serpientes, arañas, escorpiones. Antídoto urgente.',
    notificacion: 'Inmediata', esUrgente: true,
  ),
  _Ficha(
    codigo: 'TRAC', nombre: 'Tracoma',
    categoria: 'zoonosis', emoji: '👁️', color: Color(0xFF854F0B),
    descripcionCorta: 'Infección ocular por Chlamydia. Meta de eliminación OPS.',
    notificacion: '24 horas',
  ),

  // ── MATERNA / PERINATAL ───────────────────────────────────────────────────
  _Ficha(
    codigo: 'MME', nombre: 'Mortalidad materna extrema (MME)',
    categoria: 'materna', emoji: '🤰', color: Color(0xFF993556),
    descripcionCorta: 'Vigilancia de la morbilidad materna extrema. Análisis de caso obligatorio.',
    notificacion: 'Inmediata', esUrgente: true,
  ),
  _Ficha(
    codigo: 'MM', nombre: 'Mortalidad materna — Análisis de caso',
    categoria: 'materna', emoji: '📋', color: Color(0xFF993556),
    descripcionCorta: 'Ficha de análisis de caso de muerte materna. INS 2024.',
    notificacion: 'Inmediata', esUrgente: true,
  ),
  _Ficha(
    codigo: 'MMAUT', nombre: 'Mortalidad materna — Autopsia verbal',
    categoria: 'materna', emoji: '📋', color: Color(0xFF993556),
    descripcionCorta: 'Instrumento de autopsia verbal para muerte materna.',
    notificacion: 'Inmediata', esUrgente: true,
  ),
  _Ficha(
    codigo: 'MMEMB', nombre: 'Mortalidad materna — Verificación embarazo',
    categoria: 'materna', emoji: '📋', color: Color(0xFF993556),
    descripcionCorta: 'Ficha de verificación de embarazo en muerte materna.',
    notificacion: 'Inmediata', esUrgente: true,
  ),
  _Ficha(
    codigo: 'MMFAM', nombre: 'Mortalidad materna — Entrevista familiar',
    categoria: 'materna', emoji: '📋', color: Color(0xFF993556),
    descripcionCorta: 'Guía de entrevista a familia en caso de muerte materna.',
    notificacion: 'Inmediata', esUrgente: true,
  ),
  _Ficha(
    codigo: 'MORTPER', nombre: 'Mortalidad perinatal',
    categoria: 'materna', emoji: '👶', color: Color(0xFF993556),
    descripcionCorta: 'Vigilancia de muertes perinatales. Análisis e intervención.',
    notificacion: 'Inmediata', esUrgente: true,
  ),

  // ── LESIONES / VIOLENCIA ──────────────────────────────────────────────────
  _Ficha(
    codigo: 'VIO', nombre: 'Lesiones por causa externa / Violencia',
    categoria: 'lesiones', emoji: '🚨', color: _kRojo,
    descripcionCorta: 'Violencia de género, intrafamiliar y lesiones no intencionales.',
    notificacion: '24 horas',
  ),
  _Ficha(
    codigo: 'SUIC', nombre: 'Intento de suicidio',
    categoria: 'lesiones', emoji: '🆘', color: _kRojo,
    descripcionCorta: 'Notificación individual. Atención y seguimiento obligatorio.',
    notificacion: '24 horas', esUrgente: true,
  ),
  _Ficha(
    codigo: 'MAP', nombre: 'Lesiones por minas antipersona (MAP/MUSE)',
    categoria: 'lesiones', emoji: '💥', color: _kRojo,
    descripcionCorta: 'Vigilancia de víctimas de MAP y MUSE. Notificación inmediata.',
    notificacion: 'Inmediata', esUrgente: true,
  ),
  _Ficha(
    codigo: 'POLV', nombre: 'Lesiones por pólvora',
    categoria: 'lesiones', emoji: '🧨', color: _kRojo,
    descripcionCorta: 'Vigilancia especial en temporadas de fiestas. Notificación obligatoria.',
    notificacion: '24 horas',
  ),
  _Ficha(
    codigo: 'INT', nombre: 'Intoxicaciones agudas (IAPMQ)',
    categoria: 'lesiones', emoji: '☠️', color: _kRojo,
    descripcionCorta: 'Intoxicaciones por plaguicidas, medicamentos y sustancias químicas.',
    notificacion: 'Inmediata', esUrgente: true,
  ),
  _Ficha(
    codigo: 'IAD', nombre: 'Intoxicación por alcohol y drogas (IAD)',
    categoria: 'lesiones', emoji: '🍶', color: _kRojo,
    descripcionCorta: 'Vigilancia de consumo de SPA. Articulado con políticas de salud mental.',
    notificacion: '24 horas',
  ),

  // ── CRÓNICAS / OTRAS ──────────────────────────────────────────────────────
  _Ficha(
    codigo: 'MENING', nombre: 'Meningitis',
    categoria: 'cronicas', emoji: '🧠', color: Color(0xFF5F5E5A),
    descripcionCorta: 'Cualquier caso de meningitis bacteriana: notificación inmediata.',
    notificacion: 'Inmediata', esUrgente: true,
  ),
  _Ficha(
    codigo: 'IAAS', nombre: 'Infecciones Asociadas a Atención en Salud (IAAS)',
    categoria: 'cronicas', emoji: '🏥', color: Color(0xFF5F5E5A),
    descripcionCorta: 'Vigilancia de infecciones nosocomiales. Protocolo de bioseguridad.',
    notificacion: 'Semanal',
  ),
  _Ficha(
    codigo: 'RESB', nombre: 'Resistencia bacteriana a antibióticos',
    categoria: 'cronicas', emoji: '🔬', color: Color(0xFF5F5E5A),
    descripcionCorta: 'Vigilancia centinela de cepas multirresistentes.',
    notificacion: 'Semanal',
  ),
  _Ficha(
    codigo: 'ANTIB', nombre: 'Consumo de antibióticos',
    categoria: 'cronicas', emoji: '💊', color: Color(0xFF5F5E5A),
    descripcionCorta: 'Uso racional de antibióticos. Indicadores de consumo hospitalario.',
    notificacion: 'Semanal',
  ),
  _Ficha(
    codigo: 'ENF_HUERFANAS', nombre: 'Enfermedades huérfanas / raras',
    categoria: 'cronicas', emoji: '🧬', color: Color(0xFF5F5E5A),
    descripcionCorta: 'Registro de enfermedades raras y huérfanas. SISPRO.',
    notificacion: 'Semanal',
  ),
  _Ficha(
    codigo: 'CANCER', nombre: 'Cáncer de mama y cuello uterino',
    categoria: 'cronicas', emoji: '🎗️', color: Color(0xFF5F5E5A),
    descripcionCorta: 'Tamizaje y vigilancia. Registro de casos confirmados.',
    notificacion: 'Semanal',
  ),
  _Ficha(
    codigo: 'TETAN_A', nombre: 'Tétanos accidental',
    categoria: 'cronicas', emoji: '💉', color: Color(0xFF5F5E5A),
    descripcionCorta: 'Inmunoprevenible. Cualquier caso confirmado: notificación inmediata.',
    notificacion: 'Inmediata', esUrgente: true,
  ),
  _Ficha(
    codigo: 'TETAN_N', nombre: 'Tétanos neonatal',
    categoria: 'cronicas', emoji: '👶', color: Color(0xFF5F5E5A),
    descripcionCorta: 'Meta de eliminación. Todo caso es emergencia de salud pública.',
    notificacion: 'Inmediata', esUrgente: true,
  ),
];

// ═══════════════════════════════════════════════════════════════════════════
//  PANTALLA PRINCIPAL
// ═══════════════════════════════════════════════════════════════════════════
class FichasEpidemiologicasScreen extends StatefulWidget {
  const FichasEpidemiologicasScreen({super.key});

  @override
  State<FichasEpidemiologicasScreen> createState() =>
      _FichasEpidemiologicasScreenState();
}

class _FichasEpidemiologicasScreenState
    extends State<FichasEpidemiologicasScreen> {
  String _categoriaActiva = 'todas';
  String _busqueda        = '';
  bool   _soloUrgentes    = false;

  final _searchCtrl = TextEditingController();

  List<_Ficha> get _fichasFiltradas {
    var lista = _kFichas;
    if (_soloUrgentes) lista = lista.where((f) => f.esUrgente).toList();
    if (_categoriaActiva != 'todas') {
      lista = lista.where((f) => f.categoria == _categoriaActiva).toList();
    }
    if (_busqueda.isNotEmpty) {
      final q = _busqueda.toLowerCase();
      lista = lista.where((f) =>
          f.nombre.toLowerCase().contains(q) ||
          f.codigo.toLowerCase().contains(q) ||
          f.descripcionCorta.toLowerCase().contains(q)).toList();
    }
    return lista;
  }

  // ── Abrir formulario con selector de paciente ────────────────────────────
  Future<void> _abrirConPaciente(_Ficha ficha) async {
    // Cargar pacientes de la BD
    final pacientes = await DatabaseHelper.instance.obtenerPacientes();
    if (!mounted) return;

    Map<String, dynamic>? pacienteSeleccionado;

    if (pacientes.isNotEmpty) {
      // Mostrar selector de paciente
      await showModalBottomSheet(
        context: context,
        backgroundColor: _c(context).card,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (_) => DraggableScrollableSheet(
          initialChildSize: 0.5,
          maxChildSize: 0.85,
          minChildSize: 0.3,
          expand: false,
          builder: (ctx, scroll) => StatefulBuilder(
            builder: (ctx2, ss) => Column(children: [
              const SizedBox(height: 8),
              Container(width: 36, height: 4,
                  decoration: BoxDecoration(
                      color: _c(context).border,
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(children: [
                  Icon(Icons.person_search_rounded, color: _kVerde, size: 20),
                  const SizedBox(width: 8),
                  Text('Seleccionar paciente',
                      style: TextStyle(color: _c(context).textPrimary,
                          fontSize: 15, fontWeight: FontWeight.bold)),
                ]),
              ),
              const SizedBox(height: 8),
              Expanded(child: ListView.separated(
                controller: scroll,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                itemCount: pacientes.length + 1,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  if (i == 0) {
                    // Opción sin paciente
                    return GestureDetector(
                      onTap: () {
                        pacienteSeleccionado = {};
                        Navigator.pop(ctx2);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                            color: _c(context).bg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _c(context).border)),
                        child: Row(children: [
                          Icon(Icons.person_add_outlined,
                              color: _c(context).textHint, size: 20),
                          const SizedBox(width: 10),
                          Text('Continuar sin paciente',
                              style: TextStyle(color: _c(context).textSecondary,
                                  fontSize: 13)),
                        ]),
                      ),
                    );
                  }
                  final p = pacientes[i - 1];
                  final nombre = p['nombre'] as String? ?? 'Sin nombre';
                  final doc    = p['documento'] as String? ?? '';
                  final mun    = p['municipio'] as String? ?? '';
                  return GestureDetector(
                    onTap: () {
                      pacienteSeleccionado = p;
                      Navigator.pop(ctx2);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                          color: _c(context).card,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _c(context).border)),
                      child: Row(children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: _kVerde.withOpacity(0.12),
                          child: Text(
                              nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
                              style: const TextStyle(color: _kVerde,
                                  fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(nombre,
                              style: TextStyle(color: _c(context).textPrimary,
                                  fontSize: 13, fontWeight: FontWeight.w600)),
                          if (doc.isNotEmpty || mun.isNotEmpty)
                            Text([if (doc.isNotEmpty) doc,
                                  if (mun.isNotEmpty) mun].join(' · '),
                                style: TextStyle(color: _c(context).textHint,
                                    fontSize: 11)),
                        ])),
                        Icon(Icons.chevron_right_rounded,
                            color: _c(context).textHint, size: 20),
                      ]),
                    ),
                  );
                },
              )),
            ]),
          ),
        ),
      );
    } else {
      pacienteSeleccionado = {};
    }

    if (!mounted || pacienteSeleccionado == null) return;

    Navigator.push(context, MaterialPageRoute(
      builder: (_) => FichaFormularioScreen(
        codigoFicha:    ficha.codigo,
        nombreFicha:    ficha.nombre,
        colorFicha:     ficha.color,
        emojiFicha:     ficha.emoji,
        datosPaciente:  pacienteSeleccionado!,
      ),
    ));
  }

  void _snack(String msg, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color ?? _kVerde,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 3),
    ));
  }

  // ═══════════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final dc      = _c(context);
    final fichas  = _fichasFiltradas;
    final urgentes = _kFichas.where((f) => f.esUrgente).length;

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
          Text('Fichas Epidemiológicas',
              style: TextStyle(color: dc.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
          const Text('Protocolos INS · SIVIGILA Colombia',
              style: TextStyle(color: _kVerde, fontSize: 10.5, fontWeight: FontWeight.w500)),
        ]),
        actions: [
          IconButton(
            tooltip: 'Fichas guardadas',
            icon: const Icon(Icons.folder_open_rounded),
            onPressed: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => const FichasReportesScreen())),
          ),
          // Mis fichas guardadas
          IconButton(
            tooltip: 'Mis fichas guardadas',
            icon: const Icon(Icons.folder_outlined, color: _kVerde),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const HistorialFichasScreen())),
          ),
          // Filtro urgentes
          GestureDetector(
            onTap: () => setState(() => _soloUrgentes = !_soloUrgentes),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _soloUrgentes ? _kRojo.withOpacity(0.15) : dc.bg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: _soloUrgentes ? _kRojo : dc.border,
                    width: _soloUrgentes ? 1.5 : 1),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.warning_rounded,
                    color: _soloUrgentes ? _kRojo : dc.textHint, size: 13),
                const SizedBox(width: 4),
                Text('Urgentes',
                    style: TextStyle(
                        color: _soloUrgentes ? _kRojo : dc.textHint,
                        fontSize: 10, fontWeight: FontWeight.w700)),
              ]),
            ),
          ),
        ],
      ),
      body: Column(children: [
        // ── Banner estadísticas ─────────────────────────────────────────
        Container(
          color: dc.card,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Row(children: [
            _StatBadge('${_kFichas.length}', 'Fichas\ntotales', _kAzul),
            const SizedBox(width: 10),
            _StatBadge('$urgentes', 'Notific.\ninmediata', _kRojo),
            const SizedBox(width: 10),
            _StatBadge('${_kCategorias.length - 1}', 'Catego-\nrías', _kVerde),
            const Spacer(),
            // Ícono INS
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                  color: _kAzul.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _kAzul.withOpacity(0.3))),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.verified_rounded, color: _kAzul, size: 14),
                const SizedBox(width: 5),
                Text('INS\nColombia',
                    style: const TextStyle(
                        color: _kAzul, fontSize: 9,
                        fontWeight: FontWeight.w700)),
              ]),
            ),
          ]),
        ),

        // ── Buscador ───────────────────────────────────────────────────
        Container(
          color: dc.card,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _busqueda = v),
            style: TextStyle(color: dc.textPrimary, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Buscar ficha: dengue, IRA, VIH, código...',
              hintStyle: TextStyle(color: dc.textHint, fontSize: 12),
              prefixIcon: Icon(Icons.search, color: dc.textHint, size: 18),
              suffixIcon: _busqueda.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.close, color: dc.textHint, size: 16),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _busqueda = '');
                      })
                  : null,
              filled: true, fillColor: dc.bg,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
            ),
          ),
        ),

        // ── Chips de categorías ────────────────────────────────────────
        Container(
          color: dc.card,
          height: 42,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            itemCount: _kCategorias.length,
            itemBuilder: (_, i) {
              final cat    = _kCategorias[i];
              final activo = cat.id == _categoriaActiva;
              return GestureDetector(
                onTap: () => setState(() => _categoriaActiva = cat.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: activo ? cat.color.withOpacity(0.15) : dc.bg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: activo ? cat.color : dc.border,
                        width: activo ? 1.5 : 1),
                  ),
                  child: Text('${cat.emoji} ${cat.nombre}',
                      style: TextStyle(
                          color: activo ? cat.color : dc.textSecondary,
                          fontSize: 11,
                          fontWeight: activo ? FontWeight.w700 : FontWeight.normal)),
                ),
              );
            },
          ),
        ),

        Divider(height: 1, color: dc.border),

        // ── Contador resultados ────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
          child: Row(children: [
            Text('${fichas.length} ficha${fichas.length == 1 ? '' : 's'} encontrada${fichas.length == 1 ? '' : 's'}',
                style: TextStyle(color: dc.textHint, fontSize: 12)),
            const Spacer(),
            if (_soloUrgentes)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: _kRojo.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20)),
                child: const Text('🚨 Solo urgentes',
                    style: TextStyle(color: _kRojo, fontSize: 10, fontWeight: FontWeight.bold))),
          ]),
        ),

        // ── Lista de fichas ────────────────────────────────────────────
        Expanded(
          child: fichas.isEmpty
              ? _buildVacio(dc)
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: fichas.length,
                  itemBuilder: (_, i) => _TarjetaFicha(
                    ficha: fichas[i],
                    dc: dc,
                    onTap: () => _abrirConPaciente(fichas[i]),
                    onVerDetalle: () => _mostrarDetalle(fichas[i]),
                  ),
                ),
        ),
      ]),
    );
  }

  Widget _buildVacio(DispersaludColors dc) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.find_in_page_outlined, color: dc.textHint, size: 52),
      const SizedBox(height: 12),
      Text('Sin fichas para esta búsqueda',
          style: TextStyle(color: dc.textPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
      const SizedBox(height: 6),
      Text('Intenta con otro término o categoría',
          style: TextStyle(color: dc.textHint, fontSize: 12)),
    ]),
  );

  // ── Modal de detalle / info antes de abrir PDF ────────────────────
  void _mostrarDetalle(_Ficha ficha) {
    final dc  = _c(context);
    final clr = ficha.color;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: BoxDecoration(
            color: dc.card,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22))),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Handle
          Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: dc.border, borderRadius: BorderRadius.circular(2))),

          // Header
          Row(children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                  color: clr.withOpacity(0.13),
                  borderRadius: BorderRadius.circular(14)),
              child: Center(child: Text(ficha.emoji,
                  style: const TextStyle(fontSize: 30)))),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                      color: clr.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6)),
                  child: Text('Código: ${ficha.codigo}',
                      style: TextStyle(color: clr, fontSize: 10, fontWeight: FontWeight.bold))),
                const SizedBox(width: 6),
                if (ficha.esUrgente)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                        color: _kRojo.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6)),
                    child: const Text('🚨 Inmediata',
                        style: TextStyle(color: _kRojo, fontSize: 10, fontWeight: FontWeight.bold))),
              ]),
              const SizedBox(height: 6),
              Text(ficha.nombre,
                  style: TextStyle(color: dc.textPrimary,
                      fontSize: 15, fontWeight: FontWeight.bold)),
            ])),
          ]),
          const SizedBox(height: 16),

          // Descripción
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: clr.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: clr.withOpacity(0.2))),
            child: Text(ficha.descripcionCorta,
                style: TextStyle(color: dc.textPrimary, fontSize: 13, height: 1.5)),
          ),
          const SizedBox(height: 12),

          // Notificación + categoría
          Row(children: [
            Expanded(child: _InfoRow(
              icon: Icons.notifications_active_rounded,
              label: 'Notificación',
              value: ficha.notificacion,
              color: ficha.esUrgente ? _kRojo : _kNaranja,
              dc: dc,
            )),
            const SizedBox(width: 10),
            Expanded(child: _InfoRow(
              icon: Icons.category_rounded,
              label: 'Categoría',
              value: _kCategorias.firstWhere((c) => c.id == ficha.categoria,
                  orElse: () => _kCategorias[0]).nombre,
              color: _kAzul,
              dc: dc,
            )),
          ]),
          const SizedBox(height: 16),

          // Botón llenar formulario SIVIGILA
          SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _abrirConPaciente(ficha);
              },
              icon: const Icon(Icons.edit_note_rounded, color: Colors.white, size: 22),
              label: const Text('Llenar formulario SIVIGILA',
                  style: TextStyle(color: Colors.white,
                      fontWeight: FontWeight.bold, fontSize: 15)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: clr, elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
            ),
          ),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  WIDGETS AUXILIARES
// ═══════════════════════════════════════════════════════════════════════════

/// Tarjeta de cada ficha en la lista
class _TarjetaFicha extends StatelessWidget {
  final _Ficha   ficha;
  final DispersaludColors dc;
  final VoidCallback onTap;
  final VoidCallback onVerDetalle;

  const _TarjetaFicha({
    required this.ficha, required this.dc,
    required this.onTap, required this.onVerDetalle,
  });

  @override
  Widget build(BuildContext context) {
    final clr = ficha.color;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
          color: dc.card,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
              color: ficha.esUrgente ? clr.withOpacity(0.4) : dc.border)),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(13),
          onTap: onVerDetalle,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              // Emoji / ícono
              Container(
                width: 46, height: 46,
                decoration: BoxDecoration(
                    color: clr.withOpacity(0.11),
                    borderRadius: BorderRadius.circular(12)),
                child: Center(child: Text(ficha.emoji,
                    style: const TextStyle(fontSize: 22)))),
              const SizedBox(width: 12),

              // Contenido
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Nombre + badge urgente
                Row(children: [
                  Expanded(child: Text(ficha.nombre,
                      style: TextStyle(color: dc.textPrimary,
                          fontSize: 13, fontWeight: FontWeight.bold),
                      maxLines: 2, overflow: TextOverflow.ellipsis)),
                  if (ficha.esUrgente) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                          color: _kRojo.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6)),
                      child: const Text('🚨',
                          style: TextStyle(fontSize: 11))),
                  ],
                ]),
                const SizedBox(height: 3),
                // Descripción corta
                Text(ficha.descripcionCorta,
                    style: TextStyle(color: dc.textSecondary, fontSize: 11),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 5),
                // Footer: código + notificación + PDF btn
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                        color: clr.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(6)),
                    child: Text(ficha.codigo,
                        style: TextStyle(color: clr, fontSize: 10, fontWeight: FontWeight.bold))),
                  const SizedBox(width: 6),
                  Icon(Icons.notifications_rounded,
                      color: ficha.esUrgente ? _kRojo : dc.textHint, size: 11),
                  const SizedBox(width: 3),
                  Text(ficha.notificacion,
                      style: TextStyle(
                          color: ficha.esUrgente ? _kRojo : dc.textHint,
                          fontSize: 10)),
                  const Spacer(),
                  // Botón llenar formulario
                  GestureDetector(
                    onTap: onTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                          color: clr.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: clr.withOpacity(0.25))),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.edit_note_rounded, color: clr, size: 13),
                        const SizedBox(width: 4),
                        Text('Llenar',
                            style: TextStyle(color: clr,
                                fontSize: 10, fontWeight: FontWeight.w700)),
                      ]),
                    ),
                  ),
                ]),
              ])),
            ]),
          ),
        ),
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String valor, label;
  final Color  color;
  const _StatBadge(this.valor, this.label, this.color);

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(valor, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold)),
      Text(label, style: TextStyle(color: _c(context).textHint, fontSize: 9.5, height: 1.2)),
    ],
  );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  final DispersaludColors dc;
  const _InfoRow({required this.icon, required this.label, required this.value,
      required this.color, required this.dc});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2))),
    child: Row(children: [
      Icon(icon, color: color, size: 16),
      const SizedBox(width: 8),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(color: dc.textHint, fontSize: 9.5)),
        Text(value, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
      ])),
    ]),
  );
}