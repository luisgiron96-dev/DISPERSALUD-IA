import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../database/database_helper.dart';

// ════════════════════════════════════════════════════════════════════════════
//  alertas_screen.dart  —  DISPERSALUD IA
//  Diseño: dashboard SIVIGILA con métricas, mapa, urgentes, alertas, seguimiento
// ════════════════════════════════════════════════════════════════════════════

const Color _kVerde   = Color(0xFF1D9E75);
const Color _kDark    = Color(0xFF0F6E56);
const Color _kRojo    = Color(0xFFE24B4A);
const Color _kNaranja = Color(0xFFEF9F27);
const Color _kAzul    = Color(0xFF185FA5);

DispersaludColors _c(BuildContext ctx) =>
    Theme.of(ctx).extension<DispersaludColors>() ?? DispersaludColors.dark;

// ─────────────────────────────────────────────────────────────────────────────
// CATEGORÍAS SIVIGILA
// ─────────────────────────────────────────────────────────────────────────────
class _Categoria {
  final String id, nombre, emoji;
  final Color color;
  const _Categoria({required this.id, required this.nombre,
      required this.emoji, required this.color});
}

const List<_Categoria> _kCategorias = [
  _Categoria(id: 'todas',     nombre: 'Todos',             emoji: '🗂️',  color: Color(0xFF1D9E75)),
  _Categoria(id: 'urgente',   nombre: 'Urgentes',          emoji: '🚨',  color: Color(0xFFE24B4A)),
  _Categoria(id: 'vectores',  nombre: 'Vectores',          emoji: '🦟',  color: Color(0xFF3B6D11)),
  _Categoria(id: 'inmuno',    nombre: 'Inmunoprevenibles', emoji: '💉',  color: Color(0xFF185FA5)),
  _Categoria(id: 'respira',   nombre: 'Respiratorias',     emoji: '🫁',  color: Color(0xFF534AB7)),
  _Categoria(id: 'alimentos', nombre: 'Alimentos/Agua',    emoji: '💧',  color: Color(0xFF0F6E56)),
  _Categoria(id: 'its',       nombre: 'ITS',               emoji: '🔬',  color: Color(0xFF993556)),
  _Categoria(id: 'zoonosis',  nombre: 'Zoonosis',          emoji: '🐾',  color: Color(0xFF854F0B)),
  _Categoria(id: 'materna',   nombre: 'Materna',           emoji: '🤰',  color: Color(0xFF993556)),
  _Categoria(id: 'infantil',  nombre: 'Infantil',          emoji: '👶',  color: Color(0xFF854F0B)),
  _Categoria(id: 'cronicas',  nombre: 'Crónicas',          emoji: '🏥',  color: Color(0xFF5F5E5A)),
  _Categoria(id: 'violencia', nombre: 'Violencias',        emoji: '🚨',  color: Color(0xFFE24B4A)),
  _Categoria(id: 'ambiental', nombre: 'Ambiental',         emoji: '🏭',  color: Color(0xFFEF9F27)),
  _Categoria(id: 'especial',  nombre: 'Vigilancia especial', emoji: '⚠️', color: Color(0xFFE24B4A)),
];

