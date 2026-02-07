class NavigationPathModel {
  String? sessionId;
  int? markerId;
  int? confidence;
  String? start;
  String? destination;
  List? path;
  int? totalDistance;
  String? targetSide;

  NavigationPathModel({
    this.sessionId,
    this.markerId,
    this.confidence,
    this.start,
    this.destination,
    this.path,
    this.totalDistance,
    this.targetSide,
  });

  factory NavigationPathModel.fromJSON(Map<String, dynamic> json) {
    return NavigationPathModel(
      sessionId: json['session_id'],
      markerId: json['marker_id'],
      confidence: json['confidence'],
      start: json['start'],
      destination: json['destination'],
      path: json['path'],
      totalDistance: json['totalDistance'],
      targetSide: json['targetSide'],
    );
  }
}
