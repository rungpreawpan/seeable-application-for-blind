package com.example.seeable

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Matrix
import android.util.Log
import androidx.exifinterface.media.ExifInterface
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.opencv.android.OpenCVLoader
import org.opencv.android.Utils
import org.opencv.core.CvType
import org.opencv.core.Mat
import org.opencv.imgproc.Imgproc
import org.opencv.objdetect.ArucoDetector
import org.opencv.objdetect.DetectorParameters
import org.opencv.objdetect.Objdetect

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.aruco_scanner/detector"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        OpenCVLoader.initLocal()

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "detectAruco") {
                    val dictName = call.argument<String>("dictionary") ?: "DICT_4X4_50"
                    val imagePath = call.argument<String>("imagePath")

                    if (imagePath != null) {
                        // ImagePicker path
                        val markerId = detectArucoFromPath(imagePath, dictName)
                        result.success(markerId)
                    } else {
                        // CameraImage raw bytes
                        val bytes = call.argument<ByteArray>("bytes")
                        val width = call.argument<Int>("width")
                        val height = call.argument<Int>("height")

                        if (bytes == null || width == null || height == null) {
                            result.error("INVALID_ARGS", "Missing required arguments", null)
                            return@setMethodCallHandler
                        }

                        val markerId = detectAruco(bytes, width, height, dictName)
                        result.success(markerId)
                    }
                } else {
                    result.notImplemented()
                }
            }
    }

    private fun detectArucoFromPath(imagePath: String, dictName: String): Int? {
        val ids = Mat()
        val corners = ArrayList<Mat>()
        var grayMat: Mat? = null

        return try {
            val raw = BitmapFactory.decodeFile(imagePath)
            if (raw == null) {
                Log.e("ArucoDetector", "Failed to decode image: $imagePath")
                return null
            }
            val bitmap = correctBitmapRotation(imagePath, raw)

            val rgbaMat = Mat()
            Utils.bitmapToMat(bitmap, rgbaMat)
            grayMat = Mat()
            Imgproc.cvtColor(rgbaMat, grayMat, Imgproc.COLOR_RGBA2GRAY)
            rgbaMat.release()

            Log.d("ArucoDetector", "Image size: ${bitmap.width}x${bitmap.height}")

            val dictId = when (dictName) {
                "DICT_4X4_50"  -> Objdetect.DICT_4X4_50
                "DICT_4X4_100" -> Objdetect.DICT_4X4_100
                "DICT_4X4_250" -> Objdetect.DICT_4X4_250
                "DICT_5X5_50"  -> Objdetect.DICT_5X5_50
                "DICT_6X6_50"  -> Objdetect.DICT_6X6_50
                else           -> Objdetect.DICT_4X4_50
            }

            val dictionary = Objdetect.getPredefinedDictionary(dictId)
            val parameters = DetectorParameters()
            val detector = ArucoDetector(dictionary, parameters)

            detector.detectMarkers(grayMat, corners, ids)

            Log.d("ArucoDetector", "Detected ${ids.rows()} markers")

            if (ids.rows() > 0) ids.get(0, 0)[0].toInt() else null
        } catch (e: Exception) {
            Log.e("ArucoDetector", "Detection failed: ${e.message}", e)
            null
        } finally {
            grayMat?.release()
            ids.release()
            corners.forEach { it.release() }
        }
    }

    private fun correctBitmapRotation(imagePath: String, bitmap: Bitmap): Bitmap {
        val exif = ExifInterface(imagePath)
        val orientation = exif.getAttributeInt(
            ExifInterface.TAG_ORIENTATION,
            ExifInterface.ORIENTATION_NORMAL
        )
        val rotation = when (orientation) {
            ExifInterface.ORIENTATION_ROTATE_90  -> 90f
            ExifInterface.ORIENTATION_ROTATE_180 -> 180f
            ExifInterface.ORIENTATION_ROTATE_270 -> 270f
            else -> 0f
        }
        if (rotation == 0f) return bitmap
        val matrix = Matrix().apply { postRotate(rotation) }
        return Bitmap.createBitmap(bitmap, 0, 0, bitmap.width, bitmap.height, matrix, true)
    }

    private fun detectAruco(bytes: ByteArray, width: Int, height: Int, dictName: String): Int? {
        var grayMat: Mat? = null
        val ids = Mat()
        val corners = ArrayList<Mat>()

        return try {
            // Use Y plane only (grayscale) — first width*height bytes of YUV420
            grayMat = Mat(height, width, CvType.CV_8UC1)
            grayMat.put(0, 0, bytes, 0, width * height)

            val dictId = when (dictName) {
                "DICT_4X4_50"  -> Objdetect.DICT_4X4_50
                "DICT_4X4_100" -> Objdetect.DICT_4X4_100
                "DICT_4X4_250" -> Objdetect.DICT_4X4_250
                "DICT_5X5_50"  -> Objdetect.DICT_5X5_50
                "DICT_6X6_50"  -> Objdetect.DICT_6X6_50
                else           -> Objdetect.DICT_4X4_50
            }

            val dictionary = Objdetect.getPredefinedDictionary(dictId)
            val parameters = DetectorParameters()
            val detector = ArucoDetector(dictionary, parameters)

            detector.detectMarkers(grayMat, corners, ids)

            if (ids.rows() > 0) ids.get(0, 0)[0].toInt() else null
        } catch (e: Exception) {
            null
        } finally {
            grayMat?.release()
            ids.release()
            corners.forEach { it.release() }
        }
    }
}
