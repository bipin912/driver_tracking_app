import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../model/trip_summary_model.dart';
import '../repository/tracking_repository.dart';

class TripDashboardController extends GetxController {
  final TrackingRepository _repo = TrackingRepository();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  //Reactive State
  RxList<TripSummary> trips = <TripSummary>[].obs;
  RxBool isLoading = false.obs;
  RxString driverName = 'Driver'.obs;
  RxString dateFilter = 'This Week'.obs;
  Rx<DateTimeRange?> customRange = Rx<DateTimeRange?>(null);
  RxList<String> tripLabels = <String>[].obs;

  //Chart data
  RxList<double> speedData = <double>[].obs;
  RxList<String> timeLabels = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    _loadDriverName();
    ever(dateFilter, (_) => loadTrips()); //Reload when filter changes
    loadTrips();
  }

  //  Fetch name with priority logic (Firestore > Auth > Fallback)
  Future<void> _loadDriverName() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        driverName.value = doc.data()?['displayName'] ?? user.displayName ?? 'Driver';
      } catch (_) {
        driverName.value = user.displayName ?? 'Driver';
      }
    }
  }

  Future<void> loadTrips() async {
    isLoading.value = true;
    try {
      final driverId = _auth.currentUser?.uid;
      if (driverId == null) return;

      DateTime? start, end;
      final now = DateTime.now();

      // Calculate date range based on filter
      switch (dateFilter.value) {
        case 'Today':
          start = DateTime(now.year, now.month, now.day);
          end = now;
          break;
        case 'This Week':
          start = now.subtract(Duration(days: now.weekday - 1));
          start = DateTime(start.year, start.month, start.day);
          end = now;
          break;
        case 'This Month':
          start = DateTime(now.year, now.month, 1);
          end = now;
          break;
        case 'Custom':
          if (customRange.value != null) {
            start = customRange.value!.start;
            end = customRange.value!.end;
          }
          break;
      }

      // Use repository method (handles fetch + group + filter correctly)
      final results = await _repo.getTripHistory(driverId, startDate: start, endDate: end);

      trips.value = results;
      _prepareChartData(results);

    } catch (e) {
      print('Error loading trips: $e');
      Get.snackbar('Error', 'Failed to load trips', snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }
  void _prepareChartData(List<TripSummary> trips) {
    if (trips.isEmpty) {
      speedData.clear();
      timeLabels.clear();
      tripLabels.clear();
      return;
    }

    // trips are sorted newest first, but we want to number them oldest first
    // so trip 1 of the day has no #, trip 2 gets #2, etc.
    final chronological = trips.reversed.toList(); // oldest first

    // Count trips per date in chronological order
    final allTripsPerDate = <String, int>{};
    final chronologicalLabels = chronological.map((t) {
      final dateKey = '${t.startTime.day}/${t.startTime.month}';
      allTripsPerDate[dateKey] = (allTripsPerDate[dateKey] ?? 0) + 1;
      final count = allTripsPerDate[dateKey]!;
      return count == 1 ? dateKey : '$dateKey #$count';
    }).toList();

    // Reverse back to match trips order (newest first)
    tripLabels.value = chronologicalLabels.reversed.toList();

    // Same for chart labels — only valid trips (>0 km)
    final validChronological = chronological.where((t) => t.totalDistanceKm > 0).toList();
    final chartTripsPerDate = <String, int>{};
    final chronologicalTimeLabels = validChronological.map((t) {
      final dateKey = '${t.startTime.day}/${t.startTime.month}';
      chartTripsPerDate[dateKey] = (chartTripsPerDate[dateKey] ?? 0) + 1;
      final count = chartTripsPerDate[dateKey]!;
      return count == 1 ? dateKey : '$dateKey #$count';
    }).toList();

    // Chart shows oldest→newest (left to right), so keep chronological order
    timeLabels.value = chronologicalTimeLabels;
    speedData.value = validChronological.map((t) => t.totalDistanceKm).toList();
  }


  void setCustomDateRange(DateTimeRange range) {
    customRange.value = range;
    dateFilter.value = 'Custom';
    loadTrips();
  }

  String formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes % 60;
    return '${hours}h ${minutes}m';
  }
}