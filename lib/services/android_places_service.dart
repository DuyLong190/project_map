import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class AndroidPlacesService {
  static const MethodChannel _channel = MethodChannel('com.example.project_map/places');

  static Future<Map<String, dynamic>?> openPlacesAutocomplete() async {
    try {
      final result = await _channel.invokeMethod('openPlacesAutocomplete');
      return Map<String, dynamic>.from(result);
    } on PlatformException catch (e) {
      debugPrint('Error opening places autocomplete: ${e.message}');
      return null;
    }
  }
}
