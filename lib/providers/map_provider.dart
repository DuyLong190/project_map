import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/location_model.dart';
import '../models/route_model.dart';
import '../models/search_result_model.dart';
import '../services/location_service.dart';
import '../services/route_service.dart';
import '../services/search_service.dart';

class MapProvider with ChangeNotifier {
  // Services
  final LocationService _locationService = LocationService();
  final RouteService _routeService = RouteService();
  final SearchService _searchService = SearchService();

  // State variables
  LocationModel? _currentLocation;
  LocationModel? _selectedLocation;
  LocationModel? _startLocation;
  LocationModel? _endLocation;

  List<SearchResultModel> _searchResults = [];
  RouteModel _currentRoute = RouteModel.empty();

  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  GoogleMapController? _mapController;

  // Loading states
  bool _isLoadingCurrentLocation = false;
  bool _isSearching = false;
  bool _isGettingRoute = false;

  // Getters
  LocationModel? get currentLocation => _currentLocation;
  LocationModel? get selectedLocation => _selectedLocation;
  LocationModel? get startLocation => _startLocation;
  LocationModel? get endLocation => _endLocation;

  List<SearchResultModel> get searchResults => _searchResults;
  RouteModel get currentRoute => _currentRoute;

  Set<Marker> get markers => _markers;
  Set<Polyline> get polylines => _polylines;

  GoogleMapController? get mapController => _mapController;

  bool get isLoadingCurrentLocation => _isLoadingCurrentLocation;
  bool get isSearching => _isSearching;
  bool get isGettingRoute => _isGettingRoute;

  bool get hasRoute => !_currentRoute.isEmpty;
  bool get canGetRoute => _startLocation != null && _endLocation != null;

  // Initialize
  Future<void> initialize() async {
    await getCurrentLocation();
  }

  // Map controller
  void setMapController(GoogleMapController controller) {
    _mapController = controller;
    notifyListeners();
  }

  // Current location
  Future<void> getCurrentLocation() async {
    _isLoadingCurrentLocation = true;
    notifyListeners();

    try {
      _currentLocation = await _locationService.getCurrentLocation();
      if (_currentLocation != null) {
        _updateMarkers();
        _moveToLocation(_currentLocation!.coordinates);
      }
    } catch (e) {
      print('Error getting current location: $e');
    } finally {
      _isLoadingCurrentLocation = false;
      notifyListeners();
    }
  }

  // Location selection
  void selectLocation(LatLng coordinates, String address) {
    _selectedLocation = LocationModel.fromLatLng(coordinates, address);
    _updateMarkers();
    notifyListeners();
  }

  void selectLocationFromTap(LatLng coordinates) async {
    String address = await _locationService.getAddressFromCoordinates(
      coordinates.latitude,
      coordinates.longitude,
    );
    selectLocation(coordinates, address);
  }

  void setStartLocation() {
    if (_selectedLocation != null) {
      _startLocation = _selectedLocation;
      _clearRoute();
      _updateMarkers();
      notifyListeners();
    }
  }

  void setEndLocation() {
    if (_selectedLocation != null) {
      _endLocation = _selectedLocation;
      _clearRoute();
      _updateMarkers();
      notifyListeners();

      // Auto get route if both locations are set
      if (_startLocation != null && _endLocation != null) {
        getRoute();
      }
    }
  }

  // Search functionality
  Future<void> searchPlaces(String query) async {
    if (query.isEmpty) {
      _searchResults.clear();
      notifyListeners();
      return;
    }

    _isSearching = true;
    notifyListeners();

    try {
      _searchResults = await _searchService.searchPlaces(query);
    } catch (e) {
      print('Search error: $e');
      _searchResults.clear();
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  void selectSearchResult(SearchResultModel result) {
    _selectedLocation = LocationModel(
      coordinates: result.coordinates,
      address: result.address,
      name: result.name,
    );
    _searchResults.clear();
    _updateMarkers();
    _moveToLocation(result.coordinates);
    notifyListeners();
  }

  // Route functionality
  Future<void> getRoute() async {
    if (_startLocation == null || _endLocation == null) return;

    _isGettingRoute = true;
    notifyListeners();

    try {
      _currentRoute = await _routeService.getRoute(
        _startLocation!,
        _endLocation!,
      );
      _updatePolylines();
      _fitCameraToRoute();
    } catch (e) {
      print('Route error: $e');
    } finally {
      _isGettingRoute = false;
      notifyListeners();
    }
  }

  void clearRoute() {
    _currentRoute = RouteModel.empty();
    _polylines.clear();
    notifyListeners();
  }

  // Map navigation
  void moveToLocation(LatLng coordinates) {
    _moveToLocation(coordinates);
  }

  void _moveToLocation(LatLng coordinates) {
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: coordinates, zoom: 15.0),
      ),
    );
  }

  void _fitCameraToRoute() {
    if (_currentRoute.isEmpty) return;

    LatLngBounds? bounds = _routeService.calculateRouteBounds(_currentRoute);
    if (bounds != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 100.0),
      );
    }
  }

  // Markers and polylines
  void _updateMarkers() {
    _markers.clear();

    // Current location marker
    if (_currentLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: _currentLocation!.coordinates,
          infoWindow: const InfoWindow(title: 'Vị trí hiện tại'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    }

    // Start location marker
    if (_startLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('start_location'),
          position: _startLocation!.coordinates,
          infoWindow: const InfoWindow(title: 'Điểm xuất phát'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
        ),
      );
    }

    // End location marker
    if (_endLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('end_location'),
          position: _endLocation!.coordinates,
          infoWindow: const InfoWindow(title: 'Điểm đến'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }
  }

  void _updatePolylines() {
    _polylines.clear();

    if (!_currentRoute.isEmpty) {
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: _currentRoute.coordinates,
          color: _currentRoute.isEstimated ? Colors.orange : Colors.blue,
          width: 5,
          patterns: _currentRoute.isEstimated
              ? [PatternItem.dash(20), PatternItem.gap(10)]
              : [],
        ),
      );
    }
  }

  void _clearRoute() {
    _currentRoute = RouteModel.empty();
    _polylines.clear();
  }

  // Utility methods
  String getCurrentAddress() {
    if (_selectedLocation != null) {
      return _selectedLocation!.address;
    } else if (_currentLocation != null) {
      return _currentLocation!.address;
    }
    return '';
  }

  bool hasSelectedLocation() {
    return _selectedLocation != null;
  }

  void clearSelection() {
    _selectedLocation = null;
    _updateMarkers();
    notifyListeners();
  }
}
