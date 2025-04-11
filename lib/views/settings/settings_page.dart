import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seeable/widgets/main_template.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MainTemplate(
      appBarTitle: 'settings'.tr,
      body: Column(
        children: [],
      ),
    );
  }
}
