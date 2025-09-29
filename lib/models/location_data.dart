class LocationData {
  final double latitude;
  final double longitude;
  final String? address;
  final String? name;

  LocationData({
    required this.latitude,
    required this.longitude,
    this.address,
    this.name,
  });

  factory LocationData.fromLatLng(double lat, double lng, {String? address, String? name}) {
    return LocationData(
      latitude: lat,
      longitude: lng,
      address: address,
      name: name,
    );
  }

  @override
  String toString() {
    return 'LocationData(lat: $latitude, lng: $longitude, address: $address)';
  }
}
