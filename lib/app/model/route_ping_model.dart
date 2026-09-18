//Models define the shape of your data
//Converts between Dart objects and Firestore documents

import 'package:cloud_firestore/cloud_firestore.dart';

class RoutePing {
  final String driverId;
  final String sessionId;
  final DateTime timestamp;
  final GeoPoint location;
  final double speedkmh;
  final int batteryLevel;
  final String batteryStatus;
  final bool isTrackingActive;


  RoutePing({
    required this.driverId,
    required this.sessionId,
    required this.timestamp,
    required this.location,
    required this.speedkmh,
    required this.batteryLevel,
    required this.batteryStatus,
    required this.isTrackingActive,


  });

  // Write to firestore
  Map<String, dynamic> toMap()  => {
    'driver_id': driverId,
    'session_id': sessionId,
    'timestamp': Timestamp.fromDate(timestamp),
    'location': location,
    'speed_kmh': speedkmh,
    'battery_level': batteryLevel,
    'battery_status': batteryStatus,
    'is_tracking_active': isTrackingActive,
};
  //Read from Firestore
factory RoutePing.fromMap(Map<String, dynamic> map) => RoutePing(
  driverId: map['driver_id'] ?? '',
  sessionId: map['session_id'] ?? '',
  timestamp: (map['timestamp'] as Timestamp).toDate(),
  location: map['location'] as GeoPoint,
  speedkmh: (map['speed_kmh'] as num).toDouble(),
  batteryLevel: map['battery_level'] ?? 0,
  batteryStatus: map['battery_status'] ?? 'unknown',
  isTrackingActive: map['is_tracking_active'] ?? false,
);
}