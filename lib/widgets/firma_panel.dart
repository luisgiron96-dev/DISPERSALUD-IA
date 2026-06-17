// lib/widgets/firma_panel.dart
//
// Panel reutilizable para capturar la firma manuscrita de un profesional
// de salud, dibujada con el dedo sobre la pantalla. No depende de paquetes
// externos: usa CustomPainter puro de Flutter.
//
// Uso típico:
//   final firmaBytes = await mostrarDialogoFirma(
//     context: context,
//     nombreProfesional: 'Juan Pérez',
//   );
//   // firmaBytes es un Uint8List PNG, o null si el usuario canceló.
// ─────────────────────────────────────────────────────────────────────────

import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../core/app_theme.dart';

DispersaludColors _c(BuildContext ctx) =>
    Theme.of(ctx).extension<DispersaludColors>() ?? DispersaludColors.dark;

/// Controlador interno: guarda los trazos dibujados por el usuario.
class _TrazoFirma {
  final List<Offset?> puntos = [];
}

/// Widget de lienzo donde el usuario dibuja la firma con el dedo.
class FirmaCanvas extends StatefulWidget {
  final GlobalKey lienzoKey;
  const FirmaCanvas({super.key, required this.lienzoKey});

  @override
  State<FirmaCanvas> createState() => FirmaCanvasState();
}

class FirmaCanvasState extends State<FirmaCanvas> {
  final List<_TrazoFirma> _trazos = [];
  _TrazoFirma? _trazoActual;

  bool get tieneFirma => _trazos.isNotEmpty;

  void limpiar() => setState(() {
    _trazos.clear();
    _trazoActual = null;
  });

  void _iniciarTrazo(Offset punto) {
    final t = _TrazoFirma();
    t.puntos.add(punto);
    setState(() {
      _trazoActual = t;
      _trazos.add(t);
    });
  }

  void _continuarTrazo(Offset punto) {
    setState(() => _trazoActual?.puntos.add(punto));
  }

  void _finalizarTrazo() {
    setState(() => _trazoActual?.puntos.add(null));
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: widget.lienzoKey,
      child: Container(
        color: Colors.white, // Fondo blanco fijo: la firma debe verse igual
        width: double.infinity,
        height: double.infinity,
        child: GestureDetector(
          onPanStart: (d) => _iniciarTrazo(d.localPosition),
          onPanUpdate: (d) => _continuarTrazo(d.localPosition),
          onPanEnd: (_) => _finalizarTrazo(),
          child: CustomPaint(
            painter: _FirmaPainter(_trazos),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }
}

class _FirmaPainter extends CustomPainter {
  final List<_TrazoFirma> trazos;
  _FirmaPainter(this.trazos);

  @override
  void paint(Canvas canvas, Size size) {
    final pintura = Paint()
      ..color = Colors.black
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (final trazo in trazos) {
      for (int i = 0; i < trazo.puntos.length - 1; i++) {
        final p1 = trazo.puntos[i];
        final p2 = trazo.puntos[i + 1];
        if (p1 != null && p2 != null) {
          canvas.drawLine(p1, p2, pintura);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FirmaPainter oldDelegate) => true;
}

/// Convierte lo dibujado en el lienzo a bytes PNG.
Future<Uint8List?> _capturarFirmaPng(GlobalKey lienzoKey) async {
  try {
    final boundary = lienzoKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: 2.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  } catch (_) {
    return null;
  }
}

/// Muestra el diálogo modal de captura de firma.
/// Devuelve los bytes PNG de la firma si el usuario confirma, o null si
/// cancela o cierra sin firmar.
Future<Uint8List?> mostrarDialogoFirma({
  required BuildContext context,
  String? nombreProfesional,
  String titulo = 'Firma del profesional',
}) {
  final lienzoKey = GlobalKey();
  final canvasKey = GlobalKey<FirmaCanvasState>();

  return showModalBottomSheet<Uint8List?>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final dc = _c(ctx);
      return Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom +
                MediaQuery.of(ctx).padding.bottom),
        child: Container(
          decoration: BoxDecoration(
            color: dc.card,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                    color: dc.border, borderRadius: BorderRadius.circular(2))),
            Row(children: [
              Icon(Icons.draw_outlined, color: kVerde, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(titulo, style: TextStyle(color: dc.textPrimary,
                    fontSize: 15, fontWeight: FontWeight.bold)),
                if (nombreProfesional != null && nombreProfesional.isNotEmpty)
                  Text(nombreProfesional, style: TextStyle(
                      color: dc.textHint, fontSize: 12)),
              ])),
            ]),
            const SizedBox(height: 14),
            Text('Dibuje su firma en el recuadro con el dedo',
                style: TextStyle(color: dc.textHint, fontSize: 11.5)),
            const SizedBox(height: 8),
            Container(
              height: 220,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: dc.border, width: 1.4),
              ),
              clipBehavior: Clip.antiAlias,
              child: FirmaCanvas(lienzoKey: lienzoKey, key: canvasKey),
            ),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => canvasKey.currentState?.limpiar(),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Limpiar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: dc.textSecondary,
                    side: BorderSide(color: dc.border),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    if (canvasKey.currentState?.tieneFirma != true) {
                      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                        content: const Text('Por favor dibuje la firma antes de confirmar'),
                        backgroundColor: Colors.orange,
                        behavior: SnackBarBehavior.floating,
                      ));
                      return;
                    }
                    final bytes = await _capturarFirmaPng(lienzoKey);
                    if (ctx.mounted) Navigator.pop(ctx, bytes);
                  },
                  icon: const Icon(Icons.check_rounded, size: 18, color: Colors.white),
                  label: const Text('Confirmar firma',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kVerde,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 6),
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: Text('Cancelar', style: TextStyle(color: dc.textHint, fontSize: 12.5)),
            ),
          ]),
        ),
      );
    },
  );
}

/// Widget pequeño para PREVISUALIZAR una firma ya guardada (bytes PNG),
/// útil en pantallas de historial o detalle.
class FirmaPreview extends StatelessWidget {
  final Uint8List? firmaBytes;
  final String? nombreProfesional;
  final double height;
  const FirmaPreview({
    super.key,
    required this.firmaBytes,
    this.nombreProfesional,
    this.height = 90,
  });

  @override
  Widget build(BuildContext context) {
    final dc = _c(context);
    if (firmaBytes == null) {
      return Container(
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: dc.border.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text('Sin firma registrada',
            style: TextStyle(color: dc.textHint, fontSize: 11.5)),
      );
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        height: height,
        width: double.infinity,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: dc.border),
        ),
        child: Image.memory(firmaBytes!, fit: BoxFit.contain),
      ),
      if (nombreProfesional != null && nombreProfesional!.isNotEmpty) ...[
        const SizedBox(height: 4),
        Text(nombreProfesional!,
            style: TextStyle(color: dc.textHint, fontSize: 10.5)),
      ],
    ]);
  }
}