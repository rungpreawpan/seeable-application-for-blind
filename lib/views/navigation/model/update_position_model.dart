class UpdatePositionModel {
  String? status;
  int? remainingDistance;
  String? message;

  UpdatePositionModel({
    this.status,
    this.remainingDistance,
    this.message,
  });

  factory UpdatePositionModel.fromJSON(Map<String, dynamic> json) {
    return UpdatePositionModel(
      status: json['status'],
      remainingDistance: json['remainingDistance'],
      message: json['message'],
    );
  }
}
