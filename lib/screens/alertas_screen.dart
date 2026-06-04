import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../database/database_helper.dart';

// ════════════════════════════════════════════════════════════════════════════
//  alertas_screen.dart  —  DISPERSALUD
//  Catálogo SIVIGILA completo · Notificación obligatoria INS Colombia
// ════════════════════════════════════════════════════════════════════════════

const Color _kVerde = Color(0xFF1D9E75);
DispersaludColors _c(BuildContext ctx) =>
    Theme.of(ctx).extension<DispersaludColors>() ?? DispersaludColors.dark;

// ─────────────────────────────────────────────────────────────────────────────
// CATEGORÍAS SIVIGILA
// ─────────────────────────────────────────────────────────────────────────────
class _Categoria {
  final String id;
  final String nombre;
  final String emoji;
  final Color color;
  const _Categoria({
    required this.id,
    required this.nombre,
    required this.emoji,
    required this.color,
  });
}

const List<_Categoria> _kCategorias = [
  _Categoria(id: 'todas',     nombre: 'Todas',             emoji: '📋', color: Color(0xFF1D9E75)),
  _Categoria(id: 'vectores',  nombre: 'Vectores',          emoji: '🦟', color: Color(0xFF3B6D11)),
  _Categoria(id: 'inmuno',    nombre: 'Inmunoprevenibles', emoji: '💉', color: Color(0xFF185FA5)),
  _Categoria(id: 'respira',   nombre: 'Respiratorias',     emoji: '🤧', color: Color(0xFF534AB7)),
  _Categoria(id: 'alimentos', nombre: 'Alimentos y agua',  emoji: '💧', color: Color(0xFF0F6E56)),
  _Categoria(id: 'its',       nombre: 'ITS',               emoji: '🔬', color: Color(0xFF993556)),
  _Categoria(id: 'zoonosis',  nombre: 'Zoonosis',          emoji: '🐾', color: Color(0xFF854F0B)),
  _Categoria(id: 'materna',   nombre: 'Materna/Perinatal', emoji: '🤰', color: Color(0xFF993556)),
  _Categoria(id: 'infantil',  nombre: 'Salud infantil',    emoji: '👶', color: Color(0xFF854F0B)),
  _Categoria(id: 'cronicas',  nombre: 'Crónicas',          emoji: '🏥', color: Color(0xFF5F5E5A)),
  _Categoria(id: 'violencia', nombre: 'Violencias',        emoji: '🚨', color: Color(0xFFE24B4A)),
  _Categoria(id: 'ambiental', nombre: 'Ambiental/Laboral', emoji: '🏭', color: Color(0xFFEF9F27)),
  _Categoria(id: 'especial',  nombre: 'Vigilancia especial', emoji: '⚠️', color: Color(0xFFE24B4A)),
];

