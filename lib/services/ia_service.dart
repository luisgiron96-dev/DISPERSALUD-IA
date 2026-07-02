import 'dart:convert';
import 'package:http/http.dart' as http;
import 'connectivity_service.dart';
import 'sivigila_service.dart';

// ─── Servicio de IA Híbrido ───────────────────────────────────────────────
// Con internet  → Groq API (Llama 3.1) — gratuito, sin vencimiento
// Sin internet  → Motor local de reglas clínicas — 100% offline
class IaService {
  static final IaService instance = IaService._();
  IaService._();

  static const _groqApiUrl = 'https://api.groq.com/openai/v1/chat/completions';
  // ⚠️  REEMPLAZA ESTE VALOR con tu API Key real de https://console.groq.com
  static const _groqApiKey = 'API KEY';
  static const _groqModel  = 'llama-3.1-8b-instant';

  static const _sistemaPrompt =
      'Eres DISPERSALUD IA, asistente de salud para promotores rurales en el Cauca, Colombia.\n'
      'Tu rol es orientar al promotor en campo — no reemplazas al médico.\n'
      '\n'
      'REGLAS ESTRICTAS:\n'
      '- Responde SIEMPRE en español colombiano, claro y sencillo\n'
      '- Máximo 3-4 oraciones por respuesta — el promotor está con el paciente\n'
      '- Si hay riesgo de vida, empieza con: EMERGENCIA:\n'
      '- Basa tus respuestas en protocolos del Ministerio de Salud de Colombia\n'
      '- Menciona cuándo remitir al médico o a urgencias\n'
      '- No diagnostiques enfermedades específicas — orienta y triaja\n'
      '- Si no sabes algo con certeza, dilo y recomienda consultar al médico\n'
      '\n'
      'CONTEXTO:\n'
      '- Zona rural dispersa del Cauca, Colombia\n'
      '- Enfermedades prevalentes: dengue, malaria, EDA, IRA, desnutrición\n'
      '- Población vulnerable: gestantes, menores de 5 años, adultos mayores\n'
      '- Alertas SIVIGILA activas:\n'
      '{ALERTAS_SIVIGILA}\n';

  Future<String> _buildSystemPrompt() async {
    try {
      final alertas = await SivigilaService.instance
          .obtenerResumenAlertas()
          .timeout(const Duration(seconds: 4));
      return _sistemaPrompt.replaceAll('{ALERTAS_SIVIGILA}', alertas);
    } catch (_) {
      return _sistemaPrompt.replaceAll(
        '{ALERTAS_SIVIGILA}',
        'dengue en Santander de Quilichao, malaria en López de Micay',
      );
    }
  }

  // ── Consulta híbrida — siempre responde (online → Groq, offline → local) ──
  Future<String> consultar(String pregunta) async {
    if (ConnectivityService.instance.tieneInternet) {
      try {
        return await _consultarGroq(pregunta);
      } catch (_) {
        return _consultarLocal(pregunta);
      }
    }
    return _consultarLocal(pregunta);
  }

  Future<String> _consultarGroq(String pregunta) async {
    final response = await http.post(
      Uri.parse(_groqApiUrl),
      headers: {
        'Content-Type':  'application/json',
        'Authorization': 'Bearer $_groqApiKey',
      },
      body: jsonEncode({
        'model':       _groqModel,
        'max_tokens':  400,
        'temperature': 0.3,
        'messages': [
          {'role': 'system', 'content': await _buildSystemPrompt()},
          {'role': 'user',   'content': pregunta},
        ],
      }),
    ).timeout(const Duration(seconds: 14));

    if (response.statusCode == 200) {
      final data  = jsonDecode(response.body);
      final texto = data['choices']?[0]?['message']?['content'] as String? ?? '';
      return texto.isNotEmpty ? texto.trim() : _consultarLocal(pregunta);
    }
    // Error de API (incluyendo key inválida) → motor local
    return _consultarLocal(pregunta);
  }

