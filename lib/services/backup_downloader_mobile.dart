import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// En Android/iOS simplemente guarda el archivo en la carpeta de
/// documentos de la app, igual que ya hacía `_crearCopia()` antes de
/// separar esta lógica por plataforma.
Future<String> descargarBackup(String contenido, String nombre) async {
  final dir  = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/$nombre');
  await file.writeAsString(contenido);
  return file.path;
}
