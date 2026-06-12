import 'dart:convert';
import 'package:http/http.dart' as http;
import 'connectivity_service.dart';

// ─── Servicio de IA Híbrido ───────────────────────────────────────────────
// Con internet  → Groq API (Llama 3.1) — gratuito, sin vencimiento
// Sin internet  → Motor local de reglas clínicas — 100% offline
class IaService {
  static final IaService instance = IaService._();
  IaService._();

  static const _groqApiUrl = 'https://api.groq.com/openai/v1/chat/completions';
  static const _groqApiKey = 'API KEY';
  static const _groqModel  = 'llama-3.1-8b-instant';

  static const _sistemaPrompt = '''
Eres DISPERSALUD IA, asistente de salud p
ara promotores rurales en el Cauca, Colombia.
Tu rol es orientar al promotor en campo — no reemplazas al médico.

REGLAS ESTRICTAS:
- Responde SIEMPRE en español colombiano, claro y sencillo
- Máximo 3-4 oraciones por respuesta — el promotor está con el paciente
- Si hay riesgo de vida, empieza con: EMERGENCIA:
- Basa tus respuestas en protocolos del Ministerio de Salud de Colombia
- Menciona cuándo remitir al médico o a urgencias
- No diagnostiques enfermedades específicas — orienta y triaja
- Si no sabes algo con certeza, dilo y recomienda consultar al médico

CONTEXTO:
- Zona rural dispersa del Cauca, Colombia
- Enfermedades prevalentes: dengue, malaria, EDA, IRA, desnutrición
- Población vulnerable: gestantes, menores de 5 años, adultos mayores
- Alertas activas: dengue en Santander de Quilichao, malaria en López de Micay
''';

  // ── Consulta híbrida — detecta internet automáticamente ──────────────
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

  // ── Con internet: Groq API ────────────────────────────────────────────
  Future<String> _consultarGroq(String pregunta) async {
    final response = await http.post(
      Uri.parse(_groqApiUrl),
      headers: {
        'Content-Type':  'application/json',
        'Authorization': 'Bearer $_groqApiKey',
      },
      body: jsonEncode({
        'model':       _groqModel,
        'max_tokens':  300,
        'temperature': 0.3,
        'messages': [
          {'role': 'system', 'content': _sistemaPrompt},
          {'role': 'user',   'content': pregunta},
        ],
      }),
    ).timeout(const Duration(seconds: 12));

    if (response.statusCode == 200) {
      final data  = jsonDecode(response.body);
      final texto = data['choices']?[0]?['message']?['content'] as String? ?? '';
      return texto.isNotEmpty ? texto.trim() : _consultarLocal(pregunta);
    }
    return _consultarLocal(pregunta);
  }

