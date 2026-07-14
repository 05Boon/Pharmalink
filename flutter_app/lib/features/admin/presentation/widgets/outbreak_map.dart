import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import '../../models/outbreak_analytic_model.dart';

class OutbreakMap extends StatelessWidget {
  final List<OutbreakAnalytic> outbreaks;
  final MapController mapController;

  const OutbreakMap({
    super.key,
    required this.outbreaks,
    required this.mapController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 350,
      decoration: BoxDecoration(
        color: const Color(0xFFF1EFEA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0x80B4B2A9)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: FlutterMap(
          mapController: mapController,
          options: const MapOptions(
            initialCenter: LatLng(-4.04, 39.68), // Mombasa center coordinate
            initialZoom: 10.0,
            maxZoom: 18.0,
            minZoom: 2.0,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.pharmalink.app',
            ),
            MarkerClusterLayerWidget(
              options: MarkerClusterLayerOptions(
                maxClusterRadius: 45,
                markers: outbreaks.map((o) {
                  return Marker(
                    key: ValueKey(o),
                    point: LatLng(o.centroidLatitude, o.centroidLongitude),
                    width: 40,
                    height: 40,
                    child: Tooltip(
                      message: 'Detected Anomaly Signal\nDrug: ${o.requestedDrug}\nFrequency: ${o.requestFrequency}\nRegion: ${o.regionName}',
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A18).withAlpha(230),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      textStyle: const TextStyle(color: Colors.white, fontSize: 10),
                      child: GestureDetector(
                        onTap: () {
                          // Focus on tapped marker
                          mapController.move(
                            LatLng(o.centroidLatitude, o.centroidLongitude),
                            13.0,
                          );
                        },
                        child: const Icon(
                          Icons.location_on,
                          color: Color(0xFFB91C1C),
                          size: 32,
                        ),
                      ),
                    ),
                  );
                }).toList(),
                builder: (context, markers) {
                  int totalFrequency = 0;
                  final Set<String> drugs = {};
                  final Set<String> regions = {};

                  for (final marker in markers) {
                    if (marker.key is ValueKey<OutbreakAnalytic>) {
                      final data = (marker.key as ValueKey<OutbreakAnalytic>).value;
                      totalFrequency += data.requestFrequency;
                      drugs.add(data.requestedDrug);
                      regions.add(data.regionName);
                    }
                  }

                  final drugPreview = drugs.take(2).join(', ') + (drugs.length > 2 ? '...' : '');
                  final regionPreview = regions.take(2).join(', ') + (regions.length > 2 ? '...' : '');

                  return Tooltip(
                    message: 'Detected Anomaly Signal\nDrugs: $drugPreview\nAggregate Frequency: $totalFrequency\nRegion: $regionPreview',
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A18).withAlpha(230),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    textStyle: const TextStyle(color: Colors.white, fontSize: 10),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: const Color(0xFFB91C1C),
                      ),
                      child: Center(
                        child: Text(
                          markers.length.toString(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
