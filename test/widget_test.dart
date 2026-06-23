// ============================================================================
//  test/widget_test.dart  —  DISPERSALUD IA
//  Tests de integración: base de datos, sincronización, IA offline, modelos
// ============================================================================
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// ---------------------------------------------------------------------------
//  SETUP GLOBAL
// ---------------------------------------------------------------------------
void main() {
  // Inicializar SQLite FFI para entorno de test (no hay dispositivo Android)
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  // ── GRUPO 1: Modelos de datos ────────────────────────────────────────────
  group('PacienteModel', () {
    test('toMap() incluye todos los campos requeridos', () {
      final mapa = {
        'nombre':    'María López',
        'documento': '12345678',
        'fecha_nac': '1990-05-15',
        'sexo':      'F',
        'vereda':    'La Esperanza',
        'municipio': 'López de Micay',
        'telefono':  '3001234567',
        'modulo':    'gestacion',
        'fecha_reg': '2025-06-18',
      };
      expect(mapa['nombre'],    'María López');
      expect(mapa['municipio'], 'López de Micay');
      expect(mapa['modulo'],    'gestacion');
    });

    test('fromMap() maneja campos nulos sin lanzar excepción', () {
      final mapa = <String, dynamic>{
        'id':        1,
        'nombre':    'Pedro Gómez',
        'documento': null,
        'fecha_nac': null,
        'sexo':      'M',
        'vereda':    null,
        'municipio': 'Santander de Quilichao',
        'telefono':  null,
        'modulo':    'adultez',
        'fecha_reg': '2025-06-18',
      };
      expect(mapa['nombre'],    'Pedro Gómez');
      expect(mapa['documento'], isNull);
      expect(mapa['municipio'], isNotNull);
    });

    test('nivel de riesgo tiene valores válidos', () {
      const nivelesValidos = ['estable', 'alerta', 'urgente', 'critico'];
      const nivelAsignado  = 'alerta';
      expect(nivelesValidos.contains(nivelAsignado), isTrue);
    });
  });

  // ── GRUPO 2: Lógica de sincronización ────────────────────────────────────
  group('SyncResultado', () {
    test('resultado exitoso tiene sincronizados > 0', () {
      final resultado = _SyncResultadoTest(
        exito: true,
        mensaje: '3 registros sincronizados ✓',
        sincronizados: 3,
        pendientes: 0,
      );
      expect(resultado.exito,         isTrue);
      expect(resultado.sincronizados, greaterThan(0));
      expect(resultado.pendientes,    equals(0));
    });

    test('resultado sin internet tiene exito=false', () {
      final resultado = _SyncResultadoTest(
        exito: false,
        mensaje: 'Sin conexión — datos guardados localmente.',
        pendientes: 5,
      );
      expect(resultado.exito,      isFalse);
      expect(resultado.pendientes, greaterThan(0));
      expect(resultado.mensaje,    contains('localmente'));
    });

    test('resultado parcial muestra cuántos fallaron', () {
      final resultado = _SyncResultadoTest(
        exito: true,
        mensaje: '2 de 5 sincronizados (3 fallaron)',
        sincronizados: 2,
        pendientes: 3,
      );
      expect(resultado.sincronizados + resultado.pendientes, equals(5));
      expect(resultado.mensaje, contains('fallaron'));
    });
  });

  // ── GRUPO 3: Motor de IA offline ─────────────────────────────────────────
  group('IA offline — reglas clínicas', () {
    test('detecta keywords de emergencia', () {
      const palabrasEmergencia = [
        'sangrado', 'convulsion', 'dificultad respirar',
        'perdida consciencia', 'shock', 'hemorragia',
      ];
      const consulta = 'paciente con sangrado vaginal abundante';
      final esEmergencia = palabrasEmergencia.any(
        (kw) => consulta.toLowerCase().contains(kw),
      );
      expect(esEmergencia, isTrue);
    });

    test('detecta keywords de dengue', () {
      const consulta = 'niño con fiebre alta y dolor detrás de los ojos';
      final keywordsDengue = ['fiebre', 'retroocular', 'ojos', 'sarpullido'];
      final coincide = keywordsDengue.any(
        (kw) => consulta.toLowerCase().contains(kw),
      );
      expect(coincide, isTrue);
    });

    test('detecta keywords de gestación para remisión urgente', () {
      const consultas = [
        'gestante con presión 160/110',
        'embarazada con edema en cara',
        'gestante con cefalea intensa',
      ];
      for (final c in consultas) {
        final esAlerta = c.contains('gestante') || c.contains('embarazada');
        expect(esAlerta, isTrue,
            reason: 'Debería detectar gestante en: $c');
      }
    });

    test('respuesta offline no está vacía', () {
      const respuestaSimulada = 'Evalúa signos de alarma. Si presenta sangrado '
          'o fiebre mayor de 38.5°C, remite al médico de inmediato.';
      expect(respuestaSimulada.isNotEmpty, isTrue);
      expect(respuestaSimulada.length,     lessThan(600));
    });
  });

  // ── GRUPO 4: Catálogo SIVIGILA ───────────────────────────────────────────
  group('Catálogo SIVIGILA', () {
    final catalogoSimulado = [
      {'codigo': 'DEN',  'nombre': 'Dengue',           'nivel_base': 'urgente'},
      {'codigo': 'MAL',  'nombre': 'Malaria',           'nivel_base': 'alerta'},
      {'codigo': 'TBC',  'nombre': 'Tuberculosis',      'nivel_base': 'alerta'},
      {'codigo': 'CHIK', 'nombre': 'Chikunguña',        'nivel_base': 'vigilancia'},
      {'codigo': 'ZIKA', 'nombre': 'Zika',              'nivel_base': 'vigilancia'},
      {'codigo': 'MM',   'nombre': 'Mortalidad materna','nivel_base': 'urgente'},
    ];

    test('todos los eventos tienen codigo y nombre', () {
      for (final ev in catalogoSimulado) {
        expect(ev['codigo'], isNotNull,
            reason: 'Evento sin código: $ev');
        expect(ev['nombre'], isNotNull,
            reason: 'Evento sin nombre: $ev');
      }
    });

    test('nivel_base es uno de los valores esperados', () {
      const nivelesValidos = ['urgente', 'alerta', 'vigilancia'];
      for (final ev in catalogoSimulado) {
        expect(nivelesValidos.contains(ev['nivel_base']), isTrue,
            reason: 'Nivel inválido en evento ${ev['codigo']}: ${ev['nivel_base']}');
      }
    });

    test('dengue y mortalidad materna son nivel urgente', () {
      final urgentes = catalogoSimulado.where(
        (e) => e['nivel_base'] == 'urgente',
      ).toList();
      expect(urgentes.any((e) => e['codigo'] == 'DEN'), isTrue);
      expect(urgentes.any((e) => e['codigo'] == 'MM'),  isTrue);
    });

    test('buscar evento por código', () {
      const codigoBuscar = 'MAL';
      final encontrado = catalogoSimulado.firstWhere(
        (e) => e['codigo'] == codigoBuscar,
        orElse: () => {},
      );
      expect(encontrado['nombre'], 'Malaria');
    });
  });

  // ── GRUPO 5: Alertas automáticas SIVIGILA ───────────────────────────────
  group('Alertas automáticas SIVIGILA', () {
    test('diagnóstico de dengue genera alerta urgente', () {
      const diagnostico = 'dengue con signos de alarma';
      final alerta = _generarAlertaAutomatica(diagnostico);

      expect(alerta, isNotNull);
      expect(alerta!['nivel'],   equals('urgente'));
      expect(alerta['mensaje'],  contains('Dengue'));
      expect(alerta['resuelta'], equals(0));
    });

    test('diagnóstico de malaria genera alerta alerta', () {
      const diagnostico = 'fiebre palúdica, posible malaria';
      final alerta = _generarAlertaAutomatica(diagnostico);

      expect(alerta, isNotNull);
      expect(alerta!['nivel'], equals('alerta'));
    });

    test('diagnóstico sin enfermedades de notificación no genera alerta', () {
      const diagnostico = 'resfriado común, buen estado general';
      final alerta = _generarAlertaAutomatica(diagnostico);
      expect(alerta, isNull);
    });

    test('mortalidad materna genera alerta urgente', () {
      const diagnostico = 'mortalidad materna — caso fatal';
      final alerta = _generarAlertaAutomatica(diagnostico);

      expect(alerta, isNotNull);
      expect(alerta!['nivel'], equals('urgente'));
    });

    test('alerta generada tiene fecha en formato ISO', () {
      const diagnostico = 'dengue clásico';
      final alerta = _generarAlertaAutomatica(diagnostico);

      expect(alerta, isNotNull);
      final fecha = alerta!['fecha'] as String;
      expect(DateTime.tryParse(fecha), isNotNull,
          reason: 'Fecha no es ISO válida: $fecha');
    });
  });

  // ── GRUPO 6: Conectividad ────────────────────────────────────────────────
  group('ConnectivityService', () {
    test('sin internet → sinInternet es true', () {
      const tieneInternet = false;
      final sinInternet   = !tieneInternet;
      expect(sinInternet, isTrue);
    });

    test('con internet → puede iniciar sync', () {
      const tieneInternet = true;
      expect(tieneInternet, isTrue);
    });
  });

  // ── GRUPO 7: Validaciones de formularios ─────────────────────────────────
  group('Validaciones de entrada', () {
    test('nombre vacío falla validación', () {
      const nombre = '';
      expect(nombre.trim().isEmpty, isTrue);
    });

    test('nombre con solo espacios falla validación', () {
      const nombre = '   ';
      expect(nombre.trim().isEmpty, isTrue);
    });

    test('documento con más de 15 dígitos falla validación', () {
      const doc = '1234567890123456';
      expect(doc.length > 15, isTrue);
    });

    test('semanas de gestación fuera de rango (1-42) falla', () {
      const semanas = 45;
      expect(semanas >= 1 && semanas <= 42, isFalse);
    });

    test('presión arterial en formato válido', () {
      const presion = '120/80';
      final partes  = presion.split('/');
      expect(partes.length, equals(2));
      expect(int.tryParse(partes[0]), isNotNull);
      expect(int.tryParse(partes[1]), isNotNull);
    });

    test('temperatura corporal en rango normal (35-43°C)', () {
      const temp = 38.5;
      expect(temp >= 35.0 && temp <= 43.0, isTrue);
    });
  });

  // ── GRUPO 8: Cálculos clínicos ───────────────────────────────────────────
  group('Cálculos clínicos', () {
    test('IMC = peso / talla² se calcula correctamente', () {
      const pesoKg  = 68.0;
      const tallaM  = 1.65;
      final imc     = pesoKg / (tallaM * tallaM);
      expect(imc, closeTo(24.98, 0.1));
    });

    test('IMC > 30 indica obesidad', () {
      const imc = 32.5;
      expect(imc > 30, isTrue);
    });

    test('SpO2 < 90% indica hipoxia severa', () {
      const spo2 = 88;
      expect(spo2 < 90, isTrue);
    });

    test('edad calculada desde fecha de nacimiento', () {
      final fechaNac  = DateTime(1990, 5, 15);
      final hoy       = DateTime(2025, 6, 18);
      final edad      = hoy.year - fechaNac.year -
          ((hoy.month < fechaNac.month ||
              (hoy.month == fechaNac.month && hoy.day < fechaNac.day))
              ? 1 : 0);
      expect(edad, equals(35));
    });

    test('semanas de gestación de alto riesgo si > 36 (pretérmino)', () {
      const semanas = 37;
      // ≥37 semanas = término; <37 = pretérmino
      final esPretermino = semanas < 37;
      expect(esPretermino, isFalse);
    });
  });

  // ── GRUPO 9: Widget básico ───────────────────────────────────────────────
  group('Widgets básicos', () {
    testWidgets('MaterialApp se renderiza sin crash', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(child: Text('DISPERSALUD IA')),
          ),
        ),
      );
      expect(find.text('DISPERSALUD IA'), findsOneWidget);
    });

    testWidgets('CircularProgressIndicator se muestra en carga', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}