  // ── Sin internet: motor local de reglas clínicas ──────────────────────
  String _consultarLocal(String pregunta) {
    final t = pregunta.toLowerCase()
        .replaceAll('á','a').replaceAll('é','e')
        .replaceAll('í','i').replaceAll('ó','o')
        .replaceAll('ú','u');

    // EMERGENCIAS
    if (_c(t, ['convuls'])) return 'EMERGENCIA: Convulsión activa. Posición lateral de seguridad, no introducir objetos en boca. Remisión URGENTE. Si es gestante, sospechar eclampsia.';
    if (_c(t, ['ahogando']) || (_c(t, ['dificultad']) && _c(t, ['respir']))) return 'EMERGENCIA: Dificultad respiratoria. Mantener vías aéreas abiertas, posición semisentada. Si SpO2 < 92%: remisión inmediata.';
    if (_c(t, ['sangrado']) && _c(t, ['embar','gestante','semana'])) return 'EMERGENCIA: Sangrado en gestante. No administrar oxitocina. Remisión urgente a ginecobstetricia. No dejar sola a la paciente.';
    if (_c(t, ['infarto','dolor de pecho'])) return 'EMERGENCIA: Posible infarto. Reposo absoluto, aspirina 300mg si no es alérgico. Remisión inmediata a urgencias.';
    if (_c(t, ['suicid','autolesion','quitarme la vida'])) return 'EMERGENCIA: Riesgo de autolesión. No dejar solo al paciente, activar ruta de salud mental. Llamar a la línea 106.';

    // GESTACIÓN
    if (_c(t, ['gestante','embaraz','semana','prenatal','parto','trimestre','toxoide','altura uterina','fcf'])) {
      if (_c(t, ['presion','140','150','160','preeclampsia'])) return 'EMERGENCIA: Presión elevada en gestante — sospechar preeclampsia. Posición decúbito lateral izquierdo. Remisión inmediata a ginecobstetricia.';
      return 'Usa el módulo Gestación para el control prenatal. Registra PA, peso, altura uterina y FCF. Señales de alarma: PA ≥ 140/90, cefalea intensa, visión borrosa — remisión urgente.';
    }

    // PRESIÓN
    if (_c(t, ['presion','tension','hipertens','mmhg'])) {
      if (_c(t, ['180','190','200','crisis'])) return 'EMERGENCIA: Crisis hipertensiva (PA ≥ 180). Reposo, sin medicamentos sin orden médica. Remisión urgente.';
      if (_c(t, ['140','150','160','170'])) return 'PA entre 140-179 = hipertensión. Registra en módulo Adultez. Dieta sin sal y cita médica prioritaria. Si hay cefalea intensa o visión borrosa: remisión inmediata.';
      return 'PA normal < 120/80 mmHg. Recomienda: sin sal, ejercicio moderado y control mensual.';
    }

    // DIABETES
    if (_c(t, ['diabetes','glucemia','azucar','glucosa','insulina'])) {
      if (_c(t, ['200','250','300'])) return 'EMERGENCIA: Glucemia > 200 mg/dL — hiperglucemia severa. Remisión urgente sin administrar insulina.';
      if (_c(t, ['bajo','desmayo','temblor','60','70'])) return 'Posible hipoglucemia. Si está consciente: azúcar o jugo inmediatamente. Si está inconsciente: EMERGENCIA — remisión urgente.';
      return 'Glucemia en ayunas ≥ 126 mg/dL en dos tomas = posible diabetes. Registra en módulo Adultez. Orienta: sin azúcar, ejercicio diario, control médico.';
    }

    // NIÑOS
    if (_c(t, ['bebe','nino','menor','infan','lactante','recien nacido'])) {
      if (_c(t, ['desnutr','peso bajo'])) return 'Evalúa peso/talla en módulo Primera Infancia. Si P/T < -3 DE o edema en pies: EMERGENCIA — desnutrición severa, hospitalización. Notifica al ICBF.';
      if (_c(t, ['vacuna','esquema'])) return 'Al nacer: BCG y Hep B. A los 2 meses: Pentavalente, Polio, Neumococo. A los 12 meses: Triple viral. Registra en el módulo correspondiente.';
      return 'Usa módulo Primera Infancia (0-5 años) o Infancia (6-11 años). Evalúa: peso, talla, hemoglobina y vacunación.';
    }

    // DENGUE / FIEBRE
    if (_c(t, ['dengue','fiebre','sarpullido','mosquito','zika'])) {
      if (_c(t, ['sangrado','vomito','dolor abdominal'])) return 'EMERGENCIA: Signos de dengue grave. Hospitalización urgente. Notifica en SIVIGILA. Alerta activa en Santander de Quilichao.';
      return 'Sospecha dengue: reposo, hidratación, paracetamol — NO aspirina. Revisión en 24h. Si sangrado o vómito persistente: remisión urgente.';
    }

    // MALARIA
    if (_c(t, ['malaria','paludismo','gota gruesa'])) return 'Fiebre intermitente con escalofríos: sospechar malaria. Realiza gota gruesa. Alerta activa en López de Micay. Notifica en SIVIGILA.';

    // IRA
    if (_c(t, ['tos','bronquitis','neumonia','gripa','respiratorio'])) {
      if (_c(t, ['tiraje','cianosis','no respira'])) return 'EMERGENCIA: Dificultad respiratoria. Posición sentada y transporte urgente.';
      return 'IRA: paracetamol y líquidos. Señales de alarma: tiraje, cianosis o saturación < 94% — remisión inmediata.';
    }

    // EDA
    if (_c(t, ['diarrea','eda','vomito','deshidrat'])) {
      if (_c(t, ['nino','bebe','menor'])) return 'EDA en menor: inicia sales de rehidratación oral. Ojos hundidos o letargo: EMERGENCIA — remisión urgente.';
      return 'Diarrea aguda: sales de rehidratación oral, dieta blanda, agua hervida. Si hay fiebre o sangre: evaluación médica urgente.';
    }

    // TUBERCULOSIS
    if (_c(t, ['tuberculosis','tbc','tos cronica'])) return 'Tos > 15 días = sintomático respiratorio. Solicitar baciloscopia. Tratamiento DOTS supervisado. Notificar en SIVIGILA.';

    // VIOLENCIA
    if (_c(t, ['violencia','maltrato','abuso','vif'])) return 'EMERGENCIA de salud pública. Activa ruta de atención integral, notifica a comisaría de familia e ICBF. Registra en alertas SIVIGILA.';

    // ADULTO MAYOR
    if (_c(t, ['anciano','adulto mayor','vejez','mayor de 60'])) {
      if (_c(t, ['caida','fractura'])) return 'Caída en adulto mayor: si hay dolor intenso en cadera o no puede caminar: EMERGENCIA — posible fractura. Registra en módulo Vejez.';
      return 'Usa módulo Vejez. Evalúa: PA, glucemia, movilidad, cognición y medicamentos. Verifica signos de maltrato.';
    }

    // SALUDO
    if (_c(t, ['hola','buenos','ayuda','que puedes'])) return 'Hola, soy DISPERSALUD IA. Puedo orientarte en gestación, infancia, diabetes, hipertensión, dengue, malaria, TBC y alertas SIVIGILA. ¿Qué situación tienes ahora mismo?';

    // GENERAL
    return 'Entendí: "$pregunta". Para orientarte mejor describe los síntomas específicos, la edad del paciente y desde cuándo los presenta. Ante cualquier riesgo de vida, la remisión inmediata es siempre la mejor decisión.';
  }

  bool _c(String texto, List<String> palabras) =>
      palabras.any((p) => texto.contains(p));
}