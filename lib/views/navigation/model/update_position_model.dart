class UpdatePositionModel {
  String? status;
  int? remainingDistance;

  UpdatePositionModel({
    this.status,
    this.remainingDistance,
  });

  factory UpdatePositionModel.fromJSON(Map<String, dynamic> json) {
    return UpdatePositionModel(
      status: json['status'],
      remainingDistance: json['remainDistance'],
    );
  }
}
