import 'package:flutter/cupertino.dart';

class Sketcher extends CustomPainter {
  final List<Offset?> points;

  Sketcher(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = const Color.fromARGB(255, 255, 255, 255)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 30;

    for (int i = 0; i < points.length - 1; ++i) {
      if (points[i] == null) continue;
      if (points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(Sketcher oldDelegate) {
    return oldDelegate.points != points;
  }
}