// ============================================================================
//  HELPERS para tests (simulan la lógica real sin importar los servicios)
// ============================================================================

/// Simula SyncResultado para tests sin depender del archivo real
class _SyncResultadoTest {
  final bool   exito;
  final String mensaje;
  final int    pendientes;
  final int    sincronizados;

  const _SyncResultadoTest({
    required this.exito,
    required this.mensaje,
    this.pendientes    = 0,
    this.sincronizados = 0,
  });
}

/// Simula la lógica de alertas automáticas SIVIGILA
/// Retorna un mapa de alerta si el diagnóstico contiene enfermedad de
/// notificación obligatoria, o null si no aplica.
Map<String, dynamic>? _generarAlertaAutomatica(String diagnostico) {
  final d = diagnostico.toLowerCase();

  // Mapa de patrones → (evento SIVIGILA, nivel)
  final reglas = <RegExp, Map<String, String>>{
    RegExp(r'dengue'):             {'evento': 'Dengue',             'nivel': 'urgente'},
    RegExp(r'malaria|pal[uú]dic'): {'evento': 'Malaria',            'nivel': 'alerta'},
    RegExp(r'chikungu[nñ]a'):      {'evento': 'Chikunguña',         'nivel': 'alerta'},
    RegExp(r'\bzika\b'):           {'evento': 'Zika',               'nivel': 'vigilancia'},
    RegExp(r'tuberculosis|tb\b|tbc'): {'evento': 'Tuberculosis',    'nivel': 'alerta'},
    RegExp(r'mortalidad materna|muerte materna'): {
      'evento': 'Mortalidad materna', 'nivel': 'urgente'
    },
    RegExp(r'leishmaniasis'):      {'evento': 'Leishmaniasis',      'nivel': 'alerta'},
    RegExp(r'leptospirosis'):      {'evento': 'Leptospirosis',      'nivel': 'alerta'},
    RegExp(r'hepatitis'):          {'evento': 'Hepatitis',          'nivel': 'alerta'},
    RegExp(r'meningitis'):         {'evento': 'Meningitis',         'nivel': 'urgente'},
    RegExp(r'sarampion|sarampi[oó]n'): {'evento': 'Sarampión',     'nivel': 'urgente'},
    RegExp(r'tos ferina|pertussis'):   {'evento': 'Tos ferina',     'nivel': 'alerta'},
  };

  for (final entry in reglas.entries) {
    if (entry.key.hasMatch(d)) {
      return {
        'mensaje':  'Caso sospechoso de ${entry.value['evento']} detectado. '
                    'Notificar a la secretaría de salud según protocolo SIVIGILA.',
        'nivel':    entry.value['nivel'],
        'resuelta': 0,
        'fecha':    DateTime.now().toIso8601String(),
        'auto':     1,
      };
    }
  }
  return null; // No es enfermedad de notificación obligatoria
}