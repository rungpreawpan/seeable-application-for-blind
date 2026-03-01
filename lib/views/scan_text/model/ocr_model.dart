class OcrModel {
  String? text;
  String? language;

  OcrModel({
    this.text,
    this.language,
  });

  factory OcrModel.fromJSON(Map<String, dynamic> json) {
    return OcrModel(
      text: json['text'],
      language: json['lang'],
    );
  }
}
