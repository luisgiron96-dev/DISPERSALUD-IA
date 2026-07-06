import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../core/responsive.dart';

DispersaludColors _c(BuildContext ctx) =>
    Theme.of(ctx).extension<DispersaludColors>() ?? DispersaludColors.dark;

const Color _kVerde  = Color(0xFF1D9E75);
const Color _kDark   = Color(0xFF0F6E56);

// ─────────────────────────────────────────────────────────────────────────────
// DATOS DEL BOTIQUÍN — Protocolos Ministerio de Salud Colombia / OPS
// ─────────────────────────────────────────────────────────────────────────────
const List<Map<String, dynamic>> _kMedicamentos = [
  // ── ANALGÉSICOS / ANTIPIRÉTICOS ───────────────────────────────────────
  {
    'nombre': 'Acetaminofén (Paracetamol)',
    'categoria': 'Analgésico / Antipirético',
    'emoji': '💊',
    'color': 0xFF1D9E75,
    'presentaciones': ['Tabletas 500 mg', 'Jarabe 150 mg/5 mL', 'Gotas 100 mg/mL'],
    'indicaciones': 'Fiebre, dolor leve a moderado, cefalea, dolor muscular.',
    'dosis': [
      {'grupo': 'Adultos',         'dosis': '500–1000 mg cada 6–8 h', 'max': 'Máx 4 g/día'},
      {'grupo': 'Niños 1–12 años', 'dosis': '10–15 mg/kg cada 6–8 h', 'max': 'Máx 60 mg/kg/día'},
      {'grupo': 'Lactantes',       'dosis': '10–15 mg/kg cada 6–8 h', 'max': 'Según peso, gotas'},
    ],
    'contraindicaciones': 'Insuficiencia hepática grave. Evitar alcohol durante el tratamiento.',
    'alertas': 'No superar dosis máxima. Riesgo de toxicidad hepática en sobredosis.',
    'nivel': 'basico',
  },
  {
    'nombre': 'Ibuprofeno',
    'categoria': 'Analgésico / Antiinflamatorio',
    'emoji': '💊',
    'color': 0xFF185FA5,
    'presentaciones': ['Tabletas 200 mg', 'Tabletas 400 mg', 'Suspensión 100 mg/5 mL'],
    'indicaciones': 'Dolor, fiebre, inflamación, dismenorrea, cefalea.',
    'dosis': [
      {'grupo': 'Adultos',         'dosis': '200–400 mg cada 6–8 h', 'max': 'Máx 1200 mg/día automedicación'},
      {'grupo': 'Niños > 6 meses', 'dosis': '5–10 mg/kg cada 6–8 h', 'max': 'Máx 40 mg/kg/día'},
    ],
    'contraindicaciones': 'Úlcera péptica, insuficiencia renal, último trimestre de embarazo.',
    'alertas': '⚠️ NO usar en embarazadas. Tomar con alimentos. Precaución en adultos mayores.',
    'nivel': 'basico',
  },
  // ── ANTIBIÓTICOS ──────────────────────────────────────────────────────
  {
    'nombre': 'Amoxicilina',
    'categoria': 'Antibiótico',
    'emoji': '🔬',
    'color': 0xFF993556,
    'presentaciones': ['Cápsulas 500 mg', 'Suspensión 250 mg/5 mL'],
    'indicaciones': 'Infecciones respiratorias, OMA, faringoamigdalitis, IVU no complicada.',
    'dosis': [
      {'grupo': 'Adultos',    'dosis': '500 mg cada 8 h × 7–10 días', 'max': ''},
      {'grupo': 'Niños',      'dosis': '25–50 mg/kg/día ÷ cada 8 h',  'max': 'Máx 3 g/día'},
      {'grupo': 'Neumonía',   'dosis': '80–90 mg/kg/día ÷ cada 12 h', 'max': 'Dosis alta'},
    ],
    'contraindicaciones': 'Alergia a penicilinas. Mononucleosis (riesgo de exantema).',
    'alertas': '⚠️ Verificar alergia antes de administrar. Completar el esquema completo.',
    'nivel': 'prescripcion',
  },
  {
    'nombre': 'Trimetoprim/Sulfametoxazol (TMP/SMX)',
    'categoria': 'Antibiótico',
    'emoji': '🔬',
    'color': 0xFF993556,
    'presentaciones': ['Tabletas 80/400 mg', 'Tabletas 160/800 mg (forte)', 'Suspensión 40/200 mg/5 mL'],
    'indicaciones': 'IVU no complicada, diarrea bacteriana, otitis media aguda.',
    'dosis': [
      {'grupo': 'Adultos (IVU)',   'dosis': '1 tableta forte cada 12 h × 3–7 días', 'max': ''},
      {'grupo': 'Niños',           'dosis': '8/40 mg/kg/día ÷ cada 12 h × 10 días', 'max': ''},
    ],
    'contraindicaciones': 'Alergia a sulfonamidas. Embarazo (1er y 3er trimestre). Insuficiencia renal grave.',
    'alertas': '⚠️ Hidratación adecuada. Suspender si aparece exantema.',
    'nivel': 'prescripcion',
  },
  {
    'nombre': 'Metronidazol',
    'categoria': 'Antibiótico / Antiparasitario',
    'emoji': '🔬',
    'color': 0xFF534AB7,
    'presentaciones': ['Tabletas 250 mg', 'Tabletas 500 mg', 'Suspensión 125 mg/5 mL'],
    'indicaciones': 'Giardiasis, amebiasis, tricomoniasis, infecciones anaerobias, vaginosis bacteriana.',
    'dosis': [
      {'grupo': 'Adultos (Giardia)',   'dosis': '250 mg cada 8 h × 5–7 días', 'max': ''},
      {'grupo': 'Adultos (Amebiasis)', 'dosis': '500–750 mg cada 8 h × 5–10 días', 'max': ''},
      {'grupo': 'Niños',               'dosis': '15–35 mg/kg/día ÷ cada 8 h', 'max': 'Según indicación'},
    ],
    'contraindicaciones': 'Primer trimestre de embarazo. Evitar alcohol durante y 48h después del tratamiento.',
    'alertas': '⚠️ No consumir alcohol. Puede causar sabor metálico y náuseas.',
    'nivel': 'prescripcion',
  },
  // ── ANTIPARASITARIOS ──────────────────────────────────────────────────
  {
    'nombre': 'Albendazol',
    'categoria': 'Antiparasitario',
    'emoji': '🦠',
    'color': 0xFF854F0B,
    'presentaciones': ['Tabletas 200 mg', 'Suspensión 200 mg/5 mL'],
    'indicaciones': 'Parasitosis intestinales: áscaris, uncinaria, trichuris, enterobiasis.',
    'dosis': [
      {'grupo': 'Adultos y niños > 2 años', 'dosis': '400 mg dosis única', 'max': 'Repetir a los 15 días si persiste'},
      {'grupo': 'Niños 1–2 años',           'dosis': '200 mg dosis única', 'max': ''},
    ],
    'contraindicaciones': 'Menores de 1 año. Embarazo (especialmente 1er trimestre).',
    'alertas': 'Tomar con alimentos grasos para mejor absorción. Programa de desparasitación cada 6 meses.',
    'nivel': 'basico',
  },
  {
    'nombre': 'Mebendazol',
    'categoria': 'Antiparasitario',
    'emoji': '🦠',
    'color': 0xFF854F0B,
    'presentaciones': ['Tabletas 100 mg', 'Suspensión 100 mg/5 mL'],
    'indicaciones': 'Oxiuros, áscaris, trichuris, anquilostoma.',
    'dosis': [
      {'grupo': 'Adultos y niños > 2 años', 'dosis': '100 mg cada 12 h × 3 días', 'max': 'O 500 mg dosis única'},
      {'grupo': 'Oxiuros',                  'dosis': '100 mg dosis única',         'max': 'Repetir a las 2 semanas'},
    ],
    'contraindicaciones': 'Menores de 2 años. Embarazo.',
    'alertas': 'Tratar a toda la familia simultáneamente en caso de oxiuros.',
    'nivel': 'basico',
  },
  // ── SALES DE REHIDRATACIÓN ────────────────────────────────────────────
  {
    'nombre': 'Sales de Rehidratación Oral (SRO)',
    'categoria': 'Rehidratación',
    'emoji': '💧',
    'color': 0xFF0F6E56,
    'presentaciones': ['Sobre 27.9 g para 1 litro de agua'],
    'indicaciones': 'Diarrea aguda, vómito, deshidratación leve a moderada en todas las edades.',
    'dosis': [
      {'grupo': 'Menores 2 años',  'dosis': '50–100 mL después de cada deposición', 'max': 'Plan B OMS si hay signos de deshidratación'},
      {'grupo': 'Niños 2–10 años', 'dosis': '100–200 mL después de cada deposición', 'max': ''},
      {'grupo': 'Adultos',         'dosis': 'A libre demanda según sed y pérdidas', 'max': ''},
    ],
    'contraindicaciones': 'Deshidratación grave (requiere hidratación IV). Vómito incoercible.',
    'alertas': '🚨 Si hay signos de deshidratación grave: referir URGENTE. Preparar con agua limpia hervida.',
    'nivel': 'basico',
  },
  // ── ANTIHISTAMÍNICOS ──────────────────────────────────────────────────
  {
    'nombre': 'Loratadina',
    'categoria': 'Antihistamínico',
    'emoji': '🌿',
    'color': 0xFF3B6D11,
    'presentaciones': ['Tabletas 10 mg', 'Jarabe 5 mg/5 mL'],
    'indicaciones': 'Rinitis alérgica, urticaria, reacciones alérgicas leves.',
    'dosis': [
      {'grupo': 'Adultos y niños > 12 años', 'dosis': '10 mg una vez al día', 'max': ''},
      {'grupo': 'Niños 2–12 años (> 30 kg)', 'dosis': '10 mg una vez al día', 'max': ''},
      {'grupo': 'Niños 2–12 años (≤ 30 kg)', 'dosis': '5 mg una vez al día',  'max': ''},
    ],
    'contraindicaciones': 'Hipersensibilidad a loratadina.',
    'alertas': 'No causa somnolencia significativa. Puede tomarse con o sin alimentos.',
    'nivel': 'basico',
  },
  // ── ANTIHIPERTENSIVOS ─────────────────────────────────────────────────
  {
    'nombre': 'Enalapril',
    'categoria': 'Antihipertensivo (IECA)',
    'emoji': '❤️',
    'color': 0xFFE24B4A,
    'presentaciones': ['Tabletas 5 mg', 'Tabletas 10 mg', 'Tabletas 20 mg'],
    'indicaciones': 'Hipertensión arterial, insuficiencia cardíaca, nefropatía diabética.',
    'dosis': [
      {'grupo': 'Adultos (HTA)',  'dosis': '5–10 mg una vez al día', 'max': 'Máx 40 mg/día'},
      {'grupo': 'Ajuste renal',   'dosis': 'Reducir dosis si hay insuficiencia renal', 'max': ''},
    ],
    'contraindicaciones': '⚠️ CONTRAINDICADO en embarazo (2do y 3er trimestre). Angioedema previo por IECA. Estenosis bilateral de arterias renales.',
    'alertas': '🚨 Nunca usar en embarazo. Monitorear potasio y función renal. Tos seca es efecto común.',
    'nivel': 'prescripcion',
  },
  {
    'nombre': 'Amlodipino',
    'categoria': 'Antihipertensivo (Calcioantagonista)',
    'emoji': '❤️',
    'color': 0xFFE24B4A,
    'presentaciones': ['Tabletas 5 mg', 'Tabletas 10 mg'],
    'indicaciones': 'Hipertensión arterial, angina de pecho.',
    'dosis': [
      {'grupo': 'Adultos', 'dosis': '5 mg una vez al día', 'max': 'Máx 10 mg/día'},
    ],
    'contraindicaciones': 'Hipersensibilidad a dihidropiridinas. Shock cardiogénico.',
    'alertas': 'Puede causar edema en tobillos. Tomar a la misma hora cada día.',
    'nivel': 'prescripcion',
  },
  // ── ANTIDIABÉTICOS ────────────────────────────────────────────────────
  {
    'nombre': 'Metformina',
    'categoria': 'Antidiabético',
    'emoji': '🩺',
    'color': 0xFF534AB7,
    'presentaciones': ['Tabletas 500 mg', 'Tabletas 850 mg', 'Tabletas 1000 mg'],
    'indicaciones': 'Diabetes mellitus tipo 2. Primera línea de tratamiento.',
    'dosis': [
      {'grupo': 'Adultos (inicio)', 'dosis': '500 mg cada 12 h con comidas', 'max': 'Aumentar gradualmente'},
      {'grupo': 'Mantenimiento',    'dosis': '850–1000 mg cada 12 h',       'max': 'Máx 2550 mg/día'},
    ],
    'contraindicaciones': 'Insuficiencia renal (TFG < 30). Insuficiencia hepática. Alcoholismo.',
    'alertas': 'Tomar con alimentos. Suspender ante procedimientos con contraste. Riesgo de acidosis láctica si hay insuficiencia renal.',
    'nivel': 'prescripcion',
  },
  // ── VITAMINAS / SUPLEMENTOS ───────────────────────────────────────────
  {
    'nombre': 'Ácido Fólico',
    'categoria': 'Vitamina / Suplemento',
    'emoji': '🌟',
    'color': 0xFFEF9F27,
    'presentaciones': ['Tabletas 0.4 mg (400 mcg)', 'Tabletas 1 mg', 'Tabletas 5 mg'],
    'indicaciones': 'Prevención defectos del tubo neural. Embarazo. Anemia megaloblástica.',
    'dosis': [
      {'grupo': 'Prevención (preconcepcional)', 'dosis': '0.4–0.8 mg/día',  'max': 'Iniciar 1–3 meses antes del embarazo'},
      {'grupo': 'Embarazo',                     'dosis': '0.4–1 mg/día',    'max': 'Todo el embarazo'},
      {'grupo': 'Alto riesgo (ant. DTN)',        'dosis': '4–5 mg/día',     'max': 'Con indicación médica'},
    ],
    'contraindicaciones': 'No se conocen contraindicaciones absolutas a dosis habituales.',
    'alertas': 'Suplemento esencial en todas las gestantes. Incluido en control prenatal.',
    'nivel': 'basico',
  },
  {
    'nombre': 'Sulfato Ferroso',
    'categoria': 'Vitamina / Suplemento',
    'emoji': '🌟',
    'color': 0xFFEF9F27,
    'presentaciones': ['Tabletas 300 mg (60 mg hierro elemental)', 'Jarabe 125 mg/5 mL'],
    'indicaciones': 'Anemia ferropénica, suplementación en embarazo, prevención en niños.',
    'dosis': [
      {'grupo': 'Adultos (tratamiento)',  'dosis': '150–200 mg hierro elemental/día ÷ 2–3 dosis', 'max': ''},
      {'grupo': 'Embarazo (prevención)',  'dosis': '30–60 mg hierro elemental/día',               'max': ''},
      {'grupo': 'Niños (tratamiento)',    'dosis': '3–6 mg/kg/día hierro elemental',              'max': 'Máx 200 mg/día'},
    ],
    'contraindicaciones': 'Hemocromatosis. Anemia no ferropénica.',
    'alertas': 'Tomar en ayunas o con vitamina C para mejor absorción. Puede causar estreñimiento y heces oscuras (normal).',
    'nivel': 'basico',
  },
  // ── ANTICONCEPTIVOS ───────────────────────────────────────────────────
  {
    'nombre': 'Anticonceptivos Orales Combinados',
    'categoria': 'Anticoncepción',
    'emoji': '🔵',
    'color': 0xFF993556,
    'presentaciones': ['Tabletas 28 días (21 activas + 7 placebo)', 'Tabletas 21 días'],
    'indicaciones': 'Anticoncepción hormonal. Regulación menstrual. Dismenorrea.',
    'dosis': [
      {'grupo': 'Adultas', 'dosis': '1 tableta diaria a la misma hora', 'max': 'Sin interrupciones'},
    ],
    'contraindicaciones': 'Trombosis venosa. HTA no controlada. Migraña con aura. Tabaquismo > 35 años. Lactancia < 6 semanas posparto.',
    'alertas': '⚠️ Orientar sobre tomar a la misma hora. Si olvida tableta: instrucciones según ficha. No protege contra ITS.',
    'nivel': 'prescripcion',
  },
  // ── EMERGENCIAS ───────────────────────────────────────────────────────
  {
    'nombre': 'Sulfato de Magnesio',
    'categoria': '🚨 Emergencia Obstétrica',
    'emoji': '🚨',
    'color': 0xFFE24B4A,
    'presentaciones': ['Ampolla 20% (2 g/10 mL)', 'Ampolla 50% (5 g/10 mL)'],
    'indicaciones': 'Prevención y tratamiento de eclampsia. Preeclampsia severa.',
    'dosis': [
      {'grupo': 'Carga IV', 'dosis': '4–6 g en 250 mL SSN en 20 min',        'max': 'Solo personal capacitado'},
      {'grupo': 'Mantenimiento', 'dosis': '1–2 g/hora IV en bomba de infusión', 'max': 'Por 24 h postparto/convulsión'},
      {'grupo': 'IM (sin bomba)', 'dosis': '10 g IM (5 g en cada glúteo)',    'max': 'Protocolo rural'},
    ],
    'contraindicaciones': 'Bloqueo cardíaco. Insuficiencia renal grave. Depresión respiratoria.',
    'alertas': '🚨 EMERGENCIA. Monitorear: reflejo patelar, frecuencia respiratoria > 12/min, diuresis > 25 mL/h. Antídoto: gluconato de calcio 1 g IV.',
    'nivel': 'emergencia',
  },
  {
    'nombre': 'Oxitocina',
    'categoria': '🚨 Emergencia Obstétrica',
    'emoji': '🚨',
    'color': 0xFFE24B4A,
    'presentaciones': ['Ampolla 10 UI/mL'],
    'indicaciones': 'Manejo activo del 3er período del parto. Prevención y tratamiento de hemorragia postparto.',
    'dosis': [
      {'grupo': 'MATEP (profilaxis)', 'dosis': '10 UI IM inmediatamente tras nacimiento', 'max': 'Protocolo OMS'},
      {'grupo': 'HPP (tratamiento)',  'dosis': '10–20 UI en 500 mL SSN IV rápido',        'max': 'Solo personal capacitado'},
    ],
    'contraindicaciones': 'No usar para inducción sin indicación médica. Precaución en cesárea anterior.',
    'alertas': '🚨 Solo personal capacitado. Conservar en cadena de frío 2–8°C. Primera línea en HPP.',
    'nivel': 'emergencia',
  },

  // ── ANTIFÚNGICOS ──────────────────────────────────────────────────────
  {
    'nombre': 'Fluconazol',
    'categoria': 'Antifúngico',
    'emoji': '🍄',
    'color': 0xFF534AB7,
    'presentaciones': ['Cápsulas 150 mg', 'Cápsulas 50 mg', 'Suspensión 10 mg/mL'],
    'indicaciones': 'Candidiasis vaginal, oral (muguet), esofágica. Tiña versicolor sistémica.',
    'dosis': [
      {'grupo': 'Candidiasis vaginal', 'dosis': '150 mg dosis única oral', 'max': ''},
      {'grupo': 'Candidiasis oral',    'dosis': '50–100 mg/día × 7–14 días', 'max': ''},
      {'grupo': 'Niños',               'dosis': '3–6 mg/kg/día × 7–14 días', 'max': 'Máx 400 mg/día'},
    ],
    'contraindicaciones': 'Embarazo (1er trimestre). Uso con terfenadina o cisaprida.',
    'alertas': 'Puede causar hepatotoxicidad. Verificar interacciones con otros medicamentos.',
    'nivel': 'prescripcion',
  },
  {
    'nombre': 'Clotrimazol Tópico',
    'categoria': 'Antifúngico',
    'emoji': '🍄',
    'color': 0xFF534AB7,
    'presentaciones': ['Crema 1%', 'Óvulos vaginales 100 mg', 'Óvulos vaginales 500 mg', 'Solución tópica 1%'],
    'indicaciones': 'Candidiasis cutánea, vaginal, tiña pedis, corporis, cruris, versicolor.',
    'dosis': [
      {'grupo': 'Tópico cutáneo',      'dosis': 'Aplicar 2–3 veces/día × 2–4 semanas', 'max': ''},
      {'grupo': 'Vaginal (óvulo 100)', 'dosis': '1 óvulo intravaginal × 7 noches',      'max': ''},
      {'grupo': 'Vaginal (óvulo 500)', 'dosis': '1 óvulo intravaginal dosis única',      'max': ''},
    ],
    'contraindicaciones': 'Hipersensibilidad al clotrimazol. No aplicar en ojos.',
    'alertas': 'Puede debilitar condones de látex. Continuar tratamiento durante la menstruación.',
    'nivel': 'basico',
  },
  {
    'nombre': 'Nistatina',
    'categoria': 'Antifúngico',
    'emoji': '🍄',
    'color': 0xFF534AB7,
    'presentaciones': ['Suspensión oral 100.000 UI/mL', 'Óvulos 100.000 UI', 'Crema tópica'],
    'indicaciones': 'Candidiasis oral (muguet) en lactantes y niños. Candidiasis cutánea e intertriginosa.',
    'dosis': [
      {'grupo': 'Lactantes (oral)',    'dosis': '100.000 UI 4 veces/día × 7–14 días', 'max': 'Aplicar en boca con hisopo'},
      {'grupo': 'Niños/Adultos (oral)', 'dosis': '400.000–600.000 UI 4 veces/día',    'max': 'Retener en boca antes de tragar'},
      {'grupo': 'Tópico',              'dosis': 'Aplicar 2–3 veces/día',              'max': ''},
    ],
    'contraindicaciones': 'Hipersensibilidad a nistatina.',
    'alertas': 'No se absorbe por vía oral — solo actúa localmente. Muy seguro en lactantes.',
    'nivel': 'basico',
  },

  // ── ANTIÁCIDOS / PROTECTORES GÁSTRICOS ───────────────────────────────
  {
    'nombre': 'Omeprazol',
    'categoria': 'Inhibidor de Bomba de Protones',
    'emoji': '🫀',
    'color': 0xFF0F6E56,
    'presentaciones': ['Cápsulas 20 mg', 'Cápsulas 40 mg'],
    'indicaciones': 'Úlcera péptica, ERGE, gastritis por H. pylori, protección gástrica con AINEs.',
    'dosis': [
      {'grupo': 'Adultos (ERGE/úlcera)', 'dosis': '20 mg una vez al día × 4–8 semanas', 'max': 'En ayunas, 30 min antes del desayuno'},
      {'grupo': 'H. pylori (triple)',     'dosis': '20 mg cada 12 h + 2 antibióticos × 14 días', 'max': ''},
      {'grupo': 'Niños > 1 año',          'dosis': '0.7–1.5 mg/kg/día',                 'max': 'Máx 20 mg/día'},
    ],
    'contraindicaciones': 'Uso crónico sin indicación. Hipersensibilidad a benzimidazoles.',
    'alertas': 'Uso prolongado asociado a déficit de magnesio, vitamina B12 y mayor riesgo de fracturas.',
    'nivel': 'basico',
  },
  {
    'nombre': 'Ranitidina / Famotidina',
    'categoria': 'Antihistamínico H2 / Antiácido',
    'emoji': '🫀',
    'color': 0xFF0F6E56,
    'presentaciones': ['Famotidina tabletas 20 mg', 'Famotidina tabletas 40 mg'],
    'indicaciones': 'Úlcera duodenal y gástrica, ERGE leve, dispepsia, hiperacidez.',
    'dosis': [
      {'grupo': 'Adultos (úlcera)',    'dosis': '40 mg en la noche × 4–8 semanas', 'max': ''},
      {'grupo': 'Adultos (ERGE leve)', 'dosis': '20 mg cada 12 h',                 'max': ''},
      {'grupo': 'Niños',               'dosis': '0.5 mg/kg cada 12 h',             'max': 'Máx 40 mg/día'},
    ],
    'contraindicaciones': 'Insuficiencia renal grave (ajustar dosis). Hipersensibilidad.',
    'alertas': 'Ranitidina retirada del mercado (NDMA). Usar famotidina como alternativa.',
    'nivel': 'basico',
  },
  {
    'nombre': 'Hidróxido de Aluminio/Magnesio',
    'categoria': 'Antiácido',
    'emoji': '🫀',
    'color': 0xFF0F6E56,
    'presentaciones': ['Suspensión oral', 'Tabletas masticables'],
    'indicaciones': 'Acidez, pirosis, dispepsia, gastritis leve, síntomas de ERGE.',
    'dosis': [
      {'grupo': 'Adultos',  'dosis': '10–20 mL o 1–2 tabletas 3–4 veces/día', 'max': 'Entre comidas y al acostarse'},
      {'grupo': 'Niños',    'dosis': '5–10 mL 3–4 veces/día',                 'max': 'Según edad y peso'},
    ],
    'contraindicaciones': 'Insuficiencia renal (riesgo de hipermagnesemia). Obstrucción intestinal.',
    'alertas': 'Puede reducir absorción de otros medicamentos. Administrar 2h separado de otros fármacos.',
    'nivel': 'basico',
  },

  // ── CORTICOIDES ───────────────────────────────────────────────────────
  {
    'nombre': 'Prednisolona / Prednisona',
    'categoria': 'Corticoide Sistémico',
    'emoji': '⚡',
    'color': 0xFFEF9F27,
    'presentaciones': ['Tabletas 5 mg', 'Tabletas 20 mg', 'Tabletas 50 mg', 'Solución oral 5 mg/5 mL'],
    'indicaciones': 'Crisis asmática, reacciones alérgicas graves, síndrome nefrótico, enfermedades autoinmunes, crup laríngeo.',
    'dosis': [
      {'grupo': 'Crisis asmática adultos',  'dosis': '40–60 mg/día × 5–7 días',      'max': ''},
      {'grupo': 'Crisis asmática niños',    'dosis': '1–2 mg/kg/día × 3–5 días',     'max': 'Máx 40 mg/día'},
      {'grupo': 'Crup (dosis única)',        'dosis': '0.6 mg/kg dosis única oral',   'max': 'Máx 10 mg'},
      {'grupo': 'Reacción alérgica grave',  'dosis': '1 mg/kg/día × 3–5 días',       'max': ''},
    ],
    'contraindicaciones': 'Infecciones sistémicas sin tratamiento. Úlcera péptica activa. Diabetes descompensada.',
    'alertas': '⚠️ No suspender abruptamente en tratamientos prolongados. Monitorear glucemia en diabéticos. Riesgo de inmunosupresión.',
    'nivel': 'prescripcion',
  },
  {
    'nombre': 'Dexametasona',
    'categoria': 'Corticoide Sistémico',
    'emoji': '⚡',
    'color': 0xFFEF9F27,
    'presentaciones': ['Ampolla 4 mg/mL', 'Ampolla 8 mg/2mL', 'Tabletas 0.5 mg', 'Tabletas 4 mg'],
    'indicaciones': 'Edema cerebral, crup severo, shock séptico, náuseas postoperatorias, maduración pulmonar fetal (24–34 sem).',
    'dosis': [
      {'grupo': 'Maduración pulmonar fetal', 'dosis': '6 mg IM cada 12 h × 4 dosis', 'max': 'Entre sem 24–34 amenaza parto prematuro'},
      {'grupo': 'Crup severo',               'dosis': '0.6 mg/kg IM/IV dosis única', 'max': 'Máx 10 mg'},
      {'grupo': 'Edema cerebral',            'dosis': '10 mg IV luego 4 mg cada 6 h', 'max': 'Solo personal capacitado'},
    ],
    'contraindicaciones': 'Infecciones micóticas sistémicas. Hipersensibilidad a corticosteroides.',
    'alertas': '🚨 Maduración pulmonar fetal: iniciar ante amenaza de parto prematuro 24–34 semanas. Referir inmediatamente.',
    'nivel': 'emergencia',
  },
  {
    'nombre': 'Beclometasona Inhalada',
    'categoria': 'Corticoide Inhalado',
    'emoji': '💨',
    'color': 0xFFEF9F27,
    'presentaciones': ['Inhalador 50 mcg/dosis', 'Inhalador 100 mcg/dosis', 'Inhalador 250 mcg/dosis'],
    'indicaciones': 'Asma persistente leve, moderada y severa. Tratamiento de mantenimiento.',
    'dosis': [
      {'grupo': 'Adultos (leve)',    'dosis': '100–200 mcg cada 12 h',  'max': 'Máx 800 mcg/día'},
      {'grupo': 'Adultos (moderada)', 'dosis': '200–400 mcg cada 12 h', 'max': ''},
      {'grupo': 'Niños',              'dosis': '50–100 mcg cada 12 h',  'max': 'Máx 400 mcg/día'},
    ],
    'contraindicaciones': 'Crisis asmática aguda (usar broncodilatador). Hipersensibilidad.',
    'alertas': 'Enjuagar boca después de cada inhalación para prevenir candidiasis oral. Es tratamiento de mantenimiento, NO rescate.',
    'nivel': 'prescripcion',
  },

  // ── BRONCODILATADORES ─────────────────────────────────────────────────
  {
    'nombre': 'Salbutamol (Albuterol)',
    'categoria': 'Broncodilatador β2',
    'emoji': '💨',
    'color': 0xFF185FA5,
    'presentaciones': ['Inhalador 100 mcg/dosis (MDI)', 'Solución para nebulizar 5 mg/mL', 'Jarabe 2 mg/5 mL', 'Tabletas 2 mg'],
    'indicaciones': 'Crisis asmática, broncoespasmo, EPOC agudizado, sibilancias en lactantes.',
    'dosis': [
      {'grupo': 'Crisis (inhalador adultos)', 'dosis': '2–4 puffs cada 20 min × 3 veces, luego cada 4 h', 'max': 'Con espaciador'},
      {'grupo': 'Crisis (nebulización)',      'dosis': '2.5 mg en 3 mL SSN cada 20 min × 3',             'max': ''},
      {'grupo': 'Niños (inhalador)',           'dosis': '2 puffs cada 4–6 h según necesidad',             'max': 'Siempre con espaciador'},
      {'grupo': 'Mantenimiento oral',          'dosis': '2–4 mg cada 6–8 h',                              'max': ''},
    ],
    'contraindicaciones': 'Taquicardia severa. Hipersensibilidad a salbutamol.',
    'alertas': '⚠️ Si requiere > 1 canister/mes: asma NO controlada — referir. Puede causar temblor y taquicardia.',
    'nivel': 'basico',
  },

  // ── ANTIHIPERTENSIVOS EMBARAZO ────────────────────────────────────────
  {
    'nombre': 'Metildopa',
    'categoria': 'Antihipertensivo (Embarazo)',
    'emoji': '🤰',
    'color': 0xFF993556,
    'presentaciones': ['Tabletas 250 mg', 'Tabletas 500 mg'],
    'indicaciones': 'Hipertensión arterial en embarazo. Primera línea en HTA crónica gestacional.',
    'dosis': [
      {'grupo': 'Embarazadas (inicio)', 'dosis': '250 mg cada 8 h',  'max': 'Aumentar según respuesta'},
      {'grupo': 'Mantenimiento',        'dosis': '500 mg cada 6–8 h', 'max': 'Máx 3 g/día'},
    ],
    'contraindicaciones': 'Hepatitis activa. Depresión severa. Feocromocitoma.',
    'alertas': '✅ SEGURO en embarazo — primera línea. Puede causar somnolencia y boca seca. Monitorear PA regularmente.',
    'nivel': 'prescripcion',
  },
  {
    'nombre': 'Nifedipino (Acción Corta)',
    'categoria': 'Antihipertensivo (Urgencia Obstétrica)',
    'emoji': '🤰',
    'color': 0xFFE24B4A,
    'presentaciones': ['Cápsulas 10 mg', 'Tabletas liberación prolongada 30 mg'],
    'indicaciones': 'Crisis hipertensiva en embarazo (PA ≥ 160/110). Tocolisis (amenaza de parto prematuro).',
    'dosis': [
      {'grupo': 'Crisis HTA gestacional', 'dosis': '10 mg oral, repetir cada 30 min si PA ≥ 160/110', 'max': 'Máx 3 dosis. Referir urgente'},
      {'grupo': 'Tocolisis',              'dosis': '20 mg oral, luego 10–20 mg cada 4–8 h',           'max': 'Solo bajo supervisión'},
    ],
    'contraindicaciones': 'NO usar sublingual (hipotensión severa). Shock cardiovascular.',
    'alertas': '🚨 NUNCA sublingual en embarazo — riesgo de hipotensión brusca y muerte fetal. Solo vía oral. Referir URGENTE.',
    'nivel': 'emergencia',
  },
  {
    'nombre': 'Hidralazina',
    'categoria': 'Antihipertensivo (Urgencia Obstétrica)',
    'emoji': '🤰',
    'color': 0xFFE24B4A,
    'presentaciones': ['Ampolla 20 mg/mL'],
    'indicaciones': 'Crisis hipertensiva severa en embarazo y puerperio cuando no hay respuesta a nifedipino.',
    'dosis': [
      {'grupo': 'IV lento', 'dosis': '5 mg IV lento en 5 min, repetir cada 20 min', 'max': 'Máx 20 mg. Solo personal capacitado'},
    ],
    'contraindicaciones': 'Lupus eritematoso sistémico. Cardiopatía isquémica severa.',
    'alertas': '🚨 Solo personal capacitado. Monitorear PA cada 5 min. Tener disponible líquidos IV ante hipotensión.',
    'nivel': 'emergencia',
  },

  // ── ANTICONVULSIVANTES ────────────────────────────────────────────────
  {
    'nombre': 'Diazepam',
    'categoria': 'Anticonvulsivante / Ansiolítico',
    'emoji': '🧠',
    'color': 0xFF534AB7,
    'presentaciones': ['Ampolla 10 mg/2 mL', 'Tabletas 5 mg', 'Tabletas 10 mg', 'Solución rectal 5 mg/2.5 mL'],
    'indicaciones': 'Convulsiones agudas, estado epiléptico, abstinencia alcohólica, ansiedad severa.',
    'dosis': [
      {'grupo': 'Convulsión adultos (IV)',  'dosis': '5–10 mg IV lento (2 mg/min)',    'max': 'Repetir cada 10–15 min. Máx 30 mg'},
      {'grupo': 'Convulsión niños (IV)',    'dosis': '0.2–0.3 mg/kg IV lento',         'max': 'Máx 10 mg por dosis'},
      {'grupo': 'Convulsión niños (rectal)', 'dosis': '0.5 mg/kg rectal si no hay vía', 'max': 'Opción prehospitalaria'},
    ],
    'contraindicaciones': 'Depresión respiratoria. Miastenia gravis. Glaucoma de ángulo cerrado.',
    'alertas': '🚨 Tener equipo de resucitación disponible. Puede causar depresión respiratoria. Antídoto: Flumazenil.',
    'nivel': 'emergencia',
  },
  {
    'nombre': 'Fenobarbital',
    'categoria': 'Anticonvulsivante',
    'emoji': '🧠',
    'color': 0xFF534AB7,
    'presentaciones': ['Tabletas 100 mg', 'Ampolla 200 mg/mL'],
    'indicaciones': 'Epilepsia (mantenimiento), convulsiones febriles, estado epiléptico refractario.',
    'dosis': [
      {'grupo': 'Adultos (mantenimiento)', 'dosis': '60–180 mg/día en 1–2 dosis', 'max': ''},
      {'grupo': 'Niños (mantenimiento)',   'dosis': '3–5 mg/kg/día',              'max': ''},
      {'grupo': 'Estado epiléptico (IV)',  'dosis': '20 mg/kg IV a 100 mg/min',   'max': 'Solo personal capacitado'},
    ],
    'contraindicaciones': 'Porfiria. Depresión respiratoria severa. Hipersensibilidad a barbitúricos.',
    'alertas': '⚠️ Inductor enzimático potente — interacciones múltiples. Somnolencia intensa. No suspender abruptamente.',
    'nivel': 'prescripcion',
  },

  // ── ANTIDIARREICOS / DIGESTIVOS ───────────────────────────────────────
  {
    'nombre': 'Zinc (Suplemento)',
    'categoria': 'Digestivo / Suplemento',
    'emoji': '🔩',
    'color': 0xFF3B6D11,
    'presentaciones': ['Tabletas dispersables 20 mg', 'Jarabe 10 mg/5 mL'],
    'indicaciones': 'Tratamiento complementario de diarrea aguda en niños. Prevención de diarrea recurrente.',
    'dosis': [
      {'grupo': 'Niños < 6 meses', 'dosis': '10 mg/día × 10–14 días', 'max': 'Junto con SRO'},
      {'grupo': 'Niños > 6 meses', 'dosis': '20 mg/día × 10–14 días', 'max': 'Junto con SRO'},
    ],
    'contraindicaciones': 'No se conocen contraindicaciones a dosis terapéuticas en niños.',
    'alertas': '✅ OMS recomienda zinc + SRO en toda diarrea infantil. Reduce duración y severidad.',
    'nivel': 'basico',
  },
  {
    'nombre': 'Loperamida',
    'categoria': 'Antidiarreico',
    'emoji': '💊',
    'color': 0xFF3B6D11,
    'presentaciones': ['Cápsulas 2 mg', 'Solución oral 1 mg/5 mL'],
    'indicaciones': 'Diarrea aguda no infecciosa en adultos. Diarrea crónica.',
    'dosis': [
      {'grupo': 'Adultos', 'dosis': '4 mg dosis inicial, luego 2 mg tras cada deposición', 'max': 'Máx 16 mg/día'},
    ],
    'contraindicaciones': '⚠️ NO usar en niños < 2 años. NO usar en diarrea con sangre o fiebre alta (posible colitis). NO en cólera.',
    'alertas': 'En diarrea infecciosa bacteriana puede prolongar la enfermedad. Si no mejora en 48h: buscar causa.',
    'nivel': 'basico',
  },

  // ── VITAMINAS ADICIONALES ─────────────────────────────────────────────
  {
    'nombre': 'Vitamina A',
    'categoria': 'Vitamina / Suplemento',
    'emoji': '🌟',
    'color': 0xFFEF9F27,
    'presentaciones': ['Cápsulas 100.000 UI', 'Cápsulas 200.000 UI'],
    'indicaciones': 'Prevención y tratamiento de deficiencia de vitamina A. Complemento en sarampión y diarrea severa.',
    'dosis': [
      {'grupo': 'Niños 6–11 meses',  'dosis': '100.000 UI dosis única cada 4–6 meses', 'max': 'Programa PAI'},
      {'grupo': 'Niños 1–5 años',    'dosis': '200.000 UI dosis única cada 4–6 meses', 'max': ''},
      {'grupo': 'Sarampión (niños)', 'dosis': '200.000 UI por 2 días consecutivos',     'max': ''},
    ],
    'contraindicaciones': 'Hipervitaminosis A. Embarazo (altas dosis teratogénicas).',
    'alertas': '⚠️ NO dar altas dosis en embarazo. Parte del programa de micronutrientes en menores de 5 años.',
    'nivel': 'basico',
  },
  {
    'nombre': 'Vitamina D3 (Colecalciferol)',
    'categoria': 'Vitamina / Suplemento',
    'emoji': '🌟',
    'color': 0xFFEF9F27,
    'presentaciones': ['Gotas 400 UI/gota', 'Cápsulas 1000 UI', 'Cápsulas 5000 UI'],
    'indicaciones': 'Prevención y tratamiento de raquitismo, osteoporosis, déficit de vitamina D.',
    'dosis': [
      {'grupo': 'Lactantes (prevención)',  'dosis': '400 UI/día desde el nacimiento',   'max': 'Hasta que consuma 1 L leche/día'},
      {'grupo': 'Niños y adultos',         'dosis': '600–1000 UI/día',                  'max': ''},
      {'grupo': 'Adultos mayores',         'dosis': '800–2000 UI/día',                  'max': 'Con calcio para osteoporosis'},
    ],
    'contraindicaciones': 'Hipercalcemia. Hipervitaminosis D. Sarcoidosis.',
    'alertas': 'Déficit muy común en zonas rurales con baja exposición solar. Considerar en adultos mayores.',
    'nivel': 'basico',
  },
  {
    'nombre': 'Calcio (Carbonato de Calcio)',
    'categoria': 'Vitamina / Suplemento',
    'emoji': '🦴',
    'color': 0xFFEF9F27,
    'presentaciones': ['Tabletas 500 mg (calcio elemental)', 'Tabletas 600 mg', 'Suspensión'],
    'indicaciones': 'Osteoporosis, prevención de preeclampsia en embarazo, hipocalcemia, antiácido.',
    'dosis': [
      {'grupo': 'Osteoporosis adultos',      'dosis': '1000–1200 mg/día ÷ 2 dosis',   'max': 'Con vitamina D'},
      {'grupo': 'Embarazo (preeclampsia)',   'dosis': '1.5–2 g/día ÷ 3 dosis',        'max': 'OMS: desde semana 20'},
      {'grupo': 'Como antiácido',            'dosis': '500 mg 2–4 veces/día',          'max': 'Entre comidas'},
    ],
    'contraindicaciones': 'Hipercalcemia. Nefrolitiasis cálcica. Insuficiencia renal grave.',
    'alertas': 'Separar 2h de hierro (inhiben absorción mutua). Tomar carbonato de calcio con comidas.',
    'nivel': 'basico',
  },

  // ── ANTIPALÚDICOS ─────────────────────────────────────────────────────
  {
    'nombre': 'Cloroquina',
    'categoria': 'Antipalúdico',
    'emoji': '🦟',
    'color': 0xFF185FA5,
    'presentaciones': ['Tabletas 150 mg base', 'Tabletas 250 mg fosfato'],
    'indicaciones': 'Malaria por P. vivax y P. malariae sensible. Profilaxis en zonas endémicas.',
    'dosis': [
      {'grupo': 'Tratamiento adultos', 'dosis': '600 mg base día 1, 300 mg día 2 y 3', 'max': 'Total 1500 mg base'},
      {'grupo': 'Tratamiento niños',   'dosis': '10 mg base/kg día 1, 5 mg/kg días 2–3', 'max': ''},
      {'grupo': 'Profilaxis',          'dosis': '300 mg base semanal',                  'max': 'Iniciar 1–2 sem antes viaje'},
    ],
    'contraindicaciones': 'Retinopatía. Epilepsia no controlada. Porfiria.',
    'alertas': '⚠️ Alta resistencia de P. falciparum en Colombia. Para P. falciparum usar artemisina. Notificar al SIVIGILA.',
    'nivel': 'prescripcion',
  },
  {
    'nombre': 'Primaquina',
    'categoria': 'Antipalúdico',
    'emoji': '🦟',
    'color': 0xFF185FA5,
    'presentaciones': ['Tabletas 5 mg base', 'Tabletas 15 mg base'],
    'indicaciones': 'Erradicación de hipnozoítos de P. vivax y P. ovale (previene recaídas). Gametocidas en P. falciparum.',
    'dosis': [
      {'grupo': 'P. vivax (adultos)', 'dosis': '0.25–0.5 mg/kg/día × 14 días', 'max': 'Siempre con cloroquina'},
      {'grupo': 'Niños',              'dosis': '0.25 mg/kg/día × 14 días',      'max': ''},
    ],
    'contraindicaciones': '⚠️ CONTRAINDICADO en embarazo. Déficit de G6PD (riesgo de hemólisis grave).',
    'alertas': '🚨 Descartar déficit de G6PD antes de administrar. Puede causar hemólisis severa. Nunca en embarazo.',
    'nivel': 'prescripcion',
  },

  // ── ANTITUBERCULOSOS ──────────────────────────────────────────────────
  {
    'nombre': 'Isoniazida (INH)',
    'categoria': 'Antituberculoso',
    'emoji': '🫁',
    'color': 0xFF5F5E5A,
    'presentaciones': ['Tabletas 100 mg', 'Tabletas 300 mg'],
    'indicaciones': 'Tuberculosis activa (esquema DOTS). Profilaxis TB latente en contactos.',
    'dosis': [
      {'grupo': 'TB activa (adultos)',    'dosis': '5 mg/kg/día (habitualmente 300 mg/día)', 'max': 'En esquema combinado × 6 meses'},
      {'grupo': 'TB activa (niños)',      'dosis': '10–15 mg/kg/día',                        'max': 'Máx 300 mg/día'},
      {'grupo': 'Profilaxis TB latente',  'dosis': '300 mg/día × 6–9 meses',                 'max': 'Con piridoxina'},
    ],
    'contraindicaciones': 'Hepatitis activa por drogas. Neuropatía periférica severa previa.',
    'alertas': '⚠️ Administrar con piridoxina (vitamina B6) 25–50 mg/día para prevenir neuropatía. Programa DOTS del MinSalud.',
    'nivel': 'prescripcion',
  },

  // ── ANESTÉSICOS / PROCEDIMIENTOS ─────────────────────────────────────
  {
    'nombre': 'Lidocaína',
    'categoria': 'Anestésico Local',
    'emoji': '💉',
    'color': 0xFF5F5E5A,
    'presentaciones': ['Ampolla 1% (10 mg/mL)', 'Ampolla 2% (20 mg/mL)', 'Gel tópico 2%'],
    'indicaciones': 'Anestesia local para sutura de heridas, procedimientos menores, bloqueos nerviosos.',
    'dosis': [
      {'grupo': 'Infiltración adultos',  'dosis': 'Máx 4.5 mg/kg (sin epinefrina)', 'max': 'Máx absoluto 300 mg'},
      {'grupo': 'Infiltración niños',    'dosis': 'Máx 3–4 mg/kg',                 'max': ''},
      {'grupo': 'Tópico (gel)',          'dosis': 'Aplicar en zona a anestesiar',   'max': 'Esperar 2–3 min'},
    ],
    'contraindicaciones': 'Alergia a anestésicos tipo amida. Bloqueo cardíaco severo.',
    'alertas': '⚠️ Aspirar antes de inyectar para evitar inyección intravascular. Toxicidad: convulsiones, arritmias.',
    'nivel': 'prescripcion',
  },

  // ── OXÍGENO MEDICINAL ─────────────────────────────────────────────────
  {
    'nombre': 'Oxígeno Medicinal',
    'categoria': '🚨 Emergencia',
    'emoji': '🫁',
    'color': 0xFFE24B4A,
    'presentaciones': ['Cilindro portátil', 'Concentrador de oxígeno', 'Máscara + reservorio', 'Cánula nasal'],
    'indicaciones': 'Hipoxemia (SpO2 < 94%), insuficiencia respiratoria, crisis asmática severa, shock, convulsiones.',
    'dosis': [
      {'grupo': 'Cánula nasal',         'dosis': '2–4 L/min → SpO2 94–98%',          'max': 'Objetivo SpO2 ≥ 94%'},
      {'grupo': 'Máscara simple',       'dosis': '5–10 L/min → SpO2 94–98%',         'max': ''},
      {'grupo': 'Máscara con reservorio', 'dosis': '10–15 L/min → SpO2 ≥ 94%',       'max': 'Emergencias graves'},
      {'grupo': 'Neonatos (oxihood)',    'dosis': 'Titular hasta SpO2 90–95%',         'max': 'Evitar hiperoxia en prematuros'},
    ],
    'contraindicaciones': 'EPOC con hipercapnia crónica: titular cuidadosamente (objetivo SpO2 88–92%).',
    'alertas': '🚨 Monitorear SpO2 continuamente. En EPOC no superar SpO2 92% — riesgo de depresión respiratoria.',
    'nivel': 'emergencia',
  },
];

