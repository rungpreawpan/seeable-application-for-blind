class NavigationPathModel {
  String? sessionId;
  String? start;
  String? destination;
  List? path;
  int? totalDistance;
  String? destinationSide;
  String? message;

  NavigationPathModel({
    this.sessionId,
    this.start,
    this.destination,
    this.path,
    this.totalDistance,
    this.destinationSide,
    this.message,
  });

  factory NavigationPathModel.fromJSON(Map<String, dynamic> json) {
    return NavigationPathModel(
      sessionId: json['session_id'],
      start: json['start'],
      destination: json['destination'],
      path: json['path'],
      totalDistance: json['totalDistance'],
      destinationSide: json['destinationSide'],
      message: json['message'],
    );
  }
}