// ─────────────────────────────────────────────────────────────────────────────
// CATÁLOGO SIVIGILA COMPLETO
// ─────────────────────────────────────────────────────────────────────────────
const List<Map<String, dynamic>> _kEventos = [
  // VECTORES
  { 'codigo':'DEN',    'categoria':'vectores', 'nombre':'Dengue',                'emoji':'🦟', 'nivel_base':'urgente',
    'descripcion':'Enfermedad viral transmitida por Aedes aegypti. Vigilancia activa en temporada de lluvias.',
    'prevencion':'Eliminar criaderos de agua estancada. Usar toldillos y repelente con DEET.',
    'signos_alarma':'Fiebre alta súbita, dolor retroocular, sarpullido. EMERGENCIA: sangrado, vómito persistente.',
    'municipios_riesgo':['Santander de Quilichao','Puerto Tejada','Caloto','Corinto','Popayán'],
    'casos':18, 'tendencia':42 },
  { 'codigo':'DENGV',  'categoria':'vectores', 'nombre':'Dengue grave',           'emoji':'🦟', 'nivel_base':'urgente',
    'descripcion':'Forma severa del dengue con choque, hemorragia o compromiso grave de órganos.',
    'prevencion':'Identificar signos de alarma. No automedicar con AINES.',
    'signos_alarma':'EMERGENCIA: Choque, hemorragia grave, falla respiratoria.',
    'municipios_riesgo':['Todo el departamento en temporada de lluvias'], 'casos':3, 'tendencia':100 },
  { 'codigo':'CHIK',   'categoria':'vectores', 'nombre':'Chikunguña',             'emoji':'🦟', 'nivel_base':'vigilancia',
    'descripcion':'Infección viral por arbovirus. Artritis severa característica.',
    'prevencion':'Control vectorial. Repelente y toldillos.',
    'signos_alarma':'Fiebre alta + artralgia severa bilateral.',
    'municipios_riesgo':['Santander de Quilichao','Puerto Tejada','Miranda'], 'casos':4, 'tendencia':0 },
  { 'codigo':'ZIKA',   'categoria':'vectores', 'nombre':'Zika',                   'emoji':'🦟', 'nivel_base':'vigilancia',
    'descripcion':'Transmisión vectorial y sexual. Riesgo de microcefalia en embarazadas.',
    'prevencion':'Protección vectorial. Relaciones protegidas en zonas endémicas.',
    'signos_alarma':'Exantema + fiebre + artralgia + conjuntivitis. URGENTE en embarazadas.',
    'municipios_riesgo':['Zonas bajo los 2200 msnm'], 'casos':1, 'tendencia':0 },
  { 'codigo':'MAL',    'categoria':'vectores', 'nombre':'Malaria',                'emoji':'🦠', 'nivel_base':'alerta',
    'descripcion':'Parasitosis transmitida por Anopheles. P. falciparum: forma grave con alta mortalidad.',
    'prevencion':'Toldillos impregnados. Rociamiento intradomiciliario.',
    'signos_alarma':'Fiebre intermitente, escalofríos. EMERGENCIA: alteración de conciencia.',
    'municipios_riesgo':['López de Micay','Timbiquí','Guapi','Santa Bárbara'], 'casos':5, 'tendencia':15 },
  { 'codigo':'LEISH',  'categoria':'vectores', 'nombre':'Leishmaniasis',          'emoji':'🦠', 'nivel_base':'vigilancia',
    'descripcion':'Transmitida por flebotomíneos. Formas: cutánea, mucocutánea y visceral.',
    'prevencion':'Repelente y ropa en zonas boscosas.',
    'signos_alarma':'Úlcera indolora. Fiebre + pérdida peso + esplenomegalia = URGENTE.',
    'municipios_riesgo':['Argelia','El Tambo','Balboa','La Vega'], 'casos':2, 'tendencia':0 },
  { 'codigo':'CHAGAS', 'categoria':'vectores', 'nombre':'Enfermedad de Chagas',   'emoji':'🐛', 'nivel_base':'vigilancia',
    'descripcion':'Infección por Trypanosoma cruzi transmitida por triatominos.',
    'prevencion':'Mejora de vivienda. Tamizaje en donantes de sangre.',
    'signos_alarma':'Chagoma. Fase crónica: arritmias, cardiomegalia.',
    'municipios_riesgo':['Zonas rurales del norte del Cauca'], 'casos':0, 'tendencia':0 },
  { 'codigo':'FAMAR',  'categoria':'vectores', 'nombre':'Fiebre amarilla',        'emoji':'🟡', 'nivel_base':'alerta',
    'descripcion':'Enfermedad viral hemorrágica. Vacunable. Notificación inmediata.',
    'prevencion':'Vacunación obligatoria en zonas de riesgo.',
    'signos_alarma':'Fiebre + ictericia + hemorragia = EMERGENCIA NACIONAL.',
    'municipios_riesgo':['Zonas selváticas del Cauca'], 'casos':0, 'tendencia':0 },
  // INMUNOPREVENIBLES
  { 'codigo':'SARAM',  'categoria':'inmuno', 'nombre':'Sarampión',                'emoji':'💉', 'nivel_base':'urgente',
    'descripcion':'Altamente contagioso. Un caso es emergencia de salud pública.',
    'prevencion':'Vacunación 2 dosis SRP. Cobertura > 95%.',
    'signos_alarma':'Fiebre + exantema + tos + coriza + conjuntivitis. NOTIFICAR INMEDIATAMENTE.',
    'municipios_riesgo':['Todo el departamento'], 'casos':3, 'tendencia':0 },
  { 'codigo':'RUBE',   'categoria':'inmuno', 'nombre':'Rubéola',                  'emoji':'💉', 'nivel_base':'vigilancia',
    'descripcion':'Teratogénica en primer trimestre. Colombia en eliminación.',
    'prevencion':'Vacunación SRP en mujeres edad fértil.',
    'signos_alarma':'Exantema rosado + adenopatías. URGENTE en embarazadas.',
    'municipios_riesgo':['Todo el departamento'], 'casos':0, 'tendencia':0 },
  { 'codigo':'SRC',    'categoria':'inmuno', 'nombre':'Síndrome rubéola congénita','emoji':'👶', 'nivel_base':'vigilancia',
    'descripcion':'Malformaciones por rubéola materna: cardiopatía, cataratas, sordera.',
    'prevencion':'Vacunación preconcepcional.',
    'signos_alarma':'RN con cataratas + soplo cardíaco + microcefalia.',
    'municipios_riesgo':['Todo el departamento'], 'casos':0, 'tendencia':0 },
  { 'codigo':'TOSF',   'categoria':'inmuno', 'nombre':'Tos ferina',               'emoji':'💉', 'nivel_base':'vigilancia',
    'descripcion':'Muy grave en menores de 6 meses. Reemergente.',
    'prevencion':'DPT/Pentavalente. Tdap en embarazadas.',
    'signos_alarma':'Tos paroxística + estridor + cianosis. EMERGENCIA < 6 meses.',
    'municipios_riesgo':['Todo el departamento'], 'casos':1, 'tendencia':0 },
  { 'codigo':'DIFT',   'categoria':'inmuno', 'nombre':'Difteria',                 'emoji':'💉', 'nivel_base':'alerta',
    'descripcion':'Pseudomembrana faríngea, toxina cardíaca y neurológica.',
    'prevencion':'Vacunación DPT > 95%.',
    'signos_alarma':'Faringitis con membrana grisácea. Un caso = EMERGENCIA.',
    'municipios_riesgo':['Zonas con bajas coberturas'], 'casos':0, 'tendencia':0 },
  { 'codigo':'TETNEO', 'categoria':'inmuno', 'nombre':'Tétanos neonatal',         'emoji':'💉', 'nivel_base':'alerta',
    'descripcion':'Neonatos por Clostridium tetani. Indicador de partos sin asistencia.',
    'prevencion':'Toxoide tetánico en embarazadas. Parto limpio.',
    'signos_alarma':'RN que al 3-7 días presenta trismus + espasmos.',
    'municipios_riesgo':['Zonas rurales con partos domiciliarios'], 'casos':0, 'tendencia':0 },
  { 'codigo':'PFA',    'categoria':'inmuno', 'nombre':'Parálisis flácida aguda',  'emoji':'🦽', 'nivel_base':'alerta',
    'descripcion':'Vigilancia centinela de poliomielitis en < 15 años.',
    'prevencion':'OPV/IPV > 95%.',
    'signos_alarma':'Parálisis súbita, flácida, asimétrica. NOTIFICAR < 24 H.',
    'municipios_riesgo':['Todo el departamento'], 'casos':0, 'tendencia':0 },
  { 'codigo':'MENB',   'categoria':'inmuno', 'nombre':'Meningitis bacteriana',    'emoji':'🧠', 'nivel_base':'alerta',
    'descripcion':'Infección grave de meninges por N. meningitidis, S. pneumoniae.',
    'prevencion':'Vacunas Hib, neumocócica y meningocócica.',
    'signos_alarma':'Fiebre + cefalea + rigidez de nuca + fotofobia. EMERGENCIA MÉDICA.',
    'municipios_riesgo':['Todo el departamento'], 'casos':1, 'tendencia':0 },
  { 'codigo':'ESAVI',  'categoria':'inmuno', 'nombre':'ESAVI',                    'emoji':'⚡', 'nivel_base':'vigilancia',
    'descripcion':'Evento adverso tras vacunación. Notificación obligatoria.',
    'prevencion':'Técnica correcta. Espera 30 min post-vacuna.',
    'signos_alarma':'Anafilaxia, convulsiones, absceso post-vacuna.',
    'municipios_riesgo':['Todo el departamento'], 'casos':0, 'tendencia':0 },
  // RESPIRATORIAS
  { 'codigo':'IRA',    'categoria':'respira', 'nombre':'IRA',                     'emoji':'🤧', 'nivel_base':'vigilancia',
    'descripcion':'Principal causa de mortalidad infantil evitable en Colombia.',
    'prevencion':'Vacunación neumocócica. Lactancia materna exclusiva.',
    'signos_alarma':'Dificultad respiratoria, tiraje, cianosis. EMERGENCIA < 2 meses.',
    'municipios_riesgo':['Silvia','Inzá','Puracé','La Vega'], 'casos':12, 'tendencia':8 },
  { 'codigo':'IRAG1',  'categoria':'respira', 'nombre':'IRAG inusitado',          'emoji':'😷', 'nivel_base':'alerta',
    'descripcion':'IRA grave de etiología desconocida. Vigilancia centinela hospitalaria.',
    'prevencion':'Bioseguridad en UCI. Aislamiento.',
    'signos_alarma':'Neumonía grave sin agente + falla respiratoria. NOTIFICAR INMEDIATO.',
    'municipios_riesgo':['Todo el departamento'], 'casos':0, 'tendencia':0 },
  { 'codigo':'IRAGV',  'categoria':'respira', 'nombre':'IRAG por virus nuevos',   'emoji':'🦠', 'nivel_base':'alerta',
    'descripcion':'IRA grave por virus nuevo tipo (pandémica, coronavirus emergente).',
    'prevencion':'Control de infecciones. Notificación a red de laboratorios INS.',
    'signos_alarma':'Neumonía grave en cluster o nexo epidemiológico. ALERTA INMEDIATA.',
    'municipios_riesgo':['Todo el departamento'], 'casos':0, 'tendencia':0 },
  { 'codigo':'COV',    'categoria':'respira', 'nombre':'COVID-19',                'emoji':'😷', 'nivel_base':'vigilancia',
    'descripcion':'SARS-CoV-2. Vigilancia según lineamientos INS vigentes.',
    'prevencion':'Ventilación de espacios. Vacunación completa.',
    'signos_alarma':'Fiebre + tos + dificultad respiratoria. Saturación < 94%.',
    'municipios_riesgo':['Todo el departamento'], 'casos':5, 'tendencia':-10 },
  { 'codigo':'TBP',    'categoria':'respira', 'nombre':'Tuberculosis pulmonar',   'emoji':'🫁', 'nivel_base':'vigilancia',
    'descripcion':'Transmisión aérea. Principal causa infecciosa de muerte mundial.',
    'prevencion':'Baciloscopía. DOTS 6 meses. BCG al nacer.',
    'signos_alarma':'Tos > 15 días, pérdida de peso, sudoración nocturna. Hemoptisis = urgente.',
    'municipios_riesgo':['Popayán','Santander de Quilichao','Miranda'], 'casos':8, 'tendencia':5 },
  { 'codigo':'TBE',    'categoria':'respira', 'nombre':'Tuberculosis extrapulmonar','emoji':'🫁','nivel_base':'vigilancia',
    'descripcion':'TB en ganglios, pleura, meninges, hueso, riñón u otros.',
    'prevencion':'Investigación de contactos. Tratamiento supervisado.',
    'signos_alarma':'Síntomas sistémicos + compromiso órgano. TB meníngea: cefalea, rigidez.',
    'municipios_riesgo':['Todo el departamento'], 'casos':2, 'tendencia':0 },
  // ALIMENTOS Y AGUA
  { 'codigo':'EDA',    'categoria':'alimentos', 'nombre':'Enfermedad diarreica aguda','emoji':'💧','nivel_base':'alerta',
    'descripcion':'Infección gastrointestinal. Principal causa de desnutrición.',
    'prevencion':'Agua hervida. Lavado de manos. Lactancia materna.',
    'signos_alarma':'Diarrea > 3/día. EMERGENCIA menores: deshidratación grave.',
    'municipios_riesgo':['Toribío','Páez','La Sierra','El Tambo'], 'casos':12, 'tendencia':20 },
  { 'codigo':'COLERA', 'categoria':'alimentos', 'nombre':'Cólera',               'emoji':'💧', 'nivel_base':'alerta',
    'descripcion':'Diarrea acuosa profusa. Deshidratación severa en horas.',
    'prevencion':'Agua potable. Saneamiento básico. Vacuna oral en brotes.',
    'signos_alarma':'Diarrea en agua de arroz + deshidratación rápida. UN CASO = EMERGENCIA.',
    'municipios_riesgo':['Zonas costeras del Cauca'], 'casos':0, 'tendencia':0 },
  { 'codigo':'HEPA',   'categoria':'alimentos', 'nombre':'Hepatitis A',          'emoji':'🍽️', 'nivel_base':'vigilancia',
    'descripcion':'Transmisión fecal-oral. Brotes en zonas sin saneamiento.',
    'prevencion':'Agua segura. Saneamiento. Vacuna para grupos de riesgo.',
    'signos_alarma':'Ictericia + coluria + acolia + fiebre.',
    'municipios_riesgo':['Zonas sin acueducto'], 'casos':3, 'tendencia':0 },
  { 'codigo':'ETA',    'categoria':'alimentos', 'nombre':'ETA',                  'emoji':'🍽️', 'nivel_base':'vigilancia',
    'descripcion':'Intoxicaciones por alimentos contaminados. Dos o más casos notificables.',
    'prevencion':'Cadena de frío. Cocción adecuada. Higiene.',
    'signos_alarma':'Dos o más casos tras comer mismo alimento. Conservar muestras.',
    'municipios_riesgo':['Todo el departamento'], 'casos':0, 'tendencia':0 },
  // ITS
  { 'codigo':'VIH',    'categoria':'its', 'nombre':'VIH/SIDA',                   'emoji':'🔴', 'nivel_base':'vigilancia',
    'descripcion':'Notificación obligatoria y confidencial. TARV garantizado.',
    'prevencion':'Condón. Prueba voluntaria. Profilaxis pre/post-exposición.',
    'signos_alarma':'Infecciones oportunistas, pérdida de peso, linfadenopatía.',
    'municipios_riesgo':['Todo el departamento'], 'casos':17, 'tendencia':0 },
  { 'codigo':'SIFGEST','categoria':'its', 'nombre':'Sífilis gestacional',        'emoji':'🤰', 'nivel_base':'vigilancia',
    'descripcion':'Indicador de calidad prenatal. Transmisible al feto.',
    'prevencion':'VDRL en primer control y tercer trimestre. Penicilina benzatínica.',
    'signos_alarma':'VDRL reactivo en embarazada. Tratamiento inmediato.',
    'municipios_riesgo':['Todo el departamento'], 'casos':4, 'tendencia':0 },
  { 'codigo':'SIFCONG','categoria':'its', 'nombre':'Sífilis congénita',          'emoji':'👶', 'nivel_base':'vigilancia',
    'descripcion':'Infección del RN por T. pallidum vía transplacentaria.',
    'prevencion':'Prevención y tratamiento de sífilis gestacional.',
    'signos_alarma':'RN + hepatomegalia + pénfigo palmoplantar + rinitis hemorrágica.',
    'municipios_riesgo':['Todo el departamento'], 'casos':1, 'tendencia':0 },
  { 'codigo':'HEPB',   'categoria':'its', 'nombre':'Hepatitis B',                'emoji':'🔬', 'nivel_base':'vigilancia',
    'descripcion':'Riesgo de cirrosis y hepatocarcinoma. Transmisión sexual y perinatal.',
    'prevencion':'Vacunación universal. Primera dosis < 12h nacimiento.',
    'signos_alarma':'Ictericia, fatiga, náuseas, dolor hipocondrio derecho.',
    'municipios_riesgo':['Todo el departamento'], 'casos':2, 'tendencia':0 },
  { 'codigo':'HEPC',   'categoria':'its', 'nombre':'Hepatitis C',                'emoji':'🔬', 'nivel_base':'vigilancia',
    'descripcion':'Principal causa de trasplante hepático. Curable con antivirales.',
    'prevencion':'No compartir material de inyección. Screening grupos de riesgo.',
    'signos_alarma':'Mayoría asintomática. Detectar por anti-VHC.',
    'municipios_riesgo':['Todo el departamento'], 'casos':1, 'tendencia':0 },
  // ZOONOSIS
  { 'codigo':'RABIAH', 'categoria':'zoonosis', 'nombre':'Rabia humana',          'emoji':'🐺', 'nivel_base':'alerta',
    'descripcion':'Mortal una vez aparecen síntomas. 100% prevenible con profilaxis.',
    'prevencion':'Lavado inmediato + vacuna + inmunoglobulina tras mordedura.',
    'signos_alarma':'Hidrofobia, aerofobia, agitación. Un caso = EMERGENCIA NACIONAL.',
    'municipios_riesgo':['Zonas rurales con murciélagos y animales silvestres'], 'casos':0, 'tendencia':0 },
  { 'codigo':'RABIAA', 'categoria':'zoonosis', 'nombre':'Rabia animal',          'emoji':'🐶', 'nivel_base':'vigilancia',
    'descripcion':'Rabia en perros, gatos, bovinos, murciélagos.',
    'prevencion':'Vacunación masiva canina. Control murciélagos hematófagos.',
    'signos_alarma':'Animal con cambios comportamiento, agresividad, disfagia. Aislar.',
    'municipios_riesgo':['Zonas rurales del Cauca'], 'casos':0, 'tendencia':0 },
  { 'codigo':'EXPRAB', 'categoria':'zoonosis', 'nombre':'Exposición rábica',     'emoji':'🩹', 'nivel_base':'vigilancia',
    'descripcion':'Mordedura con animal sospechoso. Inicio inmediato de profilaxis.',
    'prevencion':'Lavado profundo con agua y jabón. Vacuna + inmunoglobulina.',
    'signos_alarma':'Mordedura de murciélago, perro sin vacunar. Profilaxis ANTES de confirmar.',
    'municipios_riesgo':['Todo el departamento'], 'casos':1, 'tendencia':0 },
  { 'codigo':'LEPTO',  'categoria':'zoonosis', 'nombre':'Leptospirosis',         'emoji':'🌊', 'nivel_base':'vigilancia',
    'descripcion':'Por Leptospira. Contacto con agua contaminada con orina de roedores.',
    'prevencion':'Botas y guantes en zonas inundadas. Control de roedores.',
    'signos_alarma':'Fiebre + cefalea + mialgias + sufusión conjuntival. Forma grave: ictericia + IR.',
    'municipios_riesgo':['Zonas de inundación y comunidades agrícolas'], 'casos':1, 'tendencia':0 },
  { 'codigo':'OFIDIO', 'categoria':'zoonosis', 'nombre':'Accidente ofídico',     'emoji':'🐍', 'nivel_base':'alerta',
    'descripcion':'Mordedura de serpiente venenosa. Urgencia médica.',
    'prevencion':'Botas altas en zonas rurales. Suero antiofídico disponible.',
    'signos_alarma':'Mordedura + edema + sangrado. Suero en < 6 h. EMERGENCIA.',
    'municipios_riesgo':['Argelia','El Tambo','Balboa','López de Micay'], 'casos':2, 'tendencia':0 },
  // MATERNA
  { 'codigo':'MM',     'categoria':'materna', 'nombre':'Mortalidad materna',     'emoji':'🤰', 'nivel_base':'urgente',
    'descripcion':'Muerte durante embarazo, parto o 42 días posparto.',
    'prevencion':'Control prenatal de calidad. Atención del parto calificada.',
    'signos_alarma':'Toda muerte materna = notificación obligatoria < 24 h.',
    'municipios_riesgo':['Todo el departamento rural'], 'casos':2, 'tendencia':100 },
  { 'codigo':'MPN',    'categoria':'materna', 'nombre':'Mortalidad perinatal',   'emoji':'👶', 'nivel_base':'alerta',
    'descripcion':'Muerte fetal tardía o neonatal < 28 días.',
    'prevencion':'Control prenatal. Reanimación neonatal.',
    'signos_alarma':'Todo óbito fetal o muerte neonatal debe notificarse.',
    'municipios_riesgo':['Todo el departamento'], 'casos':1, 'tendencia':0 },
  { 'codigo':'MME',    'categoria':'materna', 'nombre':'Morbilidad materna extrema','emoji':'🚑','nivel_base':'vigilancia',
    'descripcion':'Mujer que casi muere por complicación grave del embarazo.',
    'prevencion':'Detección temprana. Protocolos de hemorragia y eclampsia.',
    'signos_alarma':'Eclampsia, choque hemorrágico, sepsis. Sobrevivió pero notificar.',
    'municipios_riesgo':['Todo el departamento'], 'casos':3, 'tendencia':0 },
  { 'codigo':'BPN',    'categoria':'materna', 'nombre':'Bajo peso al nacer',     'emoji':'⚖️', 'nivel_base':'vigilancia',
    'descripcion':'RN < 2500 g. Indicador de desnutrición materna.',
    'prevencion':'Nutrición materna. Control prenatal. Micronutrientes.',
    'signos_alarma':'RN < 2500 g: hipoglucemia, hipotermia, infecciones.',
    'municipios_riesgo':['Páez','Toribío','Jambaló','Silvia'], 'casos':5, 'tendencia':0 },
  // INFANTIL
  { 'codigo':'MME5',   'categoria':'infantil', 'nombre':'Mortalidad < 5 años',   'emoji':'👶', 'nivel_base':'alerta',
    'descripcion':'Indicador de desarrollo. Causas: neumonía, diarrea, malnutrición.',
    'prevencion':'Vacunación completa. Lactancia materna. Agua segura.',
    'signos_alarma':'Toda muerte < 5 años requiere notificación e investigación.',
    'municipios_riesgo':['Resguardos indígenas con barreras de acceso'], 'casos':0, 'tendencia':0 },
  { 'codigo':'DESN',   'categoria':'infantil', 'nombre':'Desnutrición aguda < 5 años','emoji':'⚖️','nivel_base':'alerta',
    'descripcion':'P/T < -2 DE (moderada) o < -3 DE (severa). Edemas bilaterales.',
    'prevencion':'Monitoreo mensual. Complementación alimentaria. Activar ICBF.',
    'signos_alarma':'P/T < -3 DE, edema en pies. EMERGENCIA: hospitalización inmediata.',
    'municipios_riesgo':['Toribío','Páez','Jambaló','Caldono'], 'casos':5, 'tendencia':10 },
  { 'codigo':'DEFCON', 'categoria':'infantil', 'nombre':'Defectos congénitos',   'emoji':'🧬', 'nivel_base':'vigilancia',
    'descripcion':'Anomalías estructurales al nacer. Vigilancia de agrupaciones.',
    'prevencion':'Ácido fólico preconcepcional. Evitar teratógenos.',
    'signos_alarma':'Notificar toda malformación congénita mayor.',
    'municipios_riesgo':['Todo el departamento'], 'casos':0, 'tendencia':0 },
  // CRÓNICAS
  { 'codigo':'CANINF', 'categoria':'cronicas', 'nombre':'Cáncer infantil',       'emoji':'🎗️', 'nivel_base':'vigilancia',
    'descripcion':'Leucemia, linfoma, tumor cerebral en < 18 años.',
    'prevencion':'Diagnóstico temprano ante síntomas persistentes.',
    'signos_alarma':'Palidez, fiebre sin foco, masas abdominales. Remitir oncología.',
    'municipios_riesgo':['Todo el departamento'], 'casos':1, 'tendencia':0 },
  { 'codigo':'CANMAM', 'categoria':'cronicas', 'nombre':'Cáncer de mama',        'emoji':'🎗️', 'nivel_base':'vigilancia',
    'descripcion':'Principal cáncer en mujeres colombianas.',
    'prevencion':'Mamografía cada 2 años en > 50. Autoexamen mensual.',
    'signos_alarma':'Masa palpable, retracción del pezón, cambios en piel.',
    'municipios_riesgo':['Todo el departamento'], 'casos':3, 'tendencia':0 },
  { 'codigo':'CANCX',  'categoria':'cronicas', 'nombre':'Cáncer cuello uterino', 'emoji':'🎗️', 'nivel_base':'vigilancia',
    'descripcion':'100% prevenible con vacuna VPH y tamización.',
    'prevencion':'Vacuna VPH 9-17 años. Citología cada 3 años.',
    'signos_alarma':'Sangrado intermenstrual o poscoital, flujo fétido.',
    'municipios_riesgo':['Todo el departamento'], 'casos':2, 'tendencia':0 },
  { 'codigo':'ERC',    'categoria':'cronicas', 'nombre':'Enfermedad renal crónica','emoji':'🫘','nivel_base':'vigilancia',
    'descripcion':'Daño renal progresivo. Causa: HTA y DM no controladas.',
    'prevencion':'Control TA y glucemia. Evitar AINES.',
    'signos_alarma':'Edema, oliguria, fatiga en paciente con HTA o DM.',
    'municipios_riesgo':['Todo el departamento'], 'casos':4, 'tendencia':0 },
  { 'codigo':'DIAB',   'categoria':'cronicas', 'nombre':'Diabetes',              'emoji':'🩸', 'nivel_base':'vigilancia',
    'descripcion':'DM tipo 1, tipo 2 y gestacional. Monitoreo de complicaciones.',
    'prevencion':'Dieta saludable. Actividad física. Tamizaje en > 45 años.',
    'signos_alarma':'Cetoacidosis, estado hiperosmolar, hipoglucemia grave = EMERGENCIA.',
    'municipios_riesgo':['Todo el departamento'], 'casos':23, 'tendencia':5 },
  { 'codigo':'CARDIO', 'categoria':'cronicas', 'nombre':'Eventos cardiovasculares','emoji':'❤️','nivel_base':'vigilancia',
    'descripcion':'IAM, ACV. Primera causa de mortalidad en adultos.',
    'prevencion':'Control HTA, DM, dislipidemia. No fumar. Actividad física.',
    'signos_alarma':'Dolor precordial, disnea súbita, paresia hemicorporal. SAMU.',
    'municipios_riesgo':['Todo el departamento'], 'casos':6, 'tendencia':0 },
  // VIOLENCIAS
  { 'codigo':'VIF',    'categoria':'violencia', 'nombre':'Violencia intrafamiliar','emoji':'🏠','nivel_base':'alerta',
    'descripcion':'Violencia física, psicológica, sexual, económica en el hogar.',
    'prevencion':'Línea 155 Profamilia. Comisaría de familia.',
    'signos_alarma':'TODO caso = EMERGENCIA. Activar ruta inmediatamente.',
    'municipios_riesgo':['Todo el departamento'], 'casos':8, 'tendencia':15 },
  { 'codigo':'VS',     'categoria':'violencia', 'nombre':'Violencia sexual',     'emoji':'🚨', 'nivel_base':'alerta',
    'descripcion':'Atención integral en < 72 h para profilaxis ITS y anticoncepción.',
    'prevencion':'Línea 155. Activación de ruta de atención.',
    'signos_alarma':'Toda víctima: profilaxis VIH, anticoncepción de emergencia.',
    'municipios_riesgo':['Todo el departamento'], 'casos':3, 'tendencia':0 },
  { 'codigo':'IS',     'categoria':'violencia', 'nombre':'Intento de suicidio',  'emoji':'🆘', 'nivel_base':'alerta',
    'descripcion':'Conducta suicida no fatal. Puerta de entrada a salud mental.',
    'prevencion':'Línea 106 salud mental. Restricción de medios letales.',
    'signos_alarma':'Valoración psiquiátrica y plan de seguridad antes del egreso.',
    'municipios_riesgo':['Todo el departamento'], 'casos':2, 'tendencia':0 },
  { 'codigo':'POLVO',  'categoria':'violencia', 'nombre':'Lesiones por pólvora', 'emoji':'💥', 'nivel_base':'vigilancia',
    'descripcion':'Quemaduras y amputaciones. Pico en temporada navideña.',
    'prevencion':'No usar pólvora. Pirotecnia profesional.',
    'signos_alarma':'Quemadura + amputación manos/cara/ojos. URGENCIA.',
    'municipios_riesgo':['Todo el departamento'], 'casos':0, 'tendencia':0 },
  { 'codigo':'SPA',    'categoria':'violencia', 'nombre':'Consumo de SPA',       'emoji':'💊', 'nivel_base':'vigilancia',
    'descripcion':'Alcohol, tabaco y drogas. Según protocolos INS vigentes.',
    'prevencion':'Prevención en escuelas. Reducción de daños.',
    'signos_alarma':'Sobredosis, abstinencia, conducta violenta. Atención en crisis.',
    'municipios_riesgo':['Zonas urbanas y periurbanas'], 'casos':4, 'tendencia':0 },
  // AMBIENTAL
  { 'codigo':'PLAGUI', 'categoria':'ambiental', 'nombre':'Intox. plaguicidas',   'emoji':'🌿', 'nivel_base':'vigilancia',
    'descripcion':'Organofosforados, carbamatos. Frecuente en zonas agrícolas.',
    'prevencion':'EPP en aplicación. Almacenamiento seguro.',
    'signos_alarma':'Miosis, salivación, broncospasmo, convulsiones. URGENCIA: atropina.',
    'municipios_riesgo':['Zonas cafeteras del Cauca'], 'casos':2, 'tendencia':0 },
  { 'codigo':'INTMED', 'categoria':'ambiental', 'nombre':'Intox. medicamentos',  'emoji':'💊', 'nivel_base':'vigilancia',
    'descripcion':'Sobredosis intencional o accidental. Segunda causa de intoxicación.',
    'prevencion':'Almacenamiento seguro. Prescripción racional.',
    'signos_alarma':'Somnolencia, alteración conciencia. Línea Toxicología 018000111444.',
    'municipios_riesgo':['Todo el departamento'], 'casos':1, 'tendencia':0 },
  { 'codigo':'METPES', 'categoria':'ambiental', 'nombre':'Intox. metales pesados','emoji':'⚗️','nivel_base':'alerta',
    'descripcion':'Mercurio (minería), plomo, cadmio. Daño neurológico y renal.',
    'prevencion':'Control minería ilegal. EPP para mineros.',
    'signos_alarma':'Temblor + gingivitis + nefropatía en zonas mineras.',
    'municipios_riesgo':['López de Micay','Timbiquí','Guapi'], 'casos':1, 'tendencia':0 },
  { 'codigo':'INTQUIM','categoria':'ambiental', 'nombre':'Intox. sustancias químicas','emoji':'🧪','nivel_base':'vigilancia',
    'descripcion':'Solventes, gases tóxicos, cáusticos. Industrial y doméstica.',
    'prevencion':'Hojas de seguridad. Ventilación. EPP.',
    'signos_alarma':'Irritación ocular/respiratoria, quemaduras químicas.',
    'municipios_riesgo':['Zonas industriales'], 'casos':0, 'tendencia':0 },
  { 'codigo':'LESCE',  'categoria':'ambiental', 'nombre':'Lesiones causa externa','emoji':'🚗','nivel_base':'vigilancia',
    'descripcion':'Accidentes de tránsito, caídas, ahogamiento. Principal causa muerte jóvenes.',
    'prevencion':'Casco y cinturón. No conducir bajo efectos del alcohol.',
    'signos_alarma':'TCE, trauma tórax, abdomen agudo. SAMU inmediatamente.',
    'municipios_riesgo':['Vías principales del departamento'], 'casos':5, 'tendencia':0 },
  { 'codigo':'ACLAB',  'categoria':'ambiental', 'nombre':'Accidentes laborales', 'emoji':'🦺', 'nivel_base':'vigilancia',
    'descripcion':'Graves en trabajo agrícola, minería, construcción.',
    'prevencion':'Comités paritarios. EPP. Capacitación.',
    'signos_alarma':'Todo accidente laboral grave o fatal. Notificar ARL < 2 días.',
    'municipios_riesgo':['Zonas mineras y agrícolas'], 'casos':2, 'tendencia':0 },
  // ESPECIAL
  { 'codigo':'BROTE',  'categoria':'especial', 'nombre':'Brotes epidémicos',     'emoji':'⚠️', 'nivel_base':'alerta',
    'descripcion':'Incremento inusual de casos. Requiere investigación inmediata.',
    'prevencion':'Vigilancia activa. Sistema de alerta temprana.',
    'signos_alarma':'Dos o más casos relacionados inusuales. Notificar e investigar.',
    'municipios_riesgo':['Todo el departamento'], 'casos':2, 'tendencia':0 },
  { 'codigo':'IAAS',   'categoria':'especial', 'nombre':'IAAS',                  'emoji':'🏥', 'nivel_base':'vigilancia',
    'descripcion':'Infecciones adquiridas en la atención en salud.',
    'prevencion':'Higiene de manos. Bundles de prevención. Uso racional ATB.',
    'signos_alarma':'Infección en hospitalizado > 48 h sin período de incubación al ingreso.',
    'municipios_riesgo':['Todos los prestadores de salud'], 'casos':3, 'tendencia':0 },
  { 'codigo':'RESIS',  'categoria':'especial', 'nombre':'Resistencia antimicrobiana','emoji':'🦠','nivel_base':'vigilancia',
    'descripcion':'MRSA, BLEE, KPC, CRE. Amenaza global de salud pública.',
    'prevencion':'Uso racional de antibióticos. No automedicarse.',
    'signos_alarma':'Aislamiento de bacteria multirresistente. Notificar laboratorio.',
    'municipios_riesgo':['Todos los prestadores de salud'], 'casos':1, 'tendencia':0 },
  { 'codigo':'EMERG',  'categoria':'especial', 'nombre':'Eventos emergentes/reemergentes','emoji':'🌐','nivel_base':'vigilancia',
    'descripcion':'Enfermedades nuevas o que reaparecen (mpox, ébola, nuevas variantes).',
    'prevencion':'Vigilancia global activa. Seguimiento alertas OPS/OMS.',
    'signos_alarma':'Enfermedad inusual con nexo epidemiológico internacional. NOTIFICAR.',
    'municipios_riesgo':['Todo el departamento'], 'casos':0, 'tendencia':0 },
  { 'codigo':'MORTPRI','categoria':'especial', 'nombre':'Mortalidad enf. prioritarias','emoji':'📊','nivel_base':'vigilancia',
    'descripcion':'Muertes evitables por enfermedades priorizadas en el PIC.',
    'prevencion':'Fortalecimiento del acceso. Calidad de la atención.',
    'signos_alarma':'Toda muerte por enfermedad priorizada debe reportarse.',
    'municipios_riesgo':['Todo el departamento'], 'casos':0, 'tendencia':0 },
];

