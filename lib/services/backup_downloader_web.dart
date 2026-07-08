import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Dispara la descarga del archivo de backup (JSON) en el navegador.
/// Usa el mismo mecanismo (Blob + <a download>) que ya usa la app para
/// exportar a Excel — el navegador lo guarda en la carpeta de Descargas
/// del usuario, tal como esperaría cualquiera al pedir una "copia de
/// seguridad" en web (aquí no existe una carpeta de documentos interna
/// como en Android/iOS).
Future<String> descargarBackup(String contenido, String nombre) async {
  final bytes  = utf8.encode(contenido);
  final blob   = html.Blob([bytes], 'application/json');
  final url    = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', nombre)
    ..click();
  html.Url.revokeObjectUrl(url);
  return nombre;
}
