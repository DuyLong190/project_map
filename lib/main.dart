import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final geolocator = Geolocator.getCurrentPosition(forceAndroidLocationManager: true);
  late Position _currentPosition;
  String currentAddress = "";

  void getCurrentLocation() {
    Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high).then((Position position) {
      setState(() {
        _currentPosition = position;
      });

      getAddressFromLatLng();
    }).catchError((e) {
      print(e);
    });
  }

  void getAddressFromLatLng() async {
    try {
      List<Placemark> p = await placemarkFromCoordinates(_currentPosition.latitude, _currentPosition.longitude);
      Placemark place = p[0];
      setState(() {
        currentAddress = "${place.name}, ${place.locality}, ${place.postalCode}, ${place.country}";
      });
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text("Geolocator"),
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.location_on),
                SizedBox(
                  width: 8,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      ElevatedButton(
                        child: Text(
                          'Get Location',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        onPressed: getCurrentLocation,
                      ),
                      if (_currentPosition != null &&
                          currentAddress != null)
                        Text(currentAddress,
                            style: TextStyle(fontSize: 20.0))
                      else
                        Text("Couldn't fetch the location"),
                    ],
                  ),
                ),
                SizedBox(
                  width: 8,
                ),
              ],
            ),
          ],
        )
      )
    );
  }
}