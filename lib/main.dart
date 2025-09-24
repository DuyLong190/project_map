import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Position? _currentPosition;
  String currentAddress = "";

  @override
  void initState() {
    super.initState();
    getCurrentLocation();
  }

  void getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            currentAddress = "Location permissions are denied";
          });
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          currentAddress = "Location permissions are permanently denied";
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        forceAndroidLocationManager: true,
      );

      setState(() {
        _currentPosition = position;
      });
      getAddressFromLatLng();
    } catch (e) {
      print(e);
      setState(() {
        currentAddress = "Error getting location";
      });
    }
  }

  void getAddressFromLatLng() async {
    try {
      if (_currentPosition == null) return;

      List<Placemark> p = await placemarkFromCoordinates(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );
      Placemark place = p[0];
      setState(() {
        currentAddress =
        "${place.street}, ${place.subLocality}, ${place.locality}, ${place.administrativeArea}, ${place.country}";
      });
    } catch (e) {
      print(e);
      setState(() {
        currentAddress = "Error getting address";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text("Geolocator")),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.location_on),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      ElevatedButton(
                        onPressed: getCurrentLocation,
                        child: Text(
                          'Get Location',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      if (currentAddress != null)
                        Text(currentAddress, style: TextStyle(fontSize: 20.0))
                      else
                        Text("Couldn't fetch the location"),
                    ],
                  ),
                ),
                SizedBox(width: 8),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
