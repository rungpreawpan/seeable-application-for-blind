class ObstacleModel {
  String? label;
  double? confidence;
  int? x1;
  int? y1;
  int? x2;
  int? y2;
  double? area;
  String? direction;
  double? priority;
  String? message;

  ObstacleModel({
    this.label,
    this.confidence,
    this.x1,
    this.y1,
    this.x2,
    this.y2,
    this.area,
    this.direction,
    this.priority,
    this.message,
  });

  factory ObstacleModel.fromJSON(Map<String, dynamic> json) {
    return ObstacleModel(
      label: json['label'],
      confidence: json['confidence'],
      x1: json['x1'],
      y1: json['y1'],
      x2: json['x2'],
      y2: json['y2'],
      area: json['area'],
      direction: json['direction'],
      priority: json['priority'],
      message: json['message'],
    );
  }
}
