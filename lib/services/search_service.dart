import 'package:geocoding/geocoding.dart';
import '../models/search_result_model.dart';

class SearchService {
  static final SearchService _instance = SearchService._internal();
  factory SearchService() => _instance;
  SearchService._internal();

  /// Search for places using geocoding
  Future<List<SearchResultModel>> searchPlaces(String query) async {
    if (query.isEmpty) return [];

    try {
      // Use geocoding to search for places
      List<Location> locations = await locationFromAddress(query);

      if (locations.isEmpty) return [];

      List<SearchResultModel> results = [];

      for (int i = 0; i < locations.length && i < 5; i++) {
        Location location = locations[i];

        // Get detailed address information
        List<Placemark> placemarks = await placemarkFromCoordinates(
          location.latitude,
          location.longitude,
        );

        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          String fullAddress =
              "${place.street}, ${place.subLocality}, "
              "${place.locality}, ${place.administrativeArea}, "
              "${place.country}";

          results.add(
            SearchResultModel.fromGeocodingResult(
              query,
              location.latitude,
              location.longitude,
              fullAddress,
            ),
          );
        }
      }

      return results;
    } catch (e) {
      print('Search error: $e');
      return [];
    }
  }

  /// Search for places with specific type (future enhancement)
  Future<List<SearchResultModel>> searchPlacesByType(
    String query,
    String type,
  ) async {
    // For now, just use regular search
    // This can be enhanced with Google Places API or similar
    return searchPlaces(query);
  }

  /// Get nearby places (future enhancement)
  Future<List<SearchResultModel>> getNearbyPlaces(
    double latitude,
    double longitude,
    double radiusKm,
  ) async {
    // This would require Google Places API or similar
    // For now, return empty list
    return [];
  }

  /// Validate search query
  bool isValidSearchQuery(String query) {
    return query.trim().isNotEmpty && query.trim().length >= 2;
  }

  /// Clean search query
  String cleanSearchQuery(String query) {
    return query.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Get search suggestions (future enhancement)
  Future<List<String>> getSearchSuggestions(String partialQuery) async {
    // This could be implemented with a local database
    // or by caching previous searches
    return [];
  }
}