// ─────────────────────────────────────────────────────────────────────────────
// MUNICIPIOS DEL MAPA (simplificado)
// ─────────────────────────────────────────────────────────────────────────────
const _kMunicipios = [
  {'nombre': 'Santander de Quilichao', 'nivel': 'alto'},
  {'nombre': 'Toribío',                'nivel': 'medio'},
  {'nombre': 'López de Micay',         'nivel': 'medio'},
  {'nombre': 'Argelia',                'nivel': 'bajo'},
  {'nombre': 'Popayán',                'nivel': 'bajo'},
  {'nombre': 'El Tambo',               'nivel': 'bajo'},
];

// ════════════════════════════════════════════════════════════════════════════
// PANTALLA PRINCIPAL
// ════════════════════════════════════════════════════════════════════════════
class AlertasScreen extends StatefulWidget {
  AlertasScreen({super.key});
  @override
  State<AlertasScreen> createState() => _AlertasScreenState();
}

class _AlertasScreenState extends State<AlertasScreen> {
  List<Map<String, dynamic>> _alertasDB = [];
  String _categoriaSeleccionada = 'todas';
  String _busqueda = '';
  bool _cargando = true;
  bool _mostrarTodosUrgentes = false;
  bool _mostrarTodasAlertas  = false;
  bool _mostrarTodosSeguimiento = false;
  final _searchCtrl = TextEditingController();

