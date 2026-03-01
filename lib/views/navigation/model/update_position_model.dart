class UpdatePositionModel {
  bool? success;
  String? status;
  String? warning;
  int? remainingDistance;
  String? message;

  UpdatePositionModel({
    this.success,
    this.status,
    this.warning,
    this.remainingDistance,
    this.message,
  });

  factory UpdatePositionModel.fromJSON(Map<String, dynamic> json) {
    return UpdatePositionModel(
      success: json['success'],
      status: json['status'],
      warning: json['warning'],
      remainingDistance: json['remainDistance'],
      message: json['message'],
    );
  }
}
