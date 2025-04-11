import 'package:flutter/material.dart';

import 'dart:async';
import 'dart:isolate';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:seeable/views/object_detection/real_time_components/detect_painter.dart';
import 'package:seeable/views/object_detection/real_time_components/inference_utils.dart';
import 'package:seeable/views/object_detection/real_time_components/isolate_data.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class CameraDetectionPage extends StatefulWidget {
  const CameraDetectionPage({super.key});

  @override
  State<CameraDetectionPage> createState() => _CameraDetectionPageState();
}

class _CameraDetectionPageState extends State<CameraDetectionPage>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;

  bool _isDetecting = false;
  bool _isModelLoaded = false;
  bool _isIsolateRunning = false;
  bool _isDetectionActive =
      false; // State variable to track if detection is active
  late Interpreter _interpreter;
  late List<String> _labels;
  List<DetectionResult> _recognitions = [];

  // Detection parameters
  final int inputSize = 640;
  final double confidenceThreshold = 0.2;
  final double iouThreshold = 0.45;

  // Processing frame rate control
  DateTime? _lastProcessingTime;
  final int _processingDelayMs = 300; // Decreased for more responsive detection

  // Isolate for background processing
  Isolate? _isolate;
  ReceivePort? _receivePort;
  SendPort? _sendPort;

  // Memory management
  int _frameSkipCount = 0;
  final int _frameSkipTarget = 2; // Reduced for more frequent detection

  // Cached values for UI optimization
  Size? _cachedPreviewSize;

  @override
  void initState() {
    super.initState();
    // Ensure Flutter binding is initialized
    WidgetsBinding.instance.addObserver(this);

    // Initialize in order: camera -> model -> isolate
    _initializeCamera().then((_) {
      _loadModel().then((_) {
        _startBackgroundIsolate();
      });
    });
  }

  Future<void> _startBackgroundIsolate() async {
    print("Starting background isolate...");
    _receivePort = ReceivePort();

    try {
      _isolate = await Isolate.spawn<SendPort>(
        InferenceUtils.isolateEntryPoint,
        _receivePort!.sendPort,
      );

      _receivePort!.listen((message) {
        if (message is SendPort) {
          print("Received send port from isolate");
          _sendPort = message;
          _isIsolateRunning = true;
        } else if (message is List<DetectionResult>) {
          print("Received ${message.length} detections from isolate");
          // Update UI with detection results
          if (mounted) {
            setState(() {
              _recognitions = message;
              _isDetecting = false;
            });
          } else {
            _isDetecting = false;
          }
        } else {
          print("Received unknown message from isolate: $message");
          _isDetecting = false;
        }
      });
    } catch (e) {
      print("Error starting isolate: $e");
      // Try to recover by setting isDetecting to false
      _isDetecting = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle state changes
    final CameraController? cameraController = _cameraController;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      _stopDetection();
      _stopCamera();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    print("Initializing camera...");
    try {
      _cameras = await availableCameras();
      if (_cameras!.isEmpty) {
        print('No cameras available');
        return;
      }

      // Use the first camera (usually back camera)
      final CameraDescription camera = _cameras!.first;
      print("Using camera: ${camera.name}, ${camera.lensDirection}");

      _cameraController = CameraController(
        camera,
        ResolutionPreset.medium, // Medium for better detection
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _cameraController!.initialize();
      print(
          "Camera initialized with resolution: ${_cameraController!.value.previewSize}");

      // Cache preview size for optimized rendering
      _cachedPreviewSize = _cameraController!.value.previewSize;

      // Start image stream with a reduced processing rate
      await _cameraController!.startImageStream(_processCameraImage);
      print("Camera stream started");

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  Future<void> _stopCamera() async {
    if (_cameraController != null) {
      try {
        if (_cameraController!.value.isStreamingImages) {
          await _cameraController!.stopImageStream();
        }
      } catch (e) {
        print('Error stopping camera stream: $e');
      }
    }
  }

  Future<void> _loadModel() async {
    print("Loading TFLite model...");
    try {
      // Load model with optimized options
      final interpreterOptions = InterpreterOptions()
        ..threads = 4; // Use multi-threading

      _interpreter = await Interpreter.fromAsset(
        'assets/yolov8_small/yolov8n.tflite',
        options: interpreterOptions,
      );

      // Debug info
      print('Model loaded successfully');
      print('Input Shape: ${_interpreter.getInputTensor(0).shape}');
      print('Output Shape: ${_interpreter.getOutputTensor(0).shape}');

      // Load labels
      final labelsData =
          await rootBundle.loadString('assets/yolov8_small/yolov8n.txt');
      _labels = labelsData.split('\n').where((s) => s.isNotEmpty).toList();
      print('Labels loaded: ${_labels.length} classes');

      setState(() {
        _isModelLoaded = true;
      });
      print('Model loading complete');
    } catch (e) {
      print('Error loading model: $e');
      // Add more detailed error information
      if (e is Exception) {
        print('Exception details: ${e.toString()}');
      }
    }
  }

  void _processCameraImage(CameraImage cameraImage) {
    // Skip processing if detection is not active
    if (!_isDetectionActive) {
      return;
    }

    // Debug log
    if (_frameSkipCount == 0) {
      print(
          'Processing camera frame: ${cameraImage.width}x${cameraImage.height}');
    }

    // Skip processing if not ready
    if (_isDetecting ||
        !_isModelLoaded ||
        !_isIsolateRunning ||
        _sendPort == null) {
      if (_frameSkipCount == 0) {
        print(
            'Skipping frame. isDetecting: $_isDetecting, isModelLoaded: $_isModelLoaded, isIsolateRunning: $_isIsolateRunning, sendPort: ${_sendPort != null}');
      }
      _frameSkipCount++;
      if (_frameSkipCount >= 30) {
        // Reset counter after some time to prevent getting stuck
        _frameSkipCount = 0;
        _isDetecting = false; // Reset detecting flag if it might be stuck
      }
      return;
    }

    // Frame skipping for performance
    _frameSkipCount++;
    if (_frameSkipCount < _frameSkipTarget) {
      return;
    }
    _frameSkipCount = 0;

    // Check time since last processing
    final now = DateTime.now();
    if (_lastProcessingTime != null &&
        now.difference(_lastProcessingTime!).inMilliseconds <
            _processingDelayMs) {
      return;
    }
    _lastProcessingTime = now;

    // Set detecting flag
    setState(() {
      _isDetecting = true;
    });

    try {
      print('Sending frame to isolate for processing');
      // Send data to isolate for processing
      _sendPort!.send(IsolateData(
        cameraImage: cameraImage,
        responsePort: _receivePort!.sendPort,
        interpreterInputShape: _interpreter.getInputTensor(0).shape,
        interpreterOutputShape: _interpreter.getOutputTensor(0).shape,
        inputSize: inputSize,
        labels: _labels,
        confidenceThreshold: confidenceThreshold,
        iouThreshold: iouThreshold,
      ));
    } catch (e) {
      print('Error sending data to isolate: $e');
      setState(() {
        _isDetecting = false;
      });
    }
  }

  // Start detection
  void _startDetection() {
    if (!_isModelLoaded || !_isIsolateRunning) {
      return;
    }

    setState(() {
      _isDetectionActive = true;
      _recognitions = []; // Clear previous recognitions
      _lastProcessingTime = null; // Reset processing time to start immediately
      _frameSkipCount = 0;
    });

    print("Object detection started");
  }

  // Stop detection
  void _stopDetection() {
    setState(() {
      _isDetectionActive = false;
    });
    print("Object detection stopped");
  }

  // Toggle detection on/off
  void _toggleDetection() {
    if (_isDetectionActive) {
      _stopDetection();
    } else {
      _startDetection();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return Scaffold(
        appBar: AppBar(title: const Text('Camera Object Detection')),
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Initializing camera and model...'),
            ],
          ),
        ),
      );
    }

    // Get screen size once to avoid repeated calculations
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera Object Detection'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ClipRect(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Camera preview
                    CameraPreview(_cameraController!),

                    // Draw bounding boxes
                    RepaintBoundary(
                      child: CustomPaint(
                        painter: DetectionPainter(
                          detections: _recognitions,
                          previewSize: _cachedPreviewSize ??
                              _cameraController!.value.previewSize!,
                          screenSize: screenSize,
                        ),
                      ),
                    ),

                    // Debug overlay
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        color: Colors.black.withOpacity(0.5),
                        child: Text(
                          'Model: ${_isModelLoaded ? "Loaded" : "Not loaded"}\n'
                          'Isolate: ${_isIsolateRunning ? "Running" : "Not running"}\n'
                          'Detecting: $_isDetecting\n'
                          'Detection Active: $_isDetectionActive\n'
                          'Detections: ${_recognitions.length}',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 10),
                        ),
                      ),
                    ),

                    // Start Detection Button overlay
                    if (!_isDetectionActive)
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Camera Ready',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: _isModelLoaded && _isIsolateRunning
                                    ? _startDetection
                                    : null,
                                icon: const Icon(Icons.play_arrow),
                                label: const Text('Start Detection'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                              if (!_isModelLoaded || !_isIsolateRunning)
                                const Padding(
                                  padding: EdgeInsets.only(top: 8),
                                  child: Text(
                                    'Waiting for model to load...',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Detection results
            if (_recognitions.isNotEmpty)
              _buildDetectionList()
            else
              Container(
                padding: const EdgeInsets.all(8),
                height: 40,
                color: Colors.black54,
                alignment: Alignment.center,
                child: Text(
                  _isDetectionActive
                      ? 'No objects detected - Try pointing at common objects'
                      : 'Press Start Detection to begin',
                  style: const TextStyle(color: Colors.white70),
                ),
              ),

            // Controls
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.black87,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(
                    'Found: ${_recognitions.length}',
                    style: const TextStyle(color: Colors.white),
                  ),
                  // Stop/Start detection button
                  ElevatedButton.icon(
                    onPressed: _isModelLoaded && _isIsolateRunning
                        ? _toggleDetection
                        : null,
                    icon: Icon(
                      _isDetectionActive ? Icons.stop : Icons.play_arrow,
                      color: _isDetectionActive ? Colors.red : Colors.green,
                    ),
                    label: Text(
                      _isDetectionActive ? 'Stop' : 'Start',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isDetectionActive
                          ? Colors.red.withOpacity(0.2)
                          : Colors.green.withOpacity(0.2),
                    ),
                  ),
                  IconButton(
                    icon:
                        const Icon(Icons.flip_camera_ios, color: Colors.white),
                    onPressed: _switchCamera,
                  ),
                  // Add reload model button
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    onPressed: _reloadModel,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Function to reload model and isolate
  Future<void> _reloadModel() async {
    // Stop detection first
    _stopDetection();

    // Clean up existing resources
    if (_isModelLoaded) {
      _interpreter.close();
    }

    _receivePort?.close();
    _isolate?.kill(priority: Isolate.immediate);

    setState(() {
      _isModelLoaded = false;
      _isIsolateRunning = false;
      _isDetectionActive = false;
      _recognitions = [];
    });

    // Reload
    await _loadModel();
    await _startBackgroundIsolate();
  }

  Widget _buildDetectionList() {
    return Container(
      padding: const EdgeInsets.all(8),
      height: 100, // Reduced height
      color: Colors.black54,
      child: ListView.builder(
        scrollDirection: Axis.horizontal, // Horizontal scrolling for better UX
        itemCount: _recognitions.length,
        itemBuilder: (context, index) {
          final detection = _recognitions[index];
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.all(8),
            width: 120,
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors
                    .primaries[detection.classId % Colors.primaries.length],
                width: 2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  detection.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${(detection.confidence * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                // Add bbox info for debugging
                Text(
                  'Box: ${detection.bbox.map((v) => v.toStringAsFixed(0)).join(",")}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 8,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) {
      // No secondary camera available
      return;
    }

    // First stop detection
    _stopDetection();

    // Stop current stream
    await _stopCamera();

    // Get current camera index
    final int currentCameraIndex =
        _cameras!.indexOf(_cameraController!.description);
    final int newCameraIndex = (currentCameraIndex + 1) % _cameras!.length;

    // Dispose current controller
    await _cameraController!.dispose();

    // Initialize new camera
    _cameraController = CameraController(
      _cameras![newCameraIndex],
      ResolutionPreset.medium, // Medium for better detection
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    await _cameraController!.initialize();

    // Update cached preview size
    _cachedPreviewSize = _cameraController!.value.previewSize;

    await _cameraController!.startImageStream(_processCameraImage);

    if (mounted) {
      setState(() {
        _recognitions = []; // Clear recognitions when switching camera
      });
    }
  }

  @override
  void dispose() {
    print("Disposing resources");
    // Clean up resources
    WidgetsBinding.instance.removeObserver(this);
    _stopCamera();
    _cameraController?.dispose();

    // Close interpreter
    if (_isModelLoaded) {
      _interpreter.close();
    }

    // Terminate isolate
    _receivePort?.close();
    _isolate?.kill(priority: Isolate.immediate);

    super.dispose();
  }
}
