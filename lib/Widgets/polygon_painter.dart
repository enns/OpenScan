import 'package:flutter/material.dart';

class PolygonPainter extends CustomPainter {
  final Offset tl, tr, bl, br;
  final double dotRadius = 15.0;

  PolygonPainter({this.tl, this.tr, this.bl, this.br});

  Paint linesConnectingDots = Paint()
    ..color = Colors.orange.withOpacity(0.4)
    ..strokeWidth = 1
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.fill;

  Paint dots = Paint()
    ..color = Colors.orange.withOpacity(0.6)
    ..strokeWidth = 3
    ..strokeCap = StrokeCap.round;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawCircle(tl, dotRadius, linesConnectingDots);
    canvas.drawCircle(tr, dotRadius, linesConnectingDots);
    canvas.drawCircle(bl, dotRadius, linesConnectingDots);
    canvas.drawCircle(br, dotRadius, linesConnectingDots);
    canvas.drawLine(tl, tr, dots);
    canvas.drawLine(tr, br, dots);
    canvas.drawLine(br, bl, dots);
    canvas.drawLine(bl, tl, dots);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
