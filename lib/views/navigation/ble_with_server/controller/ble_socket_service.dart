// import 'dart:developer';
//
// import 'package:seeable/constant/environment.dart';
// import 'package:seeable/views/navigation/ble_with_server/model/ble_model.dart';
// import 'package:socket_io_client/socket_io_client.dart' as IO;
//
// class BLESocketService {
//   late IO.Socket socket;
//
//   void connect() {
//     socket = IO.io(getBaseURL(), <String, dynamic>{
//       'transports': ['websocket'],
//       'autoConnect': true,
//     });
//
//     socket.onConnect((_) {
//       log('Socket connected');
//     });
//
//     socket.onDisconnect((_) {
//       log('Socket disconnected');
//     });
//
//     socket.on('ble-data', (data) {
//       final ble = BLEModel.fromJSON(data);
//
//       log('${ble.name}: ${ble.rssi}');
//     });
//   }
//
//   void disconnect() {
//     socket.disconnect();
//   }
// }