// Categorías únicas para filtro
const _kCategorias = [
  'Todos',
  'Básico',
  'Prescripción',
  'Emergencia',
];

// Mapa de color por nivel para los chips
const Map<String, int> _kNivelColor = {
  'Básico':       0xFF1D9E75,
  'Prescripción': 0xFF185FA5,
  'Emergencia':   0xFFE24B4A,
};

// ─────────────────────────────────────────────────────────────────────────────
// PANTALLA PRINCIPAL
// ─────────────────────────────────────────────────────────────────────────────
class MedicamentosScreen extends StatefulWidget {
  const MedicamentosScreen({super.key});
  @override
  State<MedicamentosScreen> createState() => _MedicamentosScreenState();
}

class _MedicamentosScreenState extends State<MedicamentosScreen> {
  final TextEditingController _busqueda = TextEditingController();
  String _filtro    = 'Todos';
  String _query     = '';

  List<Map<String, dynamic>> get _filtrados {
    var lista = _kMedicamentos.toList();
    // Filtro por nivel — normaliza tildes y mayúsculas
    if (_filtro != 'Todos') {
      final Map<String, String> mapaFiltro = {
        'Básico':       'basico',
        'Prescripción': 'prescripcion',
        'Emergencia':   'emergencia',
      };
      final nivelBuscado = mapaFiltro[_filtro] ?? _filtro.toLowerCase();
      lista = lista.where((m) => m['nivel'] == nivelBuscado).toList();
    }
    // Búsqueda por nombre o categoría
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      lista = lista.where((m) =>
        (m['nombre'] as String).toLowerCase().contains(q) ||
        (m['categoria'] as String).toLowerCase().contains(q) ||
        (m['indicaciones'] as String).toLowerCase().contains(q)
      ).toList();
    }
    return lista;
  }

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dc     = _c(context);
    final dark   = isDark(context);
    final lista  = _filtrados;

    return Scaffold(
      backgroundColor: dc.bg,
      body: ResponsiveCenter(child: CustomScrollView(
        slivers: [

          // ── APP BAR ──────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0A5240), Color(0xFF1D9E75)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Fila título
                      Row(children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 38, height: 38,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.arrow_back_rounded,
                                color: Colors.white, size: 20),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Medicamentos',
                                style: TextStyle(color: Colors.white,
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                            Text('Botiquín comunitario · Protocolos Colombia',
                                style: TextStyle(color: Color(0xFF9FE1CB),
                                    fontSize: 11)),
                          ],
                        )),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(children: [
                            const Icon(Icons.medication_rounded,
                                color: Colors.white, size: 14),
                            const SizedBox(width: 4),
                            Text('${_kMedicamentos.length}',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 13,
                                    fontWeight: FontWeight.bold)),
                          ]),
                        ),
                      ]),
                      const SizedBox(height: 14),

                      // Búsqueda
                      Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: TextField(
                          controller: _busqueda,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          onChanged: (v) => setState(() => _query = v),
                          decoration: InputDecoration(
                            hintText: 'Buscar medicamento...',
                            hintStyle: const TextStyle(
                                color: Colors.white54, fontSize: 13),
                            prefixIcon: const Icon(Icons.search_rounded,
                                color: Colors.white54, size: 20),
                            suffixIcon: _query.isNotEmpty
                                ? GestureDetector(
                                    onTap: () {
                                      _busqueda.clear();
                                      setState(() => _query = '');
                                    },
                                    child: const Icon(Icons.close_rounded,
                                        color: Colors.white54, size: 18))
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── FILTROS ───────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(children: _kCategorias.map((cat) {
                final activo = _filtro == cat;
                Color chipColor;
                switch (cat) {
                  case 'Básico':      chipColor = _kVerde; break;
                  case 'Prescripción': chipColor = const Color(0xFF185FA5); break;
                  case 'Emergencia':  chipColor = const Color(0xFFE24B4A); break;
                  default:            chipColor = _kVerde;
                }
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _filtro = cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: activo
                            ? chipColor.withOpacity(0.15)
                            : dc.card,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: activo ? chipColor : dc.border,
                            width: activo ? 1.5 : 1),
                      ),
                      child: Text(cat,
                          style: TextStyle(
                            color: activo ? chipColor : dc.textSecondary,
                            fontSize: 12,
                            fontWeight: activo
                                ? FontWeight.w700
                                : FontWeight.normal,
                          )),
                    ),
                  ),
                );
              }).toList()),
            ),
          ),

          // ── AVISO LEGAL ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF9F27).withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFFEF9F27).withOpacity(0.4)),
                ),
                child: Row(children: [
                  const Icon(Icons.info_outline_rounded,
                      color: Color(0xFFEF9F27), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Información de referencia basada en protocolos del Ministerio de Salud Colombia. '
                      'La administración requiere prescripción médica según el caso.',
                      style: TextStyle(
                          color: dc.textSecondary, fontSize: 11,
                          height: 1.4),
                    ),
                  ),
                ]),
              ),
            ),
          ),

          // ── CONTADOR RESULTADOS ───────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Text(
                '${lista.length} medicamento${lista.length != 1 ? "s" : ""}',
                style: TextStyle(
                    color: dc.textHint, fontSize: 12,
                    fontWeight: FontWeight.w500),
              ),
            ),
          ),

          // ── LISTA DE MEDICAMENTOS ─────────────────────────────────────
          lista.isEmpty
              ? SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Center(
                      child: Column(children: [
                        Icon(Icons.search_off_rounded,
                            color: dc.textHint, size: 48),
                        const SizedBox(height: 12),
                        Text('Sin resultados para "$_query"',
                            style: TextStyle(
                                color: dc.textSecondary, fontSize: 14)),
                      ]),
                    ),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => _MedicamentoCard(
                        med: lista[i], dc: dc, dark: dark),
                      childCount: lista.length,
                    ),
                  ),
                ),
        ],
      ), ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TARJETA DE MEDICAMENTO