  @override
  void initState() { super.initState(); _cargar(); }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      final lista = await DatabaseHelper.instance.obtenerAlertas();
      final urgentes = await DatabaseHelper.instance.consultasUrgentesRecientes();
      for (final c in urgentes) {
        final existe = lista.any((a) =>
            a['paciente'] == c['nombre'] && a['modulo'] == c['modulo']);
        if (!existe && (c['nivel_riesgo'] == 'urgente' || c['nivel_riesgo'] == 'alerta')) {
          await DatabaseHelper.instance.insertarAlerta({
            'modulo': c['modulo'] ?? '', 'paciente': c['nombre'] ?? 'Paciente',
            'mensaje': c['diagnostico'] ?? 'Consulta con nivel de riesgo elevado',
            'nivel': c['nivel_riesgo'] ?? 'alerta', 'resuelta': 0,
          });
        }
      }
      final final_ = await DatabaseHelper.instance.obtenerAlertas();
      setState(() { _alertasDB = final_; _cargando = false; });
    } catch (_) { setState(() => _cargando = false); }
  }

  Future<void> _resolverAlerta(int id) async {
    await DatabaseHelper.instance.resolverAlerta(id);
    _cargar();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  Color _nivelColor(String nivel) {
    switch (nivel) {
      case 'urgente': return _kRojo;
      case 'alerta':  return _kNaranja;
      case 'vigilancia': return _kVerde;
      default: return _kVerde;
    }
  }

  IconData _nivelIcon(String nivel) {
    switch (nivel) {
      case 'urgente': return Icons.warning_rounded;
      case 'alerta':  return Icons.warning_amber_rounded;
      default:        return Icons.check_circle_rounded;
    }
  }

  String _nivelLabel(String nivel) {
    switch (nivel) {
      case 'urgente': return '🚨 URGENTE';
      case 'alerta':  return '⚠️ ALERTA';
      default:        return '✅ VIGILANCIA';
    }
  }

  String _tendenciaStr(int t) {
    if (t > 0) return '+$t%';
    if (t < 0) return '$t%';
    return 'Estable';
  }

  Map<String, dynamic>? _eventoBase(String codigo) {
    try { return _kEventos.firstWhere((e) => e['codigo'] == codigo); }
    catch (_) { return null; }
  }

  _Categoria _catInfo(String id) =>
      _kCategorias.firstWhere((c) => c.id == id, orElse: () => _kCategorias.first);

  // Contadores
  int get _totalUrgentes    => _kEventos.where((e) => e['nivel_base'] == 'urgente').length;
  int get _totalAlertas     => _kEventos.where((e) => e['nivel_base'] == 'alerta').length;
  int get _totalSeguimiento => _kEventos.where((e) => e['nivel_base'] == 'vigilancia').fold(0, (s, e) => s + (e['casos'] as int));
  int get _totalEventos     => _kEventos.length;

  List<Map<String, dynamic>> get _urgentes =>
      _kEventos.where((e) => e['nivel_base'] == 'urgente' && (e['casos'] as int) > 0).toList();
  List<Map<String, dynamic>> get _alertas =>
      _kEventos.where((e) => e['nivel_base'] == 'alerta'  && (e['casos'] as int) > 0).toList();
  List<Map<String, dynamic>> get _seguimiento =>
      _kEventos.where((e) => e['nivel_base'] == 'vigilancia' && (e['casos'] as int) > 0).toList();

  List<Map<String, dynamic>> get _eventosFiltrados {
    return _kEventos.where((ev) {
      final enCat = _categoriaSeleccionada == 'todas' ||
          (_categoriaSeleccionada == 'urgente' && ev['nivel_base'] == 'urgente') ||
          ev['categoria'] == _categoriaSeleccionada;
      final enBusqueda = _busqueda.isEmpty ||
          (ev['nombre'] as String).toLowerCase().contains(_busqueda.toLowerCase()) ||
          (ev['descripcion'] as String).toLowerCase().contains(_busqueda.toLowerCase());
      return enCat && enBusqueda;
    }).toList();
  }

  // ── Modal detalle ──────────────────────────────────────────────────────────
  void _verDetalle(Map<String, dynamic> ev) {
    final cat = _catInfo(ev['categoria'] as String? ?? 'todas');
    final clr = _nivelColor(ev['nivel_base']);
    showModalBottomSheet(
      context: context,
      backgroundColor: _c(context).card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.65, maxChildSize: 0.94, minChildSize: 0.4,
        expand: false,
        builder: (_, ctrl) => SingleChildScrollView(
          controller: ctrl,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: _c(context).border,
                    borderRadius: BorderRadius.circular(2)))),
            Row(children: [
              Container(width: 56, height: 56,
                decoration: BoxDecoration(color: cat.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16)),
                child: Center(child: Text(ev['emoji'],
                    style: const TextStyle(fontSize: 28)))),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(ev['nombre'], style: TextStyle(color: _c(context).textPrimary,
                    fontSize: 17, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Row(children: [
                  _Badge(label: '${cat.emoji} ${cat.nombre}', color: cat.color),
                  const SizedBox(width: 6),
                  _Badge(label: _nivelLabel(ev['nivel_base']), color: clr),
                ]),
              ])),
            ]),
            if ((ev['casos'] as int) > 0) ...[
              const SizedBox(height: 12),
              Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(color: clr.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: clr.withValues(alpha: 0.3))),
                child: Row(children: [
                  Text('${ev['casos']}', style: TextStyle(color: clr,
                      fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('casos registrados', style: TextStyle(
                        color: _c(context).textSecondary, fontSize: 12)),
                    if ((ev['tendencia'] as int) != 0)
                      Text(_tendenciaStr(ev['tendencia']),
                          style: TextStyle(color: (ev['tendencia'] as int) > 0
                              ? _kRojo : _kVerde,
                              fontSize: 12, fontWeight: FontWeight.bold)),
                  ]),
                ])),
            ],
            const SizedBox(height: 14),
            _DetalleSec('📋 Descripción',   ev['descripcion']),
            _DetalleSec('🛡️ Prevención',    ev['prevencion']),
            _DetalleSec('⚠️ Signos de alarma', ev['signos_alarma']),
            Container(padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: _kAzul.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _kAzul.withValues(alpha: 0.3))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('📍 Municipios en riesgo', style: TextStyle(color: _kAzul,
                    fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(spacing: 6, runSpacing: 6,
                  children: (ev['municipios_riesgo'] as List<String>)
                      .map((m) => Container(padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: _kAzul.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20)),
                          child: Text(m, style: const TextStyle(
                              color: _kAzul, fontSize: 12)))).toList()),
              ])),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.description_outlined, size: 16),
                label: const Text('Ver protocolo'),
                style: OutlinedButton.styleFrom(foregroundColor: _kVerde,
                    side: const BorderSide(color: _kVerde),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10))),
              )),
              const SizedBox(width: 10),
              Expanded(child: ElevatedButton.icon(
                onPressed: () { Navigator.pop(context); _mostrarFormulario(); },
                icon: const Icon(Icons.add_circle_outline, size: 16),
                label: const Text('Reportar caso'),
                style: ElevatedButton.styleFrom(backgroundColor: _kVerde,
                    foregroundColor: Colors.white, elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10))),
              )),
            ]),
          ]),
        ),
      ),
    );
  }

  // ── Formulario nueva alerta ────────────────────────────────────────────────
  void _mostrarFormulario([Map<String, dynamic>? eventoPreseleccionado]) {
    final msgCtrl = TextEditingController(
        text: eventoPreseleccionado?['descripcion'] ?? '');
    String nivel = eventoPreseleccionado != null
        ? (eventoPreseleccionado['nivel_base'] ?? 'alerta')
        : 'alerta';
    String modulo  = 'General';
    String eventoSel = eventoPreseleccionado?['codigo'] ?? '';

    showModalBottomSheet(
      context: context,
      backgroundColor: _c(context).card,
      isScrollControlled: true, useSafeArea: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20,
            MediaQuery.of(ctx).viewInsets.bottom + 32),
        child: SingleChildScrollView(child: StatefulBuilder(
          builder: (_, ss) => Column(mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: _c(context).border,
                    borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text('Reportar caso / Registrar alerta',
                style: TextStyle(color: _c(context).textPrimary,
                    fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _LabelField('Evento SIVIGILA'),
            Container(padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(color: _c(context).bg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _c(context).border)),
              child: DropdownButton<String>(
                value: eventoSel.isEmpty ? null : eventoSel,
                isExpanded: true, underline: const SizedBox(),
                dropdownColor: _c(context).card,
                hint: Text('Seleccionar evento',
                    style: TextStyle(color: _c(context).textHint, fontSize: 13)),
                style: TextStyle(color: _c(context).textPrimary, fontSize: 13),
                items: [
                  const DropdownMenuItem(value: '', child: Text('— Ninguno —')),
                  ..._kEventos.map((ev) => DropdownMenuItem(
                      value: ev['codigo'] as String,
                      child: Text('${ev['emoji']} ${ev['nombre']}',
                          overflow: TextOverflow.ellipsis))),
                ],
                onChanged: (v) => ss(() {
                  eventoSel = v ?? '';
                  if (eventoSel.isNotEmpty) {
                    final ev = _eventoBase(eventoSel);
                    if (ev != null && msgCtrl.text.isEmpty) {
                      msgCtrl.text = ev['descripcion'] ?? '';
                    }
                    nivel = ev?['nivel_base'] ?? 'alerta';
                  }
                }),
              )),
            const SizedBox(height: 12),
            _LabelField('Descripción del evento *'),
            TextField(controller: msgCtrl, maxLines: 3,
              style: TextStyle(color: _c(context).textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Describe el evento observado...',
                hintStyle: TextStyle(color: _c(context).textHint, fontSize: 13),
                filled: true, fillColor: _c(context).bg,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: _c(context).border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: _c(context).border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: _kVerde, width: 1.5)),
              )),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _LabelField('Nivel'),
                Container(padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(color: _c(context).bg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _c(context).border)),
                  child: DropdownButton<String>(value: nivel,
                    isExpanded: true, underline: const SizedBox(),
                    dropdownColor: _c(context).card,
                    style: TextStyle(color: _c(context).textPrimary, fontSize: 13),
                    items: const [
                      DropdownMenuItem(value: 'urgente', child: Text('🚨 Urgente')),
                      DropdownMenuItem(value: 'alerta',  child: Text('⚠️ Alerta')),
                      DropdownMenuItem(value: 'normal',  child: Text('✅ Vigilancia')),
                    ],
                    onChanged: (v) => ss(() => nivel = v!),
                  )),
              ])),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _LabelField('Módulo'),
                Container(padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(color: _c(context).bg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _c(context).border)),
                  child: DropdownButton<String>(value: modulo,
                    isExpanded: true, underline: const SizedBox(),
                    dropdownColor: _c(context).card,
                    style: TextStyle(color: _c(context).textPrimary, fontSize: 13),
                    items: ['General','Gestación','Primera infancia','Infancia',
                            'Adolescencia','Juventud','Adultez','Vejez']
                        .map((m) => DropdownMenuItem(value: m,
                            child: Text(m, overflow: TextOverflow.ellipsis)))
                        .toList(),
                    onChanged: (v) => ss(() => modulo = v!),
                  )),
              ])),
            ]),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, height: 48,
              child: ElevatedButton(
                onPressed: () async {
                  if (msgCtrl.text.trim().isEmpty) return;
                  await DatabaseHelper.instance.insertarAlerta({
                    'modulo': modulo, 'paciente': '',
                    'mensaje': msgCtrl.text.trim(),
                    'nivel': nivel, 'resuelta': 0,
                  });
                  Navigator.pop(ctx);
                  _cargar();
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: const Text('Alerta registrada correctamente'),
                    backgroundColor: _kVerde, behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ));
                },
                style: ElevatedButton.styleFrom(backgroundColor: _kVerde,
                    foregroundColor: Colors.white, elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('Guardar alerta',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              )),
          ]),
        )),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // BUILD PRINCIPAL
  // ════════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final eventos = _eventosFiltrados;
    final mostrarDashboard = _categoriaSeleccionada == 'todas' && _busqueda.isEmpty;

    return Scaffold(
      backgroundColor: _c(context).bg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _cargar, color: _kVerde,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [

              // ── HEADER ────────────────────────────────────────────────────
              SliverToBoxAdapter(child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Eventos SIVIGILA', style: TextStyle(
                        color: _c(context).textPrimary,
                        fontSize: 22, fontWeight: FontWeight.bold)),
                    Text('Vigilancia en salud pública · INS Colombia',
                        style: TextStyle(color: _c(context).textHint, fontSize: 12)),
                  ])),
                  // Badge urgentes
                  GestureDetector(
                    onTap: _mostrarFormulario,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: _kRojo.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _kRojo.withValues(alpha: 0.4)),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.add_circle_outline_rounded,
                            color: _kRojo, size: 15),
                        const SizedBox(width: 5),
                        Text('${_urgentes.length} urgentes',
                            style: const TextStyle(color: _kRojo,
                                fontSize: 12, fontWeight: FontWeight.bold)),
                      ]),
                    ),
                  ),
                ]),
              )),

              // ── MÉTRICAS 4 CARDS ──────────────────────────────────────────
              SliverToBoxAdapter(child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(children: [
                  _MetricaCard(num: _urgentes.length.toString(),
                      label: 'Urgentes', sub: 'Requieren acción inmediata',
                      color: _kRojo, icon: Icons.warning_rounded),
                  const SizedBox(width: 8),
                  _MetricaCard(num: _alertas.length.toString(),
                      label: 'Alertas', sub: 'Requieren seguimiento',
                      color: _kNaranja, icon: Icons.warning_amber_rounded),
                  const SizedBox(width: 8),
                  _MetricaCard(num: _totalSeguimiento.toString(),
                      label: 'En seguimiento', sub: 'Casos bajo vigilancia',
                      color: _kVerde, icon: Icons.check_circle_rounded),
                  const SizedBox(width: 8),
                  _MetricaCard(num: _totalEventos.toString(),
                      label: 'Eventos vigilados', sub: 'En tu jurisdicción',
                      color: _kAzul, icon: Icons.description_outlined),
                ]),
              )),

              // ── BUSCADOR + FILTROS ────────────────────────────────────────
              SliverToBoxAdapter(child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _busqueda = v),
                  style: TextStyle(color: _c(context).textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Buscar enfermedad o evento...',
                    hintStyle: TextStyle(color: _c(context).textHint, fontSize: 13),
                    prefixIcon: Icon(Icons.search, color: _c(context).textHint, size: 20),
                    suffixIcon: _busqueda.isNotEmpty
                        ? GestureDetector(
                            onTap: () { _searchCtrl.clear(); setState(() => _busqueda = ''); },
                            child: Icon(Icons.close, color: _c(context).textHint, size: 18))
                        : null,
                    filled: true, fillColor: _c(context).card,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                  ),
                ),
              )),

              // ── CHIPS DE CATEGORÍAS ───────────────────────────────────────
              SliverToBoxAdapter(child: SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _kCategorias.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final cat = _kCategorias[i];
                    final activo = _categoriaSeleccionada == cat.id;
                    return GestureDetector(
                      onTap: () => setState(() => _categoriaSeleccionada = cat.id),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: activo ? cat.color : _c(context).card,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: activo ? cat.color : _c(context).border,
                              width: 1.2),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Text(cat.emoji, style: const TextStyle(fontSize: 12)),
                          const SizedBox(width: 5),
                          Text(cat.nombre, style: TextStyle(
                            color: activo ? Colors.white : _c(context).textSecondary,
                            fontSize: 12,
                            fontWeight: activo ? FontWeight.w700 : FontWeight.normal,
                          )),
                        ]),
                      ),
                    );
                  },
                ),
              )),

              SliverToBoxAdapter(child: const SizedBox(height: 16)),

              // ════════════════════════════════════════════════════════════════
              // VISTA DASHBOARD (categoría = todas y sin búsqueda)
              // ════════════════════════════════════════════════════════════════
              if (mostrarDashboard) ...[

                // ── MAPA EPIDEMIOLÓGICO ───────────────────────────────────────
                SliverToBoxAdapter(child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: _MapaEpidemiologico(context),
                )),

                // ── SECCIÓN URGENTES ─────────────────────────────────────────
                if (_urgentes.isNotEmpty) ...[
                  SliverToBoxAdapter(child: _SeccionHeader(
                    icono: Icons.warning_rounded, color: _kRojo,
                    titulo: 'Urgentes', count: _urgentes.length,
                    onVerTodas: () => setState(() => _mostrarTodosUrgentes = !_mostrarTodosUrgentes),
                    mostrando: _mostrarTodosUrgentes,
                  )),
                  SliverToBoxAdapter(child: SizedBox(
                    height: 200,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                      itemCount: _mostrarTodosUrgentes
                          ? _urgentes.length
                          : (_urgentes.length > 3 ? 3 : _urgentes.length),
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (_, i) => _TarjetaEvento(
                        ev: _urgentes[i], color: _kRojo,
                        onVerProtocolo: () => _verDetalle(_urgentes[i]),
                        onReportar: () => _mostrarFormulario(_urgentes[i]),
                      ),
                    ),
                  )),
                  SliverToBoxAdapter(child: const SizedBox(height: 16)),
                ],

                // ── SECCIÓN ALERTAS ───────────────────────────────────────────
                if (_alertas.isNotEmpty) ...[
                  SliverToBoxAdapter(child: _SeccionHeader(
                    icono: Icons.warning_amber_rounded, color: _kNaranja,
                    titulo: 'Alertas', count: _alertas.length,
                    onVerTodas: () => setState(() => _mostrarTodasAlertas = !_mostrarTodasAlertas),
                    mostrando: _mostrarTodasAlertas,
                  )),
                  SliverToBoxAdapter(child: SizedBox(
                    height: 200,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                      itemCount: _mostrarTodasAlertas
                          ? _alertas.length
                          : (_alertas.length > 3 ? 3 : _alertas.length),
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (_, i) => _TarjetaEvento(
                        ev: _alertas[i], color: _kNaranja,
                        onVerProtocolo: () => _verDetalle(_alertas[i]),
                        onReportar: () => _mostrarFormulario(_alertas[i]),
                      ),
                    ),
                  )),
                  SliverToBoxAdapter(child: const SizedBox(height: 16)),
                ],

                // ── SECCIÓN EN SEGUIMIENTO ────────────────────────────────────
                if (_seguimiento.isNotEmpty) ...[
                  SliverToBoxAdapter(child: _SeccionHeader(
                    icono: Icons.check_circle_rounded, color: _kVerde,
                    titulo: 'En seguimiento', count: _totalSeguimiento,
                    onVerTodas: () => setState(() => _mostrarTodosSeguimiento = !_mostrarTodosSeguimiento),
                    mostrando: _mostrarTodosSeguimiento,
                  )),
                  SliverToBoxAdapter(child: SizedBox(
                    height: 200,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                      itemCount: _mostrarTodosSeguimiento
                          ? _seguimiento.length
                          : (_seguimiento.length > 3 ? 3 : _seguimiento.length),
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (_, i) => _TarjetaEvento(
                        ev: _seguimiento[i], color: _kVerde,
                        onVerProtocolo: () => _verDetalle(_seguimiento[i]),
                        onReportar: () => _mostrarFormulario(_seguimiento[i]),
                      ),
                    ),
                  )),
                  SliverToBoxAdapter(child: const SizedBox(height: 16)),
                ],

                // ── Alertas registradas por el promotor ───────────────────────
                SliverToBoxAdapter(child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                  child: Row(children: [
                    Expanded(child: Text('Alertas registradas por ti',
                        style: TextStyle(color: _c(context).textSecondary,
                            fontSize: 13, fontWeight: FontWeight.w600))),
                    TextButton(onPressed: _mostrarFormulario,
                        child: const Text('+ Registrar', style: TextStyle(color: _kVerde))),
                  ]),
                )),
                SliverToBoxAdapter(child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _cargando
                      ? const Center(child: CircularProgressIndicator(color: _kVerde))
                      : _alertasDB.isEmpty
                          ? _VacioCard()
                          : Column(children: _alertasDB.map((a) {
                              final clr = _nivelColor(a['nivel'] ?? 'normal');
                              final resuelta = (a['resuelta'] as int? ?? 0) == 1;
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: _c(context).card,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: resuelta
                                        ? _c(context).border
                                        : clr.withValues(alpha: 0.4))),
                                child: Row(children: [
                                  Icon(_nivelIcon(a['nivel'] ?? 'normal'),
                                      color: resuelta ? _c(context).textHint : clr, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text(a['mensaje'] ?? '',
                                        style: TextStyle(color: resuelta
                                            ? _c(context).textHint : _c(context).textPrimary,
                                            fontSize: 13, fontWeight: FontWeight.w500)),
                                    Text('${a['modulo'] ?? ''} · ${a['fecha'] ?? ''}',
                                        style: TextStyle(color: _c(context).textHint, fontSize: 11)),
                                  ])),
                                  if (!resuelta)
                                    GestureDetector(
                                      onTap: () => _resolverAlerta(a['id']),
                                      child: Container(padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(color: _kVerde.withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(8)),
                                          child: const Text('Resolver',
                                              style: TextStyle(color: _kVerde,
                                                  fontSize: 12, fontWeight: FontWeight.w600))),
                                    )
                                  else
                                    Icon(Icons.check_circle_outline,
                                        color: _c(context).border, size: 20),
                                ]),
                              );
                            }).toList()),
                )),
                SliverToBoxAdapter(child: const SizedBox(height: 16)),

                // ── Guía completa ─────────────────────────────────────────────
                SliverToBoxAdapter(child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                  child: Row(children: [
                    Expanded(child: Text(
                        'Guía completa SIVIGILA (${_kEventos.length} eventos)',
                        style: TextStyle(color: _c(context).textSecondary,
                            fontSize: 13, fontWeight: FontWeight.w600))),
                  ]),
                )),
              ],

              // ════════════════════════════════════════════════════════════════
              // LISTA FILTRADA (búsqueda o categoría específica)
              // ════════════════════════════════════════════════════════════════
              if (!mostrarDashboard || true) ...[
                if (!mostrarDashboard)
                  SliverToBoxAdapter(child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: Text(
                      _busqueda.isNotEmpty
                          ? 'Resultados para "$_busqueda" (${eventos.length})'
                          : '${_catInfo(_categoriaSeleccionada).emoji} '
                            '${_catInfo(_categoriaSeleccionada).nombre} '
                            '(${eventos.length})',
                      style: TextStyle(color: _c(context).textSecondary,
                          fontSize: 13, fontWeight: FontWeight.w600)),
                  )),

                eventos.isEmpty
                    ? SliverToBoxAdapter(child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Center(child: Text('No se encontraron eventos',
                            style: TextStyle(color: _c(context).textHint, fontSize: 14)))))
                    : SliverList(delegate: SliverChildBuilderDelegate((_, i) {
                        final ev  = eventos[i];
                        final clr = _nivelColor(ev['nivel_base']);
                        final cat = _catInfo(ev['categoria'] as String? ?? 'todas');
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: GestureDetector(
                            onTap: () => _verDetalle(ev),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(color: _c(context).card,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: _c(context).border)),
                              child: Row(children: [
                                Container(width: 42, height: 42,
                                  decoration: BoxDecoration(color: cat.color.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(10)),
                                  child: Center(child: Text(ev['emoji'],
                                      style: const TextStyle(fontSize: 20)))),
                                const SizedBox(width: 12),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(ev['nombre'], style: TextStyle(
                                      color: _c(context).textPrimary,
                                      fontSize: 13, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 2),
                                  Text(ev['descripcion'], maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(color: _c(context).textHint, fontSize: 11)),
                                  if ((ev['casos'] as int) > 0)
                                    Text('${ev['casos']} casos',
                                        style: TextStyle(color: clr,
                                            fontSize: 11, fontWeight: FontWeight.w600)),
                                ])),
                                const SizedBox(width: 8),
                                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                  _Badge(label: ev['nivel_base'].toString().toUpperCase(),
                                      color: clr, small: true),
                                  const SizedBox(height: 4),
                                  Icon(Icons.chevron_right, color: _c(context).border, size: 16),
                                ]),
                              ]),
                            ),
                          ),
                        );
                      }, childCount: eventos.length)),
              ],

              SliverToBoxAdapter(child: const SizedBox(height: 32)),
            ],
          ),
        ),
      ),
    );
  }

  // ── Mapa epidemiológico simplificado ──────────────────────────────────────
  Widget _MapaEpidemiologico(BuildContext context) {
    final colores = {'alto': _kRojo, 'medio': _kNaranja, 'bajo': Colors.amber.shade600};
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: _c(context).card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _c(context).border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.location_on_rounded, color: _kVerde, size: 18),
          const SizedBox(width: 6),
          Text('Cauca', style: TextStyle(color: _c(context).textPrimary,
              fontSize: 15, fontWeight: FontWeight.bold)),
          const Spacer(),
          Text('Situación epidemiológica por municipios',
              style: TextStyle(color: _c(context).textHint, fontSize: 10)),
        ]),
        const SizedBox(height: 10),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Leyenda
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _LeyendaMapa('alto',  '${_kMunicipios.where((m) => m['nivel'] == 'alto').length} Municipios en riesgo alto',   _kRojo),
            _LeyendaMapa('medio', '${_kMunicipios.where((m) => m['nivel'] == 'medio').length} Municipios en riesgo medio', _kNaranja),
            _LeyendaMapa('bajo',  '${_kMunicipios.where((m) => m['nivel'] == 'bajo').length} Municipios en riesgo bajo',   Colors.amber.shade600),
            _LeyendaMapa('ok',    '24 Municipios sin alertas', _kVerde),
          ])),
          const SizedBox(width: 12),
          // Lista de municipios
          Expanded(child: Column(children: _kMunicipios.take(4).map((m) {
            final clr = colores[m['nivel']] ?? _kVerde;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(children: [
                Container(width: 8, height: 8,
                    decoration: BoxDecoration(color: clr, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(m['nombre']!, style: TextStyle(color: _c(context).textPrimary,
                      fontSize: 12, fontWeight: FontWeight.w500),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(m['nivel'] == 'alto' ? 'Alto'
                      : m['nivel'] == 'medio' ? 'Medio' : 'Bajo',
                      style: TextStyle(color: clr, fontSize: 10)),
                ])),
                Icon(Icons.chevron_right, color: _c(context).border, size: 14),
              ]),
            );
          }).toList())),
        ]),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {},
          child: Text('Ver todos los municipios →',
              style: const TextStyle(color: _kVerde,
                  fontSize: 12, fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }

  Widget _LeyendaMapa(String nivel, String texto, Color color) =>
      Padding(padding: const EdgeInsets.only(bottom: 5),
        child: Row(children: [
          Container(width: 10, height: 10, margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          Expanded(child: Text(texto, style: TextStyle(
              color: _c(context).textSecondary, fontSize: 11))),
        ]));
}

// ════════════════════════════════════════════════════════════════════════════
// WIDGETS AUXILIARES
// ════════════════════════════════════════════════════════════════════════════

class _MetricaCard extends StatelessWidget {
  final String num, label, sub;
  final Color color;
  final IconData icon;
  const _MetricaCard({required this.num, required this.label,
      required this.sub, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) => Expanded(child: Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(color: _c(context).card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 28, height: 28,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 16)),
      ]),
      const SizedBox(height: 6),
      Text(num, style: TextStyle(color: _c(context).textPrimary,
          fontSize: 22, fontWeight: FontWeight.bold)),
      Text(label, style: TextStyle(color: _c(context).textPrimary,
          fontSize: 11, fontWeight: FontWeight.w600),
          maxLines: 1, overflow: TextOverflow.ellipsis),
      Text(sub, style: TextStyle(color: _c(context).textHint, fontSize: 9),
          maxLines: 2, overflow: TextOverflow.ellipsis),
      const SizedBox(height: 6),
      Container(height: 3, decoration: BoxDecoration(
        color: color, borderRadius: BorderRadius.circular(2))),
    ]),
  ));
}

