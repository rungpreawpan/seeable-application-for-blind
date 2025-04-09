import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seeable/views/navigation/controller/ble_controller.dart';
import 'package:seeable/views/navigation/place_list_page.dart';
import 'package:seeable/widgets/listview_button.dart';
import 'package:seeable/widgets/navigation_main_template.dart';

class CategoryPage extends StatefulWidget {
  final String appBarTitle;

  const CategoryPage({
    super.key,
    required this.appBarTitle,
  });

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  final BleController _bleController = Get.find();

  List categoryList = [
    {
      'title': 'class room'.tr,
      'icon_path': 'assets/icons/classroom_icon.svg',
    },
    {
      'title': 'office'.tr,
      'icon_path': 'assets/icons/office_icon.svg',
    },
    {
      'title': 'elevator'.tr,
      'icon_path': 'assets/icons/elevator_icon.svg',
    },
    {
      'title': 'toilet'.tr,
      'icon_path': 'assets/icons/toilet_icon.svg',
    },
    {
      'title': 'exit'.tr,
      'icon_path': 'assets/icons/exit_icon.svg',
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
            //TODO: where deviceList by category
            Get.to(
              () => PlaceListPage(appBarTitle: item['title']),
            );
          },
          iconPath: item['icon_path'],
          title: item['title'],
        );
      },
    );
  }
}
