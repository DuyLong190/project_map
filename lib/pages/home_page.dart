import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../services/location_service.dart';
import '../widgets/current_map.dart';
import '../widgets/location_info_card.dart';
import '../widgets/osm_search_bar.dart';

enum RouteProfile { driving, walking, cycling }

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final LocationService _locationService = LocationService();

  // Map state
  GoogleMapController? mapController;
  Position? _currentPosition;
  String currentAddress = "";
  Set<Marker> markers = {};
  Set<Polyline> polylines = {};

  // Step 1: search B (đích)
  final _searchBCtrl = TextEditingController();
  LatLng? _pickedB;
  String? _pickedBLabel;

  // Step 2: form chọn A/B
  final _startCtrl = TextEditingController();
  final _destCtrl  = TextEditingController();
  LatLng? _A;
  LatLng? _B;

  // Step 3: routes & mode
  RouteProfile _profile = RouteProfile.driving;
  List<_RouteOption> _routes = [];
  int _selectedRouteIdx = 0;

  @override
  void initState() {
    super.initState();
    getCurrentLocation();
  }

  // ============ Vị trí hiện tại + marker ============
  Future<void> getCurrentLocation() async {
    try {
      final permission = await _locationService.ensurePermission();

      if (permission == LocationPermission.denied) {
        setState(() => currentAddress = "Location permissions are denied");
        return;
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() => currentAddress =
        "Location permissions are permanently denied. Please enable them in Settings.");
        return;
      }

      final position = await _locationService.getCurrentPosition();
      setState(() => _currentPosition = position);

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
      _addCurrentMarker();
    } catch (e) {
      // ignore: avoid_print
      print(e);
    }
  }

  Future<void> getAddressFromLatLng() async {
    try {
      if (_currentPosition == null) return;
      final address = await _locationService.reverseGeocode(
        _currentPosition!.latitude, _currentPosition!.longitude,
      );
      setState(() => currentAddress = address);
    } catch (e) {
      // ignore: avoid_print
      print(e);
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    _addCurrentMarker();
  }

  void _addCurrentMarker() {
    if (_currentPosition == null) return;
    final marker = Marker(
      markerId: const MarkerId('current'),
      position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
      infoWindow: InfoWindow(title: 'Current Location', snippet: currentAddress),
      draggable: true,
      onDragEnd: (pos) async {
        setState(() {
          _currentPosition = Position(
            latitude: pos.latitude, longitude: pos.longitude,
            timestamp: DateTime.now(),
            accuracy: 0, altitude: 0, heading: 0, speed: 0, speedAccuracy: 0,
            altitudeAccuracy: 0, headingAccuracy: 0,
          );
        });
        await getAddressFromLatLng();
        _addCurrentMarker();
      },
    );
    setState(() {
      markers..removeWhere((m) => m.markerId.value == 'current')..add(marker);
    });
  }

  // ============ STEP 1: nhận B từ OsmSearchBar ============
  Future<void> _onPickB(double lat, double lon, String label) async {
    final b = LatLng(lat, lon);
    setState(() {
      _pickedB = b;
      _pickedBLabel = label;
    });
    await mapController?.animateCamera(
      CameraUpdate.newCameraPosition(CameraPosition(target: b, zoom: 15)),
    );
    // đánh dấu nhẹ
    markers
      ..removeWhere((m) => m.markerId.value == 'dest_preview')
      ..add(Marker(
        markerId: const MarkerId('dest_preview'),
        position: b,
        infoWindow: InfoWindow(title: 'Điểm đến (B)', snippet: label),
      ));
    setState(() {}); // refresh
  }

  // ============ STEP 2: mở form chọn A/B ============
  void _openABForm() {
    if (_pickedB == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập điểm đến trước')),
      );
      return;
    }
    // mặc định điền B như bước 1
    _destCtrl.text = _pickedBLabel ?? '';
    _B = _pickedB;

    // show bottom sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16, right: 16, top: 16,
        ),
        child: _ABForm(
          startCtrl: _startCtrl,
          destCtrl: _destCtrl,
          onPickStart: (lat, lon, label) {
            _A = LatLng(lat, lon);
            _startCtrl.text = label;
          },
          onPickDest: (lat, lon, label) {
            _B = LatLng(lat, lon);
            _destCtrl.text = label;
          },
          onUseMyLocation: () async {
            final pos = await _locationService.getCurrentPosition();
            _A = LatLng(pos.latitude, pos.longitude);
            _startCtrl.text = 'Vị trí của bạn';
          },
          onFindRoutes: () async {
            Navigator.of(context).pop(); // đóng form
            if (_A == null || _B == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chưa chọn đủ điểm A và B')),
              );
              return;
            }
            await _loadRoutesAndShow();
          },
        ),
      ),
    );
  }

  // ============ STEP 3: gọi OSRM lấy tối đa 3 tuyến ============
  Future<void> _loadRoutesAndShow() async {
    try {
      final profileStr = switch (_profile) {
        RouteProfile.walking => 'walking',
        RouteProfile.cycling => 'cycling',
        _ => 'driving',
      };

      final url = Uri.parse(
          'https://router.project-osrm.org/route/v1/$profileStr/'
              '${_A!.longitude},${_A!.latitude};${_B!.longitude},${_B!.latitude}'
              '?overview=full&geometries=geojson&alternatives=true&steps=false'
      );

      final res = await http.get(url, headers: const {
        'User-Agent': 'your-app-name/1.0 (contact: you@example.com)',
        'Accept': 'application/json; charset=utf-8',
      });
      if (res.statusCode != 200) {
        throw 'Route API error ${res.statusCode}';
      }

      final data = jsonDecode(utf8.decode(res.bodyBytes));
      final routes = (data['routes'] as List?) ?? [];
      if (routes.isEmpty) throw 'Không tìm thấy tuyến đường';

      // parse thành RouteOption
      final opts = <_RouteOption>[];
      for (final r in routes.take(3)) {
        final coords = (r['geometry']['coordinates'] as List)
            .cast<List>()
            .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
            .toList();
        final dist = (r['distance'] as num).toDouble(); // mét
        final dur  = (r['duration'] as num).toDouble(); // giây
        opts.add(_RouteOption(points: coords, distanceM: dist, durationS: dur));
      }

      // chọn tuyến ngắn nhất theo distance
      opts.sort((a,b) => a.distanceM.compareTo(b.distanceM));
      setState(() {
        _routes = opts;
        _selectedRouteIdx = 0;
      });

      _renderSelectedRoute();

      // đưa camera bao trùm
      await mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng((_A!.latitude + _B!.latitude) / 2,
              (_A!.longitude + _B!.longitude) / 2),
          12,
        ),
      );

      // mở panel chọn tuyến + mode
      _openRoutesPanel();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi lấy tuyến: $e')),
      );
    }
  }

  void _renderSelectedRoute() {
    if (_routes.isEmpty) return;
    final sel = _routes[_selectedRouteIdx];

    final poly = Polyline(
      polylineId: const PolylineId('route_selected'),
      points: sel.points,
      width: 6,
      geodesic: true,
    );
    final a = Marker(
      markerId: const MarkerId('A'),
      position: _A!,
      infoWindow: const InfoWindow(title: 'A (Vị trí bắt đầu)'),
    );
    final b = Marker(
      markerId: const MarkerId('B'),
      position: _B!,
      infoWindow: const InfoWindow(title: 'B (Điểm đến)'),
    );

    setState(() {
      polylines = {poly};
      markers
        ..removeWhere((m) => true)
        ..addAll({a, b});
    });
  }

  void _openRoutesPanel() {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            final items = List.generate(_routes.length, (i) {
              final r = _routes[i];
              final km = (r.distanceM / 1000).toStringAsFixed(1);
              final min = (r.durationS / 60).round();
              final isBest = i == 0;
              final isSel  = i == _selectedRouteIdx;
              return ListTile(
                leading: Icon(isBest ? Icons.star : Icons.alt_route),
                title: Text('${km} km • ${min} phút'),
                subtitle: isBest ? const Text('Tuyến ngắn nhất') : null,
                selected: isSel,
                onTap: () {
                  setLocal(() => _selectedRouteIdx = i);
                  _renderSelectedRoute();
                },
              );
            });

            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Chọn mode
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                    child: Row(
                      children: [
                        const Text('Chế độ:  '),
                        SegmentedButton<RouteProfile>(
                          segments: const [
                            ButtonSegment(value: RouteProfile.driving, label: Text('Ô tô'), icon: Icon(Icons.directions_car)),
                            ButtonSegment(value: RouteProfile.walking, label: Text('Đi bộ'), icon: Icon(Icons.directions_walk)),
                            ButtonSegment(value: RouteProfile.cycling, label: Text('Xe đạp'), icon: Icon(Icons.pedal_bike)),
                          ],
                          selected: {_profile},
                          onSelectionChanged: (s) async {
                            setState(() => _profile = s.first);
                            Navigator.of(context).pop();
                            await _loadRoutesAndShow(); // nạp lại 3 tuyến theo mode mới
                          },
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  ...items,
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ============ UI ============
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
                  polylines: polylines,
                ),
              ),
              // Panel thông tin + Step 1 kết quả
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('CURRENT LOCATION', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 6),
                      Text(currentAddress),
                      const SizedBox(height: 12),
                      if (_pickedBLabel != null) ...[
                        const Divider(),
                        Text('Điểm đến (B):', style: Theme.of(context).textTheme.titleMedium),
                        Text(_pickedBLabel!, maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: _openABForm,
                          icon: const Icon(Icons.directions),
                          label: const Text('Đường đi'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Ô search B nằm nổi trên map
          Positioned(
            top: 12, left: 12, right: 12,
            child: OsmSearchBar(controller: _searchBCtrl, onPick: _onPickB),
          ),
        ],
      ),
    );
  }
}

