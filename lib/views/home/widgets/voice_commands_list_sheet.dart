import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seeable/constant/value_constant.dart';
import 'package:seeable/controller/voice_command_controller.dart';
import 'package:seeable/service/voice_commands.dart';
import 'package:seeable/views/settings/controller/settings_controller.dart';
import 'package:seeable/widgets/text_font_style.dart';

class VoiceCommandsListSheet extends StatelessWidget {
  const VoiceCommandsListSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsController = Get.find<SettingsController>();
    final voiceController = Get.find<VoiceCommandController>();
    final isThai = settingsController.currentLocale.value.languageCode == 'th';
    final wakeWord = isThai ? '"สิริ"' : '"seeable"';
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(marginX2, marginX2, marginX2, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: marginX2),
          Row(
            children: [
              const Icon(Icons.mic, size: 22),
              const SizedBox(width: margin),
              TextFontStyle(
                'voice command list'.tr,
                style: theme.textTheme.labelMedium,
              ),
              const Spacer(),
              Obx(() {
                final modeValue = voiceController.mode.value;
                final color = modeValue == VoiceMode.wakeWord
                    ? Colors.orange
                    : modeValue == VoiceMode.command
                        ? Colors.green
                        : Colors.grey;
                final label = modeValue == VoiceMode.wakeWord
                    ? (isThai ? 'รอคำปลุก' : 'Waiting')
                    : modeValue == VoiceMode.command
                        ? (isThai ? 'รับฟัง' : 'Listening')
                        : (isThai ? 'ปิด' : 'Off');
                return Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration:
                          BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 4),
                    TextFontStyle(label, size: fontSizeS, color: color),
                  ],
                );
              }),
            ],
          ),
          const SizedBox(height: margin),
          TextFontStyle(
            'wake word hint'.trParams({'wakeWord': wakeWord}),
            size: fontSizeM,
          ),
          const Divider(height: 24),
          ...voiceCommands.map((cmd) {
            final triggers = isThai ? cmd.thTriggers : cmd.enTriggers;
            final label = isThai ? cmd.thLabel : cmd.enLabel;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.keyboard_voice_outlined,
                      size: 20, color: primaryColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFontStyle(
                          label,
                          size: fontSizeL,
                          weight: FontWeight.bold,
                        ),
                        const SizedBox(height: 2),
                        TextFontStyle(
                          triggers.join(' / '),
                          size: fontSizeM,
                          color: Colors.grey.shade600,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