// ─────────────────────────────────────────────────────────────────────────────
// CATÁLOGO COMPLETO SIVIGILA — Notificación obligatoria INS Colombia
// ─────────────────────────────────────────────────────────────────────────────
const List<Map<String, dynamic>> _kEventosSivigila = [

  // ══ ENFERMEDADES TRANSMITIDAS POR VECTORES ════════════════════════════════
  {
    'codigo': 'DEN',     'categoria': 'vectores',
    'nombre': 'Dengue',  'emoji': '🦟',
    'descripcion': 'Enfermedad viral transmitida por Aedes aegypti. Vigilancia activa en temporada de lluvias. Formas graves pueden causar choque y hemorragia.',
    'prevencion': 'Eliminar criaderos de agua estancada. Usar toldillos y repelente con DEET. Ropa de manga larga. Reportar casos febriles sin foco aparente.',
    'signos_alarma': 'Fiebre alta súbita, dolor retroocular, sarpullido. EMERGENCIA: sangrado, vómito persistente, dolor abdominal intenso, decaimiento extremo.',
    'municipios_riesgo': ['Santander de Quilichao', 'Puerto Tejada', 'Caloto', 'Corinto', 'Popayán'],
    'nivel_base': 'vigilancia',
  },
  {
    'codigo': 'DENGV',   'categoria': 'vectores',
    'nombre': 'Dengue grave', 'emoji': '🦟',
    'descripcion': 'Forma severa del dengue con choque, hemorragia o compromiso grave de órganos. Mortalidad evitable con manejo oportuno.',
    'prevencion': 'Igual que dengue. Identificar signos de alarma antes de progresar a forma grave. No automedicar con AINES.',
    'signos_alarma': 'EMERGENCIA: Choque, hemorragia grave, falla respiratoria, compromiso hepático. Remitir de inmediato a nivel hospitalario.',
    'municipios_riesgo': ['Todo el departamento en temporada de lluvias'],
    'nivel_base': 'alerta',
  },
  {
    'codigo': 'CHIK',    'categoria': 'vectores',
    'nombre': 'Chikunguña', 'emoji': '🦟',
    'descripcion': 'Infección viral por arbovirus, transmitida por Aedes aegypti y Ae. albopictus. Artritis severa característica.',
    'prevencion': 'Control vectorial. Repelente y toldillos. No hay vacuna disponible.',
    'signos_alarma': 'Fiebre alta de inicio súbito + artralgia severa bilateral. Puede persistir artritis crónica meses después.',
    'municipios_riesgo': ['Santander de Quilichao', 'Puerto Tejada', 'Miranda', 'Caloto'],
    'nivel_base': 'vigilancia',
  },
  {
    'codigo': 'ZIKA',    'categoria': 'vectores',
    'nombre': 'Zika',   'emoji': '🦟',
    'descripcion': 'Infección viral por flavivirus. Transmisión vectorial y sexual. Riesgo de microcefalia en fetos de madres infectadas.',
    'prevencion': 'Protección vectorial. Relaciones sexuales protegidas en zonas endémicas. Tamizaje en mujeres embarazadas.',
    'signos_alarma': 'Exantema + fiebre + artralgia + conjuntivitis. URGENTE en embarazadas: notificación y seguimiento ecográfico.',
    'municipios_riesgo': ['Zonas bajo los 2200 msnm en el Cauca'],
    'nivel_base': 'vigilancia',
  },
  {
    'codigo': 'MAL',     'categoria': 'vectores',
    'nombre': 'Malaria', 'emoji': '🦠',
    'descripcion': 'Parasitosis transmitida por Anopheles. Zonas de riesgo bajo los 1600 msnm. P. falciparum: forma grave con alta mortalidad.',
    'prevencion': 'Toldillos impregnados con insecticida. Rociamiento intradomiciliario. Consulta inmediata ante fiebre en zona endémica.',
    'signos_alarma': 'Fiebre intermitente, escalofríos, sudoración. Gota gruesa ante toda fiebre en zona de riesgo. EMERGENCIA: alteración de conciencia.',
    'municipios_riesgo': ['López de Micay', 'Timbiquí', 'Guapi', 'Olaya Herrera', 'Santa Bárbara'],
    'nivel_base': 'alerta',
  },
  {
    'codigo': 'LEISH',   'categoria': 'vectores',
    'nombre': 'Leishmaniasis', 'emoji': '🦠',
    'descripcion': 'Enfermedad parasitaria transmitida por flebotomíneos (palomillas). Formas: cutánea, mucocutánea y visceral (la más grave).',
    'prevencion': 'Protección con repelente y ropa en zonas boscosas. Rociamiento en focos. Diagnóstico y tratamiento temprano.',
    'signos_alarma': 'Úlcera indolora en zona expuesta (cutánea). Fiebre + pérdida de peso + esplenomegalia (visceral = URGENTE).',
    'municipios_riesgo': ['Argelia', 'El Tambo', 'Balboa', 'Bolívar', 'La Vega'],
    'nivel_base': 'vigilancia',
  },
  {
    'codigo': 'CHAGAS',  'categoria': 'vectores',
    'nombre': 'Enfermedad de Chagas', 'emoji': '🐛',
    'descripcion': 'Infección por Trypanosoma cruzi transmitida por triatominos (pito). Fase crónica causa daño cardíaco y digestivo.',
    'prevencion': 'Mejora de vivienda. Eliminación de triatominos. Tamizaje en donantes de sangre y embarazadas.',
    'signos_alarma': 'Chagoma de inoculación, signo de Romaña (edema palpebral). Fase crónica: arritmias, cardiomegalia.',
    'municipios_riesgo': ['Zonas rurales del norte del Cauca'],
    'nivel_base': 'vigilancia',
  },
  {
    'codigo': 'FAMAR',   'categoria': 'vectores',
    'nombre': 'Fiebre amarilla', 'emoji': '🟡',
    'descripcion': 'Enfermedad viral hemorrágica transmitida por Aedes y Haemagogus. Vacunable. Notificación inmediata obligatoria.',
    'prevencion': 'Vacunación obligatoria en zonas de riesgo. Una dosis es suficiente para toda la vida. Control vectorial en focos.',
    'signos_alarma': 'Fiebre + ictericia + hemorragia = tríada clásica. EMERGENCIA NACIONAL: un solo caso confirmado activa protocolo.',
    'municipios_riesgo': ['Zonas selváticas del Cauca', 'Frontera con Putumayo y Caquetá'],
    'nivel_base': 'alerta',
  },

  // ══ ENFERMEDADES INMUNOPREVENIBLES ════════════════════════════════════════
  {
    'codigo': 'SARAM',   'categoria': 'inmuno',
    'nombre': 'Sarampión', 'emoji': '💉',
    'descripcion': 'Enfermedad viral altamente contagiosa. Un caso es emergencia de salud pública. Colombia en eliminación sostenida.',
    'prevencion': 'Vacunación con 2 dosis de SRP. Cobertura > 95% para inmunidad de rebaño. Investigación de caso en < 24 h.',
    'signos_alarma': 'Fiebre + exantema maculo-papular cefalocaudal + tos + coriza + conjuntivitis. NOTIFICAR INMEDIATAMENTE.',
    'municipios_riesgo': ['Todo el departamento — caso único es emergencia'],
    'nivel_base': 'alerta',
  },
  {
    'codigo': 'RUBE',    'categoria': 'inmuno',
    'nombre': 'Rubéola',  'emoji': '💉',
    'descripcion': 'Infección viral leve en adultos pero teratogénica en el primer trimestre de embarazo. Colombia en eliminación.',
    'prevencion': 'Vacunación SRP. Especial énfasis en mujeres en edad fértil sin esquema completo.',
    'signos_alarma': 'Exantema rosado + adenopatías retroauriculares. URGENTE en embarazadas: riesgo de síndrome de rubéola congénita.',
    'municipios_riesgo': ['Todo el departamento'],
    'nivel_base': 'vigilancia',
  },
  {
    'codigo': 'SRC',     'categoria': 'inmuno',
    'nombre': 'Síndrome de rubéola congénita', 'emoji': '👶',
    'descripcion': 'Malformaciones congénitas por infección materna por rubéola en primer trimestre: cardiopatía, cataratas, sordera.',
    'prevencion': 'Vacunación preconcepcional. Tamizaje serológico en primer control prenatal.',
    'signos_alarma': 'Recién nacido con cataratas + soplo cardíaco + microcefalia. Notificación obligatoria inmediata.',
    'municipios_riesgo': ['Todo el departamento'],
    'nivel_base': 'vigilancia',
  },
  {
    'codigo': 'TOSF',    'categoria': 'inmuno',
    'nombre': 'Tos ferina', 'emoji': '💉',
    'descripcion': 'Infección bacteriana respiratoria por Bordetella pertussis. Muy grave en menores de 6 meses. Reemergente.',
    'prevencion': 'Vacuna DPT/Pentavalente en menores. Tdap en embarazadas (tercer trimestre) para proteger al recién nacido.',
    'signos_alarma': 'Tos paroxística + estridor inspiratorio + cianosis en menores. EMERGENCIA en < 6 meses: apnea, cianosis.',
    'municipios_riesgo': ['Todo el departamento — mayor riesgo en comunidades rurales sin esquema'],
    'nivel_base': 'vigilancia',
  },
  {
    'codigo': 'DIFT',    'categoria': 'inmuno',
    'nombre': 'Difteria',  'emoji': '💉',
    'descripcion': 'Infección bacteriana por Corynebacterium diphtheriae. Pseudomembrana faríngea, toxina cardíaca y neurológica.',
    'prevencion': 'Vacunación DPT completa. Coberturas > 95%. Caso sospechoso: aislamiento inmediato y antitoxina.',
    'signos_alarma': 'Faringitis con membrana grisácea no desprendible + disfagia + ronquera. Un caso = EMERGENCIA DEPARTAMENTAL.',
    'municipios_riesgo': ['Zonas con bajas coberturas de vacunación'],
    'nivel_base': 'alerta',
  },
  {
    'codigo': 'TETNEO',  'categoria': 'inmuno',
    'nombre': 'Tétanos neonatal', 'emoji': '💉',
    'descripcion': 'Espasmos musculares en neonatos por Clostridium tetani. Indicador de partos sin asistencia calificada.',
    'prevencion': 'Toxoide tetánico en embarazadas. Parto limpio y ligadura aséptica del cordón. Eliminación global en marcha.',
    'signos_alarma': 'Recién nacido que llora, succiona y al 3-7 días presenta trismus + espasmos + incapacidad de succionar.',
    'municipios_riesgo': ['Zonas rurales dispersas con partos domiciliarios'],
    'nivel_base': 'alerta',
  },
  {
    'codigo': 'PFA',     'categoria': 'inmuno',
    'nombre': 'Parálisis flácida aguda', 'emoji': '🦽',
    'descripcion': 'Vigilancia centinela de poliomielitis. Todo caso de parálisis flácida aguda en < 15 años debe investigarse.',
    'prevencion': 'Vacuna OPV/IPV con coberturas > 95%. Búsqueda activa institucional y comunitaria.',
    'signos_alarma': 'Parálisis de inicio súbito, flácida, asimétrica en < 15 años. NOTIFICACIÓN OBLIGATORIA EN < 24 H.',
    'municipios_riesgo': ['Todo el departamento'],
    'nivel_base': 'alerta',
  },
  {
    'codigo': 'MENB',    'categoria': 'inmuno',
    'nombre': 'Meningitis bacteriana', 'emoji': '🧠',
    'descripcion': 'Infección grave de meninges. Principales agentes: Neisseria meningitidis, S. pneumoniae, H. influenzae tipo b.',
    'prevencion': 'Vacunas Hib, neumocócica y meningocócica. Quimioprofilaxis a contactos de meningococo.',
    'signos_alarma': 'Fiebre + cefalea intensa + rigidez de nuca + fotofobia. En niños: fontanela abombada. EMERGENCIA MÉDICA.',
    'municipios_riesgo': ['Todo el departamento'],
    'nivel_base': 'alerta',
  },
  {
    'codigo': 'ESAVI',   'categoria': 'inmuno',
    'nombre': 'ESAVI',   'emoji': '⚡',
    'descripcion': 'Evento Supuestamente Atribuible a Vacunación e Inmunización. Cualquier evento adverso tras vacunación debe notificarse.',
    'prevencion': 'Técnica correcta de vacunación. Sala de espera 30 min postvacunación. Cadena de frío adecuada.',
    'signos_alarma': 'Reacción anafiláctica, convulsiones, absceso, síncope post-vacuna. Notificar aunque no se confirme causalidad.',
    'municipios_riesgo': ['Todo el departamento'],
    'nivel_base': 'vigilancia',
  },

  // ══ INFECCIONES RESPIRATORIAS ═════════════════════════════════════════════
  {
    'codigo': 'IRA',     'categoria': 'respira',
    'nombre': 'Infección respiratoria aguda (IRA)', 'emoji': '🤧',
    'descripcion': 'Incluye resfriado, faringitis, otitis, neumonía. Principal causa de mortalidad infantil evitable en Colombia.',
    'prevencion': 'Vacunación neumocócica e influenza. Lactancia materna exclusiva. Ventilación de espacios.',
    'signos_alarma': 'Dificultad respiratoria, tiraje subcostal, cianosis, fiebre > 39°C en menores. EMERGENCIA en < 2 meses.',
    'municipios_riesgo': ['Silvia', 'Inzá', 'Puracé', 'La Vega', 'Bolívar'],
    'nivel_base': 'vigilancia',
  },
  {
    'codigo': 'IRAG1',   'categoria': 'respira',
    'nombre': 'IRAG inusitado', 'emoji': '😷',
    'descripcion': 'Infección respiratoria aguda grave de etiología desconocida o inesperada. Vigilancia centinela hospitalaria.',
    'prevencion': 'Medidas de bioseguridad en UCI. Aislamiento. Muestras para caracterización viral urgentes.',
    'signos_alarma': 'Neumonía grave sin agente identificado + falla respiratoria. NOTIFICACIÓN INMEDIATA al INS.',
    'municipios_riesgo': ['Todo el departamento'],
    'nivel_base': 'alerta',
  },
  {
    'codigo': 'IRAGV',   'categoria': 'respira',
    'nombre': 'IRAG por virus nuevos', 'emoji': '🦠',
    'descripcion': 'Infección respiratoria grave por virus de nuevo tipo (influenza pandémica, coronavirus emergente, etc.).',
    'prevencion': 'Medidas de control de infecciones. Notificación a la red de laboratorios del INS para caracterización.',
    'signos_alarma': 'Cualquier caso inusual de neumonía grave en cluster o con nexo epidemiológico. ALERTA INMEDIATA.',
    'municipios_riesgo': ['Todo el departamento'],
    'nivel_base': 'alerta',
  },
  {
    'codigo': 'COV',     'categoria': 'respira',
    'nombre': 'COVID-19', 'emoji': '😷',
    'descripcion': 'Infección por SARS-CoV-2. Vigilancia según lineamientos vigentes del INS. Monitoreo de variantes.',
    'prevencion': 'Ventilación de espacios. Higiene de manos. Vacunación con esquema completo y refuerzos.',
    'signos_alarma': 'Fiebre + tos + dificultad respiratoria. Saturación < 94% requiere valoración médica inmediata.',
    'municipios_riesgo': ['Todo el departamento'],
    'nivel_base': 'normal',
  },
  {
    'codigo': 'TBP',     'categoria': 'respira',
    'nombre': 'Tuberculosis pulmonar', 'emoji': '🫁',
    'descripcion': 'Infección por Mycobacterium tuberculosis. Transmisión aérea. Principal causa infecciosa de muerte en el mundo.',
    'prevencion': 'Diagnóstico temprano (baciloscopía). Tratamiento DOTS supervisado 6 meses. Vacuna BCG al nacer.',
    'signos_alarma': 'Tos > 15 días, pérdida de peso, sudoración nocturna, fiebre vespertina. Hemoptisis = urgente.',
    'municipios_riesgo': ['Popayán', 'Santander de Quilichao', 'Miranda', 'Caloto'],
    'nivel_base': 'vigilancia',
  },
  {
    'codigo': 'TBE',     'categoria': 'respira',
    'nombre': 'Tuberculosis extrapulmonar', 'emoji': '🫁',
    'descripcion': 'TB en ganglios, pleura, meninges, hueso, riñón u otros. Diagnóstico más difícil. Igualmente notificable.',
    'prevencion': 'Igual que TB pulmonar. Investigación de contactos. Tratamiento supervisado completo.',
    'signos_alarma': 'Síntomas sistémicos + compromiso del órgano afectado. TB meníngea: cefalea, rigidez, alteración de conciencia.',
    'municipios_riesgo': ['Todo el departamento'],
    'nivel_base': 'vigilancia',
  },

  // ══ ENFERMEDADES TRANSMITIDAS POR ALIMENTOS Y AGUA ═══════════════════════
  {
    'codigo': 'EDA',     'categoria': 'alimentos',
    'nombre': 'Enfermedad diarreica aguda', 'emoji': '💧',
    'descripcion': 'Infección gastrointestinal por bacterias, virus o parásitos. Más frecuente en menores de 5 años. Principal causa de desnutrición.',
    'prevencion': 'Agua hervida o clorada. Lavado de manos con jabón. Manejo adecuado de alimentos. Lactancia materna.',
    'signos_alarma': 'Diarrea > 3 veces/día, fiebre, vómito. EMERGENCIA en menores: signos de deshidratación grave.',
    'municipios_riesgo': ['Toribío', 'Páez', 'La Sierra', 'El Tambo', 'Balboa'],
    'nivel_base': 'normal',
  },
  {
    'codigo': 'COLERA',  'categoria': 'alimentos',
    'nombre': 'Cólera',  'emoji': '💧',
    'descripcion': 'Diarrea acuosa profusa por Vibrio cholerae. Deshidratación severa en horas. Brotes por agua y alimentos contaminados.',
    'prevencion': 'Agua potable o tratada. Saneamiento básico. Lavado de manos. Vacuna oral disponible para brotes.',
    'signos_alarma': 'Diarrea en agua de arroz + vómitos + deshidratación rápida. UN CASO = EMERGENCIA EPIDEMIOLÓGICA.',
    'municipios_riesgo': ['Zonas costeras y ribereñas del Cauca'],
    'nivel_base': 'alerta',
  },
  {
    'codigo': 'HEPA',    'categoria': 'alimentos',
    'nombre': 'Hepatitis A', 'emoji': '🍽️',
    'descripcion': 'Hepatitis viral de transmisión fecal-oral. Autolimitada en la mayoría. Brotes frecuentes en zonas sin saneamiento.',
    'prevencion': 'Agua segura. Saneamiento básico. Lavado de manos. Vacuna disponible para grupos de riesgo.',
    'signos_alarma': 'Ictericia + coluria + acolia + fiebre. Forma fulminante (rara): falla hepática aguda.',
    'municipios_riesgo': ['Zonas sin acueducto ni alcantarillado'],
    'nivel_base': 'normal',
  },
  {
    'codigo': 'ETA',     'categoria': 'alimentos',
    'nombre': 'Enfermedades transmitidas por alimentos (ETA)', 'emoji': '🍽️',
    'descripcion': 'Intoxicaciones e infecciones por consumo de alimentos contaminados. Brotes con dos o más casos relacionados son notificables.',
    'prevencion': 'Cadena de frío. Cocción adecuada. Higiene en manipulación. Inspección de establecimientos.',
    'signos_alarma': 'Dos o más casos con síntomas similares tras comer el mismo alimento. Notificar y conservar muestras.',
    'municipios_riesgo': ['Todo el departamento — especial atención en restaurantes y eventos'],
    'nivel_base': 'normal',
  },

  // ══ INFECCIONES DE TRANSMISIÓN SEXUAL ════════════════════════════════════
  {
    'codigo': 'VIH',     'categoria': 'its',
    'nombre': 'VIH/SIDA', 'emoji': '🔴',
    'descripcion': 'Infección por VIH. Notificación obligatoria y confidencial. Acceso a TARV garantizado en Colombia.',
    'prevencion': 'Uso consistente de condón. Prueba voluntaria. TARV en seropositivos. Profilaxis pre y post-exposición.',
    'signos_alarma': 'Infecciones oportunistas (PCP, toxoplasmosis, CMV), pérdida de peso inexplicable, linfadenopatía generalizada.',
    'municipios_riesgo': ['Todo el departamento'],
    'nivel_base': 'vigilancia',
  },
  {
    'codigo': 'SIFGEST', 'categoria': 'its',
    'nombre': 'Sífilis gestacional', 'emoji': '🤰',
    'descripcion': 'Sífilis diagnosticada durante el embarazo. Indicador de calidad prenatal. Transmisible al feto causando sífilis congénita.',
    'prevencion': 'Tamizaje VDRL en primer control y tercer trimestre. Tratamiento con penicilina benzatínica. Tratamiento de la pareja.',
    'signos_alarma': 'VDRL reactivo en embarazada. Tratamiento inmediato para prevenir transmisión vertical.',
    'municipios_riesgo': ['Todo el departamento'],
    'nivel_base': 'vigilancia',
  },
  {
    'codigo': 'SIFCONG', 'categoria': 'its',
    'nombre': 'Sífilis congénita', 'emoji': '👶',
    'descripcion': 'Infección del recién nacido por T. pallidum vía transplacentaria. Causa malformaciones, óbito y muerte neonatal.',
    'prevencion': 'Prevención y tratamiento de sífilis gestacional. Control prenatal de calidad.',
    'signos_alarma': 'RN con madre con sífilis no tratada + hepatomegalia + pénfigo palmoplantar + rinitis hemorrágica.',
    'municipios_riesgo': ['Todo el departamento'],
    'nivel_base': 'vigilancia',
  },
  {
    'codigo': 'HEPB',    'categoria': 'its',
    'nombre': 'Hepatitis B', 'emoji': '🔬',
    'descripcion': 'Infección viral hepática de transmisión sexual, perinatal y sanguínea. Riesgo de cirrosis y hepatocarcinoma crónico.',
    'prevencion': 'Vacunación universal. Primera dosis al nacer (< 12 h). Uso de condón. Tamizaje en embarazadas.',
    'signos_alarma': 'Ictericia, fatiga, náuseas, dolor en hipocondrio derecho. Forma crónica: detectar por serología.',
    'municipios_riesgo': ['Todo el departamento'],
    'nivel_base': 'vigilancia',
  },
  {
    'codigo': 'HEPC',    'categoria': 'its',
    'nombre': 'Hepatitis C', 'emoji': '🔬',
    'descripcion': 'Infección crónica viral. Principal causa de trasplante hepático. Transmisión sanguínea principalmente. Curable con antivirales.',
    'prevencion': 'No hay vacuna. Evitar compartir material de inyección. Screening en grupos de riesgo.',
    'signos_alarma': 'Mayoría asintomática por años. Detectar por anti-VHC en personas con factores de riesgo.',
    'municipios_riesgo': ['Todo el departamento'],
    'nivel_base': 'vigilancia',
  },

  // ══ ZOONOSIS ═════════════════════════════════════════════════════════════
  {
    'codigo': 'RABIAH',  'categoria': 'zoonosis',
    'nombre': 'Rabia humana', 'emoji': '🐺',
    'descripcion': 'Encefalitis viral invariablemente mortal una vez aparecen síntomas. 100% prevenible con profilaxis post-exposición.',
    'prevencion': 'Vacunación animal. Lavado inmediato de herida + vacuna + inmunoglobulina antirrábica tras mordedura.',
    'signos_alarma': 'Hidrofobia, aerofobia, agitación, paresia ascendente. Un caso = EMERGENCIA NACIONAL.',
    'municipios_riesgo': ['Zonas rurales en contacto con murciélagos y animales silvestres'],
    'nivel_base': 'alerta',
  },
  {
    'codigo': 'RABIAA',  'categoria': 'zoonosis',
    'nombre': 'Rabia animal', 'emoji': '🐶',
    'descripcion': 'Rabia en perros, gatos, bovinos, murciélagos. Indicador de riesgo para humanos. Notificación obligatoria al ICA.',
    'prevencion': 'Vacunación masiva canina. Eliminación y control de murciélagos hematófagos.',
    'signos_alarma': 'Animal con cambios de comportamiento, agresividad, disfagia, parálisis. Aislar y notificar.',
    'municipios_riesgo': ['Zonas rurales de todo el Cauca'],
    'nivel_base': 'vigilancia',
  },
  {
    'codigo': 'EXPRAB',  'categoria': 'zoonosis',
    'nombre': 'Exposición rábica', 'emoji': '🩹',
    'descripcion': 'Mordedura, arañazo o contacto de mucosas con animal sospechoso de rabia. Inicio inmediato de profilaxis.',
    'prevencion': 'Lavado profundo con agua y jabón. Vacuna antirrábica + inmunoglobulina según tipo de exposición.',
    'signos_alarma': 'Mordedura de murciélago, perro sin vacunar, animal silvestre. Iniciar profilaxis ANTES de confirmar.',
    'municipios_riesgo': ['Todo el departamento'],
    'nivel_base': 'normal',
  },
  {
    'codigo': 'LEPTO',   'categoria': 'zoonosis',
    'nombre': 'Leptospirosis', 'emoji': '🌊',
    'descripcion': 'Infección bacteriana zoonótica por Leptospira. Transmisión por contacto con agua o suelo contaminado con orina de roedores.',
    'prevencion': 'Botas y guantes en zonas inundadas. Control de roedores. No bañarse en aguas estancadas.',
    'signos_alarma': 'Fiebre + cefalea + mialgias + sufusión conjuntival tras exposición a aguas. Forma grave: ictericia + insuficiencia renal.',
    'municipios_riesgo': ['Zonas de inundación y comunidades agrícolas'],
    'nivel_base': 'vigilancia',
  },
  {
    'codigo': 'OFIDIO',  'categoria': 'zoonosis',
    'nombre': 'Accidente ofídico', 'emoji': '🐍',
    'descripcion': 'Mordedura de serpiente venenosa. Colombia tiene alta diversidad de ofidios venenosos. Urgencia médica.',
    'prevencion': 'Botas altas en zonas rurales. No manipular serpientes. Tener suero antiofídico disponible en puestos de salud.',
    'signos_alarma': 'Mordedura + edema + equimosis + sangrado local o sistémico. Administrar suero en < 6 h. EMERGENCIA.',
    'municipios_riesgo': ['Argelia', 'El Tambo', 'Balboa', 'López de Micay', 'Timbiquí'],
    'nivel_base': 'alerta',
  },

  // ══ SALUD MATERNA Y PERINATAL ═════════════════════════════════════════════
  {
    'codigo': 'MM',      'categoria': 'materna',
    'nombre': 'Mortalidad materna', 'emoji': '🤰',
    'descripcion': 'Muerte de mujer durante embarazo, parto o 42 días posparto. Indicador trazador de equidad y calidad del sistema de salud.',
    'prevencion': 'Control prenatal de calidad. Atención del parto por personal calificado. Manejo activo del tercer período.',
    'signos_alarma': 'Toda muerte materna es notificación obligatoria inmediata con investigación de caso en < 24 h.',
    'municipios_riesgo': ['Todo el departamento — especial rural disperso'],
    'nivel_base': 'alerta',
  },
  {
    'codigo': 'MPN',     'categoria': 'materna',
    'nombre': 'Mortalidad perinatal y neonatal tardía', 'emoji': '👶',
    'descripcion': 'Muerte fetal tardía (> 22 semanas) o neonatal (< 28 días). Indica problemas en atención obstétrica y neonatal.',
    'prevencion': 'Control prenatal. Monitoreo fetal. Reanimación neonatal. Cuidados del recién nacido.',
    'signos_alarma': 'Todo óbito fetal o muerte neonatal debe notificarse e investigarse para identificar causas prevenibles.',
    'municipios_riesgo': ['Todo el departamento'],
    'nivel_base': 'alerta',
  },
  {
    'codigo': 'MME',     'categoria': 'materna',
    'nombre': 'Morbilidad materna extrema', 'emoji': '🚑',
    'descripcion': 'Mujer que casi muere por complicación grave del embarazo, parto o puerperio. Vigilancia complementaria a la muerte materna.',
    'prevencion': 'Detección temprana de signos de alarma. Protocolos de hemorragia, eclampsia y sepsis obstétrica.',
    'signos_alarma': 'Eclampsia, choque hemorrágico, sepsis, falla multiorgánica. Sobrevivió pero notificar obligatoriamente.',
    'municipios_riesgo': ['Todo el departamento'],
    'nivel_base': 'vigilancia',
  },
  {
    'codigo': 'BPN',     'categoria': 'materna',
    'nombre': 'Bajo peso al nacer', 'emoji': '⚖️',
    'descripcion': 'Recién nacido con peso < 2500 g. Indicador de desnutrición materna, prematuridad y condiciones socioeconómicas.',
    'prevencion': 'Nutrición materna adecuada. Control prenatal. Suplementación con micronutrientes. Espaciado intergenésico.',
    'signos_alarma': 'RN con peso < 2500 g: mayor riesgo de hipoglucemia, hipotermia, infecciones. Seguimiento nutricional.',
    'municipios_riesgo': ['Páez', 'Toribío', 'Jambaló', 'Silvia', 'Caldono'],
    'nivel_base': 'vigilancia',
  },

  // ══ SALUD INFANTIL ════════════════════════════════════════════════════════
  {
    'codigo': 'MME5',    'categoria': 'infantil',
    'nombre': 'Mortalidad en menores de 5 años', 'emoji': '👶',
    'descripcion': 'Muerte en niño menor de 5 años. Indicador de desarrollo. Causas principales: neumonía, diarrea, malnutrición, malaria.',
    'prevencion': 'Vacunación completa. Lactancia materna. Acceso a agua segura. Control de crecimiento y desarrollo.',
    'signos_alarma': 'Toda muerte en < 5 años requiere notificación e investigación de causa evitable.',
    'municipios_riesgo': ['Resguardos indígenas con barreras de acceso'],
    'nivel_base': 'alerta',
  },
  {
    'codigo': 'DESN',    'categoria': 'infantil',
    'nombre': 'Desnutrición aguda en menores de 5 años', 'emoji': '⚖️',
    'descripcion': 'Emergencia nutricional. P/T < -2 DE (moderada) o < -3 DE (severa). Edemas bilaterales de pitting.',
    'prevencion': 'Monitoreo de crecimiento mensual. Complementación alimentaria. Activar ICBF y programas de recuperación nutricional.',
    'signos_alarma': 'Peso/talla < -3 DE, edema en pies, pelo rojizo y quebradizo. EMERGENCIA: hospitalización inmediata.',
    'municipios_riesgo': ['Toribío', 'Páez', 'Jambaló', 'Caldono', 'Silvia'],
    'nivel_base': 'alerta',
  },
  {
    'codigo': 'DEFCON',  'categoria': 'infantil',
    'nombre': 'Defectos congénitos', 'emoji': '🧬',
    'descripcion': 'Anomalías estructurales o funcionales presentes al nacer. Vigilancia para identificar agrupaciones y causas ambientales.',
    'prevencion': 'Ácido fólico preconcepcional. Evitar teratógenos. Control prenatal. Diagnóstico prenatal.',
    'signos_alarma': 'Notificar toda malformación congénita mayor al sistema de vigilancia. Investigar cluster de casos.',
    'municipios_riesgo': ['Todo el departamento'],
    'nivel_base': 'vigilancia',
  },

  // ══ ENFERMEDADES CRÓNICAS Y NO TRANSMISIBLES ══════════════════════════════
  {
    'codigo': 'CANINF',  'categoria': 'cronicas',
    'nombre': 'Cáncer infantil', 'emoji': '🎗️',
    'descripcion': 'Vigilancia de leucemia, linfoma, tumor cerebral y otros en menores de 18 años. Detección temprana mejora pronóstico.',
    'prevencion': 'No hay prevención primaria clara. Diagnóstico temprano ante síntomas persistentes.',
    'signos_alarma': 'Palidez persistente, fiebre sin foco, sangrado, masas abdominales, adenopatías. Remitir a oncología pediátrica.',
    'municipios_riesgo': ['Todo el departamento'],
    'nivel_base': 'vigilancia',
  },
  {
    'codigo': 'CANMAM',  'categoria': 'cronicas',
    'nombre': 'Cáncer de mama', 'emoji': '🎗️',
    'descripcion': 'Principal cáncer en mujeres colombianas. Vigilancia epidemiológica para monitorear tamización y mortalidad.',
    'prevencion': 'Mamografía cada 2 años en > 50 años. Autoexamen mensual. Conocer factores de riesgo personales y familiares.',
    'signos_alarma': 'Masa palpable, retracción del pezón, cambios en piel. Remisión urgente para estudio.',
    'municipios_riesgo': ['Todo el departamento'],
    'nivel_base': 'vigilancia',
  },
  {
    'codigo': 'CANCX',   'categoria': 'cronicas',
    'nombre': 'Cáncer de cuello uterino', 'emoji': '🎗️',
    'descripcion': 'Segunda causa de muerte por cáncer en mujeres colombianas. 100% prevenible con vacuna VPH y tamización.',
    'prevencion': 'Vacuna VPH en niñas de 9-17 años. Citología cérvico-uterina cada 3 años a partir de inicio de vida sexual.',
    'signos_alarma': 'Sangrado intermenstrual o poscoital, flujo fétido. Toda citología con lesión debe tener seguimiento colposcópico.',
    'municipios_riesgo': ['Todo el departamento — coberturas de citología < 70%'],
    'nivel_base': 'vigilancia',
  },
  {
    'codigo': 'ERC',     'categoria': 'cronicas',
    'nombre': 'Enfermedad renal crónica', 'emoji': '🫘',
    'descripcion': 'Daño renal progresivo. Principal causa: HTA y DM no controladas. Vigilancia para monitorear prevalencia y acceso a diálisis.',
    'prevencion': 'Control estricto de TA y glucemia. Evitar AINES. Detección temprana con creatinina y proteinuria en grupos de riesgo.',
    'signos_alarma': 'Edema, oliguria, fatiga, náuseas en paciente con HTA o DM. Referir a nefrología.',
    'municipios_riesgo': ['Todo el departamento'],
    'nivel_base': 'vigilancia',
  },
  {
    'codigo': 'DIAB',    'categoria': 'cronicas',
    'nombre': 'Diabetes (vigilancias específicas)', 'emoji': '🩸',
    'descripcion': 'Vigilancia epidemiológica de DM tipo 1, tipo 2 y gestacional. Monitoreo de complicaciones agudas y crónicas.',
    'prevencion': 'Dieta saludable. Actividad física. Tamizaje en > 45 años y grupos de riesgo. Educación en autocuidado.',
    'signos_alarma': 'Cetoacidosis (DM1), estado hiperosmolar (DM2), hipoglucemia grave: EMERGENCIAS médicas.',
    'municipios_riesgo': ['Todo el departamento'],
    'nivel_base': 'vigilancia',
  },
  {
    'codigo': 'CARDIO',  'categoria': 'cronicas',
    'nombre': 'Eventos cardiovasculares priorizados', 'emoji': '❤️',
    'descripcion': 'Infarto agudo de miocardio, ACV isquémico y hemorrágico. Primera causa de mortalidad en adultos colombianos.',
    'prevencion': 'Control de HTA, DM, dislipidemia. No fumar. Actividad física. Estatinas según riesgo cardiovascular.',
    'signos_alarma': 'Dolor precordial irradiado, disnea súbita, paresia hemicorporal, alteración del habla. EMERGENCIA: llamar SAMU.',
    'municipios_riesgo': ['Todo el departamento'],
    'nivel_base': 'vigilancia',
  },

  // ══ VIOLENCIAS Y SALUD MENTAL ═════════════════════════════════════════════
  {
    'codigo': 'VIF',     'categoria': 'violencia',
    'nombre': 'Violencia intrafamiliar', 'emoji': '🏠',
    'descripcion': 'Toda forma de violencia en el hogar: física, psicológica, sexual, económica. Notificación obligatoria y activación de ruta.',
    'prevencion': 'Redes de apoyo comunitario. Línea 155 de Profamilia. Casas de la mujer. Comisaría de familia.',
    'signos_alarma': 'TODO caso de violencia es EMERGENCIA. Activar ruta de atención integral inmediatamente.',
    'municipios_riesgo': ['Todo el departamento'],
    'nivel_base': 'alerta',
  },
  {
    'codigo': 'VS',      'categoria': 'violencia',
    'nombre': 'Violencia sexual', 'emoji': '🚨',
    'descripcion': 'Delito sexual incluyendo abuso, violación, acoso. Atención integral en < 72 h para profilaxis de ITS y anticoncepción.',
    'prevencion': 'Línea 155. Activación de ruta de atención a víctimas. No preguntar sobre conducta de la víctima.',
    'signos_alarma': 'Toda víctima de violencia sexual requiere atención de emergencia: profilaxis VIH, anticoncepción de emergencia.',
    'municipios_riesgo': ['Todo el departamento'],
    'nivel_base': 'alerta',
  },
  {
    'codigo': 'IS',      'categoria': 'violencia',
    'nombre': 'Intento de suicidio', 'emoji': '🆘',
    'descripcion': 'Conducta suicida con resultado no fatal. Notificación obligatoria. Puerta de entrada a salud mental.',
    'prevencion': 'Línea 106 de salud mental. Restricción de medios letales. Atención en crisis. Red de apoyo social.',
    'signos_alarma': 'Toda persona con intento de suicidio requiere valoración psiquiátrica y plan de seguridad antes del egreso.',
    'municipios_riesgo': ['Todo el departamento'],
    'nivel_base': 'alerta',
  },
  {
    'codigo': 'POLVO',   'categoria': 'violencia',
    'nombre': 'Lesiones por pólvora', 'emoji': '💥',
    'descripcion': 'Quemaduras y amputaciones por uso de pólvora, especialmente en temporada navideña. Prevenibles.',
    'prevencion': 'No usar pólvora. Sustituir por espectáculos pirotécnicos profesionales. Campaña educativa en comunidades.',
    'signos_alarma': 'Quemadura + amputación en manos/cara/ojos. URGENCIA: traslado a centro con manejo de quemados.',
    'municipios_riesgo': ['Todo el departamento — pico en diciembre'],
    'nivel_base': 'vigilancia',
  },
  {
    'codigo': 'SPA',     'categoria': 'violencia',
    'nombre': 'Consumo de sustancias psicoactivas', 'emoji': '💊',
    'descripcion': 'Vigilancia de consumo de alcohol, tabaco y drogas. Según protocolos INS y Ministerio de Salud vigentes.',
    'prevencion': 'Prevención en escuelas. Acceso a servicios de salud mental. Reducción de daños.',
    'signos_alarma': 'Sobredosis, abstinencia, conducta violenta bajo efecto. Activar atención en crisis.',
    'municipios_riesgo': ['Zonas urbanas y periurbanas'],
    'nivel_base': 'vigilancia',
  },

  // ══ EVENTOS AMBIENTALES Y OCUPACIONALES ════════════════════════════════════
  {
    'codigo': 'PLAGUI',  'categoria': 'ambiental',
    'nombre': 'Intoxicación por plaguicidas', 'emoji': '🌿',
    'descripcion': 'Intoxicación aguda o crónica por organofosforados, carbamatos u otros plaguicidas. Frecuente en zonas agrícolas.',
    'prevencion': 'Uso de EPP en aplicación. Almacenamiento seguro. No ingresar a campos recién fumigados. Señalización.',
    'signos_alarma': 'Miosis, salivación, broncospasmo, convulsiones (organofosforados). URGENCIA: atropina como antídoto.',
    'municipios_riesgo': ['Zonas cafeteras y agrícolas del Cauca'],
    'nivel_base': 'vigilancia',
  },
  {
    'codigo': 'INTMED',  'categoria': 'ambiental',
    'nombre': 'Intoxicación por medicamentos', 'emoji': '💊',
    'descripcion': 'Sobredosis intencional o accidental de medicamentos. Segunda causa de intoxicación en Colombia.',
    'prevencion': 'Almacenamiento seguro de medicamentos. Prescripción racional. Educación en uso seguro.',
    'signos_alarma': 'Somnolencia, alteración del estado de conciencia, vómito, convulsiones. Llamar Línea de Toxicología 018000111444.',
    'municipios_riesgo': ['Todo el departamento'],
    'nivel_base': 'normal',
  },
  {
    'codigo': 'METPES',  'categoria': 'ambiental',
    'nombre': 'Intoxicación por metales pesados', 'emoji': '⚗️',
    'descripcion': 'Intoxicación por mercurio (minería), plomo, cadmio u otros. Daño neurológico y renal crónico.',
    'prevencion': 'Control de minería ilegal de oro. Vigilancia de fuentes de agua en zonas mineras. EPP para mineros.',
    'signos_alarma': 'Temblor + gingivitis + nefropatía en zonas mineras (mercurio). Medición de niveles séricos para confirmación.',
    'municipios_riesgo': ['López de Micay', 'Timbiquí', 'Guapi', 'Buenos Aires'],
    'nivel_base': 'alerta',
  },
  {
    'codigo': 'INTQUIM', 'categoria': 'ambiental',
    'nombre': 'Intoxicación por sustancias químicas', 'emoji': '🧪',
    'descripcion': 'Exposición a solventes, gases tóxicos, cáusticos, ácidos. Industrial y doméstica.',
    'prevencion': 'Hojas de seguridad en industrias. Ventilación. EPP. Manejo seguro de productos del hogar.',
    'signos_alarma': 'Irritación ocular/respiratoria, quemaduras químicas, alteración de conciencia. Llamar Línea de Toxicología.',
    'municipios_riesgo': ['Zonas industriales del Cauca'],
    'nivel_base': 'normal',
  },
  {
    'codigo': 'LESCE',   'categoria': 'ambiental',
    'nombre': 'Lesiones de causa externa', 'emoji': '🚗',
    'descripcion': 'Accidentes de tránsito, caídas, ahogamiento, quemaduras. Principal causa de muerte en jóvenes de 15-29 años.',
    'prevencion': 'Uso de casco y cinturón. No conducir bajo efectos del alcohol. Señalización vial. Piscinas con cercas.',
    'signos_alarma': 'Trauma craneoencefálico, trauma de tórax, abdomen agudo traumático. Activar SAMU inmediatamente.',
    'municipios_riesgo': ['Vías principales del departamento'],
    'nivel_base': 'normal',
  },
  {
    'codigo': 'ACLAB',   'categoria': 'ambiental',
    'nombre': 'Accidentes laborales priorizados', 'emoji': '🦺',
    'descripcion': 'Accidentes graves en trabajo agrícola, minería, construcción. Subregistro alto. Notificación a ARL y SGSST.',
    'prevencion': 'Comités paritarios de seguridad. EPP adecuado. Capacitación en riesgos laborales. Supervisión.',
    'signos_alarma': 'Todo accidente laboral grave o fatal. Notificar a ARL en < 2 días hábiles.',
    'municipios_riesgo': ['Zonas mineras y agrícolas del Cauca'],
    'nivel_base': 'vigilancia',
  },

  // ══ EVENTOS DE VIGILANCIA ESPECIAL ════════════════════════════════════════
  {
    'codigo': 'BROTE',   'categoria': 'especial',
    'nombre': 'Brotes epidémicos', 'emoji': '⚠️',
    'descripcion': 'Incremento inusual de casos de una enfermedad en tiempo, lugar y persona determinados. Requiere investigación inmediata.',
    'prevencion': 'Vigilancia activa. Sistema de alerta temprana. Investigación de campo ante agrupación de casos.',
    'signos_alarma': 'Dos o más casos relacionados de cualquier enfermedad inusual. Notificar y comenzar investigación de brote.',
    'municipios_riesgo': ['Todo el departamento'],
    'nivel_base': 'alerta',
  },
  {
    'codigo': 'IAAS',    'categoria': 'especial',
    'nombre': 'Infecciones asociadas a la atención en salud (IAAS)', 'emoji': '🏥',
    'descripcion': 'Infecciones adquiridas durante la atención en salud. Incluye bacteriemias, neumonías, ITU e infecciones de sitio quirúrgico.',
    'prevencion': 'Higiene de manos. Bundles de prevención de IAAS. Precauciones de aislamiento. Uso racional de antibióticos.',
    'signos_alarma': 'Infección en paciente hospitalizado > 48 h que no estaba en período de incubación al ingreso.',
    'municipios_riesgo': ['Todos los prestadores de servicios de salud'],
    'nivel_base': 'vigilancia',
  },
  {
    'codigo': 'RESIS',   'categoria': 'especial',
    'nombre': 'Resistencia antimicrobiana', 'emoji': '🦠',
    'descripcion': 'Vigilancia de microorganismos resistentes: MRSA, BLEE, KPC, CRE. Amenaza global de salud pública.',
    'prevencion': 'Uso racional de antibióticos. No automedicarse. Prescripción según antibiograma. Higiene de manos.',
    'signos_alarma': 'Aislamiento de bacteria multirresistente. Notificar al laboratorio departamental para vigilancia.',
    'municipios_riesgo': ['Todos los prestadores de servicios de salud'],
    'nivel_base': 'vigilancia',
  },
  {
    'codigo': 'EMERG',   'categoria': 'especial',
    'nombre': 'Eventos emergentes y reemergentes', 'emoji': '🌐',
    'descripcion': 'Enfermedades nuevas o que reaparecen con mayor frecuencia. Ejemplos: mpox, ébola, nuevas variantes virales.',
    'prevencion': 'Vigilancia global activa. Seguimiento de alertas OPS/OMS. Preparación para respuesta rápida.',
    'signos_alarma': 'Cualquier caso de enfermedad inusual, sin diagnóstico, con nexo epidemiológico internacional. NOTIFICAR.',
    'municipios_riesgo': ['Todo el departamento — vigilancia en puertos y fronteras'],
    'nivel_base': 'vigilancia',
  },
  {
    'codigo': 'MORTPRI', 'categoria': 'especial',
    'nombre': 'Mortalidad por enfermedades prioritarias', 'emoji': '📊',
    'descripcion': 'Vigilancia de muertes evitables por enfermedades crónicas, infecciosas y maternas priorizadas en el PIC.',
    'prevencion': 'Fortalecimiento del acceso a servicios. Calidad de la atención. Seguimiento a pacientes con enfermedades crónicas.',
    'signos_alarma': 'Toda muerte por enfermedad priorizada debe reportarse para análisis de mortalidad evitable.',
    'municipios_riesgo': ['Todo el departamento'],
    'nivel_base': 'vigilancia',
  },
];

