import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

Future<String> descargarExcel(Uint8List bytes, String nombre) async {
  Directory? dir;

  if (Platform.isAndroid) {
    dir = Directory('/storage/emulated/0/Download');
    if (!await dir.exists()) {
      dir = await getApplicationDocumentsDirectory();
    }
  } else {
    dir = await getApplicationDocumentsDirectory();
  }

  final file = File('${dir.path}/$nombre');
  await file.writeAsBytes(bytes);

  // Abrir el archivo automáticamente con la app disponible (Google Sheets, WPS, etc.)
  await OpenFilex.open(file.path,
      type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');

  return file.path;
}