class SettingsModel {
  bool? useSpeechRecognition;
  String? speed;
  String? language;
  String? theme;

  SettingsModel({
    this.useSpeechRecognition,
    this.speed,
    this.language,
    this.theme,
  });

  factory SettingsModel.fromJSON(Map<String, dynamic> json) {
    return SettingsModel(
      useSpeechRecognition: json['use_speech_recognition'],
      speed: json['speed'],
      language: json['language'],
      theme: json['theme'],
    );
  }
}
