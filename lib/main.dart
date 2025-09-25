import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'map/marker_icon_cache.dart';
import 'api/api_service.dart';
import 'map/map_mouse_zoom.dart'; // 👈 import mixin zoom chuột

void main() async {
  await dotenv.load(fileName: ".env");
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with MouseWheelZoomMixin {
  CameraPosition? _lastCameraPosition;
  Position? _currentPosition;
  String? currentAddress;
  String? _errorMessage;
  GoogleMapController? _mapController;
  CameraPosition _initialCamera = const CameraPosition(
    target: LatLng(10.762622, 106.660172),
    zoom: 12,
  );

  final Set<Marker> _markers = {};
  BitmapDescriptor? _meIcon;

  DateTime _lastCameraIdleAt = DateTime.fromMillisecondsSinceEpoch(0);
  Timer? _cameraDebounce;

  final Duration _cameraIdleDebounce = const Duration(milliseconds: 300);
  final int _markerBatchSize = 64;

  bool _isFetching = false;

  @override
  GoogleMapController? get mapController => _mapController;

  @override
  void initState() {
    super.initState();
    _initLocationFlow();
  }

  Future<void> _initLocationFlow() async {
    final hasPermission = await _handleLocationPermission();
    if (!hasPermission) return;
    await getCurrentLocation();
  }

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _errorMessage = 'Dịch vụ vị trí đang tắt.');
      await Geolocator.openLocationSettings();
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _errorMessage = 'Quyền vị trí bị từ chối.');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() => _errorMessage = 'Quyền vị trí bị từ chối vĩnh viễn.');
      await Geolocator.openAppSettings();
      return false;
    }

    setState(() => _errorMessage = null);
    return true;
  }

  Future<void> getCurrentLocation() async {
    if (_isFetching) return;
    setState(() => _isFetching = true);
    try {
      final hasPermission = await _handleLocationPermission();
      if (!hasPermission) return;

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() => _currentPosition = position);
      await getAddressFromLatLng();

      final target = LatLng(position.latitude, position.longitude);
      await _ensureMeIcon();
      _markers
        ..clear()
        ..add(Marker(
          markerId: const MarkerId('me'),
          position: target,
          icon: _meIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: InfoWindow(title: 'Vị trí của tôi', snippet: currentAddress),
        ));
      if (_mapController != null) {
        await _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(CameraPosition(target: target, zoom: 16)),
        );
      }
    } catch (e) {
      setState(() => _errorMessage = 'Lỗi lấy vị trí: $e');
    } finally {
      if (mounted) setState(() => _isFetching = false);
    }
  }

  Future<void> getAddressFromLatLng() async {
    if (_currentPosition == null) return;

    try {
      final addrFromApi = await ApiService.reverseGeocode(
          lat: _currentPosition!.latitude, lng: _currentPosition!.longitude);
      if (addrFromApi != null) {
        setState(() => currentAddress = addrFromApi);
      } else {
        List<Placemark> p = await placemarkFromCoordinates(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        );
        Placemark place = p[0];
        setState(() {
          currentAddress =
          "${place.thoroughfare}, ${place.subThoroughfare}, ${place.name}, ${place.subLocality}";
        });
      }
    } catch (e) {
      setState(() => _errorMessage = 'Lỗi lấy địa chỉ: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text("Location")),
        body: Column(
          children: <Widget>[
            Expanded(
              child: Listener(
                onPointerSignal: onPointerSignal, // 👈 zoom bằng chuột
                child: GoogleMap(
                  initialCameraPosition: _initialCamera,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  buildingsEnabled: false,
                  trafficEnabled: false,
                  indoorViewEnabled: false,
                  liteModeEnabled: defaultTargetPlatform == TargetPlatform.android,
                  markers: _markers,
                  onMapCreated: (c) => _mapController = c,
                  onCameraIdle: _onCameraIdle,
                  onCameraMove: (position) {
                    _lastCameraPosition = position;
                    _debounceCameraIdle();
                  },

                ),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: <Widget>[
                  ElevatedButton(
                    child: Text('Get Location'),
                    onPressed: _isFetching ? null : getCurrentLocation,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _errorMessage ?? (currentAddress ?? 'Chưa có địa chỉ'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: _errorMessage != null ? Colors.red : null),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _isFetching ? null : getCurrentLocation,
          child: Icon(Icons.my_location),
        ),
      ),
    );
  }
}

Future<List<LatLng>> _fakeFetchPointsInViewport(CameraPosition camera) async {
  await Future<void>.delayed(const Duration(milliseconds: 120));
  final center = camera.target;
  return List<LatLng>.generate(120, (i) {
    final dLat = ((i % 12) - 6) * 0.0015;
    final dLng = ((i % 15) - 7) * 0.0015;
    return LatLng(center.latitude + dLat, center.longitude + dLng);
  });
}

extension _MapLogic on _MyAppState {
  void _debounceCameraIdle() {
    _cameraDebounce?.cancel();
    _cameraDebounce = Timer(_cameraIdleDebounce, _onCameraIdle);
  }

  Future<void> _onCameraIdle() async {
    final now = DateTime.now();
    if (now.difference(_lastCameraIdleAt) < const Duration(milliseconds: 200)) return;
    _lastCameraIdleAt = now;
    if (!mounted || _mapController == null) return;
    if (_lastCameraPosition == null) return;

    try {
      final camera = _lastCameraPosition!; // 👈 dùng biến lưu
      final points = await _fakeFetchPointsInViewport(camera);

      final List<Marker> newMarkers = <Marker>[];
      for (final p in points) {
        newMarkers.add(Marker(
          markerId: MarkerId('p_${p.latitude}_${p.longitude}'),
          position: p,
          icon: _meIcon ?? BitmapDescriptor.defaultMarker,
        ));

        if (newMarkers.length % _markerBatchSize == 0) {
          if (!mounted) return;
          setState(() => _markers.addAll(newMarkers));
          newMarkers.clear();
          await Future<void>.delayed(const Duration(milliseconds: 16));
        }
      }
      if (newMarkers.isNotEmpty && mounted) {
        setState(() => _markers.addAll(newMarkers));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Lỗi tải marker: $e');
      }
    }
  }


  Future<void> _ensureMeIcon() async {
    if (_meIcon != null) return;
    try {
      final icon = MarkerIconCache.instance.defaultHue(BitmapDescriptor.hueAzure);
      _meIcon = icon;
    } catch (_) {
      _meIcon = BitmapDescriptor.defaultMarker;
    }
  }
}