class _TarjetaEvento extends StatelessWidget {
  final Map<String, dynamic> ev;
  final Color color;
  final VoidCallback onVerProtocolo, onReportar;
  const _TarjetaEvento({required this.ev, required this.color,
      required this.onVerProtocolo, required this.onReportar});

  @override
  Widget build(BuildContext context) {
    final tendencia = ev['tendencia'] as int;
    return Container(
      width: 175,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: _c(context).card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.4))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 36, height: 36,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10)),
            child: Center(child: Text(ev['emoji'],
                style: const TextStyle(fontSize: 20)))),
          const Spacer(),
          Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20)),
            child: Text(ev['nivel_base'] == 'urgente' ? '🚨 URGENTE'
                : ev['nivel_base'] == 'alerta' ? '⚠️ ALERTA' : '✅',
                style: TextStyle(color: color, fontSize: 9,
                    fontWeight: FontWeight.bold))),
        ]),
        const SizedBox(height: 8),
        Text(ev['nombre'], style: TextStyle(color: _c(context).textPrimary,
            fontSize: 13, fontWeight: FontWeight.bold),
            maxLines: 2, overflow: TextOverflow.ellipsis),
        Text(ev['municipios_riesgo'][0], style: TextStyle(
            color: _c(context).textHint, fontSize: 10),
            maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 6),
        Row(children: [
          Text('${ev['casos']} casos',
              style: TextStyle(color: color,
                  fontSize: 14, fontWeight: FontWeight.bold)),
          const Spacer(),
          if (tendencia != 0) Row(children: [
            Icon(tendencia > 0 ? Icons.trending_up : Icons.trending_down,
                color: tendencia > 0 ? _kRojo : _kVerde, size: 13),
            Text('${tendencia > 0 ? '+' : ''}$tendencia%',
                style: TextStyle(color: tendencia > 0 ? _kRojo : _kVerde,
                    fontSize: 10, fontWeight: FontWeight.bold)),
          ]) else Text('Estable', style: TextStyle(
              color: _c(context).textHint, fontSize: 10)),
        ]),
        const Spacer(),
        Row(children: [
          Expanded(child: GestureDetector(
            onTap: onVerProtocolo,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 5),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8)),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.description_outlined, color: color, size: 11),
                const SizedBox(width: 3),
                Text('Protocolo', style: TextStyle(color: color,
                    fontSize: 9, fontWeight: FontWeight.w600)),
              ]),
            ),
          )),
          const SizedBox(width: 6),
          Expanded(child: GestureDetector(
            onTap: onReportar,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 5),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withValues(alpha: 0.3))),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.add_circle_outline, color: color, size: 11),
                const SizedBox(width: 3),
                Text('Reportar', style: TextStyle(color: color,
                    fontSize: 9, fontWeight: FontWeight.w600)),
              ]),
            ),
          )),
        ]),
      ]),
    );
  }
}

