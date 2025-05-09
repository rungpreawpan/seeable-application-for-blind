import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;

class ImageUtils {
  /// Convert YUV420 image from camera to RGB image
  /// Using downsampling for better performance (reduced resolution)
  static img.Image? convertYUV420ToImage(CameraImage cameraImage, {int scaleFactor = 4}) {
    try {
      // Create a new image with reduced dimensions
      final width = cameraImage.width ~/ scaleFactor;
      final height = cameraImage.height ~/ scaleFactor;

      final image = img.Image(width: width, height: height);

      // Get the planes
      final yPlane = cameraImage.planes[0];
      final uPlane = cameraImage.planes[1];
      final vPlane = cameraImage.planes[2];

      final yPixels = yPlane.bytes;
      final uPixels = uPlane.bytes;
      final vPixels = vPlane.bytes;

      final yRowStride = yPlane.bytesPerRow;
      final uRowStride = uPlane.bytesPerRow;
      final vRowStride = vPlane.bytesPerRow;

      final yPixelStride = yPlane.bytesPerPixel ?? 1;
      final uPixelStride = uPlane.bytesPerPixel ?? 1;
      final vPixelStride = vPlane.bytesPerPixel ?? 1;

      // Fill the image with data (sampling every nth pixel for speed)
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final sourceX = x * scaleFactor;
          final sourceY = y * scaleFactor;

          // Safety checks to prevent index out of bounds
          if (sourceY * yRowStride + sourceX * yPixelStride >= yPixels.length) continue;

          // Get Y value
          final yIndex = sourceY * yRowStride + sourceX * yPixelStride;
          final yValue = yPixels[yIndex];

          // Get U and V values
          final uvX = sourceX ~/ 2;
          final uvY = sourceY ~/ 2;

          // Safety checks to prevent index out of bounds
          if (uvY * uRowStride + uvX * uPixelStride >= uPixels.length ||
              uvY * vRowStride + uvX * vPixelStride >= vPixels.length) continue;

          final uIndex = uvY * uRowStride + uvX * uPixelStride;
          final vIndex = uvY * vRowStride + uvX * vPixelStride;

          final uValue = uPixels[uIndex];
          final vValue = vPixels[vIndex];

          // Simplified YUV to RGB conversion
          int r = (yValue + 1.370705 * (vValue - 128)).round().clamp(0, 255);
          int g = (yValue - 0.337633 * (uValue - 128) - 0.698001 * (vValue - 128)).round().clamp(0, 255);
          int b = (yValue + 1.732446 * (uValue - 128)).round().clamp(0, 255);

          // Set pixel in the image
          image.setPixelRgba(x, y, r, g, b, 255);
        }
      }

      return image;
    } catch (e) {
      print('Error converting YUV to RGB: $e');
      return null;
    }
  }

  /// Prepare input in NCHW format [batch, channels, height, width]
  static List<List<List<List<double>>>> prepareInputNCHW(img.Image image, int inputSize) {
    return List.generate(
      1, // batch size
          (_) => List.generate(
        3, // channels (RGB)
            (c) => List.generate(
          inputSize, // height
              (y) => List.generate(
            inputSize, // width
                (x) {
              final pixel = image.getPixel(x, y);
              if (c == 0) return pixel.r / 255.0;  // Red channel
              if (c == 1) return pixel.g / 255.0;  // Green channel
              return pixel.b / 255.0;              // Blue channel
            },
          ),
        ),
      ),
    );
  }

  /// Prepare input in NHWC format [batch, height, width, channels]
  static List<List<List<List<double>>>> prepareInputNHWC(img.Image image, int inputSize) {
    return List.generate(
      1, // batch size
          (_) => List.generate(
        inputSize, // height
            (y) => List.generate(
          inputSize, // width
              (x) => List.generate(
            3, // channels (RGB)
                (c) {
              final pixel = image.getPixel(x, y);
              if (c == 0) return pixel.r / 255.0;  // Red channel
              if (c == 1) return pixel.g / 255.0;  // Green channel
              return pixel.b / 255.0;              // Blue channel
            },
          ),
        ),
      ),
    );
  }
}