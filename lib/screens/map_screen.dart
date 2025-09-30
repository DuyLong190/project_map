import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../providers/map_provider.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/search_results_widget.dart';
import '../widgets/direction_controls_widget.dart';
import '../widgets/location_info_widget.dart';
import '../constants/app_constants.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MapProvider>().initialize();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Consumer<MapProvider>(
        builder: (context, mapProvider, child) {
          return Column(
            children: [
              // Search Bar
              SearchBarWidget(
                controller: _searchController,
                onSearch: mapProvider.searchPlaces,
                isLoading: mapProvider.isSearching,
              ),

              // Map
              Expanded(flex: 3, child: _buildMap(mapProvider)),

              // Content area (search results or location info)
              Expanded(flex: 2, child: _buildContentArea(mapProvider)),

              // Direction controls (only show if location is selected)
              if (mapProvider.hasSelectedLocation())
                DirectionControlsWidget(
                  onSetStart: mapProvider.setStartLocation,
                  onSetEnd: mapProvider.setEndLocation,
                  onGetRoute: mapProvider.getRoute,
                  onClearRoute: mapProvider.clearRoute,
                  canGetRoute: mapProvider.canGetRoute,
                  isGettingRoute: mapProvider.isGettingRoute,
                  hasStartLocation: mapProvider.startLocation != null,
                  hasEndLocation: mapProvider.endLocation != null,
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMap(MapProvider mapProvider) {
    if (mapProvider.currentLocation == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return GoogleMap(
      onMapCreated: mapProvider.setMapController,
      initialCameraPosition: CameraPosition(
        target: mapProvider.currentLocation!.coordinates,
        zoom: AppConstants.defaultZoom,
      ),
      markers: mapProvider.markers,
      polylines: mapProvider.polylines,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      onTap: (LatLng coordinates) {
        _handleMapTap(coordinates, mapProvider);
      },
    );
  }

  Widget _buildContentArea(MapProvider mapProvider) {
    if (mapProvider.searchResults.isNotEmpty) {
      return SearchResultsWidget(
        results: mapProvider.searchResults,
        onResultTap: (result) {
          mapProvider.selectSearchResult(result);
          _searchController.clear();
        },
        isLoading: mapProvider.isSearching,
      );
    }

    return LocationInfoWidget(
      currentLocation: mapProvider.currentLocation,
      selectedLocation: mapProvider.selectedLocation,
      currentRoute: mapProvider.currentRoute,
      onGetCurrentLocation: mapProvider.getCurrentLocation,
      isLoadingCurrentLocation: mapProvider.isLoadingCurrentLocation,
    );
  }

  void _handleMapTap(LatLng coordinates, MapProvider mapProvider) async {
    // Get address for tapped location
    // We'll add this method to MapProvider to handle address lookup
    mapProvider.selectLocationFromTap(coordinates);
  }
}