class _SeccionHeader extends StatelessWidget {
  final IconData icono;
  final Color color;
  final String titulo;
  final int count;
  final VoidCallback onVerTodas;
  final bool mostrando;
  const _SeccionHeader({required this.icono, required this.color,
      required this.titulo, required this.count,
      required this.onVerTodas, required this.mostrando});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
    child: Row(children: [
      Icon(icono, color: color, size: 18),
      const SizedBox(width: 8),
      Text(titulo, style: TextStyle(color: _c(context).textPrimary,
          fontSize: 15, fontWeight: FontWeight.bold)),
      const SizedBox(width: 6),
      Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20)),
        child: Text('$count', style: TextStyle(color: color,
            fontSize: 11, fontWeight: FontWeight.bold))),
      const Spacer(),
      GestureDetector(onTap: onVerTodas,
        child: Text(mostrando ? 'Ver menos' : 'Ver todas',
            style: const TextStyle(color: _kVerde,
                fontSize: 12, fontWeight: FontWeight.w600))),
    ]),
  );
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final bool small;
  const _Badge({required this.label, required this.color, this.small = false});

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(horizontal: small ? 6 : 8, vertical: small ? 2 : 3),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20)),
    child: Text(label, style: TextStyle(color: color,
        fontSize: small ? 9 : 11, fontWeight: FontWeight.bold)));
}

