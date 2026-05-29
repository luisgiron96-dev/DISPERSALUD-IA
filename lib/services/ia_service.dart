import 'dart:convert';
import 'package:http/http.dart' as http;
import 'connectivity_service.dart';

// ─── Servicio de IA Híbrido ───────────────────────────────────────────────
// Con internet  → usa Claude API (Anthropic) para respuestas clínicas reales
// Sin internet  → usa lógica local de palabras clave (ya funciona hoy)
class IaService {
  static final IaService instance = IaService._();
  IaService._();

  static const _apiUrl = 'https://api.anthropic.com/v1/messages';

  // Prompt de sistema clínico — contexto real para Colombia rural
  static const _sistemaClinical = '''
Eres DISPERSALUD IA, un asistente de salud para promotores rurales en Colombia.
Trabajas en zonas dispersas del departamento del Cauca.
Respondes preguntas clínicas breves, claras y prácticas.
Tus respuestas deben:
- Ser en español colombiano, simples, sin jerga médica compleja
- Incluir signos de alarma concretos cuando aplique
- Mencionar cuándo remitir al médico o a urgencias
- Basarte en protocolos del Ministerio de Salud de Colombia, OPS y OMS
- Ser máximo de 3-4 oraciones (el promotor está atendiendo al paciente)
Si detectas una emergencia, empieza con: EMERGENCIA:
Si no sabes algo con certeza, dilo y recomienda consultar al médico.
No diagnostiques enfermedades específicas — orienta y triaja.
''';

  // ── Consulta híbrida ──────────────────────────────────────────────────
  Future<String> consultar(String pregunta, {String? apiKey}) async {
    if (ConnectivityService.instance.tieneInternet && apiKey != null && apiKey.isNotEmpty) {
      try {
        return await _consultarClaude(pregunta, apiKey);
      } catch (e) {
        // Si falla la API, cae a lógica local
        return _consultarLocal(pregunta);
      }
    } else {
      return _consultarLocal(pregunta);
    }
  }

  // ── Con internet: Claude API ──────────────────────────────────────────
  Future<String> _consultarClaude(String pregunta, String apiKey) async {
    final response = await http.post(
      Uri.parse(_apiUrl),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: jsonEncode({
        'model': 'claude-haiku-4-5-20251001',
        'max_tokens': 300,
        'system': _sistemaClinical,
        'messages': [
          {'role': 'user', 'content': pregunta}
        ],
      }),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final texto = (data['content'] as List?)
              ?.whereType<Map>()
              .firstWhere((b) => b['type'] == 'text', orElse: () => {})['text']
          as String? ?? '';
      return texto.isNotEmpty ? texto : _consultarLocal(pregunta);
    } else {
      return _consultarLocal(pregunta);
    }
  }

