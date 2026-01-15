class ArMarkersModel {
  int? id;
  int? markerId;
  String? markerName;
  double? x;
  double? y;

  ArMarkersModel({
    this.id,
    this.markerId,
    this.markerName,
    this.x,
    this.y,
  });

  factory ArMarkersModel.fromJSON(Map<String, dynamic> json) {
    return ArMarkersModel(
      id: json['id'],
      markerId: json['marker_id'],
      markerName: json['marker_name'],
      x: json['x'] != null ? double.parse(json['x'].toString()) : null,
      y: json['y'] != null ? double.parse(json['y'].toString()) : null,
    );
  }
}
