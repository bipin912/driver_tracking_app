import 'dart:async';
import 'package:battery_plus/battery_plus.dart';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:location/location.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';


import '../repository/tracking_repository.dart';
import '../../background_service.dart';

class TrackingController extends GetxController {
  final TrackingRepository _repo = TrackingRepository();
  final Location _location = Location();
  final Battery _battery = Battery();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  RxBool isTracking = false.obs;
  RxString sessionId = ''.obs;
  RxInt batteryLevel = 100.obs;
  RxString batteryStatus = 'unknown'.obs;
  RxDouble speedKmh = 0.0.obs;
  RxString errorMessage = ''.obs;

  bool _isToggling = false;


  @override
  void onClose() {
    if (isTracking.value) _stopTracking();
    super.onClose();
  }

  Future<void> toggleTracking() async {
    if (_isToggling) return;
    _isToggling = true;
    try {
      if (isTracking.value) await _stopTracking();
      else await _startTracking();
    } finally {
      _isToggling = false;
    }
  }

  Future<void> _startTracking() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // Check GPS
      if (!await _location.serviceEnabled()) {
        if (!await _location.requestService()) return;
      }
      final permission = await _location.requestPermission();
      if (permission != PermissionStatus.granted &&
          permission != PermissionStatus.grantedLimited) return;

      // Set state
      sessionId.value = 'sess_${DateTime.now().millisecondsSinceEpoch}_${user.uid.substring(0, 6)}';
      isTracking.value = true;

      // Start background service — handles ALL pings (foreground + background + locked)
      final service = FlutterBackgroundService();

      //Stop any existing service first to get clean start
      if (await service.isRunning()) {
        service.invoke('stopService');
        await Future.delayed(const Duration(milliseconds: 500));
      }




      await service.configure(
        androidConfiguration: AndroidConfiguration(
          onStart: onStart,
          autoStart: false,
          isForegroundMode: true,
          notificationChannelId: 'tracking_channel',
          initialNotificationTitle: 'Route Tracking',
          initialNotificationContent: 'Tracking your trip...',
          foregroundServiceNotificationId: 888,
        ),
        iosConfiguration: IosConfiguration(
          autoStart: false,
          onForeground: onStart,
          onBackground: onIosBackground,
        ),
      );



      await service.startService();
      await _updateBattery();

      //Read current battery level and status immediately (in case service takes time to start) and send to service
      final currentState = await _battery.batteryState;
      batteryStatus.value = currentState.toString().split('.').last.toLowerCase();

      // Send session info to background service
      await Future.delayed(const Duration(milliseconds: 1500));
      service.invoke('setSession', {
        'sessionId': sessionId.value,
        'driverId': user.uid,
        'batteryLevel' : batteryLevel.value,
        'batteryStatus' : batteryStatus.value,
      });

      // Update battery for UI display
      await _updateBattery();
      _battery.onBatteryStateChanged.listen((state) {
        batteryStatus.value = state.toString().split('.').last.toLowerCase();
        _updateBattery();
      });

      Get.snackbar("Tracking Started", "Works in background & locked screen");
    } catch (e) {
      print(' $e');
      isTracking.value = false;
      sessionId.value = '';
    }
  }

  Future<void> _stopTracking() async {
    isTracking.value = false;
    sessionId.value = '';

    await _updateBattery();

    //Send final Battery to background service before stopping it (so it can save final ping with battery info)
    FlutterBackgroundService().invoke('stopService', {
      'batteryLevel' : batteryLevel.value,
      'batteryStatus' : batteryStatus.value,
    });



    Get.snackbar("Tracking Stopped", "Syncing data...");
  }

  Future<void> _updateBattery() async {
    try { batteryLevel.value = await _battery.batteryLevel; }
    catch (_) { batteryLevel.value = -1; }
  }
}