  // ── Sin internet: lógica local de palabras clave ───────────────────────
  String _consultarLocal(String pregunta) {
    final t = pregunta.toLowerCase();

    // Emergencias — prioridad máxima
    if (t.contains('convuls') || t.contains('convulsión')) {
      return 'EMERGENCIA: Convulsión activa. Posición lateral de seguridad, no introducir objetos en boca. '
          'Remisión URGENTE. Si es gestante, sospechar eclampsia.';
    }
    if (t.contains('dificultad') && t.contains('respir') || t.contains('ahogando')) {
      return 'EMERGENCIA: Dificultad respiratoria. Mantener vías aéreas abiertas, posición semisentada. '
          'Remisión inmediata. Si SpO2 < 92%, es urgencia.';
    }
    if (t.contains('sangrado') && (t.contains('embar') || t.contains('gestante'))) {
      return 'EMERGENCIA: Sangrado en gestante. No administrar oxitocina. '
          'Remisión urgente a ginecobstetricia. No dejar sola a la paciente.';
    }
    if (t.contains('infarto') || t.contains('dolor.*pecho') || t.contains('pecho.*dolor')) {
      return 'EMERGENCIA: Posible infarto. Reposo absoluto, aspirina 300mg si no es alérgico. '
          'Remisión inmediata a urgencias.';
    }

    // Gestación
    if (t.contains('gestante') || t.contains('embaraz') || t.contains('semanas') || t.contains('prenatal')) {
      return 'Para control prenatal ve al módulo Gestación. '
          'Registra PA, FCF, altura uterina y hemoglobina. '
          'Señales de alarma: PA ≥ 140/90, cefalea intensa, visión borrosa — remisión urgente.';
    }

    // Hipertensión
    if (t.contains('presión') || t.contains('hipertens') || t.contains('tension')) {
      return 'PA ≥ 140/90 mmHg = hipertensión. PA ≥ 160/110 = crisis — remisión urgente. '
          'Refuerza tratamiento, dieta sin sal, actividad física. '
          'Usa el módulo Adultez para registrar.';
    }

    // Diabetes
    if (t.contains('diabetes') || t.contains('glucemia') || t.contains('azúcar') || t.contains('glucosa')) {
      return 'Glucemia en ayunas ≥ 126 mg/dL = posible diabetes, confirmar con segunda muestra. '
          'Glucemia ≥ 200 mg/dL = emergencia hipoglucémica. '
          'Registra en módulo Adultez e inicia cambios en estilo de vida.';
    }

    // Niños
    if (t.contains('niño') || t.contains('bebé') || t.contains('infant') || t.contains('menor')) {
      return 'Para niños menores de 5 años usa módulo Primera Infancia. '
          'De 6 a 11 años, módulo Infancia. '
          'Evalúa peso, talla, hemoglobina y vacunación. AIEPI: evalúa respiración, hidratación y conciencia.';
    }

    // Dengue / vectores
    if (t.contains('dengue') || t.contains('fiebre') || t.contains('zika') || t.contains('mosquito')) {
      return 'Fiebre + dolor articular + sarpullido = sospecha dengue. '
          'Hidratación oral, NO aspirina. Señal de alarma: sangrado, vómito persistente, dolor abdominal intenso. '
          'Notificar en módulo Alertas SIVIGILA.';
    }

    // Vacunación
    if (t.contains('vacun') || t.contains('pai') || t.contains('inmuniz')) {
      return 'El PAI Colombia incluye: BCG al nacer, Pentavalente a los 2-4-6 meses, '
          'Triple viral 12 meses, DPT refuerzo 18 meses y 5 años. '
          'Verifica el carné y completa el esquema.';
    }

    // Salud mental
    if (t.contains('depresión') || t.contains('ansied') || t.contains('suicid') || t.contains('autolesion')) {
      return 'Si hay ideas de hacerse daño: EMERGENCIA — activar ruta de salud mental, '
          'no dejar solo al paciente, notificar familia. '
          'Escala PHQ-9 para tamizaje de depresión. Registra en módulo correspondiente.';
    }

    // TBC
    if (t.contains('tuberculosis') || t.contains('tbc') || t.contains('tos.*15') || t.contains('tos crónica')) {
      return 'Tos por más de 15 días = sintomático respiratorio. '
          'Solicitar baciloscopia seriada. Tratamiento DOTS supervisado. '
          'Notificar en SIVIGILA. Aislar hasta resultado.';
    }

    // Nutrición
    if (t.contains('desnutrición') || t.contains('peso bajo') || t.contains('bajo peso')) {
      return 'Desnutrición aguda severa (P/T < -3 DE o edema) = EMERGENCIA, hospitalización. '
          'Moderada: suplementación nutricional y seguimiento quincenal. '
          'Activar programas ICBF en niños.';
    }

    // Adulto mayor
    if (t.contains('anciano') || t.contains('adulto mayor') || t.contains('abuelo') || t.contains('vejez')) {
      return 'Para pacientes mayores de 60 años usa módulo Vejez. '
          'Evalúa funcionalidad (Barthel), cognición, riesgo de caídas y polifarmacia. '
          'Signos de maltrato → activar ruta ICBF / Comisaría de Familia.';
    }

    // Ayuda general
    if (t.contains('hola') || t.contains('ayuda') || t.contains('buenos')) {
      return 'Hola, soy DISPERSALUD IA. Puedo orientarte sobre gestación, niños, '
          'diabetes, hipertensión, dengue, tuberculosis, salud mental y alertas SIVIGILA. '
          '¿Sobre qué paciente necesitas ayuda?';
    }

    // Respuesta genérica
    return 'Entendí: "$pregunta". '
        'Puedo orientarte en gestación, primera infancia, infancia, adolescencia, '
        'adultez, vejez, diabetes, hipertensión y alertas de salud pública. '
        'Describe el síntoma principal del paciente.';
  }
}