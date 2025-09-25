import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  static String get googleMapsApiKey => dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';

  // Google Maps Web Services endpoints
  static const String geocodeBaseUrl = 'https://maps.googleapis.com/maps/api/geocode/json';
}