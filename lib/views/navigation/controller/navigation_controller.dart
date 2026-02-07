import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response, FormData, MultipartFile;
import 'package:seeable/service/request_service.dart';
import 'package:seeable/utils/alert.dart';
import 'package:seeable/views/navigation/model/ar_markers_model.dart';
import 'package:seeable/views/navigation/model/check_marker_model.dart';
import 'package:seeable/views/navigation/model/navigation_path_model.dart';
import 'package:seeable/views/navigation/model/obstacle_model.dart';
import 'package:seeable/views/navigation/model/update_position_model.dart';
import 'package:seeable/widgets/custom_alert_dialog.dart';

class NavigationController extends GetxController {
  var isLoading = false.obs;
  var isScanning = false.obs;

  bool navigateByScan = false;

  List<ArMarkersModel> markersList = [];
  List<ArMarkersModel> selectedStartMarker = [];
  List<ArMarkersModel> selectedDestinationMarker = [];

  CheckMarkerModel? checkedMarker;

  File? destinationMarkerImage;

  NavigationPathModel? navigationData;
  String? sessionId;

  UpdatePositionModel? positionData;

  List<ObstacleModel> obstacleList = [];

  getAllMarkers() async {
    bool isOnline = await RequestService().checkInternetConnection();

    if (!isOnline) {
      showAlert('no internet connection'.tr);
      isLoading.value = false;

      return;
    }

    try {
      isLoading.value = true;

      var response = await RequestService().request(
        '/ar-markers',
        method: HttpMethod.get,
      );

      if (response != null && response.statusCode == 200) {
        var dataJSON = response.data;
        markersList = dataJSON
            .map<ArMarkersModel>((json) => ArMarkersModel.fromJSON(json))
            .toList();

        print(dataJSON);
      }
    } catch (e) {
      log(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  getAllFrontDoors() async {
    bool isOnline = await RequestService().checkInternetConnection();

    if (!isOnline) {
      showAlert('no internet connection'.tr);
      isLoading.value = false;

      return;
    }

    try {
      isLoading.value = true;

      var response = await RequestService().request(
        '/ar-markers/front',
        method: HttpMethod.get,
      );

      if (response != null && response.statusCode == 200) {
        var dataJSON = response.data;
        markersList = dataJSON
            .map<ArMarkersModel>((json) => ArMarkersModel.fromJSON(json))
            .toList();
      }
    } catch (e) {
      log(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  detectAndNavigate({
    File? markerImage,
    String startMarker = '',
    required String destination,
  }) async {
    bool isOnline = await RequestService().checkInternetConnection();

    if (!isOnline) {
      showAlert('no internet connection'.tr);
      isLoading.value = false;

      return;
    }

    try {
      isLoading.value = true;

      FormData formData = FormData();

      if (markerImage != null) {
        var reqData = {
          "images": MultipartFile.fromFileSync(markerImage.path,
              filename: 'marker_image'),
        };

        formData = FormData.fromMap({
          'images': reqData,
          'destination': destination,
        });
      }

      var response = await RequestService().request(
        '/ar-markers/detect-and-navigate',
        method: HttpMethod.post,
        data: markerImage != null
            ? formData
            : {
                'start_marker': startMarker,
                'destination': destination,
              },
      );

      if (response != null && response.statusCode == 200) {
        Map<String, dynamic> dataMap = response.data;

        navigationData = NavigationPathModel.fromJSON(dataMap);
        sessionId = navigationData?.sessionId;

        print(dataMap);
      }
    } catch (e) {
      log(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  updatePosition({
    File? markerImage,
    String detectMarker = '',
  }) async {
    bool isOnline = await RequestService().checkInternetConnection();

    if (!isOnline) {
      showAlert('no internet connection'.tr);
      isLoading.value = false;

      return;
    }

    try {
      isLoading.value = true;

      FormData formData = FormData();

      if (markerImage != null) {
        var reqData = {
          "images": MultipartFile.fromFileSync(markerImage.path,
              filename: 'marker_image'),
        };

        formData = FormData.fromMap({
          'session_id': sessionId,
          'images': reqData,
        });
      }

      print(detectMarker);
      var response = await RequestService().request(
        '/ar-markers/update-position',
        method: HttpMethod.post,
        data: markerImage != null
            ? formData
            : {
                'session_id': sessionId,
                'detected_marker': detectMarker,
              },
      );

      if (response != null && response.statusCode == 200) {
        Map<String, dynamic> dataMap = response.data;

        print(dataMap);
      }
    } catch (e) {
      log(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  uploadObstacle(File obstacle) async {
    bool isOnline = await RequestService().checkInternetConnection();

    if (!isOnline) {
      showAlert('no internet connection'.tr);
      isLoading.value = false;

      return;
    }

    try {
      isLoading.value = true;

      var reqData = {
        "images": MultipartFile.fromFileSync(obstacle.path,
            filename: 'obstacle_image'),
      };

      FormData formData = FormData.fromMap(reqData);

      var response = await RequestService().request(
        '/upload-obstacle',
        method: HttpMethod.post,
        data: formData,
      );

      if (response != null && response.statusCode == 200) {
        print(response);
        await getObstacle();
      }
    } catch (e) {
      log(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  uploadMarker(File marker) async {
    bool isOnline = await RequestService().checkInternetConnection();

    if (!isOnline) {
      showAlert('no internet connection'.tr);
      isLoading.value = false;

      return;
    }

    try {
      isLoading.value = true;

      var reqData = {
        "images":
            MultipartFile.fromFileSync(marker.path, filename: 'marker_image'),
      };

      FormData formData = FormData.fromMap(reqData);

      var response = await RequestService().request(
        '/ar-markers/check',
        method: HttpMethod.post,
        data: formData,
      );

      if (response != null && response.statusCode == 200) {
        Map<String, dynamic> dataMap = response.data;

        checkedMarker = CheckMarkerModel.fromJSON(dataMap);

        if (checkedMarker?.confidence != null &&
            checkedMarker!.confidence! >= 0.3) {
          for (ArMarkersModel marker in markersList) {
            if (checkedMarker!.markerId == marker.markerId) {
              selectedStartMarker.clear();
              selectedStartMarker.add(marker);

              Get.back(result: selectedStartMarker);
            }
          }
        } else {
          Get.dialog(
            CustomAlertDialog(
              title: 'marker not found'.tr,
              content: 'please scan again'.tr,
            ),
          );
        }
      }
    } catch (e) {
      log(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  getObstacle() async {
    bool isOnline = await RequestService().checkInternetConnection();

    if (!isOnline) {
      showAlert('no internet connection'.tr);
      isLoading.value = false;

      return;
    }

    try {
      isLoading.value = true;

      var response = await RequestService().request(
        '/obstacle-results',
        method: HttpMethod.get,
      );

      if (response != null && response.statusCode == 200) {
        Map<String, dynamic> dataMap = response.data;
        var dataJSON = dataMap['obstacle'];
        log(dataJSON.toString());

        obstacleList = dataJSON
            .map<ObstacleModel>((json) => ObstacleModel.fromJSON(json))
            .toList();
      }
    } catch (e) {
      log(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  clearData() {
    selectedStartMarker.clear();
    selectedDestinationMarker.clear();
    destinationMarkerImage = null;
  }
}
