import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/place_suggestion.dart';

class PlacesService {
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/place';
  final String apiKey;

  PlacesService({required this.apiKey});

  // Tìm kiếm địa chỉ theo từ khóa
  Future<List<PlaceSuggestion>> searchPlaces(String query) async {
    if (query.isEmpty) return [];

    try {
      final encodedQuery = Uri.encodeComponent(query);
      final url = Uri.parse('$_baseUrl/autocomplete/json?'
          'input=$encodedQuery'
          '&types=establishment|geocode'
          '&language=vi'
          '&components=country:vn'
          '&key=$apiKey');

      debugPrint('Searching places: $url');

      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('Places API timeout');
          throw Exception('Request timeout');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK') {
          final predictions = data['predictions'] as List;
          final suggestions = predictions.map((json) => PlaceSuggestion.fromJson(json)).toList();
          debugPrint('Found ${suggestions.length} places from API');
          return suggestions;
        } else {
          debugPrint('Places API error: ${data['status']} - ${data['error_message']}');
          // Ném exception để fallback về mock data
          throw Exception('API error: ${data['status']}');
        }
      } else {
        debugPrint('HTTP error: ${response.statusCode} - ${response.body}');
        throw Exception('HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error searching places: $e');
      // Ném exception để fallback về mock data
      rethrow;
    }
  }

  // Lấy chi tiết địa chỉ từ place_id
  Future<PlaceSuggestion?> getPlaceDetails(String placeId) async {
    try {
      final url = Uri.parse('$_baseUrl/details/json?'
          'place_id=$placeId'
          '&fields=place_id,name,formatted_address,geometry'
          '&key=$apiKey');

      debugPrint('Getting place details: $url');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK') {
          final result = data['result'];
          return PlaceSuggestion(
            placeId: result['place_id'] ?? '',
            description: result['formatted_address'] ?? '',
            mainText: result['name'],
            latitude: result['geometry']?['location']?['lat']?.toDouble(),
            longitude: result['geometry']?['location']?['lng']?.toDouble(),
          );
        } else {
          debugPrint('Place details API error: ${data['status']}');
          return null;
        }
      } else {
        debugPrint('HTTP error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error getting place details: $e');
      return null;
    }
  }
}
