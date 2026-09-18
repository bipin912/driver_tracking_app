import 'package:driver_tracking_app/app/ui/trip/route_map_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../controller/trip_dashboard_controller.dart';
import '../../model/trip_summary_model.dart';

class TripDashboardScreen extends StatelessWidget {
  const TripDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(TripDashboardController());

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Trip Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showDateFilterDialog(ctrl),
          ),
        ],
      ),
      body: Obx(() {
        if (ctrl.isLoading.value && ctrl.trips.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return DefaultTabController(
          length: 2,
          child: Column(
            children: [
              TabBar(
                tabs: const [Tab(text: 'Analytics'), Tab(text: 'History')],
                labelColor: Colors.green,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.green,
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    //  TAB 1: Analytics
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildStatsHeader(ctrl),
                          const SizedBox(height: 24),
                          _buildDistanceChart(ctrl),
                          const SizedBox(height: 24),
                          _buildBatteryChart(ctrl),
                        ],
                      ),
                    ),
                    // TAB 2: History
                    ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: ctrl.trips.length,
                      itemBuilder: (context, index) => _buildTripCard(
                          ctrl.trips[index],
                        ctrl,
                        index,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  //  Stats Header
  Widget _buildStatsHeader(TripDashboardController ctrl) {
    final totalTrips = ctrl.trips.length;
    final totalDistance = ctrl.trips.fold(0.0, (sum, t) => sum + t.totalDistanceKm);
    final totalDuration = ctrl.trips.fold(Duration.zero, (sum, t) => sum + t.totalDuration);
    final avgSpeed = ctrl.trips.isNotEmpty
        ? ctrl.trips.map((t) => t.avgSpeedKmh).reduce((a, b) => a + b) / totalTrips
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(() => Text(
            'Hello, ${ctrl.driverName.value}!',
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          )),
          const Text('Here\'s your driving summary', style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statCard('Trips', '$totalTrips', Icons.directions_car),
              _statCard('Distance', '${totalDistance.toStringAsFixed(1)} km', Icons.map),
              _statCard('Duration', ctrl.formatDuration(totalDuration), Icons.timer),
              _statCard('Avg Speed', '${avgSpeed.toStringAsFixed(1)} km/h', Icons.speed),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }

  //  Distance per Trip Chart (Version-Safe with Overlay)
  Widget _buildDistanceChart(TripDashboardController ctrl) {
    //  Filter out 0 km trips
    final filteredTrips = ctrl.trips.reversed
        .where((t) => t.totalDistanceKm > 0)
        .toList();
    final filteredValues = filteredTrips.map((t) => t.totalDistanceKm).toList();


    if (filteredValues.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Distance per Trip', style: Theme.of(Get.context!).textTheme.titleMedium),
            const SizedBox(height: 16),
            SizedBox(height: 200, child: Center(child: Text('No trips with distance > 0 km', style: TextStyle(color: Colors.grey[500], fontSize: 13)))),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Distance per Trip', style: Theme.of(Get.context!).textTheme.titleMedium),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: (filteredValues.reduce((a, b) => a > b ? a : b) * 1.2)
                    .ceil()
                    .toDouble()
                    .clamp(1.0, 1000.0),
                barGroups: filteredValues.asMap().entries.map((entry) {
                  final km = entry.value;
                  final barColor = km > 5.0
                      ? Colors.red.shade400
                      : km > 1.5
                      ? Colors.orange.shade400
                      : Colors.green.shade400;

                  return BarChartGroupData(
                    x: entry.key,
                    showingTooltipIndicators: [0],
                    barRods: [
                      BarChartRodData(
                        toY: km,
                        color: barColor,
                        width: 22,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ],
                  );
                }).toList(),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true, reservedSize: 30,
                      getTitlesWidget: (value, meta) => Text(
                          '${value.toInt()}', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true, reservedSize: 45,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        final total = ctrl.timeLabels.length;
                        final showLabel = total <= 10
                            || (total <= 10 && index % 2 ==0) // Show every 2nd if 6-10 trips
                            || (total <= 20 && index % 3 == 0)         // Show every 3rd if 11-20 trips
                            || (total > 20 && index % 5 == 0)          // Show every 5th if 21+ trips

                            || index == total - 1;
                        if (!showLabel) return const SizedBox.shrink();

                        // Inside bottomTitles → getTitlesWidget:
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Always show the pre-computed label from controller
                              Text(
                                ctrl.timeLabels[index] ?? '',
                                style: TextStyle(
                                  fontSize: 9,  // Slightly smaller for compactness
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[800],
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: false),
                // OFFICIAL: Always show values perfectly centered above bars
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (group) => Colors.transparent,
                    tooltipPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    tooltipMargin: 10,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${rod.toY.toStringAsFixed(1)}',
                        TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  //  Battery Drain Chart
  Widget _buildBatteryChart(TripDashboardController ctrl) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Battery Drain per Trip', style: Theme.of(Get.context!).textTheme.titleMedium),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: ctrl.trips.isEmpty
                ? Center(child: Text('No data', style: TextStyle(color: Colors.grey[400])))
                : ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: ctrl.trips.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final trip = ctrl.trips[index];
                final rawDrain = trip.batteryDrain;

                String label;
                Color barColor;
                double displayHeight;

                if (rawDrain < 0) {
                  label = '+${rawDrain.abs()}%';
                  barColor = Colors.green.shade400;
                  displayHeight = 80 * (rawDrain.abs() / 100);
                } else if (rawDrain == 0) {
                  label = '0% Stable';
                  barColor = Colors.grey.shade400;
                  displayHeight = 8;
                } else {
                  label = '${rawDrain}%';
                  barColor = rawDrain > 30 ? Colors.red.shade400 : Colors.orange.shade400;
                  displayHeight = 80 * (rawDrain / 100);
                }

                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: barColor)),
                    const SizedBox(height: 4),
                    Container(
                      width: 36,
                      height: displayHeight,
                      decoration: BoxDecoration(
                        color: barColor.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Uses centralized counter labels
                    Text(ctrl.tripLabels[index] ?? '',
                        style: TextStyle(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }





  //  Trip Card - now accepts controller + index for labels
  Widget _buildTripCard(TripSummary trip, TripDashboardController ctrl, int index) {
    final baseDate = DateFormat('MMM d, yyyy').format(trip.startTime);
    final label = ctrl.tripLabels[index] ?? '';
    final displayTitle = label.contains('#')
        ? '$baseDate #${label.split('#')[1].trim()}'
        : baseDate;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        shape: const RoundedRectangleBorder(),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.route, color: Colors.green),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Uses centralized counter labels: " #2", etc.
            Text(displayTitle,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
          ],
        ),
        subtitle: Text(
          '${trip.totalDistanceKm.toStringAsFixed(1)} km • ${_formatDuration(trip.totalDuration)}',
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detailRow('Start', DateFormat('h:mm a').format(trip.startTime)),
                _detailRow('End', DateFormat('h:mm a').format(trip.endTime)),
                _detailRow('Avg Speed', '${trip.avgSpeedKmh.toStringAsFixed(1)} km/h'),
                _detailRow('Max Speed', '${trip.maxSpeedKmh.toStringAsFixed(1)} km/h'),
                _detailRow('Battery', '${trip.startBattery}% → ${trip.endBattery}% (${trip.batteryDrain}%)'),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => Get.to(() => RouteMapScreen(trip: trip)),
                    icon: const Icon(Icons.map, size: 18),
                    label: const Text('View Route on Map'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green,
                      side: const BorderSide(color: Colors.green),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    return h > 0 ? '${h}h ${m}m' : '${m}m';
  }

  //  Date Filter Dialog
  void _showDateFilterDialog(TripDashboardController ctrl) {
    Get.defaultDialog(
      title: 'Filter by Date',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: ['Today', 'This Week', 'This Month', 'Custom']
            .map((label) => RadioListTile(
          title: Text(label),
          value: label,
          groupValue: ctrl.dateFilter.value,
          onChanged: (val) {
            ctrl.dateFilter.value = val!;
            if (val != 'Custom') {
              ctrl.loadTrips();
              Get.back();
            }
          },
        ))
            .toList(),
      ),
      confirm: ElevatedButton(
        onPressed: () async {
          final range = await showDateRangePicker(
            context: Get.context!,
            firstDate: DateTime(2020),
            lastDate: DateTime.now(),
          );
          if (range != null) {
            ctrl.setCustomDateRange(range);
          }
          Get.back();
        },
        child: const Text('Select Custom Range'),
      ),
    );
  }
}