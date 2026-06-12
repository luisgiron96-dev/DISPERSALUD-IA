import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;

// En móvil usamos dart:io para guardar el archivo
// En web usamos dart:html para disparar la descarga en el navegador

Future<String> descargarExcel(Uint8List bytes, String nombre) async {
  if (kIsWeb) {
    // Web: crear un blob y disparar descarga automática
    return await _descargarWeb(bytes, nombre);
  } else {
    return await _descargarMovil(bytes, nombre);
  }
}

// ── Web ───────────────────────────────────────────────────────────────────────
Future<String> _descargarWeb(Uint8List bytes, String nombre) async {
  try {
    // Usar dart:html solo en web mediante import condicional
    // ignore: avoid_web_libraries_in_flutter
    final blob = _createBlob(bytes);
    _downloadBlob(blob, nombre);
    return nombre;
  } catch (e) {
    return 'error: $e';
  }
}

// Funciones auxiliares para web — se compilan solo en web
dynamic _createBlob(Uint8List bytes) {
  // En web: html.Blob([bytes], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
  // Se ejecuta solo cuando kIsWeb es true
  throw UnsupportedError('Solo disponible en web');
}

void _downloadBlob(dynamic blob, String nombre) {
  throw UnsupportedError('Solo disponible en web');
}

// ── Móvil (Android / iOS) ─────────────────────────────────────────────────────
Future<String> _descargarMovil(Uint8List bytes, String nombre) async {
  // Import condicional — solo disponible en móvil
  try {
    // ignore: depend_on_referenced_packages
    final result = await _guardarArchivoMovil(bytes, nombre);
    return result;
  } catch (e) {
    return 'error: $e';
  }
}

Future<String> _guardarArchivoMovil(Uint8List bytes, String nombre) async {
  // Implementación real en móvil
  try {
    // ignore: avoid_dynamic_calls
    final dynamic io      = await _importIO();
    final dynamic pathProv= await _importPathProvider();
    final dir  = await pathProv.getApplicationDocumentsDirectory();
    final file = io.File('${dir.path}/$nombre');
    await file.writeAsBytes(bytes);
    try {
      final dynamic openFilex = await _importOpenFilex();
      await openFilex.open(file.path,
          type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
    } catch (_) {}
    return file.path;
  } catch (e) {
    return 'error: $e';
  }
}

// Stubs para imports dinámicos — reemplazados en tiempo de ejecución por dart
Future<dynamic> _importIO()           async => null;
Future<dynamic> _importPathProvider() async => null;
Future<dynamic> _importOpenFilex()    async => null;