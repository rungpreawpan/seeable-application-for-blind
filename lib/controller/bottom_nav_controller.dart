import 'package:get/get.dart';

class BottomNavController extends GetxController {
  final currentIndex = 0.obs;

  void goToHome() {
    _popToRoot();
    currentIndex.value = 0;
  }

  void goToSettings() {
    _popToRoot();
    currentIndex.value = 1;
  }

  void _popToRoot() {
    // Pop all pushed routes until back at CustomNavBar
    if (Get.currentRoute != '/') {
      Get.until((route) => route.isFirst);
    }
  }
}
