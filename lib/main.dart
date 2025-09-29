import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Position? _currentPosition;
  String currentAddress = "";
  GoogleMapController? mapController;
  Set<Marker> markers = {};
  LatLng? _selectedLocation;

  // Search functionality
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

  // Direction functionality
  LatLng? _startLocation;
  LatLng? _endLocation;
  Set<Polyline> _polylines = {};
  String _routeInfo = '';
  bool _isGettingRoute = false;

  @override
  void initState() {
    super.initState();
    getCurrentLocation();
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    addMarker();
  }

  void addMarker() {
    if (_currentPosition == null) return;
    _updateMarkers();
  }

  void getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            currentAddress = "Location permissions are denied";
          });
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

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
      print(e);
    }
  }

  void getAddressFromLatLng() async {
    try {
      if (_currentPosition == null) return;

      List<Placemark> placemarks = await placemarkFromCoordinates(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );

      Placemark place = placemarks[0];
      setState(() {
        currentAddress =
            "${place.street}, ${place.subLocality}, ${place.locality}, ${place.administrativeArea}, ${place.country}";
      });
    } catch (e) {
      print(e);
    }
  }

  void _handleTap(LatLng tappedPoint) async {
    setState(() {
      _selectedLocation = tappedPoint;
    });

    // Lấy địa chỉ của điểm được chọn
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        tappedPoint.latitude,
        tappedPoint.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          currentAddress =
              "${place.street}, ${place.subLocality}, ${place.locality}, ${place.administrativeArea}, ${place.country}";
        });
      }
    } catch (e) {
      print(e);
    }

    _updateMarkers();
  }

  // Search for places
  Future<void> _searchPlaces(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
      _searchResults.clear();
    });

    try {
      // Sử dụng geocoding để tìm kiếm địa điểm
      List<Location> locations = await locationFromAddress(query);

      if (locations.isNotEmpty) {
        List<Map<String, dynamic>> results = [];

        for (int i = 0; i < locations.length && i < 5; i++) {
          Location location = locations[i];

          // Lấy thông tin địa chỉ chi tiết
          List<Placemark> placemarks = await placemarkFromCoordinates(
            location.latitude,
            location.longitude,
          );

          if (placemarks.isNotEmpty) {
            Placemark place = placemarks[0];
            results.add({
              'name': query,
              'address':
                  "${place.street}, ${place.subLocality}, ${place.locality}, ${place.administrativeArea}, ${place.country}",
              'latitude': location.latitude,
              'longitude': location.longitude,
            });
          }
        }

        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      } else {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
      }
    } catch (e) {
      print('Search error: $e');
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
    }
  }

  // Navigate to searched location
  void _navigateToLocation(double latitude, double longitude, String name) {
    if (mapController == null) return;

    LatLng targetLocation = LatLng(latitude, longitude);

    mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: targetLocation, zoom: 15),
      ),
    );

    // Add marker for searched location
    setState(() {
      markers.clear();
      markers.add(
        Marker(
          markerId: const MarkerId('searched_location'),
          position: targetLocation,
          infoWindow: InfoWindow(title: name),
        ),
      );
    });

    setState(() {
      _selectedLocation = targetLocation;
      currentAddress = name;
    });
  }

  // Set start location
  void _setStartLocation() {
    if (_selectedLocation != null) {
      setState(() {
        _startLocation = _selectedLocation;
        _clearRoute();
      });
      _updateMarkers();
    }
  }

  // Set end location
  void _setEndLocation() {
    if (_selectedLocation != null) {
      setState(() {
        _endLocation = _selectedLocation;
        _clearRoute();
      });
      _updateMarkers();

      // Auto get route if both locations are set
      if (_startLocation != null && _endLocation != null) {
        _getRoute();
      }
    }
  }

  // Clear route
  void _clearRoute() {
    setState(() {
      _polylines.clear();
      _routeInfo = '';
    });
  }

  // Update markers for start/end locations
  void _updateMarkers() {
    setState(() {
      markers.clear();

      // Add current location marker if available
      if (_currentPosition != null) {
        markers.add(
          Marker(
            markerId: const MarkerId('current_location'),
            position: LatLng(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
            ),
            infoWindow: const InfoWindow(title: 'Vị trí hiện tại'),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueBlue,
            ),
          ),
        );
      }

      // Add start location marker
      if (_startLocation != null) {
        markers.add(
          Marker(
            markerId: const MarkerId('start_location'),
            position: _startLocation!,
            infoWindow: const InfoWindow(title: 'Điểm xuất phát'),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            ),
          ),
        );
      }

      // Add end location marker
      if (_endLocation != null) {
        markers.add(
          Marker(
            markerId: const MarkerId('end_location'),
            position: _endLocation!,
            infoWindow: const InfoWindow(title: 'Điểm đến'),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            ),
          ),
        );
      }
    });
  }

  // Get route using OpenRouteService API (free)
  Future<void> _getRoute() async {
    if (_startLocation == null || _endLocation == null) return;

    setState(() {
      _isGettingRoute = true;
      _routeInfo = '';
    });

    try {
      // OSRM API endpoint (free and open source)
      String startLng = _startLocation!.longitude.toString();
      String startLat = _startLocation!.latitude.toString();
      String endLng = _endLocation!.longitude.toString();
      String endLat = _endLocation!.latitude.toString();

      String url =
          'http://router.project-osrm.org/route/v1/driving/$startLng,$startLat;$endLng,$endLat?overview=full&geometries=geojson';

      print('Requesting route from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {'Accept': 'application/json'},
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);

        if (data['routes'] != null && data['routes'].isNotEmpty) {
          List<dynamic> coordinates =
              data['routes'][0]['geometry']['coordinates'];
          List<LatLng> polylineCoordinates = coordinates
              .map((coord) => LatLng(coord[1], coord[0]))
              .toList();

          // Calculate distance and duration
          Map<String, dynamic> route = data['routes'][0];
          double distance = route['distance'] / 1000; // Convert to km
          double duration = route['duration'] / 60; // Convert to minutes

          print(
            'Route found: ${polylineCoordinates.length} points, ${distance}km, ${duration}min',
          );

          setState(() {
            _polylines = {
              Polyline(
                polylineId: const PolylineId('route'),
                points: polylineCoordinates,
                color: Colors.blue,
                width: 5,
              ),
            };

            _routeInfo =
                'Khoảng cách: ${distance.toStringAsFixed(1)} km\n'
                'Thời gian: ${duration.toStringAsFixed(0)} phút';

            _isGettingRoute = false;
          });

          // Fit camera to show entire route
          _fitCameraToRoute(polylineCoordinates);
        } else {
          setState(() {
            _routeInfo = 'Không tìm thấy đường đi';
            _isGettingRoute = false;
          });
        }
      } else {
        setState(() {
          _routeInfo = 'Lỗi API: ${response.statusCode} - ${response.body}';
          _isGettingRoute = false;
        });
      }
    } catch (e) {
      print('Route error: $e');
      // Fallback: create a simple straight line route
      _createSimpleRoute();
    }
  }

  // Create a simple straight line route as fallback
  void _createSimpleRoute() {
    if (_startLocation == null || _endLocation == null) return;

    // Calculate distance between points
    double distance =
        Geolocator.distanceBetween(
          _startLocation!.latitude,
          _startLocation!.longitude,
          _endLocation!.latitude,
          _endLocation!.longitude,
        ) /
        1000; // Convert to km

    // Create a simple straight line
    List<LatLng> simpleRoute = [_startLocation!, _endLocation!];

    setState(() {
      _polylines = {
        Polyline(
          polylineId: const PolylineId('simple_route'),
          points: simpleRoute,
          color: Colors.orange,
          width: 5,
          patterns: [PatternItem.dash(20), PatternItem.gap(10)],
        ),
      };

      _routeInfo =
          'Đường thẳng (ước tính): ${distance.toStringAsFixed(1)} km\n'
          'Thời gian: ${(distance * 2).toStringAsFixed(0)} phút (ước tính)';

      _isGettingRoute = false;
    });

    // Fit camera to show both points
    _fitCameraToRoute(simpleRoute);
  }

  // Fit camera to show entire route
  void _fitCameraToRoute(List<LatLng> coordinates) {
    if (mapController == null || coordinates.isEmpty) return;

    double minLat = coordinates.first.latitude;
    double maxLat = coordinates.first.latitude;
    double minLng = coordinates.first.longitude;
    double maxLng = coordinates.first.longitude;

    for (LatLng point in coordinates) {
      minLat = minLat < point.latitude ? minLat : point.latitude;
      maxLat = maxLat > point.latitude ? maxLat : point.latitude;
      minLng = minLng < point.longitude ? minLng : point.longitude;
      maxLng = maxLng > point.longitude ? maxLng : point.longitude;
    }

    mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        100.0, // padding
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Tìm kiếm địa điểm'),
          backgroundColor: Colors.blue[600],
          foregroundColor: Colors.white,
        ),
        body: Column(
          children: [
            // Search Bar
            Container(
              padding: const EdgeInsets.all(16.0),
              color: Colors.grey[100],
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Nhập địa điểm cần tìm...',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.search),
                      ),
                      onSubmitted: _searchPlaces,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _searchPlaces(_searchController.text),
                    child: const Text('Tìm'),
                  ),
                ],
              ),
            ),

            // Map
            Expanded(
              flex: 3,
              child: _currentPosition == null
                  ? const Center(child: CircularProgressIndicator())
                  : GoogleMap(
                      onMapCreated: _onMapCreated,
                      initialCameraPosition: CameraPosition(
                        target: LatLng(
                          _currentPosition!.latitude,
                          _currentPosition!.longitude,
                        ),
                        zoom: 15,
                      ),
                      markers: markers,
                      polylines: _polylines,
                      myLocationEnabled: true,
                      myLocationButtonEnabled: true,
                      onTap: _handleTap,
                    ),
            ),

            // Search Results or Current Location Info
            Expanded(
              flex: 2,
              child: _searchResults.isNotEmpty
                  ? _buildSearchResults()
                  : _buildCurrentLocationInfo(),
            ),

            // Direction Controls
            if (_selectedLocation != null) _buildDirectionControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'KẾT QUẢ TÌM KIẾM',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final result = _searchResults[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const Icon(
                            Icons.location_on,
                            color: Colors.red,
                          ),
                          title: Text(
                            result['name'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(result['address']),
                          onTap: () => _navigateToLocation(
                            result['latitude'],
                            result['longitude'],
                            result['name'],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentLocationInfo() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _selectedLocation != null ? 'VỊ TRÍ ĐƯỢC CHỌN' : 'VỊ TRÍ HIỆN TẠI',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(currentAddress),
          if (_selectedLocation != null) ...[
            const SizedBox(height: 8),
            Text(
              'Tọa độ: ${_selectedLocation!.latitude.toStringAsFixed(6)}, ${_selectedLocation!.longitude.toStringAsFixed(6)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
          if (_routeInfo.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Text(
                _routeInfo,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: getCurrentLocation,
            child: const Text('Lấy vị trí hiện tại'),
          ),
        ],
      ),
    );
  }

  Widget _buildDirectionControls() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CHỈ ĐƯỜNG',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _setStartLocation,
                  icon: const Icon(Icons.play_arrow, color: Colors.white),
                  label: const Text('Điểm xuất phát'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _setEndLocation,
                  icon: const Icon(Icons.flag, color: Colors.white),
                  label: const Text('Điểm đến'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _startLocation != null && _endLocation != null
                      ? _getRoute
                      : null,
                  icon: _isGettingRoute
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.directions, color: Colors.white),
                  label: const Text('Tìm đường'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _clearRoute,
                  icon: const Icon(Icons.clear, color: Colors.white),
                  label: const Text('Xóa đường'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          if (_startLocation != null || _endLocation != null) ...[
            const SizedBox(height: 8),
            Text(
              _startLocation != null
                  ? '✓ Điểm xuất phát đã chọn'
                  : 'Chưa chọn điểm xuất phát',
              style: TextStyle(
                color: _startLocation != null ? Colors.green : Colors.grey,
                fontSize: 12,
              ),
            ),
            Text(
              _endLocation != null
                  ? '✓ Điểm đến đã chọn'
                  : 'Chưa chọn điểm đến',
              style: TextStyle(
                color: _endLocation != null ? Colors.green : Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
