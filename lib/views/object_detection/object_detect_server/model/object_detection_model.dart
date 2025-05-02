class ObjectDetectionModel {
  List<BoxesModel>? boxes;
  int? imageWidth;
  int? imageHeight;

  ObjectDetectionModel({
    this.boxes,
    this.imageWidth,
    this.imageHeight,
  });

  factory ObjectDetectionModel.fromJSON(Map<String, dynamic> json) {
    return ObjectDetectionModel(
      boxes: List.from(json['boxes'])
          .map((e) => BoxesModel.fromJSON(e))
          .toList(),
      imageWidth: int.parse(json['image_width'].toString()),
      imageHeight: int.parse(json['image_height'].toString()),
    );
  }
}

class BoxesModel {
  String? label;
  double? confidence;
  double? x1;
  double? y1;
  double? x2;
  double? y2;

  BoxesModel({
    this.label,
    this.confidence,
    this.x1,
    this.y1,
    this.x2,
    this.y2,
  });

  factory BoxesModel.fromJSON(Map<String, dynamic> json) {
    return BoxesModel(
      label: json['label'],
      confidence: json['confidence'],
      x1: json['x1'],
      y1: json['y1'],
      x2: json['x2'],
      y2: json['y2'],
    );
  }
}
