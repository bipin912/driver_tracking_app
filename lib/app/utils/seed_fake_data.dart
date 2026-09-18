import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> seedMultiDayTrips(String driverId) async {
  final col = FirebaseFirestore.instance.collection('driver_route_log');
  final now = DateTime.now();

  // 📅 d1_morning — battery 55%→50%, 1 stop (3m)
  await _seedTrip(col, driverId, 'd1_morning', now.subtract(const Duration(days: 1, hours: 6)), [
    {'lat': 27.7150, 'lng': 85.3200, 'bat': 55, 'spd': 20, 'min': 0.0},
    {'lat': 27.7160, 'lng': 85.3210, 'bat': 54, 'spd': 22, 'min': 0.5},
    {'lat': 27.7170, 'lng': 85.3220, 'bat': 54, 'spd': 25, 'min': 1.0},
    // 🛑 3 min stop
    {'lat': 27.7210, 'lng': 85.3260, 'bat': 53, 'spd': 0, 'min': 1.5},
    {'lat': 27.7210, 'lng': 85.3260, 'bat': 53, 'spd': 0, 'min': 2.0},
    {'lat': 27.7210, 'lng': 85.3260, 'bat': 52, 'spd': 0, 'min': 2.5},
    {'lat': 27.7210, 'lng': 85.3260, 'bat': 52, 'spd': 0, 'min': 3.0},
    {'lat': 27.7210, 'lng': 85.3260, 'bat': 52, 'spd': 0, 'min': 3.5},
    {'lat': 27.7210, 'lng': 85.3260, 'bat': 51, 'spd': 0, 'min': 4.0},
    // Resume
    {'lat': 27.7220, 'lng': 85.3270, 'bat': 51, 'spd': 18, 'min': 4.5},
    {'lat': 27.7230, 'lng': 85.3280, 'bat': 51, 'spd': 20, 'min': 5.0},
    {'lat': 27.7250, 'lng': 85.3300, 'bat': 50, 'spd': 22, 'min': 5.5},
  ], endBat: 50);

  // 🌀 zigzag_trip — battery 33%→28%, 0 stops (traffic <2min ignored)
  await _seedTrip(col, driverId, 'zigzag_trip', now.subtract(const Duration(hours: 2)), [
    {'lat': 27.7150, 'lng': 85.3200, 'bat': 33, 'spd': 20, 'min': 0.0},
    {'lat': 27.7155, 'lng': 85.3210, 'bat': 32, 'spd': 25, 'min': 0.5},
    // 🚦 45s traffic light — should NOT appear
    {'lat': 27.7160, 'lng': 85.3220, 'bat': 32, 'spd': 0, 'min': 1.0},
    {'lat': 27.7160, 'lng': 85.3220, 'bat': 32, 'spd': 0, 'min': 1.5},
    {'lat': 27.7160, 'lng': 85.3220, 'bat': 31, 'spd': 0, 'min': 1.75},
    // Resume
    {'lat': 27.7165, 'lng': 85.3230, 'bat': 31, 'spd': 28, 'min': 2.25},
    {'lat': 27.7170, 'lng': 85.3240, 'bat': 30, 'spd': 30, 'min': 2.75},
    {'lat': 27.7180, 'lng': 85.3250, 'bat': 29, 'spd': 25, 'min': 3.25},
    {'lat': 27.7190, 'lng': 85.3260, 'bat': 28, 'spd': 20, 'min': 3.75},
  ], endBat: 28);

  // 📅 d1_evening — battery 60%→64% (charging), 1 stop (12m)
  await _seedTrip(col, driverId, 'd1_evening', now.subtract(const Duration(days: 1, hours: 19)), [
    {'lat': 27.7320, 'lng': 85.3370, 'bat': 60, 'spd': 10, 'min': 0.0},
    {'lat': 27.7325, 'lng': 85.3375, 'bat': 60, 'spd': 8,  'min': 0.5},
    // 🛑 12 min stop + charging
    {'lat': 27.7340, 'lng': 85.3390, 'bat': 60, 'spd': 0, 'min': 1.0},
    {'lat': 27.7340, 'lng': 85.3390, 'bat': 60, 'spd': 0, 'min': 1.5},
    {'lat': 27.7340, 'lng': 85.3390, 'bat': 60, 'spd': 0, 'min': 2.0},
    {'lat': 27.7340, 'lng': 85.3390, 'bat': 61, 'spd': 0, 'min': 2.5},
    {'lat': 27.7340, 'lng': 85.3390, 'bat': 61, 'spd': 0, 'min': 3.0},
    {'lat': 27.7340, 'lng': 85.3390, 'bat': 61, 'spd': 0, 'min': 3.5},
    {'lat': 27.7340, 'lng': 85.3390, 'bat': 62, 'spd': 0, 'min': 4.0},
    {'lat': 27.7340, 'lng': 85.3390, 'bat': 62, 'spd': 0, 'min': 4.5},
    {'lat': 27.7340, 'lng': 85.3390, 'bat': 62, 'spd': 0, 'min': 5.0},
    {'lat': 27.7340, 'lng': 85.3390, 'bat': 63, 'spd': 0, 'min': 5.5},
    {'lat': 27.7340, 'lng': 85.3390, 'bat': 63, 'spd': 0, 'min': 6.0},
    {'lat': 27.7340, 'lng': 85.3390, 'bat': 63, 'spd': 0, 'min': 6.5},
    {'lat': 27.7340, 'lng': 85.3390, 'bat': 63, 'spd': 0, 'min': 7.0},
    {'lat': 27.7340, 'lng': 85.3390, 'bat': 63, 'spd': 0, 'min': 7.5},
    // Resume
    {'lat': 27.7345, 'lng': 85.3395, 'bat': 63, 'spd': 5, 'min': 8.0},
    {'lat': 27.7350, 'lng': 85.3400, 'bat': 64, 'spd': 6, 'min': 8.5},
    {'lat': 27.7360, 'lng': 85.3410, 'bat': 64, 'spd': 8, 'min': 9.0},
  ], endBat: 64);

  // 📅 d2_morning — battery 22%→18%, 0 stops (clean drive)
  await _seedTrip(col, driverId, 'd2_morning', now.subtract(const Duration(hours: 3)), [
    {'lat': 27.7100, 'lng': 85.3100, 'bat': 22, 'spd': 15, 'min': 0.0},
    {'lat': 27.7110, 'lng': 85.3110, 'bat': 21, 'spd': 18, 'min': 0.5},
    {'lat': 27.7120, 'lng': 85.3120, 'bat': 21, 'spd': 20, 'min': 1.0},
    {'lat': 27.7130, 'lng': 85.3130, 'bat': 20, 'spd': 22, 'min': 1.5},
    {'lat': 27.7140, 'lng': 85.3145, 'bat': 20, 'spd': 19, 'min': 2.0},
    {'lat': 27.7150, 'lng': 85.3155, 'bat': 19, 'spd': 21, 'min': 2.5},
    {'lat': 27.7160, 'lng': 85.3160, 'bat': 18, 'spd': 18, 'min': 3.0},
  ], endBat: 18);

  // 📅 d2_afternoon — battery 77%→61%, 1 stop (1.5h)
  await _seedTrip(col, driverId, 'd2_afternoon', now.subtract(const Duration(hours: 1)), [
    {'lat': 27.7000, 'lng': 85.3000, 'bat': 77, 'spd': 45, 'min': 0.0},
    {'lat': 27.7030, 'lng': 85.3035, 'bat': 76, 'spd': 50, 'min': 0.5},
    {'lat': 27.7060, 'lng': 85.3070, 'bat': 75, 'spd': 55, 'min': 1.0},
    // 🛑 90 min stop
    {'lat': 27.7120, 'lng': 85.3140, 'bat': 74, 'spd': 0, 'min': 1.5},
    {'lat': 27.7120, 'lng': 85.3140, 'bat': 73, 'spd': 0, 'min': 16.5},
    {'lat': 27.7120, 'lng': 85.3140, 'bat': 72, 'spd': 0, 'min': 31.5},
    {'lat': 27.7120, 'lng': 85.3140, 'bat': 70, 'spd': 0, 'min': 61.5},
    {'lat': 27.7120, 'lng': 85.3140, 'bat': 68, 'spd': 0, 'min': 91.5},
    // Resume
    {'lat': 27.7150, 'lng': 85.3180, 'bat': 66, 'spd': 42, 'min': 92.0},
    {'lat': 27.7180, 'lng': 85.3210, 'bat': 64, 'spd': 40, 'min': 92.5},
    {'lat': 27.7240, 'lng': 85.3280, 'bat': 61, 'spd': 35, 'min': 93.0},
  ], endBat: 61);

  // 📅 d3_long — battery 44%→38%, 2 stops (2m + 5m)
  await _seedTrip(col, driverId, 'd3_long', now.subtract(const Duration(days: 3, hours: 10)), [
    {'lat': 27.6900, 'lng': 85.2900, 'bat': 44, 'spd': 25, 'min': 0.0},
    {'lat': 27.6910, 'lng': 85.2910, 'bat': 44, 'spd': 26, 'min': 0.5},
    // 🛑 Stop 1: 2 min
    {'lat': 27.6920, 'lng': 85.2920, 'bat': 43, 'spd': 0, 'min': 1.0},
    {'lat': 27.6920, 'lng': 85.2920, 'bat': 43, 'spd': 0, 'min': 1.5},
    {'lat': 27.6920, 'lng': 85.2920, 'bat': 43, 'spd': 0, 'min': 2.0},
    {'lat': 27.6920, 'lng': 85.2920, 'bat': 42, 'spd': 0, 'min': 2.5},
    // Drive
    {'lat': 27.6930, 'lng': 85.2935, 'bat': 42, 'spd': 28, 'min': 3.0},
    {'lat': 27.6940, 'lng': 85.2950, 'bat': 41, 'spd': 30, 'min': 3.5},
    // 🛑 Stop 2: 5 min
    {'lat': 27.6980, 'lng': 85.3000, 'bat': 41, 'spd': 0, 'min': 4.0},
    {'lat': 27.6980, 'lng': 85.3000, 'bat': 41, 'spd': 0, 'min': 4.5},
    {'lat': 27.6980, 'lng': 85.3000, 'bat': 40, 'spd': 0, 'min': 5.0},
    {'lat': 27.6980, 'lng': 85.3000, 'bat': 40, 'spd': 0, 'min': 5.5},
    {'lat': 27.6980, 'lng': 85.3000, 'bat': 40, 'spd': 0, 'min': 6.0},
    {'lat': 27.6980, 'lng': 85.3000, 'bat': 40, 'spd': 0, 'min': 6.5},
    {'lat': 27.6980, 'lng': 85.3000, 'bat': 39, 'spd': 0, 'min': 7.0},
    {'lat': 27.6980, 'lng': 85.3000, 'bat': 39, 'spd': 0, 'min': 7.5},
    {'lat': 27.6980, 'lng': 85.3000, 'bat': 39, 'spd': 0, 'min': 8.0},
    {'lat': 27.6980, 'lng': 85.3000, 'bat': 39, 'spd': 0, 'min': 8.5},
    // Drive to end
    {'lat': 27.6990, 'lng': 85.3010, 'bat': 39, 'spd': 29, 'min': 9.0},
    {'lat': 27.7020, 'lng': 85.3050, 'bat': 38, 'spd': 28, 'min': 9.5},
    {'lat': 27.7050, 'lng': 85.3080, 'bat': 38, 'spd': 22, 'min': 10.0},
  ], endBat: 38);

  // 🧪 gap_test — battery 11%→7%, 1 gap-detected stop
  await _seedTrip(col, driverId, 'gap_test', now.subtract(const Duration(minutes: 30)), [
    {'lat': 27.7100, 'lng': 85.3100, 'bat': 11, 'spd': 30, 'min': 0.0},
    {'lat': 27.7110, 'lng': 85.3110, 'bat': 10, 'spd': 28, 'min': 0.5},
    // 🤫 2-min gap
    {'lat': 27.7140, 'lng': 85.3140, 'bat': 9,  'spd': 25, 'min': 2.5},
    {'lat': 27.7150, 'lng': 85.3150, 'bat': 8,  'spd': 27, 'min': 3.0},
    {'lat': 27.7160, 'lng': 85.3160, 'bat': 7,  'spd': 24, 'min': 3.5},
  ], endBat: 7);

  // 🚫 zero_dist — battery 48%→47%, 0 km trip
  await _seedTrip(col, driverId, 'zero_dist', now.subtract(const Duration(minutes: 15)), [
    {'lat': 27.7150, 'lng': 85.3250, 'bat': 48, 'spd': 0, 'min': 0.0},
    {'lat': 27.7150, 'lng': 85.3250, 'bat': 48, 'spd': 0, 'min': 0.5},
    {'lat': 27.7150, 'lng': 85.3250, 'bat': 47, 'spd': 0, 'min': 1.0},
    {'lat': 27.7150, 'lng': 85.3250, 'bat': 47, 'spd': 0, 'min': 1.5},
    {'lat': 27.7150, 'lng': 85.3250, 'bat': 47, 'spd': 0, 'min': 2.0},
  ], endBat: 47);

  print('✅ Seeded 8 trips — each with unique battery range for easy identification:');
  print('   d1_morning:  55%→50% | 1 stop (3m)');
  print('   zigzag_trip: 33%→28% | 0 stops (traffic ignored)');
  print('   d1_evening:  60%→64% | 1 stop (12m, charging)');
  print('   d2_morning:  22%→18% | 0 stops (clean drive)');
  print('   d2_afternoon:77%→61% | 1 stop (1.5h)');
  print('   d3_long:     44%→38% | 2 stops (2m + 5m)');
  print('   gap_test:    11%→7%  | 1 gap-detected stop');
  print('   zero_dist:   48%→47% | 0 km trip');
}
Future<void> _seedTrip(
    CollectionReference col,
    String driverId,
    String sessionId,
    DateTime start,
    List<Map<String, dynamic>> points,
    {required int endBat}
    ) async {

  for (int i = 0; i < points.length; i++) {
    final p = points[i];

    final lat = (p['lat'] as num).toDouble();
    final lng = (p['lng'] as num).toDouble();
    final speed = (p['spd'] as num).toDouble();
    final battery = (p['bat'] as num).toInt();

    // ✅ FIX: Use seconds to preserve 30s intervals
    final minuteOffset = (p['min'] as num).toDouble();
    final secondsOffset = (minuteOffset * 60).toInt(); // 0.5 min → 30 seconds
    final timestamp = start.add(Duration(seconds: secondsOffset));

    await col.add({
      'driver_id': driverId,
      'session_id': sessionId,
      'timestamp': Timestamp.fromDate(timestamp),
      'location': GeoPoint(lat, lng),
      'speed_kmh': speed,
      'battery_level': battery,
      'battery_status': battery > 80 ? 'charging' : 'discharging',
      'is_tracking_active': i != points.length - 1,
    });
  }
}