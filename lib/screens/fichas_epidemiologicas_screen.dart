// lib/screens/fichas_epidemiologicas_screen.dart
//
// Pantalla de Fichas Epidemiológicas — DISPERSALUD IA
// Muestra el catálogo de protocolos del INS, permite buscar y filtrar,
// y abre cada PDF desde los assets con open_filex.
// ─────────────────────────────────────────────────────────────────────────────
// SETUP REQUERIDO:
//   1. Copiar los PDFs del RAR a:   assets/protocolos/  (ver lista _kFichas)
//   2. En pubspec.yaml, bajo assets:
//        - assets/protocolos/
//   3. Dependencias ya presentes: open_filex, path_provider
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import '../core/app_theme.dart';
import 'ficha_formulario_screen.dart';
import 'historial_fichas_screen.dart';
import 'fichas_reportes_screen.dart';

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
  final String archivoAsset;   // ruta dentro de assets/
  final String categoria;
  final String emoji;
  final Color  color;
  final String descripcionCorta;
  final String notificacion;   // inmediata / 24h / semanal
  final bool   esUrgente;

  const _Ficha({
    required this.codigo,
    required this.nombre,
    required this.archivoAsset,
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
//  archivoAsset = nombre exacto del PDF dentro de assets/protocolos/
const List<_Ficha> _kFichas = [
  // ── VECTORES ─────────────────────────────────────────────────────────────
  _Ficha(
    codigo: 'DEN', nombre: 'Dengue / Dengue grave',
    archivoAsset: 'assets/protocolos/Pro_Dengue.pdf',
    categoria: 'vectores', emoji: '🦟', color: Color(0xFF3B6D11),
    descripcionCorta: 'Enfermedad viral por Aedes aegypti. Notificación inmediata.',
    notificacion: 'Inmediata', esUrgente: true,
  ),
  _Ficha(
    codigo: 'CHIK', nombre: 'Chikunguña',
    archivoAsset: 'assets/protocolos/Pro_Chikungunya 2024.pdf',
    categoria: 'vectores', emoji: '🦟', color: Color(0xFF3B6D11),
    descripcionCorta: 'Arbovirus. Artralgia severa característica.',
    notificacion: '24 horas',
  ),
  _Ficha(
    codigo: 'ZIKA', nombre: 'Zika',
    archivoAsset: 'assets/protocolos/Pro_Zika 2024.pdf',
    categoria: 'vectores', emoji: '🦟', color: Color(0xFF3B6D11),
    descripcionCorta: 'Riesgo de microcefalia en embarazadas. Notificación urgente.',
    notificacion: 'Inmediata', esUrgente: true,
  ),
  _Ficha(
    codigo: 'MAL', nombre: 'Malaria',
    archivoAsset: 'assets/protocolos/Pro_Malaria 2024.pdf',
    categoria: 'vectores', emoji: '🦠', color: Color(0xFF3B6D11),
    descripcionCorta: 'Parasitosis por Plasmodium. Alta mortalidad en forma grave.',
    notificacion: 'Inmediata', esUrgente: true,
  ),
  _Ficha(
    codigo: 'LEISH', nombre: 'Leishmaniasis',
    archivoAsset: 'assets/protocolos/Pro_Leishmaniasis.pdf',
    categoria: 'vectores', emoji: '🦠', color: Color(0xFF3B6D11),
    descripcionCorta: 'Transmitida por flebótomos. Endémica en zonas selváticas.',
    notificacion: '24 horas',
  ),
  _Ficha(
    codigo: 'FIAM', nombre: 'Fiebre amarilla',
    archivoAsset: 'assets/protocolos/Pro_Fiebre amarilla 2024.pdf',
    categoria: 'vectores', emoji: '🟡', color: Color(0xFF3B6D11),
    descripcionCorta: 'Arbovirus. Caso único es emergencia de salud pública.',
    notificacion: 'Inmediata', esUrgente: true,
  ),
  _Ficha(
    codigo: 'CHAG', nombre: 'Enfermedad de Chagas',
    archivoAsset: 'assets/protocolos/Pro_Chagas 2022.pdf',
    categoria: 'vectores', emoji: '🐜', color: Color(0xFF3B6D11),
    descripcionCorta: 'Tripanosomiasis americana. Transmitida por pito/chipo.',
    notificacion: '24 horas',
  ),
  _Ficha(
    codigo: 'ENCEF', nombre: 'Encefalitis equina',
    archivoAsset: 'assets/protocolos/Pro_Encefalitis equina 2024.pdf',
    categoria: 'vectores', emoji: '🐴', color: Color(0xFF3B6D11),
    descripcionCorta: 'Arbovirus transmitido por mosquitos. Vigilancia en equinos.',
    notificacion: 'Inmediata', esUrgente: true,
  ),

  // ── RESPIRATORIAS ─────────────────────────────────────────────────────────
  _Ficha(
    codigo: 'IRA', nombre: 'IRA — Infección Respiratoria Aguda',
    archivoAsset: 'assets/protocolos/Pro_IRA 2024.pdf',
    categoria: 'respira', emoji: '🫁', color: _kMorado,
    descripcionCorta: 'Principal causa de mortalidad infantil en menores de 5 años.',
    notificacion: 'Semanal',
  ),
  _Ficha(
    codigo: 'TUB', nombre: 'Tuberculosis',
    archivoAsset: 'assets/protocolos/Pro_Tuberculosis 2022.pdf',
    categoria: 'respira', emoji: '🦠', color: _kMorado,
    descripcionCorta: 'Notificación individual obligatoria. Búsqueda activa de sintomáticos.',
    notificacion: '24 horas',
  ),
  _Ficha(
    codigo: 'TUBFR', nombre: 'Tuberculosis farmacorresistente',
    archivoAsset: 'assets/protocolos/PRO_Tuberculosis_farmacorresistente.pdf',
    categoria: 'respira', emoji: '⚠️', color: _kMorado,
    descripcionCorta: 'TB-MDR y TB-XDR. Protocolo especial de manejo.',
    notificacion: 'Inmediata', esUrgente: true,
  ),
  _Ficha(
    codigo: 'COVID', nombre: 'COVID-19',
    archivoAsset: 'assets/protocolos/PRO_COVID-19.pdf',
    categoria: 'respira', emoji: '😷', color: _kMorado,
    descripcionCorta: 'Vigilancia centinela y IRAG. Protocolo INS actualizado.',
    notificacion: '24 horas',
  ),
  _Ficha(
    codigo: 'TOS', nombre: 'Tos ferina (Pertussis)',
    archivoAsset: 'assets/protocolos/Pro_Tos ferina 2024.pdf',
    categoria: 'respira', emoji: '😮', color: _kMorado,
    descripcionCorta: 'Alta mortalidad en menores de 1 año no vacunados.',
    notificacion: 'Inmediata', esUrgente: true,
  ),
  _Ficha(
    codigo: 'DIFT', nombre: 'Difteria',
    archivoAsset: 'assets/protocolos/Pro_Difteria.pdf',
    categoria: 'respira', emoji: '🤒', color: _kMorado,
    descripcionCorta: 'Inmunoprevenible. Cualquier caso es emergencia epidemiológica.',
    notificacion: 'Inmediata', esUrgente: true,
  ),
  _Ficha(
    codigo: 'MPOX', nombre: 'Mpox (Viruela del mono)',
    archivoAsset: 'assets/protocolos/Pro_MPOX 2024.pdf',
    categoria: 'respira', emoji: '🔴', color: _kMorado,
    descripcionCorta: 'Vigilancia de casos sospechosos. Aislamiento de contactos.',
    notificacion: 'Inmediata', esUrgente: true,
  ),

  // ── INMUNOPREVENIBLES ─────────────────────────────────────────────────────
  _Ficha(
    codigo: 'VAR', nombre: 'Varicela',
    archivoAsset: 'assets/protocolos/Pro_Varicela.pdf',
    categoria: 'inmuno', emoji: '💉', color: _kAzul,
    descripcionCorta: 'Vigilancia de brotes. Notificación de casos hospitalizados.',
    notificacion: '24 horas',
  ),
  _Ficha(
    codigo: 'RUBE', nombre: 'Rubéola / Síndrome rubéola congénita',
    archivoAsset: 'assets/protocolos/Pro_Sarampión_Rubeola.pdf',
    categoria: 'inmuno', emoji: '🔴', color: _kAzul,
    descripcionCorta: 'Meta de eliminación en Colombia. Cualquier caso: notificación inmediata.',
    notificacion: 'Inmediata', esUrgente: true,
  ),
  _Ficha(
    codigo: 'PAROT', nombre: 'Parotiditis',
    archivoAsset: 'assets/protocolos/Pro_Parotiditis 2024.pdf',
    categoria: 'inmuno', emoji: '🤒', color: _kAzul,
    descripcionCorta: 'Vigilancia de brotes en instituciones educativas y comunidades.',
    notificacion: '24 horas',
  ),
  _Ficha(
    codigo: 'EAPV', nombre: 'Eventos Adversos Post-Vacunación (EAPV)',
    archivoAsset: 'assets/protocolos/298_EAPV_2024.pdf',
    categoria: 'inmuno', emoji: '⚕️', color: _kAzul,
    descripcionCorta: 'Reacciones adversas a biológicos del PAI. Notificación obligatoria.',
    notificacion: '24 horas',
  ),

  // ── ITS / VIH ─────────────────────────────────────────────────────────────
  _Ficha(
    codigo: 'VIH', nombre: 'VIH/SIDA',
    archivoAsset: 'assets/protocolos/Pro_VIH.pdf',
    categoria: 'its', emoji: '🔬', color: Color(0xFF993556),
    descripcionCorta: 'Notificación individual. Diagnóstico, tratamiento y adherencia.',
    notificacion: '24 horas',
  ),
  _Ficha(
    codigo: 'HEPATB', nombre: 'Hepatitis B y C',
    archivoAsset: 'assets/protocolos/Pro Hepatitis B y C.pdf',
    categoria: 'its', emoji: '🫀', color: Color(0xFF993556),
    descripcionCorta: 'Vigilancia de hepatitis virales. Énfasis en gestantes y recién nacidos.',
    notificacion: '24 horas',
  ),
  _Ficha(
    codigo: 'HEPA', nombre: 'Hepatitis A',
    archivoAsset: 'assets/protocolos/Pro_hepatitis A 2024.pdf',
    categoria: 'its', emoji: '🫀', color: Color(0xFF993556),
    descripcionCorta: 'Transmisión feco-oral. Vigilancia de brotes por agua y alimentos.',
    notificacion: '24 horas',
  ),
  _Ficha(
    codigo: 'SFILIS', nombre: 'Sífilis gestacional y congénita',
    archivoAsset: 'assets/protocolos/Pro_Sífilis Gestacional y Congénita 2024.pdf',
    categoria: 'its', emoji: '🤰', color: Color(0xFF993556),
    descripcionCorta: 'Caso de sífilis congénita: notificación inmediata. Meta eliminación.',
    notificacion: 'Inmediata', esUrgente: true,
  ),

  // ── ALIMENTOS / AGUA ──────────────────────────────────────────────────────
  _Ficha(
    codigo: 'EDA', nombre: 'EDA — Enfermedad Diarreica Aguda',
    archivoAsset: 'assets/protocolos/Pro_EDA 2024.pdf',
    categoria: 'alimentos', emoji: '💧', color: Color(0xFF0F6E56),
    descripcionCorta: 'Principal causa de consulta infantil. Vigilancia de brotes.',
    notificacion: 'Semanal',
  ),
  _Ficha(
    codigo: 'ETA', nombre: 'ETA — Enfermedades Transmitidas por Alimentos',
    archivoAsset: 'assets/protocolos/Pro_ETA 2022.pdf',
    categoria: 'alimentos', emoji: '🍽️', color: Color(0xFF0F6E56),
    descripcionCorta: 'Brotes por consumo de alimentos contaminados. Notificación de brotes.',
    notificacion: 'Inmediata', esUrgente: true,
  ),
  _Ficha(
    codigo: 'FIT', nombre: 'Fiebre tifoidea y paratifoidea',
    archivoAsset: 'assets/protocolos/Pro_Fiebre tifoidea y paratifoidea.pdf',
    categoria: 'alimentos', emoji: '🌡️', color: Color(0xFF0F6E56),
    descripcionCorta: 'Salmonella typhi. Fuente hídrica o alimentaria. Notificación obligatoria.',
    notificacion: '24 horas',
  ),
  _Ficha(
    codigo: 'LEPR', nombre: 'Lepra',
    archivoAsset: 'assets/protocolos/Pro_Lepra 2024.pdf',
    categoria: 'alimentos', emoji: '🦠', color: Color(0xFF0F6E56),
    descripcionCorta: 'Mycobacterium leprae. Vigilancia activa. Tratamiento multidroga.',
    notificacion: '24 horas',
  ),

  // ── ZOONOSIS ──────────────────────────────────────────────────────────────
  _Ficha(
    codigo: 'RABIA', nombre: 'Rabia humana y animal',
    archivoAsset: 'assets/protocolos/Pro_Vigilancia Integrada Rabia.pdf',
    categoria: 'zoonosis', emoji: '🐾', color: Color(0xFF854F0B),
    descripcionCorta: '100% letal sin tratamiento. Todo accidente ofídico: notificación inmediata.',
    notificacion: 'Inmediata', esUrgente: true,
  ),
  _Ficha(
    codigo: 'LEPT', nombre: 'Leptospirosis',
    archivoAsset: 'assets/protocolos/Pro_Leptospirosis 2024.pdf',
    categoria: 'zoonosis', emoji: '🐀', color: Color(0xFF854F0B),
    descripcionCorta: 'Transmitida por orina de roedores. Alta mortalidad en forma ictérica.',
    notificacion: '24 horas',
  ),
  _Ficha(
    codigo: 'OFID', nombre: 'Accidente ofídico / Animales venenosos',
    archivoAsset: 'assets/protocolos/Pro_AO_Venenosos_2024.pdf',
    categoria: 'zoonosis', emoji: '🐍', color: Color(0xFF854F0B),
    descripcionCorta: 'Envenenamiento por serpientes, arañas, escorpiones. Antídoto urgente.',
    notificacion: 'Inmediata', esUrgente: true,
  ),
  _Ficha(
    codigo: 'TRAC', nombre: 'Tracoma',
    archivoAsset: 'assets/protocolos/Pro_Tracoma 2022.pdf',
    categoria: 'zoonosis', emoji: '👁️', color: Color(0xFF854F0B),
    descripcionCorta: 'Infección ocular por Chlamydia. Meta de eliminación OPS.',
    notificacion: '24 horas',
  ),

  // ── MATERNA / PERINATAL ───────────────────────────────────────────────────
  _Ficha(
    codigo: 'MME', nombre: 'Mortalidad materna extrema (MME)',
    archivoAsset: 'assets/protocolos/Pro_MME 2024.pdf',
    categoria: 'materna', emoji: '🤰', color: Color(0xFF993556),
    descripcionCorta: 'Vigilancia de la morbilidad materna extrema. Análisis de caso obligatorio.',
    notificacion: 'Inmediata', esUrgente: true,
  ),
  _Ficha(
    codigo: 'MM', nombre: 'Mortalidad materna — Análisis de caso',
    archivoAsset: 'assets/protocolos/550_MM_Analisis_Caso.pdf',
    categoria: 'materna', emoji: '📋', color: Color(0xFF993556),
    descripcionCorta: 'Ficha de análisis de caso de muerte materna. INS 2024.',
    notificacion: 'Inmediata', esUrgente: true,
  ),
  _Ficha(
    codigo: 'MMAUT', nombre: 'Mortalidad materna — Autopsia verbal',
    archivoAsset: 'assets/protocolos/550_MM_Autopsia_Verbal.pdf',
    categoria: 'materna', emoji: '📋', color: Color(0xFF993556),
    descripcionCorta: 'Instrumento de autopsia verbal para muerte materna.',
    notificacion: 'Inmediata', esUrgente: true,
  ),
  _Ficha(
    codigo: 'MMEMB', nombre: 'Mortalidad materna — Verificación embarazo',
    archivoAsset: 'assets/protocolos/550_MM_Verificacion_Embarazo.pdf',
    categoria: 'materna', emoji: '📋', color: Color(0xFF993556),
    descripcionCorta: 'Ficha de verificación de embarazo en muerte materna.',
    notificacion: 'Inmediata', esUrgente: true,
  ),
  _Ficha(
    codigo: 'MMFAM', nombre: 'Mortalidad materna — Entrevista familiar',
    archivoAsset: 'assets/protocolos/550_MM_Entrevista_Familiar.pdf',
    categoria: 'materna', emoji: '📋', color: Color(0xFF993556),
    descripcionCorta: 'Guía de entrevista a familia en caso de muerte materna.',
    notificacion: 'Inmediata', esUrgente: true,
  ),
  _Ficha(
    codigo: 'MORTPER', nombre: 'Mortalidad perinatal',
    archivoAsset: 'assets/protocolos/Pro_Mortalidad perinatal.pdf',
    categoria: 'materna', emoji: '👶', color: Color(0xFF993556),
    descripcionCorta: 'Vigilancia de muertes perinatales. Análisis e intervención.',
    notificacion: 'Inmediata', esUrgente: true,
  ),

  // ── LESIONES / VIOLENCIA ──────────────────────────────────────────────────
  _Ficha(
    codigo: 'VIO', nombre: 'Lesiones por causa externa / Violencia',
    archivoAsset: 'assets/protocolos/Pro_Lesiones de causa externa 2024.pdf',
    categoria: 'lesiones', emoji: '🚨', color: _kRojo,
    descripcionCorta: 'Violencia de género, intrafamiliar y lesiones no intencionales.',
    notificacion: '24 horas',
  ),
  _Ficha(
    codigo: 'SUIC', nombre: 'Intento de suicidio',
    archivoAsset: 'assets/protocolos/Pro_Intento de suicidio.pdf',
    categoria: 'lesiones', emoji: '🆘', color: _kRojo,
    descripcionCorta: 'Notificación individual. Atención y seguimiento obligatorio.',
    notificacion: '24 horas', esUrgente: true,
  ),
  _Ficha(
    codigo: 'MAP', nombre: 'Lesiones por minas antipersona (MAP/MUSE)',
    archivoAsset: 'assets/protocolos/Pro_ Lesiones por artefactos - MAP - MUSE.pdf',
    categoria: 'lesiones', emoji: '💥', color: _kRojo,
    descripcionCorta: 'Vigilancia de víctimas de MAP y MUSE. Notificación inmediata.',
    notificacion: 'Inmediata', esUrgente: true,
  ),
  _Ficha(
    codigo: 'POLV', nombre: 'Lesiones por pólvora',
    archivoAsset: 'assets/protocolos/Pro_Lesiones por artefactos - Polvora.pdf',
    categoria: 'lesiones', emoji: '🧨', color: _kRojo,
    descripcionCorta: 'Vigilancia especial en temporadas de fiestas. Notificación obligatoria.',
    notificacion: '24 horas',
  ),
  _Ficha(
    codigo: 'INT', nombre: 'Intoxicaciones agudas (IAPMQ)',
    archivoAsset: 'assets/protocolos/Pro_IAPMQ.pdf',
    categoria: 'lesiones', emoji: '☠️', color: _kRojo,
    descripcionCorta: 'Intoxicaciones por plaguicidas, medicamentos y sustancias químicas.',
    notificacion: 'Inmediata', esUrgente: true,
  ),
  _Ficha(
    codigo: 'IAD', nombre: 'Intoxicación por alcohol y drogas (IAD)',
    archivoAsset: 'assets/protocolos/Pro_IAD 2024.pdf',
    categoria: 'lesiones', emoji: '🍶', color: _kRojo,
    descripcionCorta: 'Vigilancia de consumo de SPA. Articulado con políticas de salud mental.',
    notificacion: '24 horas',
  ),

  // ── CRÓNICAS / OTRAS ──────────────────────────────────────────────────────
  _Ficha(
    codigo: 'MENING', nombre: 'Meningitis',
    archivoAsset: 'assets/protocolos/Pro_Meningitis 2024.pdf',
    categoria: 'cronicas', emoji: '🧠', color: Color(0xFF5F5E5A),
    descripcionCorta: 'Cualquier caso de meningitis bacteriana: notificación inmediata.',
    notificacion: 'Inmediata', esUrgente: true,
  ),
  _Ficha(
    codigo: 'IAAS', nombre: 'Infecciones Asociadas a Atención en Salud (IAAS)',
    archivoAsset: 'assets/protocolos/Pro_IAAS 2024.pdf',
    categoria: 'cronicas', emoji: '🏥', color: Color(0xFF5F5E5A),
    descripcionCorta: 'Vigilancia de infecciones nosocomiales. Protocolo de bioseguridad.',
    notificacion: 'Semanal',
  ),
  _Ficha(
    codigo: 'RESB', nombre: 'Resistencia bacteriana a antibióticos',
    archivoAsset: 'assets/protocolos/Pro_Resistencia bacteriana 2022.pdf',
    categoria: 'cronicas', emoji: '🔬', color: Color(0xFF5F5E5A),
    descripcionCorta: 'Vigilancia centinela de cepas multirresistentes.',
    notificacion: 'Semanal',
  ),
  _Ficha(
    codigo: 'ANTIB', nombre: 'Consumo de antibióticos',
    archivoAsset: 'assets/protocolos/Pro_Consumo de antibioticos.pdf',
    categoria: 'cronicas', emoji: '💊', color: Color(0xFF5F5E5A),
    descripcionCorta: 'Uso racional de antibióticos. Indicadores de consumo hospitalario.',
    notificacion: 'Semanal',
  ),
  _Ficha(
    codigo: 'ENF_HUERFANAS', nombre: 'Enfermedades huérfanas / raras',
    archivoAsset: 'assets/protocolos/Pro_Enfermedades huerfanas.pdf',
    categoria: 'cronicas', emoji: '🧬', color: Color(0xFF5F5E5A),
    descripcionCorta: 'Registro de enfermedades raras y huérfanas. SISPRO.',
    notificacion: 'Semanal',
  ),
  _Ficha(
    codigo: 'CANCER', nombre: 'Cáncer de mama y cuello uterino',
    archivoAsset: 'assets/protocolos/Pro_Cáncer de mama y cuello uterino 2024.pdf',
    categoria: 'cronicas', emoji: '🎗️', color: Color(0xFF5F5E5A),
    descripcionCorta: 'Tamizaje y vigilancia. Registro de casos confirmados.',
    notificacion: 'Semanal',
  ),
  _Ficha(
    codigo: 'TETAN_A', nombre: 'Tétanos accidental',
    archivoAsset: 'assets/protocolos/Pro_tétanos accidental 2024.pdf',
    categoria: 'cronicas', emoji: '💉', color: Color(0xFF5F5E5A),
    descripcionCorta: 'Inmunoprevenible. Cualquier caso confirmado: notificación inmediata.',
    notificacion: 'Inmediata', esUrgente: true,
  ),
  _Ficha(
    codigo: 'TETAN_N', nombre: 'Tétanos neonatal',
    archivoAsset: 'assets/protocolos/Pro_tétanos neonatal 2024.pdf',
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
  String? _abriendo;          // codigo del que se está abriendo (spinner)

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

  // ── Abrir PDF desde assets ───────────────────────────────────────────────
  Future<void> _abrirPDF(_Ficha ficha) async {
    setState(() => _abriendo = ficha.codigo);
    try {
      // Copiar el asset a un directorio temporal para que open_filex lo abra
      final byteData = await rootBundle.load(ficha.archivoAsset);
      final tmpDir   = await getTemporaryDirectory();
      final fileName = ficha.archivoAsset.split('/').last;
      final file     = File('${tmpDir.path}/$fileName');
      await file.writeAsBytes(
          byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));

      final result = await OpenFilex.open(file.path);
      if (result.type != ResultType.done && mounted) {
        _snack('No se pudo abrir el PDF. ¿Tienes un lector instalado?',
            color: _kNaranja);
      }
    } catch (e) {
      if (mounted) {
        _snack('PDF no disponible aún. Cópialo a assets/protocolos/', color: _kNaranja);
      }
    } finally {
      if (mounted) setState(() => _abriendo = null);
    }
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
                    cargando: _abriendo == fichas[i].codigo,
                    onTap: () => _abrirPDF(fichas[i]),
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
  void _abrirFormulario(_Ficha ficha) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => FichaFormularioScreen(
        codigoFicha: ficha.codigo,
        nombreFicha: ficha.nombre,
        colorFicha:  ficha.color,
        emojiFicha:  ficha.emoji,
      ),
    ));
  }

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

          // Nota del archivo
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: dc.bg, borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              const Icon(Icons.picture_as_pdf_rounded, color: _kRojo, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(
                  'Documento: ${ficha.archivoAsset.split('/').last}',
                  style: TextStyle(color: dc.textHint, fontSize: 10.5),
                  maxLines: 2, overflow: TextOverflow.ellipsis)),
            ]),
          ),
          const SizedBox(height: 16),

          // Botón llenar formulario
          SizedBox(
            width: double.infinity, height: 48,
            child: ElevatedButton.icon(
              onPressed: () { Navigator.pop(context); _abrirFormulario(ficha); },
              icon: const Icon(Icons.edit_note_rounded, color: Colors.white, size: 20),
              label: const Text('Llenar formulario SIVIGILA',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: clr, elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            ),
          ),
          const SizedBox(height: 8),
          // Botón ver PDF de referencia
          SizedBox(
            width: double.infinity, height: 44,
            child: OutlinedButton.icon(
              onPressed: _abriendo == ficha.codigo
                  ? null
                  : () { Navigator.pop(context); _abrirPDF(ficha); },
              icon: _abriendo == ficha.codigo
                  ? const SizedBox(width: 14, height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.picture_as_pdf_rounded, size: 16),
              label: Text(_abriendo == ficha.codigo ? 'Abriendo…' : 'Ver protocolo PDF (INS)',
                  style: const TextStyle(fontWeight: FontWeight.w500)),
              style: OutlinedButton.styleFrom(
                  side: BorderSide(color: clr),
                  foregroundColor: clr,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
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
  final bool     cargando;
  final VoidCallback onTap;
  final VoidCallback onVerDetalle;

  const _TarjetaFicha({
    required this.ficha, required this.dc, required this.cargando,
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
                  // Botón abrir PDF
                  GestureDetector(
                    onTap: cargando ? null : onTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                          color: _kRojo.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _kRojo.withOpacity(0.25))),
                      child: cargando
                          ? const SizedBox(width: 14, height: 14,
                              child: CircularProgressIndicator(color: _kRojo, strokeWidth: 2))
                          : const Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(Icons.picture_as_pdf_rounded, color: _kRojo, size: 13),
                              SizedBox(width: 4),
                              Text('Abrir PDF',
                                  style: TextStyle(color: _kRojo,
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