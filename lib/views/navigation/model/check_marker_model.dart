class CheckMarkerModel {
  double? confidence;
  int? markerId;

  CheckMarkerModel({
    this.confidence,
    this.markerId,
});

  factory CheckMarkerModel.fromJSON(Map<String, dynamic> json) {
    return CheckMarkerModel(
      confidence: json['confidence'],
      markerId: json['marker_id'],
    );
  }
}