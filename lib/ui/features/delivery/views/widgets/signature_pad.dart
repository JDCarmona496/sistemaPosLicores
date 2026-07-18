import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Lienzo simple de firma digital. Exporta la firma como PNG.
class SignaturePad extends StatefulWidget {
  final void Function(Uint8List? bytes)? onChanged;

  const SignaturePad({super.key, this.onChanged});

  @override
  State<SignaturePad> createState() => SignaturePadState();
}

class SignaturePadState extends State<SignaturePad> {
  final List<List<Offset>> _strokes = [];

  bool get isNotEmpty => _strokes.isNotEmpty;

  void clear() {
    setState(() => _strokes.clear());
    widget.onChanged?.call(null);
  }

  Future<Uint8List?> exportPng() async {
    if (_strokes.isEmpty) return null;

    final size = context.size ?? const Size(300, 150);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size.width, size.height));

    // Fondo blanco para que la firma se vea bien al imprimir o mostrar.
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = Colors.white,
    );

    _SignaturePainter(_strokes).paint(canvas, size);

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.width.toInt(), size.height.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(12),
        ),
        child: GestureDetector(
          onPanStart: (details) {
            setState(() => _strokes.add([details.localPosition]));
          },
          onPanUpdate: (details) {
            setState(() => _strokes.last.add(details.localPosition));
          },
          onPanEnd: (_) async {
            widget.onChanged?.call(await exportPng());
          },
          child: CustomPaint(
            painter: _SignaturePainter(_strokes),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  final List<List<Offset>> strokes;

  _SignaturePainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      if (stroke.length < 2) continue;
      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (var i = 1; i < stroke.length; i++) {
        path.lineTo(stroke[i].dx, stroke[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}