// ─────────────────────────────────────────────────────────────────────────────
class _MedicamentoCard extends StatefulWidget {
  final Map<String, dynamic> med;
  final DispersaludColors dc;
  final bool dark;
  const _MedicamentoCard({
    required this.med, required this.dc, required this.dark});
  @override
  State<_MedicamentoCard> createState() => _MedicamentoCardState();
}

class _MedicamentoCardState extends State<_MedicamentoCard> {
  bool _expandido = false;

  Color get _colorBase => Color(widget.med['color'] as int);

  Color get _nivelColor {
    switch (widget.med['nivel']) {
      case 'emergencia': return const Color(0xFFE24B4A);
      case 'prescripcion': return const Color(0xFF185FA5);
      default: return _kVerde;
    }
  }

  String get _nivelLabel {
    switch (widget.med['nivel']) {
      case 'emergencia':   return 'Emergencia';
      case 'prescripcion': return 'Prescripción';
      default:             return 'Básico';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dc   = widget.dc;
    final med  = widget.med;
    final dosis = med['dosis'] as List;

    return GestureDetector(
      onTap: () => setState(() => _expandido = !_expandido),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: dc.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _expandido
                ? _colorBase.withOpacity(0.4)
                : dc.border,
            width: _expandido ? 1.5 : 1,
          ),
          boxShadow: _expandido
              ? [BoxShadow(color: _colorBase.withOpacity(0.08),
                  blurRadius: 12, offset: const Offset(0, 4))]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Fila principal ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                // Icono
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: widget.dark
                        ? _colorBase.withOpacity(0.2)
                        : _colorBase.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(med['emoji'] as String,
                        style: const TextStyle(fontSize: 22)),
                  ),
                ),
                const SizedBox(width: 12),
                // Nombre y categoría
                Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(med['nombre'] as String,
                      style: TextStyle(
                          color: dc.textPrimary, fontSize: 13,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text(med['categoria'] as String,
                      style: TextStyle(
                          color: dc.textSecondary, fontSize: 11)),
                ])),
                const SizedBox(width: 8),
                // Badge nivel
                Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _nivelColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(_nivelLabel,
                        style: TextStyle(
                            color: _nivelColor, fontSize: 9,
                            fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(height: 6),
                  Icon(
                    _expandido
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: dc.textHint, size: 18),
                ]),
              ]),
            ),

            // ── Indicaciones breves (siempre visibles) ─────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Text(med['indicaciones'] as String,
                  maxLines: _expandido ? null : 2,
                  overflow: _expandido ? null : TextOverflow.ellipsis,
                  style: TextStyle(
                      color: dc.textSecondary, fontSize: 11,
                      height: 1.4)),
            ),

            // ── DETALLE EXPANDIDO ──────────────────────────────────────
            if (_expandido) ...[
              Divider(height: 1, color: dc.border),

              // Presentaciones
              _Seccion(
                titulo: 'Presentaciones',
                icono: Icons.inventory_2_outlined,
                color: _colorBase,
                dc: dc,
                child: Wrap(
                  spacing: 6, runSpacing: 6,
                  children: (med['presentaciones'] as List).map((p) =>
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _colorBase.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: _colorBase.withOpacity(0.2)),
                      ),
                      child: Text(p as String,
                          style: TextStyle(
                              color: _colorBase, fontSize: 11,
                              fontWeight: FontWeight.w500)),
                    )
                  ).toList(),
                ),
              ),

              // Dosis
              _Seccion(
                titulo: 'Posología',
                icono: Icons.schedule_rounded,
                color: _colorBase,
                dc: dc,
                child: Column(
                  children: dosis.map((d) {
                    final dm = d as Map;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _colorBase.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: _colorBase.withOpacity(0.15)),
                        ),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(dm['grupo'] as String,
                              style: TextStyle(
                                  color: _colorBase, fontSize: 11,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: 3),
                          Text(dm['dosis'] as String,
                              style: TextStyle(
                                  color: dc.textPrimary, fontSize: 12,
                                  fontWeight: FontWeight.w500)),
                          if ((dm['max'] as String).isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(dm['max'] as String,
                                style: TextStyle(
                                    color: dc.textHint, fontSize: 10)),
                          ],
                        ]),
                      ),
                    );
                  }).toList(),
                ),
              ),

              // Contraindicaciones
              _Seccion(
                titulo: 'Contraindicaciones',
                icono: Icons.block_rounded,
                color: const Color(0xFFEF9F27),
                dc: dc,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF9F27).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: const Color(0xFFEF9F27).withOpacity(0.25)),
                  ),
                  child: Text(med['contraindicaciones'] as String,
                      style: TextStyle(
                          color: dc.textPrimary, fontSize: 12,
                          height: 1.4)),
                ),
              ),

              // Alertas
              if ((med['alertas'] as String).isNotEmpty)
                _Seccion(
                  titulo: 'Alertas importantes',
                  icono: Icons.warning_amber_rounded,
                  color: const Color(0xFFE24B4A),
                  dc: dc,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE24B4A).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: const Color(0xFFE24B4A).withOpacity(0.25)),
                    ),
                    child: Text(med['alertas'] as String,
                        style: TextStyle(
                            color: dc.textPrimary, fontSize: 12,
                            height: 1.4)),
                  ),
                ),

              const SizedBox(height: 4),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SECCIÓN AUXILIAR
// ─────────────────────────────────────────────────────────────────────────────
class _Seccion extends StatelessWidget {
  final String titulo;
  final IconData icono;
  final Color color;
  final DispersaludColors dc;
  final Widget child;
  const _Seccion({
    required this.titulo, required this.icono, required this.color,
    required this.dc, required this.child,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icono, color: color, size: 14),
        const SizedBox(width: 6),
        Text(titulo, style: TextStyle(
            color: color, fontSize: 12, fontWeight: FontWeight.w700)),
      ]),
      const SizedBox(height: 8),
      child,
      const SizedBox(height: 4),
    ]),
  );
}