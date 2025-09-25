import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class ApiService {
  static Future<String?> reverseGeocode({required double lat, required double lng}) async {
    final uri = Uri.parse(
      '${ApiConfig.geocodeBaseUrl}?latlng=$lat,$lng&key=${ApiConfig.googleMapsApiKey}',
    );
    final response = await http.get(uri);
    if (response.statusCode != 200) return null;
    final data = json.decode(response.body) as Map<String, dynamic>;
    if (data['status'] != 'OK') return null;
    final results = data['results'] as List<dynamic>;
    if (results.isEmpty) return null;
    return results.first['formatted_address'] as String?;
  }
}