import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'models/route_data.dart';
import 'models/place_suggestion.dart';
import 'services/routing_service.dart';
import 'services/places_service.dart';
import 'widgets/place_search_field.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Position? _currentPosition;
  String currentAddress = "";
  GoogleMapController? mapController;
  Set<Marker> markers = {};
  Set<Polyline> polylines = {};
  
  // Routing variables
  final TextEditingController _destinationController = TextEditingController();
  RouteData? _currentRoute;
  bool _isLoadingRoute = false;
  late RoutingService _routingService;
  late PlacesService _placesService;
  
  // Location tracking
  StreamSubscription<Position>? _positionStreamSubscription;

  @override
  void initState() {
    super.initState();
    _routingService = RoutingService(apiKey: 'AIzaSyBJecgZLfDTdBejPAUVKtZIotX036OvIdA');
    _placesService = PlacesService(apiKey: 'AIzaSyBJecgZLfDTdBejPAUVKtZIotX036OvIdA');
    getCurrentLocation();
    _startLocationTracking();
  }

  // Theo dõi vị trí liên tục
  void _startLocationTracking() {
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Cập nhật khi di chuyển 10m
      ),
    ).listen((Position position) {
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
        getAddressFromLatLng();
      }
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    addMarker();
  }

  void addMarker() {
    if (_currentPosition == null) return;

    setState(() {
      // Chỉ thêm marker cho điểm đến, không thêm cho vị trí hiện tại
      // Vị trí hiện tại sẽ được hiển thị bằng myLocationEnabled
      markers.removeWhere((marker) => marker.markerId.value == 'currentLocation');
    });
  }

  void getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            setState(() {
              currentAddress = "Location permissions are denied";
            });
          }
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
        getAddressFromLatLng();

        // Tự động xoay camera đến vị trí hiện tại
        if (mapController != null) {
          mapController!.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: LatLng(position.latitude, position.longitude),
                zoom: 16, // Tăng zoom để thấy rõ hơn
                tilt: 0, // Góc nghiêng
                bearing: 0, // Hướng bắc
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        debugPrint('Error in getCurrentLocation: $e');
        setState(() {
          currentAddress = "Không thể lấy vị trí: $e";
        });
      }
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
      if (mounted) {
        debugPrint('Error getting current location: $e');
      }
    }
  }

  // Function để tìm đường đi
  void findRoute() async {
    if (_currentPosition == null || _destinationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập điểm đến')),
      );
      return;
    }

    setState(() {
      _isLoadingRoute = true;
    });

    try {
      // Geocoding để lấy tọa độ từ địa chỉ
      List<Location> locations = await locationFromAddress(_destinationController.text);
      if (locations.isEmpty) {
        throw Exception('Không tìm thấy địa chỉ');
      }

      Location destination = locations.first;
      LatLng destinationLatLng = LatLng(destination.latitude, destination.longitude);

      // Gọi API để lấy đường đi
      RouteData route = await _routingService.getRoute(
        origin: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        destination: destinationLatLng,
      );

      if (!route.isEmpty) {
        setState(() {
          _currentRoute = route;
          _updateMapWithRoute(route, destinationLatLng);
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không thể tìm đường đi')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error finding route: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoadingRoute = false;
      });
    }
  }

  // Function để cập nhật bản đồ với đường đi
  void _updateMapWithRoute(RouteData route, LatLng destination) {
    // Thêm marker điểm đến
    markers.add(
      Marker(
        markerId: const MarkerId('destination'),
        position: destination,
        infoWindow: InfoWindow(
          title: 'Điểm đến',
          snippet: _destinationController.text,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    );

    // Thêm polyline đường đi
    polylines.add(
      Polyline(
        polylineId: const PolylineId('route'),
        points: route.points,
        color: Colors.blue,
        width: 5,
      ),
    );

    // Di chuyển camera để hiển thị toàn bộ đường đi
    if (mapController != null) {
      _fitBounds(route.points);
    }
  }

  // Function để fit camera vào toàn bộ đường đi
  void _fitBounds(List<LatLng> points) {
    if (points.isEmpty) return;

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (LatLng point in points) {
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

  // Function để xóa đường đi
  void clearRoute() {
    setState(() {
      _currentRoute = null;
      polylines.clear();
      markers.removeWhere((marker) => marker.markerId.value == 'destination');
    });
  }

  // Function xử lý khi chọn địa chỉ từ gợi ý
  void _onPlaceSelected(PlaceSuggestion place) async {
    // Lấy chi tiết địa chỉ để có tọa độ
    final placeDetails = await _placesService.getPlaceDetails(place.placeId);
    if (placeDetails != null && placeDetails.latitude != null && placeDetails.longitude != null) {
      // Tự động tìm đường đi khi chọn địa chỉ
      _findRouteFromPlace(placeDetails);
    } else {
      // Nếu không có chi tiết, sử dụng thông tin từ place
      if (place.latitude != null && place.longitude != null) {
        _findRouteFromPlace(place);
      }
    }
  }

  // Function tìm đường đi từ địa chỉ đã chọn
  void _findRouteFromPlace(PlaceSuggestion place) async {
    if (_currentPosition == null) return;

    setState(() {
      _isLoadingRoute = true;
    });

    try {
      LatLng destination = LatLng(place.latitude!, place.longitude!);

      RouteData route = await _routingService.getRoute(
        origin: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        destination: destination,
      );

      if (!route.isEmpty) {
        setState(() {
          _currentRoute = route;
          _updateMapWithRoute(route, destination);
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không thể tìm đường đi')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error finding route from place: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoadingRoute = false;
      });
    }
  }

  @override
  void dispose() {
    _destinationController.dispose();
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
        return MaterialApp(
          home: Scaffold(
            appBar: AppBar(title: const Text('Google Maps Integration')),
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                if (_currentPosition != null) {
                  mapController?.animateCamera(
                    CameraUpdate.newCameraPosition(
                      CameraPosition(
                        target: LatLng(
                          _currentPosition!.latitude,
                          _currentPosition!.longitude,
                        ),
                        zoom: 16,
                        tilt: 0,
                        bearing: 0,
                      ),
                    ),
                  );
                }
              },
              child: const Icon(Icons.my_location),
              tooltip: 'Vị trí hiện tại',
            ),
        body: Column(
          children: [
            // Thanh tìm kiếm ở đầu màn hình
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Column(
                children: [
                  // Thông tin vị trí hiện tại
                  Row(
                    children: [
                      const Icon(Icons.my_location, color: Colors.blue, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          currentAddress.isEmpty ? 'Đang lấy vị trí...' : currentAddress,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        onPressed: getCurrentLocation,
                        icon: const Icon(Icons.refresh, color: Colors.blue),
                        tooltip: 'Cập nhật vị trí',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Ô nhập điểm đến với gợi ý
                  PlaceSearchField(
                    controller: _destinationController,
                    onPlaceSelected: _onPlaceSelected,
                    hintText: 'Nhập địa chỉ điểm đến...',
                  ),
                  
                  // Nút tìm đường đi
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isLoadingRoute ? null : findRoute,
                          icon: _isLoadingRoute 
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.directions),
                          label: Text(_isLoadingRoute ? 'Đang tìm...' : 'Tìm đường đi'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: clearRoute,
                        icon: const Icon(Icons.clear),
                        label: const Text('Xóa'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Bản đồ chiếm phần còn lại
            Expanded(
              child: _currentPosition == null
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Đang lấy vị trí hiện tại...'),
                        ],
                      ),
                    )
                  : GoogleMap(
                      onMapCreated: _onMapCreated,
                      initialCameraPosition: CameraPosition(
                        target: LatLng(
                          _currentPosition!.latitude,
                          _currentPosition!.longitude,
                        ),
                        zoom: 16,
                        tilt: 0,
                        bearing: 0,
                      ),
                      markers: markers,
                      polylines: polylines,
                      // Bật chấm xanh vị trí hiện tại
                      myLocationEnabled: true,
                      myLocationButtonEnabled: true,
                      // Cài đặt bản đồ
                      mapType: MapType.normal,
                      compassEnabled: true,
                      rotateGesturesEnabled: true,
                      scrollGesturesEnabled: true,
                      tiltGesturesEnabled: true,
                      zoomGesturesEnabled: true,
                      zoomControlsEnabled: false, // Ẩn nút zoom vì có myLocationButton
                    ),
            ),
            
            // Thông tin đường đi ở dưới cùng (nếu có)
            if (_currentRoute != null)
              Container(
                width: double.infinity,
                color: Colors.green.shade50,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'THÔNG TIN ĐƯỜNG ĐI',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.straighten, color: Colors.green, size: 16),
                            const SizedBox(width: 4),
                            Text('Khoảng cách: ${_currentRoute!.distance}'),
                          ],
                        ),
                        Row(
                          children: [
                            const Icon(Icons.access_time, color: Colors.green, size: 16),
                            const SizedBox(width: 4),
                            Text('Thời gian: ${_currentRoute!.duration}'),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
