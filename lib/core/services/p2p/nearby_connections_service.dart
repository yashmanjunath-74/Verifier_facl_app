import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:nearby_connections/nearby_connections.dart';
// FIX: Add imports for permission packages
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:location/location.dart' as loc;

// Represents a payload received from a student device
class ReceivedPayload {
  final String endpointId;
  final Payload payload; 

  ReceivedPayload({required this.endpointId, required this.payload});

  String get dataAsString {
    if (payload.type == PayloadType.BYTES && payload.bytes != null) {
      return utf8.decode(payload.bytes!);
    }
    return '';
  }
}

class NearbyConnectionsService {
  final nearby = Nearby();
  final Strategy _strategy = Strategy.P2P_STAR; // Define the connection strategy
  final String _serviceId = "com.example.verifier"; // Define the service ID

  // Streams for UI updates or manager logic
  final _connectionController = StreamController<String>.broadcast();
  final _payloadController = StreamController<ReceivedPayload>.broadcast();

  Stream<String> get connectionStatusStream => _connectionController.stream;
  Stream<ReceivedPayload> get payloadStream => _payloadController.stream;

  final Map<String, ConnectionInfo> _connectedEndpoints = {};

  // --- Permission Checks (Using permission_handler and location) ---
  Future<bool> checkPermissions() async {
    // 1. Check Location Permission
    ph.PermissionStatus locationStatus = await ph.Permission.locationWhenInUse.status;
    if (locationStatus.isDenied || locationStatus.isPermanentlyDenied) {
      print("[Faculty] Location permission needed. Asking...");
      locationStatus = await ph.Permission.locationWhenInUse.request();
    }
    if (!locationStatus.isGranted) {
       print("[Faculty] Location permission denied.");
       return false;
    }

    // 2. Check Bluetooth Permissions
    Map<ph.Permission, ph.PermissionStatus> bluetoothStatuses = await [
      ph.Permission.bluetoothScan,
      ph.Permission.bluetoothAdvertise,
      ph.Permission.bluetoothConnect,
    ].request();
    bool bluetoothGranted = bluetoothStatuses.values.every((status) => status.isGranted);
    if (!bluetoothGranted) {
       print("[Faculty] One or more Bluetooth permissions were denied.");
       bluetoothStatuses.forEach((key, value) {
         print("[Faculty] ${key.toString()}: ${value.toString()}");
       });
       return false;
    }

    // 3. Check Nearby Wi-Fi Devices Permission (Android 12+)
    ph.PermissionStatus nearbyWifiStatus = await ph.Permission.nearbyWifiDevices.status;
     if (nearbyWifiStatus.isDenied || nearbyWifiStatus.isPermanentlyDenied) {
        print("[Faculty] Nearby Wi-Fi permission needed. Asking...");
        nearbyWifiStatus = await ph.Permission.nearbyWifiDevices.request();
     }
      if (!nearbyWifiStatus.isGranted) {
        print("[Faculty] Nearby Wi-Fi permissions denied.");
        // Assuming required for robust connections
        return false;
     }

    // 4. Check if Location Services are Enabled
    final locationService = loc.Location();
    bool locationEnabled = await locationService.serviceEnabled();
    if (!locationEnabled) {
      print("[Faculty] Location services are off. Asking user to enable...");
      locationEnabled = await locationService.requestService();
      if (!locationEnabled) {
         print("[Faculty] Location services not enabled by user.");
         return false;
      }
    }

    print("[Faculty] Permission Status: Location=${locationStatus.isGranted}, Bluetooth=$bluetoothGranted, NearbyWifi=${nearbyWifiStatus.isGranted}, LocationEnabled=$locationEnabled");
    return locationStatus.isGranted && bluetoothGranted && nearbyWifiStatus.isGranted && locationEnabled;
  }
  // --- End Permissions ---