class _DetalleSec extends StatelessWidget {
  final String titulo, contenido;
  const _DetalleSec(this.titulo, this.contenido);

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: _c(context).bg,
        borderRadius: BorderRadius.circular(12)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(titulo, style: TextStyle(color: _c(context).textSecondary,
          fontSize: 12, fontWeight: FontWeight.bold)),
      const SizedBox(height: 5),
      Text(contenido, style: TextStyle(color: _c(context).textHint,
          fontSize: 13, height: 1.5)),
    ]));
}

class _VacioCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Builder(builder: (ctx) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: _c(ctx).card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _c(ctx).border)),
    child: Column(children: [
      Icon(Icons.notifications_off_outlined, color: _c(ctx).border, size: 36),
      const SizedBox(height: 10),
      Text('Sin alertas registradas',
          style: TextStyle(color: _c(ctx).textHint, fontSize: 14)),
      const SizedBox(height: 4),
      Text('Registra eventos inusuales que observes en tu comunidad.',
          textAlign: TextAlign.center,
          style: TextStyle(color: _c(ctx).textHint, fontSize: 12)),
    ]),
  ));
}

Widget _LabelField(String label) => Builder(builder: (ctx) => Padding(
  padding: const EdgeInsets.only(bottom: 4),
  child: Text(label, style: TextStyle(color: _c(ctx).textHint,
      fontSize: 11, fontWeight: FontWeight.w500))));