// ─────────────────────────────────────────────────────────────────────────────
// ALERTAS ACTIVAS (simuladas — reemplazar con datos reales del servidor)
// ─────────────────────────────────────────────────────────────────────────────
final List<Map<String, dynamic>> _kAlertasActivas = [
  {
    'codigo': 'DEN',   'nivel': 'urgente',
    'fecha': DateTime.now().subtract(const Duration(hours: 2)),
    'municipio': 'Santander de Quilichao',
    'mensaje': 'Incremento de casos en últimas 2 semanas. Se activa alerta epidemiológica.',
    'casos': 18,
  },
  {
    'codigo': 'MAL',   'nivel': 'alerta',
    'fecha': DateTime.now().subtract(const Duration(days: 1)),
    'municipio': 'López de Micay',
    'mensaje': 'Casos confirmados de P. falciparum. Reforzar búsqueda activa con gota gruesa.',
    'casos': 5,
  },
  {
    'codigo': 'DESN',  'nivel': 'alerta',
    'fecha': DateTime.now().subtract(const Duration(days: 3)),
    'municipio': 'Toribío',
    'mensaje': 'Tres niños menores de 2 años con desnutrición aguda severa. Activar ICBF.',
    'casos': 3,
  },
  {
    'codigo': 'OFIDIO','nivel': 'alerta',
    'fecha': DateTime.now().subtract(const Duration(hours: 12)),
    'municipio': 'Argelia',
    'mensaje': 'Dos accidentes ofídicos en zona rural. Verificar disponibilidad de suero antiofídico.',
    'casos': 2,
  },
];

