import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';


class TripStop{
  final double lat;
  final double lng;
  final DateTime startTime;
  final Duration duration;

  TripStop({
    required this.lat,
    required this.lng,
    required this.startTime,
    required this.duration,
  });


}


class TripSummary {
  final List<TripStop> stops;
  final String sessionId;
  final String driverName;
  final DateTime startTime;
  final DateTime endTime;
  final double totalDistanceKm;
  final Duration totalDuration;
  final double avgSpeedKmh;
  final double maxSpeedKmh;
  final int startBattery;
  final int endBattery;
  final int batteryDrain;
  final List<Map<String, dynamic>> routePoints;

  TripSummary({
    required this.stops,
    required this.sessionId,
    required this.driverName,
    required this.startTime,
    required this.endTime,
    required this.totalDistanceKm,
    required this.totalDuration,
    required this.avgSpeedKmh,
    required this.maxSpeedKmh,
    required this.startBattery,
    required this.endBattery,
    required this.batteryDrain,
    required this.routePoints,
  });

  //  Updated factory to accept driverName
  factory TripSummary.fromPings(List<dynamic> pings, String driverName) {
    if (pings.isEmpty) throw Exception('No pings for session');

    //  Sort by timestamp (critical!)
    pings.sort((a, b) => (a['timestamp'] as Timestamp).compareTo(b['timestamp'] as Timestamp));

    final first = pings.first;
    final last = pings.last;

    //  SAFE BATTERY CASTING + DEBUG
    final startBat = (first['battery_level'] as num).toInt();
    final endBat = (last['battery_level'] as num).toInt();
    final batteryDrain = startBat - endBat;

    print(' Session: ${first['session_id']}');
    print('   Start: $startBat% | End: $endBat% | Drain: $batteryDrain%');
    print('   First ping time: ${(first['timestamp'] as Timestamp).toDate()}');
    print('   Last ping time: ${(last['timestamp'] as Timestamp).toDate()}');

    //  CALCULATE DISTANCE (with debug)
    double totalDistance = 0;
    for (int i = 1; i < pings.length; i++) {
      final prev = pings[i-1];
      final curr = pings[i];

      final lat1 = (prev['location'] as GeoPoint).latitude;
      final lng1 = (prev['location'] as GeoPoint).longitude;
      final lat2 = (curr['location'] as GeoPoint).latitude;
      final lng2 = (curr['location'] as GeoPoint).longitude;

      final segment = _calculateDistance(lat1, lng1, lat2, lng2);
      totalDistance += segment;

      if (i <= 2) { // Debug first few segments
        print('    Segment $i: ${segment.toStringAsFixed(3)} km (${lat1.toStringAsFixed(4)},${lng1.toStringAsFixed(4)} → ${lat2.toStringAsFixed(4)},${lng2.toStringAsFixed(4)})');
      }
    }
    print('    Total distance: ${totalDistance.toStringAsFixed(3)} km');

    // Duration & speed
    final durations = pings.map((p) => (p['timestamp'] as Timestamp).toDate()).toList();
    final totalDuration = durations.last.difference(durations.first);
    final speeds = pings.map((p) => (p['speed_kmh'] as num).toDouble()).toList();
    final avgSpeed = speeds.reduce((a, b) => a + b) / speeds.length;
    final maxSpeed = speeds.reduce((a, b) => a > b ? a : b);
    final stops = _detectStops(pings);

    return TripSummary(
      sessionId: first['session_id'],
      driverName: driverName,
      startTime: (first['timestamp'] as Timestamp).toDate(),
      endTime: (last['timestamp'] as Timestamp).toDate(),
      totalDistanceKm: totalDistance,
      totalDuration: totalDuration,
      avgSpeedKmh: avgSpeed,
      maxSpeedKmh: maxSpeed,
      startBattery: startBat,
      endBattery: endBat,
      batteryDrain: batteryDrain,
      routePoints: pings.map((p) => {
        'lat': (p['location'] as GeoPoint).latitude,
        'lng': (p['location'] as GeoPoint).longitude,
        'time': (p['timestamp'] as Timestamp).toDate(),
      }).toList(),
      stops: stops,
    );
  }

  //Stop Detecting algorithm
  static List<TripStop> _detectStops(List<dynamic> pings){
    const minDuration = Duration(minutes: 2);
    const maxStopSpeed = 3.0; // km/h (walking speed threshold)
    const maxDrift = 0.0027; // 30m in Lat/Lng
    const gapThreshold = Duration(seconds: 90); //Gap = potential OS-throttled stop

    final stops = <TripStop>[];
    int stopStartIndex = 0;

    for(int i=1; i< pings.length; i++){
      final currSpeed = (pings[i]['speed_kmh'] as num?)?.toDouble() ?? 0;
      final currLoc = pings[i]['location'] as GeoPoint;
      final startLoc = pings[stopStartIndex]['location'] as GeoPoint;

      //Calculate distance from stop-start location
      final distFromStart = _calculateDistance(
        startLoc.latitude, startLoc.longitude,
        currLoc.latitude, currLoc.longitude
      );

      //1.GAP DETECTION: Handle OS throttling / missing pings
      final timeGap = (pings[i]['timestamp'] as Timestamp).toDate().difference(
          (pings[i-1]['timestamp'] as Timestamp).toDate(),
      );

      if(timeGap >= gapThreshold){
        //Large gap -> Assume driver stopped at previous location
        stops.add(TripStop(
          lat: (pings[i-1]['location'] as GeoPoint).latitude,  // ← Previous ping (before gap)
          lng: (pings[i-1]['location'] as GeoPoint).longitude,
          startTime: (pings[i-1]['timestamp'] as Timestamp).toDate(),
          duration: timeGap, //the gap itself is the stop duration
        ));

        //Reset for next potential stop
        stopStartIndex = i;
        continue; //skip normal stop logic for this iteration
      }

      //2. NORMAL STOP LOGIC for frequent pings
      final isStillStopped = currSpeed <= maxStopSpeed && distFromStart <= maxDrift;

      //If driver moved or reached end of pings
      if(!isStillStopped || i == pings.length - 1){
        final stopDuration = (pings[i]['timestamp'] as Timestamp).toDate().difference(
            (pings[stopStartIndex]['timestamp'] as Timestamp).toDate()
        );

        if(stopDuration >= minDuration){
          stops.add(TripStop(
            lat: startLoc.latitude,
            lng: startLoc.longitude,
            startTime: (pings[stopStartIndex]['timestamp'] as Timestamp).toDate(),
            duration: stopDuration,
          ));
        }
        stopStartIndex = i; // reset for next potential stop
      }

    }
    return stops;
  }


  static double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371;
    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);
    final a = 0.5 - cos(dLat)/2 + cos(_degToRad(lat1)) * cos(_degToRad(lat2)) * (1 - cos(dLon))/2;
    return R * 2 * asin(sqrt(a));
  }

  static double _degToRad(double deg) => deg * (3.14159265359 / 180);
}