import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'firebase_options.dart';

@pragma('vm:entry-point')
Future<void> onStart(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Hive needs separate init in background isolate
  final dir = await getApplicationDocumentsDirectory();
  Hive.init(dir.path);
  final box = await Hive.openBox('gps_pings');

  String sessionId = '';
  String driverId = '';
  int batteryLevel = 0;
  String batteryStatus = 'unknown';
  Timer? timer;

  // Receive session info from controller
  service.on('setSession').listen((data) {
    sessionId = data?['sessionId'] ?? '';
    driverId = data?['driverId'] ?? '';
    batteryLevel = data?['batteryLevel'] ?? 0;
    batteryStatus = data?['batteryStatus'] ?? 'unknown';
    print('Session: $sessionId | Battery : $batteryLevel%');
  });

  // Stop command from controller
  service.on('stopService').listen((data) async {
    timer?.cancel();

    //Use battery sent from controller (accurate, from main isolate)
    final finalBattery = data?['batteryLevel'] ?? batteryLevel;
    final finalBatteryStatus = data?['batteryStatus'] ?? batteryStatus;

    // Save final ping (isTrackingActive: false marks trip as complete)
    if (sessionId.isNotEmpty) {
      await _savePing(box, sessionId, driverId, isEnd: true,
      battery: finalBattery, batteryStatus: finalBatteryStatus);
    }

    // Sync everything to Firestore before shutting down
    await _syncToFirestore(box);
    service.stopSelf();
  });

  // Every 30s: get GPS → save to Hive → sync to Firestore
  timer = Timer.periodic(const Duration(seconds: 30), (_) async {
    if (sessionId.isEmpty) return;
    await _savePing(box, sessionId, driverId, isEnd: false,
    battery: batteryLevel, batteryStatus: batteryStatus);
    await _syncToFirestore(box);
  });
  //Fire first ping immediately
  await Future.delayed(const Duration(seconds: 1));
  if (sessionId.isNotEmpty) {
    await _savePing(box, sessionId, driverId, isEnd: false,
        battery: batteryLevel, batteryStatus: batteryStatus);
    await _syncToFirestore(box);
  }

}

//Track last position
Position? _lastPosition;
DateTime? _lastTime;


// Get GPS and save to Hive
Future<void> _savePing(Box box, String sessionId, String driverId,
    {required bool isEnd, required int battery, required String batteryStatus}) async {
  try {
    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 10),
    );

    //Calculate speed manually from distance/time between pings
    double speedKmh = 0.0;
    if( _lastPosition != null && _lastTime !=null && !isEnd){
      final distanceMeters = Geolocator.distanceBetween(
      _lastPosition!.latitude , _lastPosition!.longitude,
          pos.latitude, pos.longitude
      );
    final seconds = DateTime.now().difference(_lastTime!).inSeconds;
    if(seconds > 0){
      speedKmh = (distanceMeters / seconds) * 3.6; // m/s to km/h
      speedKmh = speedKmh.clamp(0.0, 150.0); //filter spikes
    }
    }

    //update for the next ping
    _lastPosition = pos;
    _lastTime = DateTime.now();

    await box.add({
      'synced': false,
      'driver_id': driverId,
      'session_id': sessionId,
      'timestamp': DateTime.now().millisecondsSinceEpoch, // int — Hive safe
      'location': {                                        // Map — Hive safe
        'latitude': pos.latitude,
        'longitude': pos.longitude,
      },
      'speed_kmh': speedKmh,
      'battery_level': battery,
      'battery_status': batteryStatus,
      'is_tracking_active': !isEnd, // false = end of trip
    });

    print('${isEnd ? "Final" : "Regular"} ping saved to Hive');
  } catch (e) {
    print('GPS failed: $e');
  }
}

// Upload unsynced Hive pings to Firestore
Future<void> _syncToFirestore(Box box) async {
  final keys = box.keys
      .where((k) => box.get(k)?['synced'] == false)
      .toList();

  if (keys.isEmpty) return;
  print('🌐 Syncing ${keys.length} pings...');

  for (final key in keys) {
    try {
      final raw = Map<String, dynamic>.from(box.get(key));

      // Convert Hive types → Firestore types
      raw['timestamp'] = Timestamp.fromMillisecondsSinceEpoch(raw['timestamp'] as int);
      final loc = raw['location'] as Map;
      raw['location'] = GeoPoint(
        (loc['latitude'] as num).toDouble(),
        (loc['longitude'] as num).toDouble(),
      );
      raw.remove('synced');

      await FirebaseFirestore.instance.collection('driver_route_log').add(raw);
      await box.delete(key); // delete only after successful upload
      print('Synced to Firestore');
    } catch (e) {
      print('Sync failed (offline?): $e');
      break; // stop trying, retry next tick
    }
  }
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async => true;