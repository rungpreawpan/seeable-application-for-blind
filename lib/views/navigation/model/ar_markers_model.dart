class ArMarkersModel {
  int? id;
  int? markerId;
  String? markerName;

  ArMarkersModel({
    this.id,
    this.markerId,
    this.markerName,
  });

  factory ArMarkersModel.fromJSON(Map<String, dynamic> json) {
    return ArMarkersModel(
      id: json['id'],
      markerId: json['marker_id'],
      markerName: json['marker_name'],
    );
  }
}
