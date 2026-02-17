import 'dart:io';

import 'package:android_id/android_id.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppInfoController extends GetxController {
  var appVersion = ''.obs;
  var model = ''.obs;
  var os = ''.obs;

  var cameraGranted = false.obs;
  var micGranted = false.obs;
  var speechToTextGranted = false.obs;
  var accessibilityGranted = false.obs;
  var locationGranted = false.obs;
  var bluetooth = false.obs;

  FlutterSecureStorage storage = const FlutterSecureStorage();

  getDeviceInfo() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String version = packageInfo.version;
    String buildNumber = packageInfo.buildNumber;
    appVersion('$version ($buildNumber)');

    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      String osVersion =
          'Android ${androidInfo.version.release} (SDK ${androidInfo.version.sdkInt})';

      const androidIdPlugin = AndroidId();
      final String? androidId = await androidIdPlugin.getId();

      model(androidInfo.model);
      os(osVersion);
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;

      model(iosInfo.modelName);
      os('${iosInfo.systemName} ${iosInfo.systemVersion}');
    }
  }
}
