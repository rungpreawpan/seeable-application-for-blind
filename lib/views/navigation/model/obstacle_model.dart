class ObstacleModel {
  List<ObstacleBoxesModel>? boxes;
  int? imageWidth;
  int? imageHeight;

  ObstacleModel({
    this.boxes,
    this.imageWidth,
    this.imageHeight,
  });

  factory ObstacleModel.fromJSON(Map<String, dynamic> json) {
    return ObstacleModel(
      boxes: List.from(json['boxes'])
          .map((e) => ObstacleBoxesModel.fromJSON(e))
          .toList(),
      imageWidth: int.parse(json['image_width'].toString()),
      imageHeight: int.parse(json['image_height'].toString()),
    );
  }
}

class ObstacleBoxesModel {
  String? label;
  double? confidence;
  int? x1;
  int? y1;
  int? x2;
  int? y2;
  String? direction;
  double? priority;
  String? message;

  ObstacleBoxesModel({
    this.label,
    this.confidence,
    this.x1,
    this.y1,
    this.x2,
    this.y2,
    this.direction,
    this.priority,
    this.message,
  });

  factory ObstacleBoxesModel.fromJSON(Map<String, dynamic> json) {
    return ObstacleBoxesModel(
      label: json['label'],
      confidence: json['confidence'],
      x1: json['x1'],
      y1: json['y1'],
      x2: json['x2'],
      y2: json['y2'],
      direction: json['direction'],
      priority: json['priority'],
      message: json['message'],
    );
  }
}
