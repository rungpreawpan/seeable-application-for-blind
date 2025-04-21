import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seeable/views/navigation/ble_with_server/controller/navigation_controller.dart';
import 'package:seeable/views/navigation/ble_with_server/location/navigation_page.dart';
import 'package:seeable/views/navigation/ble_with_server/model/place_model.dart';
import 'package:seeable/widgets/custom_loading.dart';
import 'package:seeable/widgets/listview_button.dart';
import 'package:seeable/widgets/navigation_main_template.dart';

class LocationListPage extends StatefulWidget {
  const LocationListPage({super.key});

  @override
  State<LocationListPage> createState() => _LocationListPageState();
}

class _LocationListPageState extends State<LocationListPage> {
  final NavigationController _navigationController =
      Get.put(NavigationController());

  @override
  void initState() {
    super.initState();

    _prepareDate();
  }

  _prepareDate() async {
    _navigationController.isLoading.value = true;
    await _navigationController.getAllPlaces();
    _navigationController.isLoading.value = false;

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        NavigationMainTemplate(
          appBarTitle: 'location'.tr,
          items: _navigationController.placeList,
          itemWidget: (context, index) {
            PlaceModel? item = _navigationController.placeList[index];

            return ListViewButton(
              onTap: () {
                Get.to(
                  () => NavigationPage(appBarTitle: item.name ?? '-'),
                );
              },
              iconPath: '',
              title: item.name ?? '-',
            );
          },
        ),
        _loading(),
      ],
    );
  }

  _loading() {
    return Obx(() {
      return Visibility(
        visible: _navigationController.isLoading.value,
        child: const CustomLoading(),
      );
    });
  }
}
