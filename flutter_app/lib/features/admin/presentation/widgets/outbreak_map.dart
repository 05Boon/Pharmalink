import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
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
            MarkerLayer(
              markers: outbreaks.map((o) {
                return Marker(
                  point: LatLng(o.centroidLatitude, o.centroidLongitude),
                  width: 40,
                  height: 40,
                  child: Tooltip(
                    message: '${o.requestedDrug} Outbreak\nFrequency: ${o.requestFrequency}\nCentroid: [${o.centroidLatitude.toStringAsFixed(4)}, ${o.centroidLongitude.toStringAsFixed(4)}]',
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
            ),
          ],
        ),
      ),
    );
  }
}
