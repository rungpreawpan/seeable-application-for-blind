import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'ar_detector.dart';
import 'marker_database.dart';

class ArucoScannerPage extends StatefulWidget {
  final List<CameraDescription> cameras;

  const ArucoScannerPage({super.key, required this.cameras});

  @override
  State<ArucoScannerPage> createState() => _ArucoScannerPageState();
}

class _ArucoScannerPageState extends State<ArucoScannerPage>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isDetecting = false;
  bool _isScanning = false;

  int? _detectedMarkerId;
  MarkerInfo? _markerInfo;
  String _statusMessage = 'กดปุ่มสแกนเพื่อเริ่มต้น';

  final ArDetector _detector = ArDetector();
  final MarkerDatabase _database = MarkerDatabase();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    if (widget.cameras.isEmpty) {
      setState(() => _statusMessage = 'ไม่พบกล้อง');
      return;
    }

    final controller = CameraController(
      widget.cameras[0],
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    _cameraController = controller;

    try {
      await controller.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _statusMessage = 'พร้อมสแกน';
        });
      }
    } catch (e) {
      setState(() => _statusMessage = 'เกิดข้อผิดพลาด: $e');
    }
  }

  void _startScanning() {
    if (!_isCameraInitialized || _isScanning) return;

    setState(() {
      _isScanning = true;
      _detectedMarkerId = null;
      _markerInfo = null;
      _statusMessage = 'กำลังสแกน...';
    });

    _cameraController!.startImageStream(_processImage);
  }

  void _stopScanning() {
    _cameraController?.stopImageStream();
    setState(() {
      _isScanning = false;
      if (_detectedMarkerId == null) {
        _statusMessage = 'ไม่พบ Marker กดสแกนใหม่อีกครั้ง';
      }
    });
  }

  Future<void> _processImage(CameraImage image) async {
    if (_isDetecting) return;
    _isDetecting = true;

    try {
      final markerId = await _detector.detectMarker(image);

      if (markerId != null && mounted) {
        final info = _database.getMarkerInfo(markerId);

        await _cameraController?.stopImageStream();

        setState(() {
          _detectedMarkerId = markerId;
          _markerInfo = info;
          _isScanning = false;
          _statusMessage = 'พบ Marker ID: $markerId';
        });

        _showResultBottomSheet(markerId, info);
      }
    } finally {
      _isDetecting = false;
    }
  }

  void _showResultBottomSheet(int id, MarkerInfo? info) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _MarkerResultSheet(
        markerId: id,
        markerInfo: info,
        onScanAgain: () {
          Navigator.pop(context);
          setState(() {
            _detectedMarkerId = null;
            _markerInfo = null;
            _statusMessage = 'พร้อมสแกน';
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Preview
          if (_isCameraInitialized)
            Positioned.fill(
              child: CameraPreview(_cameraController!),
            )
          else
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),

          // Scanning Overlay
          Positioned.fill(
            child: _ScanOverlay(isScanning: _isScanning),
          ),

          // Top Bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.qr_code_scanner,
                            color: Colors.white, size: 18),
                        SizedBox(width: 6),
                        Text(
                          'ArUco Scanner',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Status & Bottom Controls
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Status message
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _isScanning
                            ? const Color(0xFF1A73E8).withOpacity(0.9)
                            : Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_isScanning) ...[
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            _statusMessage,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Scan Button
                    GestureDetector(
                      onTap: _isScanning ? _stopScanning : _startScanning,
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isScanning
                              ? Colors.red.shade400
                              : const Color(0xFF1A73E8),
                          boxShadow: [
                            BoxShadow(
                              color: (_isScanning
                                  ? Colors.red
                                  : const Color(0xFF1A73E8))
                                  .withOpacity(0.5),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(
                          _isScanning ? Icons.stop : Icons.document_scanner,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isScanning ? 'หยุด' : 'สแกน',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Scan Overlay Widget
// ──────────────────────────────────────────────
class _ScanOverlay extends StatefulWidget {
  final bool isScanning;
  const _ScanOverlay({required this.isScanning});

  @override
  State<_ScanOverlay> createState() => _ScanOverlayState();
}

class _ScanOverlayState extends State<_ScanOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _OverlayPainter(
        isScanning: widget.isScanning,
        scanProgress: _animation,
      ),
    );
  }
}

class _OverlayPainter extends CustomPainter {
  final bool isScanning;
  final Animation<double> scanProgress;

  _OverlayPainter({required this.isScanning, required this.scanProgress})
      : super(repaint: scanProgress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 - 40);
    const boxSize = 240.0;
    final rect = Rect.fromCenter(center: center, width: boxSize, height: boxSize);

    // Dim overlay
    final dimPaint = Paint()..color = Colors.black.withOpacity(0.45);
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRect(rect)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, dimPaint);

    // Corner brackets
    final cornerPaint = Paint()
      ..color = isScanning ? const Color(0xFF1A73E8) : Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const cLen = 24.0;
    final corners = [
      [rect.topLeft, const Offset(cLen, 0), const Offset(0, cLen)],
      [rect.topRight, const Offset(-cLen, 0), const Offset(0, cLen)],
      [rect.bottomLeft, const Offset(cLen, 0), const Offset(0, -cLen)],
      [rect.bottomRight, const Offset(-cLen, 0), const Offset(0, -cLen)],
    ];

    for (final c in corners) {
      final origin = c[0] as Offset;
      final h = c[1] as Offset;
      final v = c[2] as Offset;
      canvas.drawLine(origin, origin + h, cornerPaint);
      canvas.drawLine(origin, origin + v, cornerPaint);
    }

    // Scan line
    if (isScanning) {
      final scanY = rect.top + rect.height * scanProgress.value;
      final scanPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.transparent,
            const Color(0xFF1A73E8).withOpacity(0.8),
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTWH(rect.left, scanY - 1, rect.width, 2));
      canvas.drawRect(
          Rect.fromLTWH(rect.left, scanY - 1, rect.width, 2), scanPaint);
    }
  }

  @override
  bool shouldRepaint(_OverlayPainter old) =>
      old.isScanning != isScanning;
}

// ──────────────────────────────────────────────
// Result Bottom Sheet
// ──────────────────────────────────────────────
class _MarkerResultSheet extends StatelessWidget {
  final int markerId;
  final MarkerInfo? markerInfo;
  final VoidCallback onScanAgain;

  const _MarkerResultSheet({
    required this.markerId,
    required this.markerInfo,
    required this.onScanAgain,
  });

  @override
  Widget build(BuildContext context) {
    final info = markerInfo;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A73E8).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.check_circle,
                    color: Color(0xFF1A73E8), size: 24),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'พบ ArUco Marker',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    'ID: $markerId',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white54),
              ),
            ],
          ),
          if (info != null) ...[
            const SizedBox(height: 20),
            const Divider(color: Colors.white12),
            const SizedBox(height: 16),
            _InfoRow(label: 'ชื่อ', value: info.name),
            const SizedBox(height: 8),
            _InfoRow(label: 'หมวดหมู่', value: info.category),
            const SizedBox(height: 8),
            _InfoRow(label: 'รายละเอียด', value: info.description),
            if (info.additionalData.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...info.additionalData.entries.map(
                    (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _InfoRow(label: e.key, value: e.value.toString()),
                ),
              ),
            ],
          ] else ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'ไม่พบข้อมูลใน Database สำหรับ Marker ID นี้',
                      style: TextStyle(color: Colors.orange, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onScanAgain,
              icon: const Icon(Icons.document_scanner),
              label: const Text('สแกนใหม่'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A73E8),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
        ),
      ],
    );
  }
}