import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Titik koordinat goresan dengan stempel waktu dan ketebalan dinamis
class PencilStrokePoint {
  final Offset offset;
  final int timestampMs;
  final double width;

  const PencilStrokePoint({
    required this.offset,
    required this.timestampMs,
    required this.width,
  });
}

/// Controller untuk mengelola goresan tanda tangan berefek pensil dinamis
class PencilSignatureController extends ChangeNotifier {
  final Color penColor;
  final double minStrokeWidth;
  final double maxStrokeWidth;
  final double maxVelocity;

  final List<List<PencilStrokePoint>> _strokes = [];
  List<PencilStrokePoint> _currentStroke = [];

  PencilSignatureController({
    this.penColor = Colors.black,
    this.minStrokeWidth = 1.5,
    this.maxStrokeWidth = 4.2,
    this.maxVelocity = 2.4, // px/ms
  });

  bool get isEmpty => _strokes.isEmpty && _currentStroke.isEmpty;
  bool get isNotEmpty => !isEmpty;
  int get strokeCount => _strokes.length + (_currentStroke.isNotEmpty ? 1 : 0);

  List<List<PencilStrokePoint>> get allStrokes {
    if (_currentStroke.isEmpty) return _strokes;
    return [..._strokes, _currentStroke];
  }

  void onPointerDown(Offset localPosition) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final initialWidth = (minStrokeWidth + maxStrokeWidth) / 2;
    _currentStroke = [
      PencilStrokePoint(
        offset: localPosition,
        timestampMs: now,
        width: initialWidth,
      ),
    ];
    notifyListeners();
  }

  void onPointerMove(Offset localPosition) {
    if (_currentStroke.isEmpty) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final lastPoint = _currentStroke.last;
    final distance = (localPosition - lastPoint.offset).distance;

    // Abaikan getaran mikro di bawah 1 pixel
    if (distance < 1.0) return;

    final dt = (now - lastPoint.timestampMs).clamp(1, 150);
    final velocity = distance / dt; // px per millisecond

    // Efek Pensil Dinamis:
    // Kecepatan tinggi (flick cepat) -> stroke width mengecil mendekati minStrokeWidth
    // Kecepatan rendah (gerakan lambat/hati-hati) -> stroke width membesar mendekati maxStrokeWidth
    final velocityRatio = (velocity / maxVelocity).clamp(0.0, 1.0);
    final curvedRatio = math.pow(velocityRatio, 0.7).toDouble();
    final targetWidth =
        maxStrokeWidth - (maxStrokeWidth - minStrokeWidth) * curvedRatio;

    // Filter eksponensial (damping) agar ketebalan transisi halus tanpa patah-patah
    final smoothWidth = (lastPoint.width * 0.65) + (targetWidth * 0.35);

    _currentStroke.add(
      PencilStrokePoint(
        offset: localPosition,
        timestampMs: now,
        width: smoothWidth.clamp(minStrokeWidth, maxStrokeWidth),
      ),
    );
    notifyListeners();
  }

  void onPointerUp() {
    if (_currentStroke.isNotEmpty) {
      _strokes.add(List.unmodifiable(_currentStroke));
      _currentStroke = [];
      notifyListeners();
    }
  }

  /// Bersihkan seluruh coretan
  void clear() {
    _strokes.clear();
    _currentStroke.clear();
    notifyListeners();
  }

  /// Urungkan goresan terakhir
  void undo() {
    if (_strokes.isNotEmpty) {
      _strokes.removeLast();
      notifyListeners();
    }
  }

  /// Ekspor coretan ke format PNG transparan dengan resolusi tinggi (DPI optimal)
  /// Menggunakan auto-crop bounding box dengan padding agar tanda tangan proporsional di dokumen PDF
  Future<Uint8List?> toPngBytes({
    double pixelRatio = 3.0,
    Color? backgroundColor,
  }) async {
    if (isEmpty) return null;

    final strokesToRender = allStrokes;

    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = -double.infinity;
    double maxY = -double.infinity;

    for (final stroke in strokesToRender) {
      for (final pt in stroke) {
        if (pt.offset.dx < minX) minX = pt.offset.dx;
        if (pt.offset.dy < minY) minY = pt.offset.dy;
        if (pt.offset.dx > maxX) maxX = pt.offset.dx;
        if (pt.offset.dy > maxY) maxY = pt.offset.dy;
      }
    }

    // Beri batas ruang (padding) minimal di sekeliling tanda tangan agar ukuran tampil maksimal
    const double padding = 6.0;
    minX = math.max(0, minX - padding);
    minY = math.max(0, minY - padding);
    maxX += padding;
    maxY += padding;

    final double sigWidth = math.max(80.0, maxX - minX);
    final double sigHeight = math.max(35.0, maxY - minY);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    canvas.scale(pixelRatio, pixelRatio);

    if (backgroundColor != null && backgroundColor != Colors.transparent) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, sigWidth, sigHeight),
        Paint()..color = backgroundColor,
      );
    }

    // Geser titik nol kanvas ke sudut bounding box
    canvas.translate(-minX, -minY);

    for (final stroke in strokesToRender) {
      paintPencilStroke(canvas, stroke, penColor);
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(
      (sigWidth * pixelRatio).round(),
      (sigHeight * pixelRatio).round(),
    );
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }
}

