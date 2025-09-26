import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

import '../services/location_service.dart';
import '../widgets/current_map.dart';
import '../widgets/location_info_card.dart';
import '../widgets/osm_search_bar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final LocationService _locationService = LocationService();
  final _osmCtrl = TextEditingController();

  Position? _currentPosition;
  String currentAddress = "";
  GoogleMapController? mapController;
  Set<Marker> markers = {};

  @override
  void initState() {
    super.initState();
    getCurrentLocation();
  }

  // ================= Giữ nguyên tên hàm =================
  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    addMarker();
  }

  void addMarker() {
    if (_currentPosition == null) return;

    final marker = Marker(
      markerId: const MarkerId('currentLocation'),
      position: LatLng(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      ),
      infoWindow: InfoWindow(
        title: 'Current Location',
        snippet: currentAddress,
      ),
      // Tuỳ chọn: cho phép kéo để chọn vị trí thủ công
      draggable: true,
      onDragEnd: (pos) async {
        setState(() {
          _currentPosition = Position(
            latitude: pos.latitude,
            longitude: pos.longitude,
            timestamp: DateTime.now(),
            accuracy: 0,
            altitude: 0,
            heading: 0,
            speed: 0,
            speedAccuracy: 0,
            altitudeAccuracy: 0,
            headingAccuracy: 0,
          );
        });
        await getAddressFromLatLng();
        addMarker(); // cập nhật lại infoWindow
      },
    );

    setState(() {
      markers
        ..clear()
        ..add(marker);
    });
  }

  Future<void> getCurrentLocation() async {
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

      // cập nhật địa chỉ hiện tại
      await getAddressFromLatLng();

      if (mapController != null) {
        await mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(position.latitude, position.longitude),
              zoom: 15,
            ),
          ),
        );
      }
      addMarker();
    } catch (e) {
      // ignore: avoid_print
      print(e);
    }
  }

  Future<void> getAddressFromLatLng() async {
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
  // ======================================================

  // Khi người dùng chọn 1 gợi ý từ OSM Nominatim
  Future<void> _onOsmPicked(double lat, double lon, String label) async {
    final target = LatLng(lat, lon);

    // Cập nhật _currentPosition để tái dùng getAddressFromLatLng + addMarker
    setState(() {
      _currentPosition = Position(
        latitude: lat,
        longitude: lon,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );
      // Tạm gán nhãn OSM để hiển thị ngay
      currentAddress = label;
    });

    await mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: target, zoom: 15),
      ),
    );

    addMarker();

    // (Tuỳ chọn) Chuẩn hoá địa chỉ bằng reverse geocode của bạn
    await getAddressFromLatLng();

    // Ẩn bàn phím
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final hasPosition = _currentPosition != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Google Maps Integration')),
      body: Stack(
        children: [
          Column(
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

          // Ô tìm kiếm OSM nổi phía trên bản đồ
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: OsmSearchBar(
              controller: _osmCtrl,
              onPick: _onOsmPicked,
            ),
          ),
        ],
      ),
    );
  }
}
