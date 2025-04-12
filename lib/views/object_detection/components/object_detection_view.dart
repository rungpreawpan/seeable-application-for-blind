// // // Overlay layer for bounding boxes
// // CustomPaint(
// //   painter: CustomBoxPainter(
// //     recognitions: recognitions,
// //     confidence: confidence,
// //     imageHeight: imageHeight,
// //     imageWidth: imageWidth,
// //   ),
// //   // painter: DirectBoxPainter(
// //   //   recognitions: recognitions,
// //   // ),
// // ),
//
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
//
// class ObjectDetectionView extends StatelessWidget {
//   final File imageFile;
//   final int imageHeight;
//   final int imageWidth;
//   final List<Map<String, dynamic>> recognitions;
//   final double confidence;
//
//   const ObjectDetectionView({
//     super.key,
//     required this.imageFile,
//     required this.imageHeight,
//     required this.imageWidth,
//     required this.recognitions,
//     this.confidence = 0.5,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Stack(
//       children: [
//         // Image layer
//         Image.file(
//           imageFile,
//           fit: BoxFit.contain,
//         ),
//
//         ...recognitions.map((recognition) {
//           final List<int> bbox = List<int>.from(recognition['bbox']);
//           final String label = recognition['label'] as String;
//           final double score = recognition['confidence'] as double;
//           final int classId = recognition['class'] as int;
//
//           final color = Colors.primaries[classId % Colors.primaries.length];
//
//           final double scaleX = Get.width / imageWidth;
//           final double scaleY = Get.height / imageHeight;
//
//           final int bboxLeft = bbox[0];
//           final int bboxTop = bbox[1];
//           final int bboxRight = bbox[2];
//           final int bboxLeftBottom = bbox[3];
//
//           print('imageWidth: $imageWidth, imageHeight: $imageHeight');
//           print('scaleX: $scaleX, scaleY: $scaleY');
//           print('left: $bboxLeft, right: $bboxRight');
//           print('top: $bboxTop, bottom: $bboxLeftBottom');
//
//           final double left = (bbox[0] * scaleX);
//           final double top = (bbox[1] * scaleY);
//           final double right = (bbox[2] * scaleX);
//           final double bottom = (bbox[3] * scaleY);
//
//           print('left: $left, right: $right');
//           print('top: $top, bottom: $bottom');
//
//           return Positioned(
//             left: 0,
//             right: 0,
//             bottom: 0,
//             top: 0,
//             child: Container(
//               decoration: BoxDecoration(
//                 border: Border.all(color: color, width: 2),
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Text(
//                 '$label ${(score * 100).toStringAsFixed(1)}%',
//                 style: TextStyle(
//                   fontSize: 12,
//                   color: Colors.white,
//                   backgroundColor: color,
//                 ),
//               ),
//             ),
//           );
//         }),
//       ],
//     );
//   }
// }

import 'dart:io';
import 'package:flutter/material.dart';

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
    return Expanded(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double availableWidth = constraints.maxWidth;
          final double availableHeight = constraints.maxHeight;

          // Calculate the image size to fit in the available space
          double displayWidth;
          double displayHeight;
          double leftPadding = 0;
          double topPadding = 0;

          // Calculate the aspect ratio of the image
          final double imageRatio = imageWidth / imageHeight;
          final double screenRatio = availableWidth / availableHeight;

          if (imageRatio > screenRatio) {
            // Image is wider than screen area, fit to width
            displayWidth = availableWidth;
            displayHeight = availableWidth / imageRatio;
            topPadding = (availableHeight - displayHeight) / 2;
          } else {
            // Image is taller than screen area, fit to height
            displayHeight = availableHeight;
            displayWidth = availableHeight * imageRatio;
            leftPadding = (availableWidth - displayWidth) / 2;
          }

          // Debug info
          print('Image dimensions: $imageWidth x $imageHeight');
          print('Display dimensions: $displayWidth x $displayHeight');
          print('Scaling factors: X=${displayWidth/imageWidth}, Y=${displayHeight/imageHeight}');

          // Calculate scaling factors
          final double scaleX = displayWidth / imageWidth;
          final double scaleY = displayHeight / imageHeight;

          return Stack(
            children: [
              // Container for visualization
              Container(
                width: availableWidth,
                height: availableHeight,
                color: Colors.black12,
              ),

              // Image layer
              Positioned(
                left: leftPadding,
                top: topPadding,
                width: displayWidth,
                height: displayHeight,
                child: Image.file(
                  imageFile,
                  fit: BoxFit.fill,
                ),
              ),

              // Bounding boxes
              ...recognitions.map((recognition) {
                final List<int> bbox = List<int>.from(recognition['bbox']);
                final String label = recognition['label'] as String;
                final double score = recognition['confidence'] as double;
                final int classId = recognition['class'] as int;

                final color = Colors.primaries[classId % Colors.primaries.length];

                // Get coordinates from the bbox
                final int xMin = bbox[0];
                final int yMin = bbox[1];
                final int xMax = bbox[2];
                final int yMax = bbox[3];

                // Scale to display coordinates and add padding offset
                final double scaledXMin = (xMin * scaleX) + leftPadding;
                final double scaledYMin = (yMin * scaleY) + topPadding;
                final double scaledWidth = (xMax - xMin) * scaleX;
                final double scaledHeight = (yMax - yMin) * scaleY;

                // Debug
                print('Bound Box Original: [$xMin, $yMin, $xMax, $yMax]');
                print('Bound Box Scaled: [$scaledXMin, $scaledYMin, ${scaledXMin+scaledWidth}, ${scaledYMin+scaledHeight}]');

                return Positioned(
                  left: scaledXMin,
                  top: scaledYMin,
                  width: scaledWidth,
                  height: scaledHeight,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: color, width: 2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Container(
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(4),
                              bottomRight: Radius.circular(4)
                          ),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Text(
                          '$label ${(score * 100).toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ],
          );
        },
      ),
    );
  }
}