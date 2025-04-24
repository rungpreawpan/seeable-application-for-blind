class PlaceModel {
  int? id;
  String? name;
  String? gateway;
  int? bleCount;
  List<String>? bleNames;
  bool? isFavorite;

  PlaceModel({
    this.id,
    this.name,
    this.gateway,
    this.bleCount,
    this.bleNames,
    this.isFavorite,
  });

  factory PlaceModel.fromJSON(Map<String, dynamic> json) {
    return PlaceModel(
      id: json['id'],
      name: json['name'],
      gateway: json['gateway'],
      bleCount: json['ble_count'],
      bleNames: List.from(json['ble_names']),
      isFavorite: json['is_favorite'],
    );
  }
}
