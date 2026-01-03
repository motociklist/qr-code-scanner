import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Create a picture recorder
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  const size = 1024.0;

  // Draw white background
  final backgroundPaint = Paint()..color = Colors.white;
  canvas.drawRect(const Rect.fromLTWH(0, 0, size, size), backgroundPaint);

  // Draw a simple QR code pattern
  final paint = Paint()..color = Colors.black;
  const cellSize = size / 25; // 25x25 grid

  // Draw corner squares (typical QR code pattern)
  _drawCornerSquare(canvas, 0, 0, cellSize, paint);
  _drawCornerSquare(canvas, size - cellSize * 7, 0, cellSize, paint);
  _drawCornerSquare(canvas, 0, size - cellSize * 7, cellSize, paint);

  // Draw some pattern cells
  for (int i = 0; i < 25; i++) {
    for (int j = 0; j < 25; j++) {
      if ((i + j) % 3 == 0 || (i * j) % 7 == 0) {
        if (!_isInCorner(i, j)) {
          canvas.drawRect(
            Rect.fromLTWH(i * cellSize, j * cellSize, cellSize, cellSize),
            paint,
          );
        }
      }
    }
  }

  // Convert to image
  final picture = recorder.endRecording();
  final image = await picture.toImage(size.toInt(), size.toInt());
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  final pngBytes = byteData!.buffer.asUint8List();

  // Save to file
  final file = File('assets/images/app_icon.png');
  await file.create(recursive: true);
  await file.writeAsBytes(pngBytes);

  // ignore: avoid_print
  print('Icon generated successfully at ${file.path}');
}

void _drawCornerSquare(Canvas canvas, double x, double y, double cellSize, Paint paint) {
  // Outer square
  canvas.drawRect(Rect.fromLTWH(x, y, cellSize * 7, cellSize * 7), paint);
  // Inner white square
  final whitePaint = Paint()..color = Colors.white;
  canvas.drawRect(
    Rect.fromLTWH(x + cellSize, y + cellSize, cellSize * 5, cellSize * 5),
    whitePaint,
  );
  // Inner black square
  canvas.drawRect(
    Rect.fromLTWH(x + cellSize * 2, y + cellSize * 2, cellSize * 3, cellSize * 3),
    paint,
  );
}

bool _isInCorner(int i, int j) {
  // Check if cell is in one of the corner squares
  return (i < 7 && j < 7) ||
         (i >= 18 && j < 7) ||
         (i < 7 && j >= 18);
}