  // --- Advertising ---
  Future<void> startAdvertising(String facultyName) async {
    _connectionController.add('Attempting to start advertising...');
    try {
      // Permissions should be checked before calling this in the UI/Manager layer
      bool advertisingStarted = await nearby.startAdvertising(
        facultyName,
        _strategy,
        serviceId: _serviceId, // Use the defined service ID
        onConnectionInitiated: _onConnectionInitiated,
        onConnectionResult: (endpointId, status) {
          _connectionController.add(
            'Connection Result: $endpointId - ${status.name}',
          );
          if (status != Status.CONNECTED) {
            _connectedEndpoints.remove(endpointId);
            print("[Faculty] Connection failed/rejected for $endpointId");
          } else {
             print("[Faculty] Successfully connected to $endpointId");
          }
        },
        onDisconnected: (endpointId) {
          _connectedEndpoints.remove(endpointId);
          _connectionController.add('Disconnected: $endpointId');
          print("[Faculty] Disconnected from $endpointId");
        },
      );
      if (advertisingStarted) {
          _connectionController.add('Advertising started as $facultyName.');
          print("[Faculty] Advertising successfully started.");
      } else {
          _connectionController.add('Failed to start advertising (permissions?).');
          print("[Faculty] nearby.startAdvertising returned false.");
      }
    } catch (e) {
      _connectionController.add('Error starting advertising: $e');
      print("[Faculty] Error starting advertising: $e");
      rethrow;
    }
  }

  Future<void> stopAdvertising() async {
    await nearby.stopAdvertising();
    _connectionController.add('Advertising stopped.');
    print("[Faculty] Advertising stopped.");
  }
  // --- End Advertising ---


  // --- Connection Handling ---
  void _onConnectionInitiated(String endpointId, ConnectionInfo connectionInfo) {
    print("[Faculty] Connection initiated: id=$endpointId, name=${connectionInfo.endpointName}");
    _connectionController.add('Connection request from ${connectionInfo.endpointName}');
    nearby.acceptConnection(
      endpointId,
      onPayLoadRecieved: (endpointId, payload) {
        print('[Faculty] Payload received from $endpointId, Type: ${payload.type}');
        _payloadController.add(ReceivedPayload(endpointId: endpointId, payload: payload));
      },
      onPayloadTransferUpdate: (endpointId, payloadInfo) {
        print('[Faculty] Payload Transfer Update: $endpointId, Status: ${payloadInfo.status}, Bytes: ${payloadInfo.bytesTransferred}/${payloadInfo.totalBytes}');
      },
    );
     _connectedEndpoints[endpointId] = connectionInfo;
  }
  // --- End Connection Handling ---


  // --- Payload Sending ---
  Future<void> sendPayload(String endpointId, Map<String, dynamic> data) async {
    if (!_connectedEndpoints.containsKey(endpointId)) {
      print('[Faculty] Error: Not connected to endpoint $endpointId.');
      _connectionController.add("Error: Not connected to $endpointId.");
      return;
    }
    try {
      final jsonString = jsonEncode(data);
      final bytes = Uint8List.fromList(utf8.encode(jsonString));
      await nearby.sendBytesPayload(endpointId, bytes);
      _connectionController.add("Sent data to $endpointId.");
      print("[Faculty] Sent payload to $endpointId: $jsonString");
    } catch (e) {
      print('[Faculty] Error sending payload to $endpointId: $e');
      _connectionController.add("Error sending data to $endpointId.");
    }
  }
  // --- End Payload Sending ---


  // --- Disconnection & Cleanup ---
  Future<void> disconnectFromEndpoint(String endpointId) async {
    if (_connectedEndpoints.containsKey(endpointId)) {
      await nearby.disconnectFromEndpoint(endpointId);
      _connectedEndpoints.remove(endpointId);
      print("[Faculty] Manually disconnected from $endpointId");
    }
  }

  Future<void> stopAll() async {
    try {
      await nearby.stopAllEndpoints();
      await nearby.stopAdvertising();
    } catch (e) {
        print("[Faculty] Error stopping P2P: $e");
    } finally {
        _connectedEndpoints.clear();
        _connectionController.add("P2P Stopped.");
        print('[Faculty] Stopped all Nearby Connections activities.');
    }
  }

  void dispose() {
    stopAll();
    _connectionController.close();
    _payloadController.close();
  }
 
}
