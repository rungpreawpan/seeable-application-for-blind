class OcrModel {
  String? text;
  String? language;
  DateTime? timestamp;

  OcrModel({
    this.text,
    this.language,
    this.timestamp,
  });

  factory OcrModel.fromJSON(Map<String, dynamic> json) {
    DateTime? timestamp;

    if (json['timestamp'] != null) {
      timestamp = DateTime.parse(json['timestamp'].toString());
    }

    return OcrModel(
      text: json['text'],
      language: json['lang'],
      timestamp: timestamp,
    );
  }
}
