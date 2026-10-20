import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Original chart engraving rendered locally, with no image-host dependency.
class VoyageArt extends StatelessWidget {
  const VoyageArt({super.key});
  @override
  Widget build(BuildContext context) =>
      const CustomPaint(painter: _ChartPainter(), child: SizedBox.expand());
}

class _ChartPainter extends CustomPainter {
  const _ChartPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * .51, size.height * .48);
    final radius = math.min(size.width, size.height) * .36;
    final pen = Paint()
      ..color = AppTheme.paper.withAlpha(75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var i = 1; i <= 4; i++) {
      canvas.drawCircle(center, radius * i / 3, pen);
    }
    for (var i = 0; i < 16; i++) {
      final angle = math.pi * i / 8;
      canvas.drawLine(
        center,
        center + Offset(math.cos(angle), math.sin(angle)) * radius * 1.5,
        pen,
      );
    }
    final fill = Paint()..color = AppTheme.paper;
    for (var i = 0; i < 8; i++) {
      final angle = math.pi * i / 4;
      final end =
          center +
          Offset(math.cos(angle), math.sin(angle)) *
              radius *
              (i.isEven ? 1 : .6);
      final side =
          center +
          Offset(math.cos(angle + .4), math.sin(angle + .4)) * radius * .18;
      canvas.drawPath(
        Path()
          ..moveTo(center.dx, center.dy)
          ..lineTo(end.dx, end.dy)
          ..lineTo(side.dx, side.dy)
          ..close(),
        fill,
      );
    }
    canvas.drawCircle(
      center,
      radius * .12,
      Paint()..color = AppTheme.vermilion,
    );
    final route = Path()
      ..moveTo(0, size.height * .8)
      ..cubicTo(
        size.width * .3,
        size.height * .5,
        size.width * .7,
        size.height,
        size.width,
        size.height * .65,
      );
    canvas.drawPath(
      route,
      Paint()
        ..color = const Color(0xFFDBA45F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
