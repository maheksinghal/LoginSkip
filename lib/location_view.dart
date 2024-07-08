import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class LocationView extends StatefulWidget {
  const LocationView({Key? key}) : super(key: key);

  @override
  _LocationViewState createState() => _LocationViewState();
}

class _LocationViewState extends State<LocationView>
    with AutomaticKeepAliveClientMixin {
  String _location = '';

  Future<void> _getLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _location = 'Location services are disabled.';
      });
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _location = 'Location permissions are denied';
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _location = 'Location permissions are permanently denied.';
      });
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _location = 'Lat: ${position.latitude}, Lon: ${position.longitude}';
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: _getLocation,
            child: const Text('Get Location'),
          ),
          const SizedBox(height: 20),
          Text(_location),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
