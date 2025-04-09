import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seeable/views/navigation/category_page.dart';
import 'package:seeable/views/navigation/controller/ble_controller.dart';
import 'package:seeable/views/navigation/level_page.dart';
import 'package:seeable/views/navigation/place_list_page.dart';
import 'package:seeable/widgets/listview_button.dart';
import 'package:seeable/widgets/navigation_main_template.dart';

class SelectCategoryPage extends StatefulWidget {
  final String appBarTitle;

  const SelectCategoryPage({
    super.key,
    required this.appBarTitle,
  });

  @override
  State<SelectCategoryPage> createState() => _SelectCategoryPageState();
}

class _SelectCategoryPageState extends State<SelectCategoryPage> {
  final BleController _bleController = Get.find();

  @override
  void initState() {
    super.initState();

    // _prepareData();
  }

  // _prepareData() async {
  //   await _bleController.scanDevices();
  // }

  List categoryList = [
    {
      'title': 'near you'.tr,
      'icon_path': 'assets/icons/location_icon.svg',
    },
    {
      'title': 'favorite'.tr,
      'icon_path': 'assets/icons/favorite_icon.svg',
    },
    {
      'title': 'all categories'.tr,
      'icon_path': 'assets/icons/category_icon.svg',
    },
    {
      'title': 'level'.tr,
      'icon_path': 'assets/icons/level_icon.svg',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return NavigationMainTemplate(
      appBarTitle: widget.appBarTitle,
      items: categoryList,
      itemWidget: (context, index) {
        var item = categoryList[index];

        return ListViewButton(
          onTap: () {
            if (item['title'] == 'all categories'.tr) {
              Get.to(() => CategoryPage(appBarTitle: item['title']));
            } else if (item['title'] == 'level'.tr) {
              Get.to(() => LevelPage(appBarTitle: item['title']));
            } else if (item['title'] == 'near you'.tr) {
              Get.to(
                () => PlaceListPage(
                  appBarTitle: item['title'],
                  // deviceList: _bleController.deviceList,
                ),
              );
            } else if (item['title'] == 'favorite'.tr) {
              Get.to(
                () => PlaceListPage(
                  appBarTitle: item['title'],
                  isFavoritePlace: true,
                  favoriteList: _bleController.favoriteList,
                ),
              );
            } else {
              Get.offAll(
                  () => SelectCategoryPage(appBarTitle: widget.appBarTitle));
            }
          },
          iconPath: item['icon_path'],
          title: item['title'],
        );
      },
    );
  }
}
