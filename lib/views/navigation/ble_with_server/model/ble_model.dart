class BLEModel {
   String? uuid;
   String? mac;
   String? name;
   int? rssi;

  BLEModel({
     this.uuid,
     this.mac,
     this.name,
     this.rssi,
  });

  factory BLEModel.fromJSON(Map<String, dynamic> json) {
    return BLEModel(
      uuid: json['uuid'],
      mac: json['mac'],
      name: json['name'],
      rssi: json['rssi'],
    );
  }
}