// ════════════════════════════════════════════════════════════════════════════
// WIDGET PRINCIPAL
// ════════════════════════════════════════════════════════════════════════════
class AlertasScreen extends StatefulWidget {
  AlertasScreen({super.key});
  @override
  State<AlertasScreen> createState() => _AlertasScreenState();
}

class _AlertasScreenState extends State<AlertasScreen> {
  List<Map<String, dynamic>> _alertasSqlite  = [];
  String _categoriaSeleccionada              = 'todas';
  String _busqueda                           = '';
  bool   _cargando                           = true;
  final  _searchCtrl                         = TextEditingController();

  @override
  void initState() { super.initState(); _cargar(); }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    final lista = await DatabaseHelper.instance.obtenerAlertas();
    final consultasUrgentes =
        await DatabaseHelper.instance.consultasUrgentesRecientes();
    for (final c in consultasUrgentes) {
      final existe = lista.any((a) =>
          a['paciente'] == c['nombre'] && a['modulo'] == c['modulo']);
      if (!existe &&
          (c['nivel_riesgo'] == 'urgente' || c['nivel_riesgo'] == 'alerta')) {
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

  // ── Helpers ──────────────────────────────────────────────────────────────
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

  _Categoria _categoriaInfo(String id) =>
      _kCategorias.firstWhere((c) => c.id == id,
          orElse: () => _kCategorias.first);

  // Eventos filtrados según categoría y búsqueda
  List<Map<String, dynamic>> get _eventosFiltrados {
    var lista = _kEventosSivigila.where((ev) {
      final enCategoria = _categoriaSeleccionada == 'todas' ||
          ev['categoria'] == _categoriaSeleccionada;
      final enBusqueda = _busqueda.isEmpty ||
          (ev['nombre'] as String)
              .toLowerCase()
              .contains(_busqueda.toLowerCase()) ||
          (ev['descripcion'] as String)
              .toLowerCase()
              .contains(_busqueda.toLowerCase());
      return enCategoria && enBusqueda;
    }).toList();
    return lista;
  }

  // ── Modal de detalle ──────────────────────────────────────────────────────
  void _verDetalle(Map<String, dynamic> evento) {
    final catInfo = _categoriaInfo(evento['categoria'] as String? ?? 'todas');
    showModalBottomSheet(
      context: context,
      backgroundColor: _c(context).card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        maxChildSize: 0.94,
        minChildSize: 0.4,
        expand: false,
        builder: (_, ctrl) => SingleChildScrollView(
          controller: ctrl,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // Drag handle
            Center(child: Container(
              width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                  color: _c(context).border,
                  borderRadius: BorderRadius.circular(2)),
            )),

            // Encabezado
            Row(children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: catInfo.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(evento['emoji'] ?? '🦠',
                      style: const TextStyle(fontSize: 26)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(evento['nombre'] ?? '',
                    style: TextStyle(
                        color: _c(context).textPrimary,
                        fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 3),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: catInfo.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${catInfo.emoji} ${catInfo.nombre}',
                      style: TextStyle(color: catInfo.color,
                          fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _nivelColor(evento['nivel_base'])
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _nivelLabel(evento['nivel_base']),
                      style: TextStyle(
                          color: _nivelColor(evento['nivel_base']),
                          fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ]),
              ])),
            ]),

            const SizedBox(height: 16),
            _SeccionDetalle(titulo: '📋 Descripción',
                contenido: evento['descripcion'] ?? ''),
            _SeccionDetalle(titulo: '🛡️ Prevención',
                contenido: evento['prevencion'] ?? ''),
            _SeccionDetalle(titulo: '⚠️ Signos de alarma',
                contenido: evento['signos_alarma'] ?? ''),

            // Municipios en riesgo
            Container(
              width: double.infinity, padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
              ),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('📍 Municipios en riesgo',
                    style: TextStyle(
                        color: Colors.blue, fontSize: 13,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6, runSpacing: 6,
                  children: (evento['municipios_riesgo'] as List<String>)
                      .map((m) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(m,
                                style: const TextStyle(
                                    color: Colors.blue, fontSize: 12)),
                          ))
                      .toList(),
                ),
              ]),
            ),
            const SizedBox(height: 8),
          ]),
        ),
      ),
    );
  }

  // ── Formulario nueva alerta ───────────────────────────────────────────────
  void _mostrarFormularioAlerta() {
    final msgCtrl  = TextEditingController();
    String nivel   = 'alerta';
    String modulo  = 'General';
    String eventoSel = '';

    showModalBottomSheet(
      context: context,
      backgroundColor: _c(context).card,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20,
              MediaQuery.of(ctx).viewInsets.bottom +
                  (MediaQuery.of(ctx).padding.bottom < 16 ? 48
                   : MediaQuery.of(ctx).padding.bottom + 24)),
          child: StatefulBuilder(builder: (_, setS) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Registrar alerta',
                  style: TextStyle(color: _c(context).textPrimary,
                      fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              // Evento SIVIGILA (opcional)
              Text('Evento SIVIGILA (opcional)',
                  style: TextStyle(color: _c(context).textHint, fontSize: 11)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                    color: _c(context).border,
                    borderRadius: BorderRadius.circular(10)),
                child: DropdownButton<String>(
                  value: eventoSel.isEmpty ? null : eventoSel,
                  isExpanded: true, underline: const SizedBox(),
                  dropdownColor: _c(context).card,
                  hint: Text('Seleccionar evento',
                      style: TextStyle(
                          color: _c(context).textHint, fontSize: 13)),
                  style: TextStyle(color: _c(context).textPrimary, fontSize: 13),
                  items: [
                    const DropdownMenuItem(value: '', child: Text('— Ninguno —')),
                    ..._kEventosSivigila.map((ev) => DropdownMenuItem(
                          value: ev['codigo'] as String,
                          child: Text(
                            '${ev['emoji']} ${ev['nombre']}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        )),
                  ],
                  onChanged: (v) => setS(() {
                    eventoSel = v ?? '';
                    if (eventoSel.isNotEmpty) {
                      final ev = _eventoBase(eventoSel);
                      if (ev != null && msgCtrl.text.isEmpty) {
                        msgCtrl.text = ev['descripcion'] ?? '';
                      }
                    }
                  }),
                ),
              ),
              const SizedBox(height: 12),

              // Descripción
              Text('Descripción del evento *',
                  style: TextStyle(color: _c(context).textHint, fontSize: 11)),
              const SizedBox(height: 4),
              TextField(
                controller: msgCtrl, maxLines: 3,
                style: TextStyle(color: _c(context).textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Ej: Tres casos de fiebre con sarpullido en vereda La Esperanza...',
                  hintStyle: TextStyle(color: _c(context).border, fontSize: 13),
                  filled: true, fillColor: _c(context).border,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),

              // Nivel y módulo
              Row(children: [
                Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Nivel', style: TextStyle(
                      color: _c(context).textHint, fontSize: 11)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                        color: _c(context).border,
                        borderRadius: BorderRadius.circular(10)),
                    child: DropdownButton<String>(
                      value: nivel, isExpanded: true,
                      underline: const SizedBox(),
                      dropdownColor: _c(context).card,
                      style: TextStyle(color: _c(context).textPrimary, fontSize: 14),
                      items: const [
                        DropdownMenuItem(value: 'urgente', child: Text('🚨 Urgente')),
                        DropdownMenuItem(value: 'alerta',  child: Text('⚠️ Alerta')),
                        DropdownMenuItem(value: 'normal',  child: Text('✅ Vigilancia')),
                      ],
                      onChanged: (v) => setS(() => nivel = v!),
                    ),
                  ),
                ])),
                const SizedBox(width: 12),
                Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Módulo', style: TextStyle(
                      color: _c(context).textHint, fontSize: 11)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                        color: _c(context).border,
                        borderRadius: BorderRadius.circular(10)),
                    child: DropdownButton<String>(
                      value: modulo, isExpanded: true,
                      underline: const SizedBox(),
                      dropdownColor: _c(context).card,
                      style: TextStyle(color: _c(context).textPrimary, fontSize: 14),
                      items: ['General','Gestación','Primera infancia','Infancia',
                              'Adolescencia','Juventud','Adultez','Vejez']
                          .map((m) => DropdownMenuItem(
                              value: m,
                              child: Text(m, overflow: TextOverflow.ellipsis)))
                          .toList(),
                      onChanged: (v) => setS(() => modulo = v!),
                    ),
                  ),
                ])),
              ]),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity, height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    if (msgCtrl.text.trim().isEmpty) return;
                    await DatabaseHelper.instance.insertarAlerta({
                      'modulo':   modulo,
                      'paciente': '',
                      'mensaje':  msgCtrl.text.trim(),
                      'nivel':    nivel,
                      'resuelta': 0,
                    });
                    Navigator.pop(ctx);
                    _cargar();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: const Text('Alerta registrada correctamente'),
                        backgroundColor: _kVerde,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ));
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kVerde,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Guardar alerta',
                      style: TextStyle(
                          color: _c(context).textPrimary,
                          fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 8),
            ],
          )),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final urgentes =
        _kAlertasActivas.where((a) => a['nivel'] == 'urgente').length;
    final eventos  = _eventosFiltrados;

    return Scaffold(
      backgroundColor: _c(context).bg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _cargar,
          color: _kVerde,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [

              // ── Header + buscador ───────────────────────────────────────
              SliverToBoxAdapter(child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                  // Título
                  Row(children: [
                    Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Alertas SIVIGILA',
                          style: TextStyle(color: _c(context).textPrimary,
                              fontSize: 22, fontWeight: FontWeight.bold)),
                      Text('Notificación obligatoria · INS Colombia',
                          style: TextStyle(color: _c(context).textHint,
                              fontSize: 12)),
                    ])),
                    if (urgentes > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.red.withValues(alpha: 0.5)),
                        ),
                        child: Text(
                          '$urgentes urgente${urgentes > 1 ? 's' : ''}',
                          style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ]),

                  const SizedBox(height: 14),

                  // Buscador
                  TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _busqueda = v),
                    style: TextStyle(
                        color: _c(context).textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Buscar enfermedad o evento...',
                      hintStyle: TextStyle(
                          color: _c(context).textHint, fontSize: 13),
                      prefixIcon: Icon(Icons.search,
                          color: _c(context).textHint, size: 20),
                      suffixIcon: _busqueda.isNotEmpty
                          ? GestureDetector(
                              onTap: () {
                                _searchCtrl.clear();
                                setState(() => _busqueda = '');
                              },
                              child: Icon(Icons.close,
                                  color: _c(context).textHint, size: 18))
                          : null,
                      filled: true, fillColor: _c(context).card,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 12),
                ]),
              )),

              // ── Filtro por categorías ───────────────────────────────────
              SliverToBoxAdapter(child: SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _kCategorias.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final cat    = _kCategorias[i];
                    final activo = _categoriaSeleccionada == cat.id;
                    return GestureDetector(
                      onTap: () =>
                          setState(() => _categoriaSeleccionada = cat.id),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: activo
                              ? cat.color
                              : _c(context).card,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: activo
                                  ? cat.color
                                  : _c(context).border,
                              width: 1.2),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Text(cat.emoji,
                              style: const TextStyle(fontSize: 13)),
                          const SizedBox(width: 5),
                          Text(cat.nombre,
                              style: TextStyle(
                                color: activo
                                    ? Colors.white
                                    : _c(context).textSecondary,
                                fontSize: 12,
                                fontWeight: activo
                                    ? FontWeight.w700
                                    : FontWeight.normal,
                              )),
                        ]),
                      ),
                    );
                  },
                ),
              )),

              SliverToBoxAdapter(child: const SizedBox(height: 16)),

              // ── Alertas activas (solo si categoría = todas y sin búsqueda) ──
              if (_categoriaSeleccionada == 'todas' && _busqueda.isEmpty) ...[
                SliverToBoxAdapter(child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: Text('Alertas activas en tu zona',
                      style: TextStyle(color: _c(context).textSecondary,
                          fontSize: 13, fontWeight: FontWeight.w600)),
                )),
                SliverList(delegate: SliverChildBuilderDelegate(
                  (_, i) {
                    final a   = _kAlertasActivas[i];
                    final ev  = _eventoBase(a['codigo']);
                    final clr = _nivelColor(a['nivel']);
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                      child: GestureDetector(
                        onTap: ev != null ? () => _verDetalle(ev) : null,
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: _c(context).card,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: clr.withValues(alpha: 0.5)),
                          ),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Row(children: [
                              Text(ev?['emoji'] ?? '🦠',
                                  style: const TextStyle(fontSize: 24)),
                              const SizedBox(width: 10),
                              Expanded(child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start, children: [
                                Text(ev?['nombre'] ?? a['codigo'],
                                    style: TextStyle(
                                        color: _c(context).textPrimary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold)),
                                Text(
                                  '${a['municipio']} · '
                                  '${_tiempoRelativo(a['fecha'])}',
                                  style: TextStyle(
                                      color: _c(context).textHint,
                                      fontSize: 11),
                                ),
                              ])),
                              Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: clr.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(_nivelLabel(a['nivel']),
                                      style: TextStyle(
                                          color: clr,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold)),
                                ),
                                if ((a['casos'] as int) > 0) ...[
                                  const SizedBox(height: 4),
                                  Text('${a['casos']} casos',
                                      style: TextStyle(
                                          color: clr.withValues(alpha: 0.8),
                                          fontSize: 11)),
                                ],
                              ]),
                            ]),
                            const SizedBox(height: 8),
                            Text(a['mensaje'],
                                style: TextStyle(
                                    color: _c(context).textSecondary,
                                    fontSize: 12, height: 1.4)),
                            const SizedBox(height: 6),
                            Text('Toca para ver protocolo →',
                                style: TextStyle(color: clr, fontSize: 11)),
                          ]),
                        ),
                      ),
                    );
                  },
                  childCount: _kAlertasActivas.length,
                )),

                // Alertas del promotor
                SliverToBoxAdapter(child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                  child: Row(children: [
                    Expanded(child: Text('Alertas registradas por ti',
                        style: TextStyle(color: _c(context).textSecondary,
                            fontSize: 13, fontWeight: FontWeight.w600))),
                    TextButton(
                      onPressed: _mostrarFormularioAlerta,
                      child: const Text('+ Registrar alerta',
                          style: TextStyle(color: _kVerde, fontSize: 12)),
                    ),
                  ]),
                )),

                SliverToBoxAdapter(child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _cargando
                      ? const Center(
                          child: CircularProgressIndicator(color: _kVerde))
                      : _alertasSqlite.isEmpty
                          ? Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: _c(context).card,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                    color: _c(context).border),
                              ),
                              child: Column(children: [
                                Icon(Icons.notifications_off_outlined,
                                    color: _c(context).border, size: 36),
                                const SizedBox(height: 10),
                                Text('Sin alertas registradas',
                                    style: TextStyle(
                                        color: _c(context).textHint,
                                        fontSize: 14)),
                                const SizedBox(height: 4),
                                Text(
                                  'Registra eventos inusuales que '
                                  'observes en tu comunidad.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: _c(context).textHint,
                                      fontSize: 12),
                                ),
                              ]),
                            )
                          : Column(
                              children: _alertasSqlite.map((a) {
                                final clr =
                                    _nivelColor(a['nivel'] ?? 'normal');
                                final resuelta =
                                    (a['resuelta'] as int? ?? 0) == 1;
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: _c(context).card,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: resuelta
                                          ? Colors.white12
                                          : clr.withValues(alpha: 0.4),
                                    ),
                                  ),
                                  child: Row(children: [
                                    Expanded(child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                      Text(a['mensaje'] ?? '',
                                          style: TextStyle(
                                            color: resuelta
                                                ? Colors.white38
                                                : Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          )),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${a['modulo'] ?? ''} · '
                                        '${a['paciente'] ?? ''} · '
                                        '${a['fecha'] ?? ''}',
                                        style: TextStyle(
                                            color: _c(context).textHint,
                                            fontSize: 11),
                                      ),
                                    ])),
                                    if (!resuelta)
                                      GestureDetector(
                                        onTap: () =>
                                            _resolverAlerta(a['id']),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: _kVerde
                                                .withValues(alpha: 0.15),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: const Text('Resolver',
                                              style: TextStyle(
                                                  color: _kVerde,
                                                  fontSize: 12,
                                                  fontWeight:
                                                      FontWeight.w600)),
                                        ),
                                      )
                                    else
                                      Icon(Icons.check_circle_outline,
                                          color: _c(context).border,
                                          size: 20),
                                  ]),
                                );
                              }).toList(),
                            ),
                )),
                SliverToBoxAdapter(child: const SizedBox(height: 20)),
              ],

              // ── Catálogo SIVIGILA ──────────────────────────────────────
              SliverToBoxAdapter(child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Row(children: [
                  Expanded(child: Text(
                    _categoriaSeleccionada == 'todas' && _busqueda.isEmpty
                        ? 'Guía completa SIVIGILA (${eventos.length} eventos)'
                        : _busqueda.isNotEmpty
                            ? 'Resultados para "$_busqueda" (${eventos.length})'
                            : '${_categoriaInfo(_categoriaSeleccionada).emoji} '
                              '${_categoriaInfo(_categoriaSeleccionada).nombre} '
                              '(${eventos.length})',
                    style: TextStyle(color: _c(context).textSecondary,
                        fontSize: 13, fontWeight: FontWeight.w600),
                  )),
                  if (!_cargando && _categoriaSeleccionada == 'todas')
                    Text('${_kEventosSivigila.length} total',
                        style: TextStyle(
                            color: _c(context).textHint, fontSize: 11)),
                ]),
              )),

              eventos.isEmpty
                  ? SliverToBoxAdapter(child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Center(child: Text(
                        'No se encontraron eventos',
                        style: TextStyle(
                            color: _c(context).textHint, fontSize: 14),
                      )),
                    ))
                  : SliverList(delegate: SliverChildBuilderDelegate(
                      (_, i) {
                        final ev  = eventos[i];
                        final clr = _nivelColor(ev['nivel_base']);
                        final cat = _categoriaInfo(
                            ev['categoria'] as String? ?? 'todas');
                        return Padding(
                          padding:
                              const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: GestureDetector(
                            onTap: () => _verDetalle(ev),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: _c(context).card,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: _c(context).border),
                              ),
                              child: Row(children: [
                                // Emoji con fondo de categoría
                                Container(
                                  width: 40, height: 40,
                                  decoration: BoxDecoration(
                                    color:
                                        cat.color.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Center(
                                      child: Text(ev['emoji'],
                                          style: const TextStyle(
                                              fontSize: 20))),
                                ),
                                const SizedBox(width: 12),
                                Expanded(child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start, children: [
                                  Text(ev['nombre'],
                                      style: TextStyle(
                                          color: _c(context).textPrimary,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 2),
                                  Text(ev['descripcion'],
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          color: _c(context).textHint,
                                          fontSize: 11)),
                                ])),
                                const SizedBox(width: 8),
                                Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.end, children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: clr.withValues(alpha: 0.12),
                                      borderRadius:
                                          BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      ev['nivel_base']
                                          .toString()
                                          .toUpperCase(),
                                      style: TextStyle(
                                          color: clr,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Icon(Icons.chevron_right,
                                      color: _c(context).border, size: 16),
                                ]),
                              ]),
                            ),
                          ),
                        );
                      },
                      childCount: eventos.length,
                    )),

              SliverToBoxAdapter(child: const SizedBox(height: 32)),
            ],
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// WIDGETS AUXILIARES
// ═════════════════════════════════════════════════════════════════════════════
class _SeccionDetalle extends StatelessWidget {
  final String titulo, contenido;
  const _SeccionDetalle({required this.titulo, required this.contenido});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _c(context).bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(titulo,
              style: TextStyle(color: _c(context).textSecondary,
                  fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(contenido,
              style: TextStyle(
                  color: _c(context).textHint, fontSize: 13, height: 1.5)),
        ]),
      );
}