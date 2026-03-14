class VoiceCommandModel {
  final String key;
  final List<String> thTriggers;
  final List<String> enTriggers;
  final String thLabel;
  final String enLabel;

  const VoiceCommandModel({
    required this.key,
    required this.thTriggers,
    required this.enTriggers,
    required this.thLabel,
    required this.enLabel,
  });
}

const List<VoiceCommandModel> voiceCommands = [
  VoiceCommandModel(
    key: 'navigation',
    thTriggers: ['ระบบนำทาง', 'นำทาง'],
    enTriggers: ['navigation', 'navigate'],
    thLabel: 'ระบบนำทาง',
    enLabel: 'Navigation',
  ),
  VoiceCommandModel(
    key: 'object_detection',
    thTriggers: ['ตรวจจับวัตถุ', 'ตรวจวัตถุ', 'ตรวจจับ'],
    enTriggers: ['object detection', 'detect object', 'detect'],
    thLabel: 'ตรวจจับวัตถุ',
    enLabel: 'Object Detection',
  ),
  VoiceCommandModel(
    key: 'scan_text',
    thTriggers: ['สแกนตัวหนังสือ', 'สแกนข้อความ', 'สแกน'],
    enTriggers: ['scan text', 'scan'],
    thLabel: 'สแกนตัวหนังสือ',
    enLabel: 'Scan Text',
  ),
  VoiceCommandModel(
    key: 'settings',
    thTriggers: ['ตั้งค่า'],
    enTriggers: ['settings', 'setting'],
    thLabel: 'ตั้งค่า',
    enLabel: 'Settings',
  ),
  VoiceCommandModel(
    key: 'home',
    thTriggers: ['หน้าหลัก', 'กลับหน้าหลัก'],
    enTriggers: ['home', 'go home', 'main page'],
    thLabel: 'หน้าหลัก',
    enLabel: 'Home',
  ),
  VoiceCommandModel(
    key: 'back',
    thTriggers: ['ย้อนกลับ', 'กลับ'],
    enTriggers: ['back', 'go back'],
    thLabel: 'ย้อนกลับ',
    enLabel: 'Back',
  ),
  VoiceCommandModel(
    key: 'switch_camera',
    thTriggers: ['สลับกล้อง', 'เปลี่ยนกล้อง'],
    enTriggers: ['switch camera', 'flip camera', 'change camera'],
    thLabel: 'สลับกล้อง',
    enLabel: 'Switch Camera',
  ),
  VoiceCommandModel(
    key: 'open_gallery',
    thTriggers: ['เปิดแกลเลอรี่', 'แกลเลอรี่', 'เปิดคลัง'],
    enTriggers: ['open gallery', 'gallery'],
    thLabel: 'เปิดแกลเลอรี่',
    enLabel: 'Open Gallery',
  ),
  VoiceCommandModel(
    key: 'toggle_detection',
    thTriggers: ['เริ่มตรวจจับ', 'หยุดตรวจจับ', 'ตรวจจับ'],
    enTriggers: ['start detection', 'stop detection', 'toggle detection'],
    thLabel: 'เริ่ม/หยุดตรวจจับวัตถุ',
    enLabel: 'Start/Stop Detection',
  ),
  VoiceCommandModel(
    key: 'capture_scan_text',
    thTriggers: ['เริ่มสแกน', 'สแกนภาพ', 'ถ่ายรูป'],
    enTriggers: ['start scan', 'capture', 'take photo'],
    thLabel: 'เริ่มสแกนตัวหนังสือ',
    enLabel: 'Capture Scan Text',
  ),
  VoiceCommandModel(
    key: 'select_location',
    thTriggers: ['เลือกตำแหน่งของคุณ', 'เลือกตำแหน่ง', 'ตำแหน่งของฉัน'],
    enTriggers: ['select location', 'my location', 'choose location'],
    thLabel: 'เลือกตำแหน่งของคุณ',
    enLabel: 'Select Location',
  ),
  VoiceCommandModel(
    key: 'select_destination',
    thTriggers: ['เลือกเป้าหมาย', 'เลือกปลายทาง', 'ไปที่'],
    enTriggers: ['select destination', 'choose destination', 'go to'],
    thLabel: 'เลือกเป้าหมาย',
    enLabel: 'Select Destination',
  ),
  VoiceCommandModel(
    key: 'scan_marker',
    thTriggers: ['สแกนมาร์กเกอร์', 'สแกนตำแหน่ง'],
    enTriggers: ['scan marker', 'scan position'],
    thLabel: 'สแกนมาร์กเกอร์',
    enLabel: 'Scan Marker',
  ),
  VoiceCommandModel(
    key: 'swap_location',
    thTriggers: ['สลับตำแหน่ง', 'สลับต้นทางปลายทาง'],
    enTriggers: ['swap location', 'swap', 'reverse route'],
    thLabel: 'สลับตำแหน่ง',
    enLabel: 'Swap Location',
  ),
  VoiceCommandModel(
    key: 'start_navigation',
    thTriggers: ['เริ่มนำทาง', 'เดินทาง'],
    enTriggers: ['start navigation', 'begin navigation', 'navigate now'],
    thLabel: 'เริ่มนำทาง',
    enLabel: 'Start Navigation',
  ),
];
