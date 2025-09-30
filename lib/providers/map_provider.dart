import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/location_model.dart';
import '../models/route_model.dart';
import '../models/search_result_model.dart';
import '../models/saved_route_model.dart';
import '../services/location_service.dart';
import '../services/route_service.dart';
import '../services/search_service.dart';
import '../services/storage_service.dart';

class MapProvider with ChangeNotifier {
  // Services
  final LocationService _locationService = LocationService();
  final RouteService _routeService = RouteService();
  final SearchService _searchService = SearchService();
  final StorageService _storageService = StorageService();

  // State variables
  LocationModel? _currentLocation;
  LocationModel? _selectedLocation;
  LocationModel? _startLocation;
  LocationModel? _endLocation;

  List<SearchResultModel> _searchResults = [];
  RouteModel _currentRoute = RouteModel.empty();
  List<SavedRouteModel> _savedRoutes = [];

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  GoogleMapController? _mapController;

  // Loading states
  bool _isLoadingCurrentLocation = false;
  bool _isSearching = false;
  bool _isGettingRoute = false;
  bool _isLoadingSavedRoutes = false;

  // Getters
  LocationModel? get currentLocation => _currentLocation;
  LocationModel? get selectedLocation => _selectedLocation;
  LocationModel? get startLocation => _startLocation;
  LocationModel? get endLocation => _endLocation;

  List<SearchResultModel> get searchResults => _searchResults;
  RouteModel get currentRoute => _currentRoute;
  List<SavedRouteModel> get savedRoutes => _savedRoutes;

  Set<Marker> get markers => _markers;
  Set<Polyline> get polylines => _polylines;

  GoogleMapController? get mapController => _mapController;

  bool get isLoadingCurrentLocation => _isLoadingCurrentLocation;
  bool get isSearching => _isSearching;
  bool get isGettingRoute => _isGettingRoute;
  bool get isLoadingSavedRoutes => _isLoadingSavedRoutes;

  bool get hasRoute => !_currentRoute.isEmpty;
  bool get canGetRoute => _startLocation != null && _endLocation != null;
  bool get canSaveRoute =>
      hasRoute && _startLocation != null && _endLocation != null;

  // Initialize
  Future<void> initialize() async {
    await getCurrentLocation();
    await loadSavedRoutes();
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

  // Saved Routes functionality
  Future<void> loadSavedRoutes() async {
    _isLoadingSavedRoutes = true;
    notifyListeners();

    try {
      _savedRoutes = await _storageService.getSavedRoutes();
    } catch (e) {
      print('Error loading saved routes: $e');
    } finally {
      _isLoadingSavedRoutes = false;
      notifyListeners();
    }
  }

  Future<bool> saveCurrentRoute(String name, String description) async {
    if (!canSaveRoute) return false;

    try {
      final savedRoute = SavedRouteModel.create(
        name: name,
        description: description,
        startLocation: _startLocation!,
        endLocation: _endLocation!,
        route: _currentRoute,
      );

      final success = await _storageService.saveRoute(savedRoute);
      if (success) {
        await loadSavedRoutes(); // Reload to get updated list
      }
      return success;
    } catch (e) {
      print('Error saving route: $e');
      return false;
    }
  }

  Future<void> loadSavedRoute(SavedRouteModel savedRoute) async {
    try {
      // Update route and mark as accessed
      final updatedRoute = savedRoute.markAsAccessed();
      await _storageService.updateRoute(updatedRoute);

      // Load the route into current state
      _startLocation = savedRoute.startLocation;
      _endLocation = savedRoute.endLocation;
      _currentRoute = savedRoute.route;

      _updateMarkers();
      _updatePolylines();
      _fitCameraToRoute();

      // Update saved routes list
      await loadSavedRoutes();

      notifyListeners();
    } catch (e) {
      print('Error loading saved route: $e');
    }
  }

  Future<bool> deleteSavedRoute(String routeId) async {
    try {
      final success = await _storageService.deleteRoute(routeId);
      if (success) {
        await loadSavedRoutes(); // Reload to get updated list
      }
      return success;
    } catch (e) {
      print('Error deleting route: $e');
      return false;
    }
  }

  Future<void> toggleRouteFavorite(String routeId) async {
    try {
      final route = _savedRoutes.firstWhere((r) => r.id == routeId);
      final updatedRoute = route.toggleFavorite();
      await _storageService.updateRoute(updatedRoute);
      await loadSavedRoutes(); // Reload to get updated list
    } catch (e) {
      print('Error toggling route favorite: $e');
    }
  }

  List<SavedRouteModel> getFavoriteRoutes() {
    return _savedRoutes.where((route) => route.isFavorite).toList();
  }

  Future<List<SavedRouteModel>> searchSavedRoutes(String query) async {
    return await _storageService.searchRoutes(query);
  }
}
