class FingerprintModel {
  double x;
  double y;

  FingerprintModel({
    required this.x,
    required this.y,
  });

  factory FingerprintModel.fromJSON(Map<String, dynamic> json) {
    return FingerprintModel(
      x: json['x'],
      y: json['y'],
    );
  }
}
