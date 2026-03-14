import 'package:get/get.dart';

/// Holds page-specific voice action callbacks.
/// Each page registers its actions in initState and clears them in dispose.
class VoiceActionController extends GetxController {
  void Function()? onSwitchCamera;
  void Function()? onOpenGallery;
  void Function()? onToggleDetection;   // ObjectDetectPage: start/stop
  void Function()? onCaptureScanText;   // ScanTextPage: take photo
  void Function()? onSelectLocation;    // SelectedPlacePage: pick start marker
  void Function()? onSelectDestination; // SelectedPlacePage: pick destination
  void Function()? onScanMarker;        // SelectedPlacePage: scan AR marker
  void Function()? onSwapLocation;      // SelectedPlacePage: swap markers
  void Function()? onStartNavigation;   // SelectedPlacePage: begin navigation

  void clear() {
    onSwitchCamera = null;
    onOpenGallery = null;
    onToggleDetection = null;
    onCaptureScanText = null;
    onSelectLocation = null;
    onSelectDestination = null;
    onScanMarker = null;
    onSwapLocation = null;
    onStartNavigation = null;
  }
}
