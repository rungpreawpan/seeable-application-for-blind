import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seeable/views/object_detection/components/custom_box_painter.dart';

class ObjectDetectionView extends StatelessWidget {
  final File imageFile;
  final int imageHeight;
  final int imageWidth;
  final List<Map<String, dynamic>> recognitions;
  final double confidence;

  const ObjectDetectionView({
    super.key,
    required this.imageFile,
    required this.imageHeight,
    required this.imageWidth,
    required this.recognitions,
    this.confidence = 0.5,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      // fit: StackFit.expand,
      children: [
        // Image layer
        Image.file(
          imageFile,
          fit: BoxFit.contain,
        ),

        // // Overlay layer for bounding boxes
        // CustomPaint(
        //   painter: CustomBoxPainter(
        //     recognitions: recognitions,
        //     confidence: confidence,
        //     imageHeight: imageHeight,
        //     imageWidth: imageWidth,
        //   ),
        //   // painter: DirectBoxPainter(
        //   //   recognitions: recognitions,
        //   // ),
        // ),

        //TODO:
        ...recognitions.map((recognition) {
          final List<int> bbox = List<int>.from(recognition['bbox']);
          final String label = recognition['label'] as String;
          final double score = recognition['confidence'] as double;
          final int classId = recognition['class'] as int;

          final color = Colors.primaries[classId % Colors.primaries.length];

          final double scaleX = Get.width / imageWidth;
          final double scaleY = Get.height / imageHeight;

          final double left = bbox[0] * scaleX;
          final double top = bbox[1] * scaleY;
          final double right = bbox[2] * scaleX;
          final double bottom = bbox[3] * scaleY;

          return Positioned(
            left: 100,
            top: 10,
            width: 150,
            height: 100,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: color, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$label ${(score * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  backgroundColor: color,
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}