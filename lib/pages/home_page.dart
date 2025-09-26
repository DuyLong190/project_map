import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

import '../services/location_service.dart';
import '../widgets/current_map.dart';
import '../widgets/location_info_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final LocationService _locationService = LocationService();

  Position? _currentPosition;
  String currentAddress = "";
  GoogleMapController? mapController;
  Set<Marker> markers = {};

  @override
  void initState() {
    super.initState();
    getCurrentLocation();
  }

  // ————— Giữ nguyên tên hàm —————

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    addMarker();
  }

  void addMarker() {
    if (_currentPosition == null) return;

    setState(() {
      markers.clear();
      markers.add(
        Marker(
          markerId: const MarkerId('currentLocation'),
          position: LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          infoWindow: InfoWindow(
            title: 'Current Location',
            snippet: currentAddress,
          ),
        ),
      );
    });
  }

  void getCurrentLocation() async {
    try {
      final permission = await _locationService.ensurePermission();

      if (permission == LocationPermission.denied) {
        setState(() {
          currentAddress = "Location permissions are denied";
        });
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          currentAddress =
          "Location permissions are permanently denied. Please enable them in Settings.";
        });
        return;
      }

      final position = await _locationService.getCurrentPosition();

      setState(() {
        _currentPosition = position;
      });

      getAddressFromLatLng();

      if (mapController != null) {
        mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(position.latitude, position.longitude),
              zoom: 15,
            ),
          ),
        );
        addMarker();
      }
    } catch (e) {
      // Bạn có thể show SnackBar thay vì print
      // ignore: avoid_print
      print(e);
    }
  }

  void getAddressFromLatLng() async {
    try {
      if (_currentPosition == null) return;

      final address = await _locationService.reverseGeocode(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );

      setState(() {
        currentAddress = address;
      });
    } catch (e) {
      // ignore: avoid_print
      print(e);
    }
  }

  // ————— UI —————
  @override
  Widget build(BuildContext context) {
    final hasPosition = _currentPosition != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Google Maps Integration')),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: !hasPosition
                ? const Center(child: CircularProgressIndicator())
                : CurrentMap(
              onMapCreated: _onMapCreated,
              initialTarget: LatLng(
                _currentPosition!.latitude,
                _currentPosition!.longitude,
              ),
              markers: markers,
            ),
          ),
          Expanded(
            child: LocationInfoCard(
              title: 'CURRENT LOCATION',
              address: currentAddress,
              onRefresh: getCurrentLocation,
            ),
          ),
        ],
      ),
    );
  }
}
