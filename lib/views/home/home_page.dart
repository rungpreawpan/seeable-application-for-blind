import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seeable/controller/voice_command_controller.dart';
import 'package:seeable/views/navigation/selected_place_page.dart';
import 'package:seeable/views/object_detection/object_detect_page.dart';
import 'package:seeable/views/scan_text/scan_text_page.dart';
import 'package:seeable/views/home/widgets/voice_commands_list_sheet.dart';
import 'package:seeable/views/settings/controller/settings_controller.dart';
import 'package:seeable/widgets/listview_button.dart';
import 'package:seeable/widgets/navigation_main_template.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with RouteAware {
  final SettingsController _settingsController = Get.find();
  final VoiceCommandController _voiceController = Get.find();

  List get featuresList => [
        {'title': 'navigation'.tr, 'icon_path': 'assets/icons/navigation_icon.svg'},
        {
          'title': 'object detection'.tr,
          'icon_path': 'assets/icons/object_detect_icon.svg'
        },
        {'title': 'scan text'.tr, 'icon_path': 'assets/icons/scan_text_icon.svg'},
      ];

  @override
  void didPopNext() {
    // Resumed after popping a sub-page — restart wake word listening
    _voiceController.resumeListening();
  }

  void _showVoiceCommandsSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const VoiceCommandsListSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final features = featuresList;

    return NavigationMainTemplate(
      appBarTitle: '',
      actions: [
        Obx(() {
          final isEnabled = _settingsController.useSpeechRecognition.value;
          if (!isEnabled) return const SizedBox.shrink();
          return IconButton(
            tooltip: 'voice command list'.tr,
            icon: Obx(() {
              final mode = _voiceController.mode.value;
              final color = mode == VoiceMode.command
                  ? Colors.green
                  : mode == VoiceMode.wakeWord
                      ? Colors.orange
                      : Colors.grey;
              return Icon(Icons.mic, color: color);
            }),
            onPressed: _showVoiceCommandsSheet,
          );
        }),
      ],
      items: features,
      itemWidget: (context, index) {
        var item = features[index];

        return ListViewButton(
          onTap: () async {
            if (item['title'] == 'navigation'.tr) {
              Get.to(() => const SelectedPlacePage());
            } else if (item['title'] == 'object detection'.tr) {
              Get.to(() => const ObjectDetectPage());
            } else if (item['title'] == 'scan text'.tr) {
              Get.to(() => const ScanTextPage());
            } else {
              Get.offAll(() => const HomePage());
            }
          },
          iconPath: item['icon_path'],
          title: item['title'],
          showArrow: false,
        );
      },
    );
  }
}
