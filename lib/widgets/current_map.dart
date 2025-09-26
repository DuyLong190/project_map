import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class CurrentMap extends StatelessWidget {
  final void Function(GoogleMapController) onMapCreated;
  final LatLng initialTarget;
  final Set<Marker> markers;
  final bool myLocationEnabled;
  final bool myLocationButtonEnabled;

  const CurrentMap({
    super.key,
    required this.onMapCreated,
    required this.initialTarget,
    required this.markers,
    this.myLocationEnabled = true,
    this.myLocationButtonEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      onMapCreated: onMapCreated,
      initialCameraPosition: CameraPosition(target: initialTarget, zoom: 15),
      markers: markers,
      myLocationEnabled: myLocationEnabled,
      myLocationButtonEnabled: myLocationButtonEnabled,
    );
  }
}
