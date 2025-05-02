class BLEModel {
  String? uuid;
  String? mac;
  String? name;
  // List<int>? rssiList;
  int? rssi;

  BLEModel({
    this.uuid,
    this.mac,
    this.name,
    // this.rssiList,
    this.rssi,
  });

  factory BLEModel.fromJSON(Map<String, dynamic> json) {
    return BLEModel(
      uuid: json['uuid'],
      mac: json['mac'],
      name: json['name'],
      // rssiList: [json['rssi'] ?? 0],
      rssi: json['rssi'],
    );
  }
}

class BLEListModel {
  String? uuid;
  String? mac;
  String? name;
  List<int>? rssiList;

  BLEListModel({
    this.uuid,
    this.mac,
    this.name,
    this.rssiList,
  });

  factory BLEListModel.fromJSON(Map<String, dynamic> json) {
    return BLEListModel(
      uuid: json['uuid'],
      mac: json['mac'],
      name: json['name'],
      rssiList: [json['rssi'] ?? 0],
    );
  }
}