  // ── Motor local expandido con términos de materna y síntomas comunes ─────
  String _consultarLocal(String pregunta) {
    final t = _norm(pregunta);

    // ── EMERGENCIAS — siempre primero ────────────────────────────────────
    if (_c(t, ['convuls','epilepsi'])) return
        'EMERGENCIA: Convulsión activa. Posición lateral de seguridad, '
        'no introducir objetos en la boca. Si es gestante, sospechar eclampsia. '
        'Remisión URGENTE.';

    if (_c(t, ['ahogando']) || (_c(t, ['dificultad','falta']) && _c(t, ['respir','aire']))) return
        'EMERGENCIA: Dificultad respiratoria. Mantener vías aéreas abiertas, '
        'posición semisentada. Si SpO2 < 92%: remisión inmediata.';

    if (_c(t, ['infarto','dolor de pecho','presion en el pecho'])) return
        'EMERGENCIA: Posible infarto. Reposo absoluto, aspirina 300 mg si no '
        'es alérgico. Remisión inmediata a urgencias.';

    if (_c(t, ['suicid','autolesion','quitarme la vida','no quiero vivir'])) return
        'EMERGENCIA: Riesgo de autolesión. No dejar solo al paciente, activar '
        'ruta de salud mental. Llamar a la línea 106.';

    // ── SALUD MATERNA — síntomas y situaciones frecuentes ────────────────
    // Sangrado en gestante
    if (_c(t, ['sangrado','sangra','hemorragia']) &&
        _c(t, ['embaraz','gestante','semana','parto','bebe','feto'])) return
        'EMERGENCIA: Sangrado en gestante. No administrar oxitocina. '
        'Remisión urgente a ginecobstetricia. No dejar sola a la paciente.';

    // Cefalea / dolor de cabeza en gestante
    if ((_c(t, ['cefalea','dolor de cabeza','cabeza me duele','me duele la cabeza',
                  'dolor cabeza','jaqueca','migraña'])) &&
        _c(t, ['embaraz','gestante','semana','bebe'])) return
        'EMERGENCIA posible: Cefalea intensa en gestante puede ser señal de '
        'preeclampsia. Toma la presión arterial — si PA ≥ 140/90: remisión urgente. '
        'Reposo en decúbito lateral izquierdo mientras espera traslado.';

    // Presión alta en gestante
    if (_c(t, ['presion','tension']) &&
        _c(t, ['embaraz','gestante']) &&
        _c(t, ['alta','elevada','140','150','160'])) return
        'EMERGENCIA: Presión elevada en gestante — sospechar preeclampsia. '
        'Posición decúbito lateral izquierdo. Remisión inmediata a ginecobstetricia.';

    // Movimientos fetales
    if (_c(t, ['movimiento','mueve','patadas','bebe no se mueve',
                'no siento','dejo de moverse'])) return
        'Disminución de movimientos fetales es señal de alarma. Pide a la '
        'gestante que cuente las patadas en 1 hora (normal ≥ 10). Si hay menos '
        'de 10 movimientos o no siente nada: remisión urgente a urgencias obstétricas.';

    // Contracciones / trabajo de parto
    if (_c(t, ['contraccion','contractura','dolor que viene y va',
                'trabajo de parto','dilatacion','parto'])) return
        'Si las contracciones son regulares cada 5 minutos o menos y duran '
        '≥ 30 segundos: posible trabajo de parto. Evalúa semanas de gestación. '
        'Antes de 37 semanas: remisión urgente por amenaza de parto prematuro.';

    // Náuseas y vómitos en gestante
    if (_c(t, ['nausea','vomito','asco','arcada','mareo']) &&
        _c(t, ['embaraz','gestante','semana','bebe'])) return
        'Náuseas y vómitos son frecuentes en el primer trimestre. Si son muy '
        'intensos (hiperémesis), evalúa signos de deshidratación. Refiere si '
        'lleva > 24 h sin tolerar líquidos o hay pérdida de peso importante.';

    // Edema / hinchazón en gestante
    if (_c(t, ['edema','hincha','hinchaz','inflamad']) &&
        _c(t, ['embaraz','gestante','bebe','semana'])) return
        'Edema leve en pies al final del día puede ser normal. Si el edema '
        'es en manos o cara, o viene con cefalea y visión borrosa: '
        'EMERGENCIA por posible preeclampsia — toma la presión y refiere urgente.';

    // Líquido amniótico / ruptura de membranas
    if (_c(t, ['liquido','perdida de agua','rompio fuente','bolsa de agua',
                'membranas','amniotico'])) return
        'Posible ruptura de membranas. Confirma con pH (papel tornasol) o '
        'simplemente por olor y cantidad del líquido. Remisión urgente al hospital '
        'independientemente de las semanas de gestación.';

    // Fiebre en gestante
    if (_c(t, ['fiebre','calentura','temperatura']) &&
        _c(t, ['embaraz','gestante','bebe','semana'])) return
        'Fiebre en gestante (≥ 38°C) requiere evaluación urgente. Puede ser '
        'signo de infección urinaria, corioamnionitis u otras complicaciones. '
        'Toma temperatura, hidrata y refiere a control médico el mismo día.';

    // Control prenatal general
    if (_c(t, ['prenatal','control','gestante','embaraz','semana',
                'trimestre','altura uterina','fcf','toxoide'])) return
        'Para el control prenatal registra: PA, peso, altura uterina, FCF y '
        'movimientos fetales. Señales de alarma: PA ≥ 140/90, cefalea intensa, '
        'visión borrosa, edema en cara/manos, disminución de movimientos fetales — '
        'cualquiera de estas: remisión urgente.';

    // ── SÍNTOMAS GENERALES frecuentes ────────────────────────────────────

    // Dolor de cabeza (sin contexto de gestante)
    if (_c(t, ['cefalea','dolor de cabeza','cabeza me duele',
                'me duele la cabeza','dolor cabeza','jaqueca','migraña'])) return
        'Dolor de cabeza: evalúa la presión arterial. Si PA ≥ 160/100: '
        'remisión urgente. Si es en gestante: posible preeclampsia. '
        'Para cefalea leve sin señales de alarma: descanso, hidratación, '
        'paracetamol 500 mg en adultos. Consulta médica si persiste > 24 h.';

    // Fiebre general
    if (_c(t, ['fiebre','calentura','temperatura alta'])) return
        'Fiebre ≥ 38°C: hidratación oral, paracetamol 500–1000 mg en adultos. '
        'Busca el foco: si hay sarpullido + dolor articular → sospechar dengue. '
        'Si hay escalofríos intermitentes en zona maláricas → sospechar malaria. '
        'Referir si fiebre > 3 días sin mejoría.';

    // Mareo / desmayo
    if (_c(t, ['mareo','mareado','desmay','vahido','debilidad','me cai'])) return
        'Mareo o desmayo: evalúa presión arterial y glucemia. Hipoglucemia '
        '(glucosa < 70): azúcar o jugo si está consciente. Hipotensión: reposo '
        'y líquidos. En gestante: posición lateral izquierda. Si persiste o '
        'hay pérdida de conciencia: remisión urgente.';

    // Dolor abdominal
    if (_c(t, ['dolor abdomen','dolor de barriga','dolor estomago',
                'dolor abdominal','barriga duele','estomago me duele'])) {
      if (_c(t, ['embaraz','gestante','semana','bebe'])) return
          'EMERGENCIA posible: Dolor abdominal en gestante puede indicar '
          'desprendimiento de placenta, ruptura uterina u otras complicaciones. '
          'Evalúa signos vitales y refiere urgente a ginecobstetricia.';
      return 'Dolor abdominal: evalúa localización y características. '
          'Si es intenso, persistente o con fiebre/vómito/diarrea con sangre: '
          'referir a urgencias. Si parece EDA: sales de rehidratación y dieta blanda.';
    }

    // Vómito / diarrea general
    if (_c(t, ['diarrea','vomito','eda','deposicion','heces'])) {
      if (_c(t, ['nino','bebe','menor','infan','lactante'])) return
          'EDA en menor: inicia sales de rehidratación oral de inmediato. '
          'Ojos hundidos, llanto sin lágrimas o letargo: EMERGENCIA — remisión urgente.';
      return 'Diarrea/vómito: sales de rehidratación oral, dieta blanda, '
          'agua hervida. Si hay sangre en heces, fiebre o el paciente no '
          'tolera líquidos: evaluación médica urgente ese día.';
    }

    // ── ENFERMEDADES TRANSMISIBLES ────────────────────────────────────────
    if (_c(t, ['dengue','sarpullido','mosquito','zika','chikungunya'])) {
      if (_c(t, ['sangrado','vomito','dolor abdominal'])) return
          'EMERGENCIA: Signos de dengue grave. Hospitalización urgente. '
          'Notifica en SIVIGILA. Alerta activa en Santander de Quilichao.';
      return 'Sospecha dengue: reposo, hidratación, paracetamol — NO aspirina. '
          'Revisión en 24 h. Si hay sangrado, vómito persistente o dolor abdominal: '
          'remisión urgente. Notificar en SIVIGILA.';
    }

    if (_c(t, ['malaria','paludismo','gota gruesa'])) return
        'Fiebre intermitente con escalofríos: sospechar malaria. Realiza gota '
        'gruesa. Alerta activa en López de Micay. Notificar en SIVIGILA.';

    if (_c(t, ['tos','bronquitis','neumonia','gripa','respiratorio'])) {
      if (_c(t, ['tiraje','cianosis','no respira'])) return
          'EMERGENCIA: Dificultad respiratoria. Posición sentada y transporte urgente.';
      return 'IRA: paracetamol y líquidos. Señales de alarma: tiraje, cianosis '
          'o saturación < 94% — remisión inmediata.';
    }

    if (_c(t, ['tuberculosis','tbc','tos cronica','tos por mas de'])) return
        'Tos > 15 días = sintomático respiratorio. Solicitar baciloscopia. '
        'Tratamiento DOTS supervisado. Notificar en SIVIGILA.';

    // ── ENFERMEDADES CRÓNICAS ─────────────────────────────────────────────
    if (_c(t, ['presion','tension','hipertens','mmhg'])) {
      if (_c(t, ['180','190','200','crisis'])) return
          'EMERGENCIA: Crisis hipertensiva (PA ≥ 180). Reposo, sin medicamentos '
          'sin orden médica. Remisión urgente.';
      if (_c(t, ['140','150','160','170'])) return
          'PA entre 140-179 = hipertensión. Dieta sin sal y cita médica '
          'prioritaria. Si hay cefalea intensa o visión borrosa: remisión inmediata.';
      return 'PA normal < 120/80 mmHg. Recomendaciones: dieta sin sal, '
          'ejercicio moderado y control mensual.';
    }

    if (_c(t, ['diabetes','glucemia','azucar','glucosa','insulina'])) {
      if (_c(t, ['200','250','300'])) return
          'EMERGENCIA: Glucemia > 200 mg/dL — hiperglucemia severa. '
          'Remisión urgente sin administrar insulina.';
      if (_c(t, ['bajo','desmayo','temblor','60','70'])) return
          'Posible hipoglucemia. Si está consciente: azúcar o jugo de inmediato. '
          'Si está inconsciente: EMERGENCIA — remisión urgente.';
      return 'Glucemia en ayunas ≥ 126 mg/dL en dos tomas = posible diabetes. '
          'Dieta sin azúcar, ejercicio diario y control médico.';
    }

    // ── POBLACIÓN ESPECIAL ────────────────────────────────────────────────
    if (_c(t, ['bebe','nino','menor','infan','lactante','recien nacido'])) {
      if (_c(t, ['desnutr','peso bajo'])) return
          'Evalúa peso/talla. Si P/T < -3 DE o edema en pies: EMERGENCIA — '
          'desnutrición severa, hospitalización. Notifica al ICBF.';
      if (_c(t, ['vacuna','esquema'])) return
          'Esquema: al nacer BCG y Hep B. 2 meses: Pentavalente, Polio, Neumococo. '
          '12 meses: Triple viral. Registra en el módulo correspondiente.';
      return 'Usa módulo Primera Infancia (0-5 años) o Infancia (6-11 años). '
          'Evalúa: peso, talla, hemoglobina y vacunación.';
    }

    if (_c(t, ['anciano','adulto mayor','vejez','mayor de 60','tercera edad'])) {
      if (_c(t, ['caida','fractura','se cayo'])) return
          'Caída en adulto mayor: si hay dolor intenso en cadera o no puede '
          'caminar: EMERGENCIA — posible fractura. Registra en módulo Vejez.';
      return 'Usa módulo Vejez. Evalúa: PA, glucemia, movilidad, cognición '
          'y medicamentos. Verifica signos de maltrato.';
    }

    if (_c(t, ['violencia','maltrato','abuso','vif','golpes'])) return
        'EMERGENCIA de salud pública. Activa ruta de atención integral, '
        'notifica a comisaría de familia e ICBF. Registra en alertas SIVIGILA.';

    // ── SALUDO / AYUDA GENERAL ────────────────────────────────────────────
    if (_c(t, ['hola','buenos','ayuda','que puedes','que sabes'])) return
        'Hola, soy DISPERSALUD IA. Puedo orientarte en salud materna, '
        'infancia, diabetes, hipertensión, dengue, malaria, TBC y alertas '
        'SIVIGILA. ¿Qué situación tienes ahora mismo?';

    // ── RESPUESTA GENÉRICA MEJORADA ───────────────────────────────────────
    return 'Para orientarte mejor necesito más detalles: ¿cuáles son los '
        'síntomas exactos, la edad del paciente y desde cuándo los tiene? '
        'Si hay riesgo de vida, la remisión inmediata es siempre la mejor decisión.';
  }

  // Normaliza texto: minúsculas + quita tildes
  String _norm(String s) => s.toLowerCase()
      .replaceAll('á','a').replaceAll('é','e')
      .replaceAll('í','i').replaceAll('ó','o').replaceAll('ú','u')
      .replaceAll('ñ','n');

  bool _c(String texto, List<String> palabras) =>
      palabras.any((p) => texto.contains(p));
}