/// Fungsi helper untuk menggambar satu goresan pensil mulus dengan interpolasi Bezier dan ketebalan dinamis
void paintPencilStroke(
  Canvas canvas,
  List<PencilStrokePoint> stroke,
  Color penColor,
) {
  if (stroke.isEmpty) return;

  final fillPaint = Paint()
    ..color = penColor
    ..style = PaintingStyle.fill;

  if (stroke.length == 1) {
    canvas.drawCircle(stroke[0].offset, stroke[0].width / 2, fillPaint);
    return;
  }

  if (stroke.length == 2) {
    final linePaint = Paint()
      ..color = penColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = (stroke[0].width + stroke[1].width) / 2;
    canvas.drawLine(stroke[0].offset, stroke[1].offset, linePaint);
    canvas.drawCircle(stroke[0].offset, stroke[0].width / 2, fillPaint);
    canvas.drawCircle(stroke[1].offset, stroke[1].width / 2, fillPaint);
    return;
  }

  // Interpolasi Quadratic Bezier kurva mulus antar titik tengah (midpoint)
  for (int i = 0; i < stroke.length - 1; i++) {
    final p0 = i == 0
        ? stroke[0].offset
        : Offset(
            (stroke[i - 1].offset.dx + stroke[i].offset.dx) / 2,
            (stroke[i - 1].offset.dy + stroke[i].offset.dy) / 2,
          );
    final p1 = stroke[i].offset;
    final p2 = (i == stroke.length - 2)
        ? stroke[i + 1].offset
        : Offset(
            (stroke[i].offset.dx + stroke[i + 1].offset.dx) / 2,
            (stroke[i].offset.dy + stroke[i + 1].offset.dy) / 2,
          );

    final double wStart = stroke[i].width;
    final double wEnd = stroke[i + 1].width;

    const int steps = 6;
    Offset prevPoint = p0;

    for (int s = 1; s <= steps; s++) {
      final double t = s / steps;
      final double invT = 1.0 - t;

      // Persamaan kurva Bezier B(t) = (1-t)^2 * p0 + 2(1-t)t * p1 + t^2 * p2
      final Offset currentPoint = Offset(
        invT * invT * p0.dx + 2 * invT * t * p1.dx + t * t * p2.dx,
        invT * invT * p0.dy + 2 * invT * t * p1.dy + t * t * p2.dy,
      );

      final double currentWidth = wStart + (wEnd - wStart) * t;

      final stepPaint = Paint()
        ..color = penColor
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = currentWidth;

      canvas.drawLine(prevPoint, currentPoint, stepPaint);
      canvas.drawCircle(currentPoint, currentWidth / 2, fillPaint);
      prevPoint = currentPoint;
    }
  }
}

/// CustomPainter untuk me-render goresan di kanvas interaktif
class _PencilSignaturePainter extends CustomPainter {
  final PencilSignatureController controller;

  _PencilSignaturePainter({required this.controller})
    : super(repaint: controller);

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in controller.allStrokes) {
      paintPencilStroke(canvas, stroke, controller.penColor);
    }
  }

  @override
  bool shouldRepaint(covariant _PencilSignaturePainter oldDelegate) => true;
}

/// Widget Pad Tanda Tangan Berefek Pensil / Ink Dinamis
class PencilSignaturePad extends StatelessWidget {
  final PencilSignatureController controller;
  final Color backgroundColor;
  final String placeholderText;
  final VoidCallback? onStartDrawing;
  final VoidCallback? onEndDrawing;

  const PencilSignaturePad({
    super.key,
    required this.controller,
    this.backgroundColor = Colors.transparent,
    this.placeholderText = 'Tanda tangan di sini',
    this.onStartDrawing,
    this.onEndDrawing,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Menangkap event drag vertikal & horizontal agar Scrollable (ListView) induk tidak ikut scroll
      onVerticalDragDown: (_) {},
      onVerticalDragStart: (_) => onStartDrawing?.call(),
      onVerticalDragUpdate: (_) {},
      onVerticalDragEnd: (_) => onEndDrawing?.call(),
      onVerticalDragCancel: () => onEndDrawing?.call(),
      onHorizontalDragDown: (_) {},
      onHorizontalDragStart: (_) => onStartDrawing?.call(),
      onHorizontalDragUpdate: (_) {},
      onHorizontalDragEnd: (_) => onEndDrawing?.call(),
      onHorizontalDragCancel: () => onEndDrawing?.call(),
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: backgroundColor,
        child: Stack(
          children: [
            // Garis panduan tanda tangan (dashed signature baseline)
            Positioned(
              left: 20,
              right: 20,
              bottom: 30,
              child: Opacity(
                opacity: 0.25,
                child: Container(height: 1, color: Colors.grey.shade600),
              ),
            ),

            // Placeholder teks saat belum ada coretan
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: controller,
                  builder: (context, _) {
                    if (controller.isNotEmpty) return const SizedBox.shrink();
                    return Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.edit_outlined,
                            size: 18,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            placeholderText,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade400,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),

            // Area sentuh dan kanvas goresan dengan Listener langsung
            Positioned.fill(
              child: Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: (event) {
                  onStartDrawing?.call();
                  controller.onPointerDown(event.localPosition);
                },
                onPointerMove: (event) =>
                    controller.onPointerMove(event.localPosition),
                onPointerUp: (_) {
                  controller.onPointerUp();
                  onEndDrawing?.call();
                },
                onPointerCancel: (_) {
                  controller.onPointerUp();
                  onEndDrawing?.call();
                },
                child: RepaintBoundary(
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: _PencilSignaturePainter(controller: controller),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
