import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../model/route_ping_model.dart';
import '../model/trip_summary_model.dart';

class TrackingRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String _collection = 'driver_route_log';

  // Write a single GPS ping directly to Firestore
  Future<void> logRoutePing(RoutePing ping) async {
    try {
      await _firestore.collection(_collection).add(ping.toMap());
    } catch (e) {
      print(' Route log failed: $e');
    }
  }

  // Fetch trip history grouped by session
  Future<List<TripSummary>> getTripHistory(String driverId, {DateTime? startDate, DateTime? endDate}) async {
    var query = FirebaseFirestore.instance
        .collection('driver_route_log')
        .where('driver_id', isEqualTo: driverId)
        .orderBy('timestamp', descending: false);

    if (startDate != null) {
      query = query.where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }
    if (endDate != null) {
      query = query.where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
    }

    final snapshot = await query.get();

    // Group pings by session_id
    final sessions = <String, List<dynamic>>{};
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final sessionId = data['session_id'] as String;
      sessions.putIfAbsent(sessionId, () => []).add(data);
    }

    // Filter to only completed trips
    final completedSessions = sessions.entries.where((entry) {
      final pings = entry.value;
      if (pings.isEmpty) return false;
      pings.sort((a, b) => (a['timestamp'] as Timestamp).compareTo(b['timestamp'] as Timestamp));
      return pings.last['is_tracking_active'] == false;
    }).toList();

    // Fetch driver name
    String driverName = 'Driver';
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(driverId).get();
      if (userDoc.exists && userDoc.data()?['displayName'] != null) {
        driverName = userDoc.data()!['displayName'];
      } else {
        final user = _auth.currentUser;
        if (user?.displayName != null) driverName = user!.displayName!;
      }
    } catch (_) {}

    // Build TripSummary objects
    final trips = <TripSummary>[];
    for (final entry in completedSessions) {
      try {
        trips.add(TripSummary.fromPings(entry.value, driverName));
      } catch (e) {
        print('Failed to parse session ${entry.key}: $e');
      }
    }

    trips.sort((a, b) => b.startTime.compareTo(a.startTime));
    return trips;
  }

  // Stream route data for live admin view
  Stream<QuerySnapshot> getRouteStream(String sessionId) {
    return _firestore
        .collection(_collection)
        .where('session_id', isEqualTo: sessionId)
        .orderBy('timestamp', descending: false)
        .snapshots();
  }
}