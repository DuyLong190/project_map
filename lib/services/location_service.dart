import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  /// Kiểm tra & xin quyền. Trả về quyền hiện tại.
  Future<LocationPermission> ensurePermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission;
  }

  /// Lấy vị trí hiện tại với độ chính xác cao.
  Future<Position> getCurrentPosition() async {
    return Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  /// Reverse geocoding -> địa chỉ dạng chuỗi.
  Future<String> reverseGeocode(double latitude, double longitude) async {
    final placemarks = await placemarkFromCoordinates(latitude, longitude);
    if (placemarks.isEmpty) return "";

    final p = placemarks.first;
    return "${p.street}, ${p.subLocality}, ${p.locality}, ${p.administrativeArea}, ${p.country}";
  }
}
