import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../providers/map_provider.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/search_results_widget.dart';
import '../widgets/direction_controls_widget.dart';
import '../widgets/location_info_widget.dart';
import '../widgets/save_route_dialog.dart';
import '../widgets/saved_routes_widget.dart';
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
        actions: [
          IconButton(
            onPressed: () => _showSavedRoutes(context),
            icon: const Icon(Icons.bookmark),
            tooltip: AppConstants.savedRoutesTitle,
          ),
        ],
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
                  onSaveRoute: mapProvider.canSaveRoute
                      ? () => _showSaveRouteDialog(context, mapProvider)
                      : null,
                  canGetRoute: mapProvider.canGetRoute,
                  isGettingRoute: mapProvider.isGettingRoute,
                  hasStartLocation: mapProvider.startLocation != null,
                  hasEndLocation: mapProvider.endLocation != null,
                  canSaveRoute: mapProvider.canSaveRoute,
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

  void _showSaveRouteDialog(BuildContext context, MapProvider mapProvider) {
    showDialog(
      context: context,
      builder: (context) => SaveRouteDialog(
        onSave: (name, description) async {
          final success = await mapProvider.saveCurrentRoute(name, description);
          if (success && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(AppConstants.routeSavedSuccess),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
      ),
    );
  }

  void _showSavedRoutes(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.3,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.defaultPadding,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppConstants.savedRoutesTitle,
                      style: AppConstants.titleStyle.copyWith(fontSize: 20),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),

              // Saved routes list
              Expanded(
                child: Consumer<MapProvider>(
                  builder: (context, mapProvider, child) {
                    return SavedRoutesWidget(
                      routes: mapProvider.savedRoutes,
                      onLoadRoute: (route) {
                        mapProvider.loadSavedRoute(route);
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(AppConstants.routeLoadedSuccess),
                            backgroundColor: Colors.blue,
                          ),
                        );
                      },
                      onDeleteRoute: (routeId) async {
                        final success = await mapProvider.deleteSavedRoute(
                          routeId,
                        );
                        if (success && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(AppConstants.routeDeletedSuccess),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        }
                      },
                      onToggleFavorite: (routeId) {
                        mapProvider.toggleRouteFavorite(routeId);
                      },
                      isLoading: mapProvider.isLoadingSavedRoutes,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
