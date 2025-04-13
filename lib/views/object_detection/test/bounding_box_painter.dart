// Custom painter for drawing bounding boxes over camera feed
import 'package:flutter/material.dart';

class BoundingBoxPainter extends CustomPainter {
  final List<Map<String, dynamic>> recognitions;
  final double imageWidth;
  final double imageHeight;
  final double screenWidth;
  final double screenHeight;

  BoundingBoxPainter({
    required this.recognitions,
    required this.imageWidth,
    required this.imageHeight,
    required this.screenWidth,
    required this.screenHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Calculate scaling factors
    final double scaleX = screenWidth / imageWidth;
    final double scaleY = screenHeight / imageHeight;

    for (final recognition in recognitions) {
      // Get bbox coordinates
      final List<int> bbox = List<int>.from(recognition['bbox']);
      final int classId = recognition['class'] as int;
      final double confidence = recognition['confidence'] as double;
      final String label = recognition['label'] as String;

      // Select color based on class
      final Color boxColor = Colors.primaries[classId % Colors.primaries.length];

      // Scale bbox to screen size
      final double left = bbox[0] * scaleX;
      final double top = bbox[1] * scaleY;
      final double right = bbox[2] * scaleX;
      final double bottom = bbox[3] * scaleY;

      // Create bounding box paint
      final Paint boxPaint = Paint()
        ..color = boxColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      // Draw bounding box
      canvas.drawRect(
        Rect.fromLTRB(left, top, right, bottom),
        boxPaint,
      );

      // Create text paint for label
      final TextSpan textSpan = TextSpan(
        text: '$label ${(confidence * 100).toStringAsFixed(0)}%',
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          backgroundColor: boxColor.withOpacity(0.8),
        ),
      );

      final TextPainter textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();

      // Draw text label at top of bounding box
      textPainter.paint(
        canvas,
        Offset(left, top > 10 ? top - textPainter.height : top),
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}