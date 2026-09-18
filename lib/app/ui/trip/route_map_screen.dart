import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import '../../model/trip_summary_model.dart';

class RouteMapScreen extends StatefulWidget {
  final TripSummary trip;
  const RouteMapScreen({super.key, required this.trip});

  @override
  State<RouteMapScreen> createState() => _RouteMapScreenState();
}

class _RouteMapScreenState extends State<RouteMapScreen> {
  final mapController = MapController(); // Stable controller

  @override
  Widget build(BuildContext context) {
    //  Sanitize coordinates
    final validPoints = <LatLng>[];
    for (final p in widget.trip.routePoints) {
      final lat = p['lat'] as num?;
      final lng = p['lng'] as num?;

      if (lat == null || lng == null) continue;
      if (!lat.isFinite || !lng.isFinite) continue;
      if (lat == 0.0 && lng == 0.0) continue;
      if (lat < -85.0511 || lat > 85.0511) continue;

      validPoints.add(LatLng(lat.toDouble(), lng.toDouble()));
    }



    if (validPoints.length < 2) {
      return Scaffold(
        appBar: AppBar(title: const Text('Trip Route')),
        body: const Center(child: Text('Not enough valid GPS points to draw route.')),
      );
    }

    final safeCenter = validPoints[validPoints.length ~/ 2];


    return Scaffold(
      appBar: AppBar(
        title: Text('Trip Route • ${DateFormat('MMM d, yyyy').format(widget.trip.startTime)}'),
        actions: [IconButton(icon: const Icon(Icons.share), onPressed: () => _shareTrip(context))],
      ),
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
              mapController: mapController,
              options: MapOptions(
                initialCenter: safeCenter,
                initialZoom: 13,
                //  CRITICAL FIX: Prevents projection NaN crash at extreme zoom-out
                minZoom: 3.0,  // Still shows entire world, but keeps math safe
                maxZoom: 18.0, // Street-level detail
                // Constraint camera to valid world bounds - prevents NAN during extreme gestures
                cameraConstraint: CameraConstraint.contain(
                    bounds: LatLngBounds(
                        const LatLng(-85.0511, -180.0),
                        const LatLng(85.0511, 180.0))),

                //Disable rotation - it's a common source of Nan in flutter_map transforms
                interactionOptions: InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
              ),
              children: [
                //  Clean, modern Cartocdn tiles
                TileLayer(
                  urlTemplate: 'https://tiles.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                  userAgentPackageName: 'com.driver.tracking.app',
                  maxZoom: 19,
                  tileBuilder: (context, widget, tile) => widget,
                ),
                //  Route polyline
                PolylineLayer(
                  polylines: [
                    Polyline(
                      //Fix 4: Re-filter points at render time - double safety net
                      points: validPoints.where((p) =>
                            p.latitude.isFinite &&
                             p.longitude.isFinite
                      ).toList(),
                      color: const Color(0xFF2563EB),
                      strokeWidth: 4.5,
                      borderStrokeWidth: 2,
                      borderColor: Colors.white,
                    ),
                  ],
                ),


                //  Combined Markers Layer (Start, End, + Stops)
                MarkerLayer(
                  markers: [
                    // Start marker
                    Marker(
                      point: validPoints.first,
                      width: 60, height: 60, alignment: Alignment.topCenter,
                      child: _buildMarker(Icons.location_on, Colors.green, 'Start'),
                    ),
                    // End marker
                    Marker(
                      point: validPoints.last,
                      width: 60, height: 60, alignment: Alignment.topCenter,
                      child: _buildMarker(Icons.location_on, Colors.red, 'End'),
                    ),
                    // Stop markers (if any)
                    if (widget.trip.stops.isNotEmpty)
                      ...widget.trip.stops.map((stop) {
                        final mins = stop.duration.inMinutes;
                        final label = mins < 60 ? '${mins}m' : '${(mins/60).toStringAsFixed(1)}h';


                        return Marker(
                          point: LatLng(stop.lat, stop.lng),
                          width: 50, height: 50, alignment: Alignment.topCenter,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade600,
                                  shape: BoxShape.circle,
                                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 3)],
                                ),
                                child: const Icon(Icons.pause_circle_filled, color: Colors.white, size: 16),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 2)],
                                ),
                                child: Text(label,
                                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.orange)),
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),




              ],
            ),
          ),
          _buildStatsFooter(widget.trip),
        ],
      ),
    );
  }

  Widget _buildMarker(IconData icon, Color color, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 3)],
          ),
          child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
        ),
      ],
    );
  }

  Widget _buildStatsFooter(TripSummary trip) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _footerStat('${trip.totalDistanceKm.toStringAsFixed(1)} km', 'Distance'),
          _footerStat(_formatDuration(trip.totalDuration), 'Duration'),
          _footerStat('${trip.avgSpeedKmh.toStringAsFixed(1)} km/h', 'Avg Speed'),
          _footerStat('${trip.batteryDrain.abs()}%', 'Battery'),
        ],
      ),
    );
  }

  Widget _footerStat(String value, String label) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
    ]);
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    return h > 0 ? '${h}h ${m}m' : '${m}m';
  }

  void _shareTrip(BuildContext context) {
    Get.snackbar("Coming Soon", "Share feature will be added in next update",
        snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 2));
  }
}