// ======= Model tuyến =======
class _RouteOption {
  final List<LatLng> points;
  final double distanceM;
  final double durationS;
  _RouteOption({required this.points, required this.distanceM, required this.durationS});
}

// ======= BottomSheet chọn A/B =======
class _ABForm extends StatelessWidget {
  final TextEditingController startCtrl;
  final TextEditingController destCtrl;
  final void Function(double, double, String) onPickStart;
  final void Function(double, double, String) onPickDest;
  final Future<void> Function() onUseMyLocation;
  final Future<void> Function() onFindRoutes;

  const _ABForm({
    required this.startCtrl,
    required this.destCtrl,
    required this.onPickStart,
    required this.onPickDest,
    required this.onUseMyLocation,
    required this.onFindRoutes,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Chọn điểm bắt đầu & điểm đến', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),

            // A: Vị trí bắt đầu
            const Text('Vị trí bắt đầu (A)'),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: OsmSearchBar(
                    controller: startCtrl,
                    onPick: onPickStart,
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: onUseMyLocation,
                  icon: const Icon(Icons.my_location),
                  label: const Text('Vị trí của bạn'),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // B: Điểm đến
            const Text('Điểm đến (B)'),
            const SizedBox(height: 6),
            OsmSearchBar(
              controller: destCtrl,
              onPick: onPickDest,
            ),

            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onFindRoutes,
              icon: const Icon(Icons.alt_route),
              label: const Text('Tìm tuyến'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
