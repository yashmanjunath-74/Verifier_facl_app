import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:location/location.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';

// A wrapper class for incoming payloads to associate them with the sender.
class ReceivedPayload {
  final String endpointId;
  final String data;

  ReceivedPayload({required this.endpointId, required this.data});
}

class NearbyConnectionsService {
  final Strategy _strategy = Strategy.P2P_STAR;
  final nearby = Nearby();

  final _connectionController = StreamController<String>.broadcast();
  Stream<String> get connectionStream => _connectionController.stream;

  final _payloadController = StreamController<ReceivedPayload>.broadcast();
  Stream<ReceivedPayload> get payloadStream => _payloadController.stream;

  Future<bool> checkPermissions() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt >= 31) {
        // Android 12+
        await [
          Permission.bluetooth,
          Permission.bluetoothAdvertise,
          Permission.bluetoothConnect,
          Permission.bluetoothScan,
          Permission.nearbyWifiDevices,
          Permission.locationWhenInUse,
        ].request();
      } else {
        // Android 11 and below
        await [
          Permission.bluetooth,
          Permission.bluetoothAdvertise,
          Permission.bluetoothConnect,
          Permission.location,
        ].request();
      }
    }

    if (await Permission.location.isGranted &&
        await Permission.bluetooth.isGranted &&
        await Permission.bluetoothAdvertise.isGranted &&
        await Permission.bluetoothConnect.isGranted &&
        await Permission.bluetoothScan.isGranted) {
      if (!await Location.instance.serviceEnabled()) {
        await Location.instance.requestService();
      }
      return true;
    }
    return false;
  }

  Future<void> startAdvertising(String facultyName) async {
    try {
      await nearby.startAdvertising(
        facultyName,
        _strategy,
        onConnectionInitiated: _onConnectionInitiated,
        onConnectionResult: (endpointId, status) {
          _connectionController.add(
            'Connection Result: $endpointId - ${status.name}',
          );
        },
        onDisconnected: (endpointId) {
          _connectionController.add('Disconnected: $endpointId');
        },
      );
      _connectionController.add('Advertising started as $facultyName.');
    } catch (e) {
      _connectionController.add('Error starting advertising: $e');
      rethrow;
    }
  }

  void _onConnectionInitiated(
    String endpointId,
    ConnectionInfo connectionInfo,
  ) {
    // Automatically accept all incoming connections.
    nearby.acceptConnection(
      endpointId,
      onPayLoadRecieved: (endpointId, payload) {
        if (payload.type == PayloadType.BYTES) {
          final data = utf8.decode(payload.bytes!);
          _payloadController.add(
            ReceivedPayload(endpointId: endpointId, data: data),
          );
        }
      },
      onPayloadTransferUpdate: (endpointId, payloadTransferUpdate) {
        // Can be used to show transfer progress
      },
    );
  }

  Future<void> stopAdvertising() async {
    await nearby.stopAdvertising();
    _connectionController.add('Advertising stopped.');
  }

  Future<void> sendPayload(String endpointId, Map<String, dynamic> data) async {
    try {
      final jsonData = jsonEncode(data);
      await nearby.sendBytesPayload(
        endpointId,
        Uint8List.fromList(utf8.encode(jsonData)),
      );
    } catch (e) {
      print("Failed to send payload to $endpointId: $e");
    }
  }

  Future<void> disconnectFromAll() async {
    await nearby.stopAllEndpoints();
  }

  void dispose() {
    stopAdvertising();
    disconnectFromAll();
    _connectionController.close();
    _payloadController.close();
  }
}