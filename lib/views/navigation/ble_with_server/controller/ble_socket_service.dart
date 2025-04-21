import 'package:seeable/constant/environment.dart';
import 'package:seeable/views/navigation/ble_with_server/model/ble_model.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class BLESocketService {
  late IO.Socket socket;

  void connect() {
    socket = IO.io(getBaseURL(), <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    socket.onConnect((_) {
      print('Socket connected');
    });

    socket.onDisconnect((_) {
      print('Socket disconnected');
    });

    socket.on('ble-data', (data) {
      // print('ได้ข้อมูล BLE จาก backend: $data');

      // คุณสามารถแปลง JSON มาใช้ในแอปได้ เช่น:
      final ble = BLEModel.fromJSON(data);
      // แล้วโยนเข้า state / Bloc / Provider ได้เลย

      print(ble.name);
    });
  }

  void disconnect() {
    socket.disconnect();
  }
}